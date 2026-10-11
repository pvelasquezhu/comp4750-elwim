module Parser.Ast where

import qualified Scanner

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
