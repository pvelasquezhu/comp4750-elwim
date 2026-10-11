{-# LANGUAGE TypeFamilies #-}
module Scanner.TokenItr where

import qualified Source
import qualified Iterator

import Scanner.Token


-- Used to iterate over (positioned) tokens in a list
newtype TokenItr = TokenItr [PosToken]
  deriving (Show)


-- Create iterator pointing at beginning of list
begin :: [PosToken] -> TokenItr
begin = TokenItr


-- Iterators are equal if their positions are equal
-- (This assumes we only ever compare iterators pointing to the same token list)
instance Eq TokenItr where
  (==) :: TokenItr -> TokenItr -> Bool
  (TokenItr []) == (TokenItr []) = True
  (TokenItr (a : _)) == (TokenItr (b : _)) = Source.posOf a == Source.posOf b
  _ == _ = False



-- Define as an iterator
instance Iterator.Iterator TokenItr where
  type Value TokenItr = Token

  isEnd :: TokenItr -> Bool
  isEnd (TokenItr []) = True
  isEnd _ = False

  curValue :: TokenItr -> Maybe Token
  curValue (TokenItr []) = Nothing
  curValue (TokenItr (PosToken _ token : _)) = Just token

  next :: TokenItr -> TokenItr
  next (TokenItr []) = TokenItr []
  next (TokenItr (_ : rest)) = TokenItr rest



-- Define as positioned
instance Source.Positioned TokenItr where
  posOf :: TokenItr -> Source.Position
  posOf (TokenItr []) = error "cannot dereference end"
  posOf (TokenItr (PosToken pos _ : _)) = pos
