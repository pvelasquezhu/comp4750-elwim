{-# LANGUAGE TypeFamilies #-}

module Iterator where


-- Class for iterator types
class Iterator a where

  -- What do you get when you dereference?
  type Value a

  -- Are we at the end?
  isEnd :: a -> Bool

  -- What value are you pointing to?
  curValue :: a -> Maybe (Value a)

  -- Gives iterator pointing to next value
  next :: a -> a

