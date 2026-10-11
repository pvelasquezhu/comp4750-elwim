module Scanner.Token (Operator(..), Token(..), PosToken(..)) where

import Source

data Operator
  = Not
  | Add
  | Sub
  | Mul
  | Div
  | Mod
  | Eq
  | Ne
  | Lt
  | Ge
  | Gt
  | Le
  | And
  | Or
  deriving (Show, Eq, Ord)


data Token
  = Number Double
  | Identifier String
  | Operator Operator
  | Assign
  | Semicolon
  | LeftBrace
  | RightBrace
  | LeftParen
  | RightParen
  | Scan
  | Print
  | If
  | Else
  | While
  | Do
  deriving (Eq)


instance Show Token where
  show :: Token -> String
  show (Number num) = show num
  show (Identifier id) = show id
  show (Operator op) = show op
  show Assign = "Assign"
  show Semicolon = "Semicolon"
  show LeftBrace = "LeftBrace"
  show RightBrace = "RightBrace"
  show LeftParen = "LeftParen"
  show RightParen = "RightParen"
  show Scan = "Scan"
  show Print = "Print"
  show If = "If"
  show Else = "Else"
  show While = "While"
  show Do = "Do"


data PosToken = PosToken Source.Position Token

instance Show PosToken where
  show :: PosToken -> String
  show (PosToken pos token) = show pos ++ show token

instance Source.Positioned PosToken where
  posOf :: PosToken -> Source.Position
  posOf (PosToken pos _) = pos
