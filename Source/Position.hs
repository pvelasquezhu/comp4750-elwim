module Source.Position (Position(..), Positioned(..)) where



-- A position (i.e., line number/character number) in the source text
data Position = Position {
    line :: Int,
    char :: Int
  }
  deriving (Eq)


-- Pretty print
instance Show Position where
  show :: Position -> String
  show (Position l c) = "[" ++ show l ++ ":" ++ show c ++ "]"



-- Class for types that have a position
class Positioned a where
  posOf :: a -> Position


instance Positioned Position where
  posOf :: Position -> Position
  posOf = id
