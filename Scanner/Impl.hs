module Scanner.Impl (scan) where

import qualified Data.Char as Char
import Control.Applicative (many, some, optional, (<|>))
import Data.Map.Strict ((!?))
import Data.Maybe (fromMaybe)

import qualified Source
import qualified Stream
import qualified Scanner.Lexemes as Lexemes
import Scanner.Token



-- A scanner is just a special kind of stream processor
type Scanner = Stream.Processor Source.SourceItr


scanWhitespace :: Scanner String
scanWhitespace = many (Stream.satisfy Char.isSpace)


scanIdentifier :: Scanner Token
scanIdentifier = do
  first <- Stream.satisfy isIdStart
  rest <- many (Stream.satisfy isIdContinue)
  let id = first : rest
  return $ fromMaybe (Identifier id) (Lexemes.keywords !? id)
  where
    isIdStart c = c == '_' || Char.isAlpha c
    isIdContinue c = c == '_' || Char.isAlphaNum c


scanNumber :: Scanner Token
scanNumber = do
  intStr <- some (Stream.satisfy Char.isDigit)
  maybeFloatStr <- optional fraction
  case maybeFloatStr of
    Just floatStr -> return (Number $ read $ intStr ++ floatStr)
    Nothing       -> return (Number $ read intStr)
  where
    fraction = do
      Stream.satisfy (== '.')
      digits <- some (Stream.satisfy Char.isDigit)
      return ('.' : digits)


scanPunctuation2 :: Scanner Token
scanPunctuation2 = do
  c <- Stream.getNext
  d <- Stream.getNext
  maybe Stream.optionFail return (Lexemes.punctuation !? [c, d])


scanPunctuation1 :: Scanner Token
scanPunctuation1 = do
  c <- Stream.getNext
  maybe Stream.optionFail return (Lexemes.punctuation !? [c])


scanToken :: Scanner PosToken
scanToken = do
  scanWhitespace
  pos <- Stream.getPos
  token <- scanNumber <|> scanIdentifier <|> scanPunctuation2 <|> scanPunctuation1
  return $ PosToken pos token


allTokens :: Scanner [PosToken]
allTokens = do
  tokens <- some scanToken
  scanWhitespace
  pos <- Stream.getPos
  eof <- Stream.getEof
  if eof
    then return tokens
    else fail "unrecognized character"


scan :: String -> Either (Source.Position, String) [PosToken]
scan text = Stream.processResult allTokens (Source.begin text)
