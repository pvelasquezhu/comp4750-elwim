module Parser.Ast where

import qualified Scanner


-- Need to refine this with better constructors
data Ast
  = Node Scanner.Token [Ast]
  | Leaf Scanner.Token
  deriving (Eq)


-- You may define your own pretty-print, or just use Haskell's default implementation
instance Show Ast where
  show :: Ast -> String
  show (Node token asts) = show token ++ show asts
  show (Leaf token) = show token
