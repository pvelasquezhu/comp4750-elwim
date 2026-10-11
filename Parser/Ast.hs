module Parser.Ast where

import qualified Scanner


-- Need to refine this with better constructors
data Ast
  = Node Scanner.Token [Ast]
  | Leaf Scanner.Token
  deriving (Eq)

-- calculate a numeric value
data Expression
  = NumberLiteral Double
  | Variable String
  | UnaryExpression Scanner.Operator Expression
  | BinaryExpression Scanner.Operator Expression Expression
  deriving (Show, Eq)

-- Statements describe actions
data Statement
  = Assignment String Expression
  | ScanStatement String
  | PrintStatement Expression
  | Block [Statement]
  | IfStatement Expression Statement
  | IfElseStatement Expression Statement Statement
  | WhileStatement Expression Statement
  | DoWhileStatement Statement Expression
  deriving (Show, Eq)

-- You may define your own pretty-print, or just use Haskell's default implementation
instance Show Ast where
  show :: Ast -> String
  show (Node token asts) = show token ++ show asts
  show (Leaf token) = show token
