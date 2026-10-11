module Stream where

import Control.Applicative (Alternative (..))
import Control.Monad (liftM, ap)

import qualified Source
import qualified Iterator ( Iterator(..) )


data ProcessResult itrT va
  = Processed va itrT
  | OptionFailed itrT
  | ProcessFailed String itrT
  deriving (Show)


--------------------------------------------------------------------------------
-- The actual type and its accessors

newtype Processor itrT valT = Processor (itrT -> ProcessResult itrT valT)


-- Getter for the function inside the processor
process :: Processor itrT valT -> itrT -> ProcessResult itrT valT
process (Processor f) = f


-- Run a parser and interpret the ProcessResult as success or failure
processResult :: Source.Positioned itrT => Processor itrT valT -> itrT -> Either (Source.Position, String) valT
processResult (Processor f) itr = case f itr of
  Processed value _         -> Right value
  OptionFailed itr          -> Left (Source.posOf itr, "parser error")
  ProcessFailed msg itr_msg -> Left (Source.posOf itr_msg, msg)


-- Return next value in the stream without removing it
peekNext :: Iterator.Iterator itrT => Processor itrT (Iterator.Value itrT)
peekNext = Processor impl
  where
    impl itr = case Iterator.curValue itr of
      Just value -> Processed value itr
      Nothing    -> OptionFailed itr


-- Remove and return next value in the stream
getNext :: Iterator.Iterator itrT => Processor itrT (Iterator.Value itrT)
getNext = Processor impl
  where
    impl itr = case Iterator.curValue itr of
      Just value -> Processed value (Iterator.next itr)
      Nothing    -> OptionFailed itr


-- Return current position in the stream
getPos :: Source.Positioned itrT => Processor itrT Source.Position
getPos = Processor impl
  where
    impl itr = Processed (Source.posOf itr) itr


-- Test for end of stream
getEof :: Iterator.Iterator itrT => Processor itrT Bool
getEof = Processor impl
  where
    impl itr = Processed (Iterator.isEnd itr) itr


-- Trigger a soft failure
optionFail :: Processor itrT a
optionFail = Processor OptionFailed


-- Remove and return next value *if* it satisfies predicate
satisfy :: Iterator.Iterator itrT => (Iterator.Value itrT -> Bool) -> Processor itrT (Iterator.Value itrT)
satisfy pred = Processor impl
  where
    impl itr = case Iterator.curValue itr of
      Just value | pred value -> Processed value (Iterator.next itr)
      _                       -> OptionFailed itr


-- Run processor and trigger hard failure if it does not succeed
require :: Processor itrT valT -> String -> Processor itrT valT
require procA msg = Processor impl
  where
    impl itr = case process procA itr of
      OptionFailed itr -> ProcessFailed msg itr
      result           -> result


--------------------------------------------------------------------------------
-- Type class definitions

instance Functor (Processor itrT) where
  fmap :: (a -> b) -> Processor itrT a -> Processor itrT b
  fmap = liftM


instance Applicative (Processor itrT) where
  pure :: a -> Processor itrT a
  pure a = Processor (Processed a)

  (<*>) :: Processor itrT (a -> b) -> Processor itrT a -> Processor itrT b
  (<*>) = ap


instance Monad (Processor itrT) where
  (>>=) :: Processor itrT a -> (a -> Processor itrT b) -> Processor itrT b
  procA >>= f = Processor impl
    where
      impl itr = case process procA itr of
        ProcessFailed msg itr_fail -> ProcessFailed msg itr_fail
        OptionFailed itr_fail      -> OptionFailed itr_fail
        Processed a itr_a          -> process (f a) itr_a


instance MonadFail (Processor itrT) where
  fail :: String -> Processor itrT a
  fail msg = Processor (ProcessFailed msg)


instance Alternative (Processor itrT) where
  empty :: Processor itrT a
  empty = Processor OptionFailed

  (<|>) :: Processor itrT a -> Processor itrT a -> Processor itrT a
  procA <|> procB = Processor impl
    where
      impl itr = case process procA itr of
        ProcessFailed msg itr_a -> ProcessFailed msg itr_a
        OptionFailed _          -> process procB itr
        Processed a itr_a       -> Processed a itr_a
