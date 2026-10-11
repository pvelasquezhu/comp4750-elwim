{-# LANGUAGE TypeFamilies #-}
module Source.SourceItr (SourceItr, begin) where

import qualified Iterator

import Source.Position


-- Used to iterate over characters in the string
data SourceItr = SourceItr Position String


-- Create iterator pointing at beginning of string
begin :: String -> SourceItr
begin = SourceItr (Position 1 1)


-- Iterators are equal if their positions are equal
-- (This assumes we only ever compare iterators pointing into the same string)
instance Eq SourceItr where
  (==) :: SourceItr -> SourceItr -> Bool
  (SourceItr pos1 _) == (SourceItr pos2 _) = pos1 == pos2


-- We don't want to show the whole string, only its position
instance Show SourceItr where
  show :: SourceItr -> String
  show (SourceItr pos _) = show pos



-- Define as an iterator
instance Iterator.Iterator SourceItr where
  type Value SourceItr = Char

  isEnd :: SourceItr -> Bool
  isEnd (SourceItr _ "") = True
  isEnd _ = False

  curValue :: SourceItr -> Maybe Char
  curValue (SourceItr _ "") = Nothing
  curValue (SourceItr _ (c:_)) = Just c

  next :: SourceItr -> SourceItr
  next self@(SourceItr _ "") = self
  next (SourceItr pos (c:rest)) =
    if c == '\n'
      then SourceItr Position { line = line pos + 1, char = 1 } rest
      else SourceItr pos { char = char pos + 1 } rest


-- Define as positioned
instance Positioned SourceItr where
  posOf :: SourceItr -> Position
  posOf (SourceItr pos _) = pos


