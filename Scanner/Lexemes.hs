module Scanner.Lexemes (keywords, punctuation) where

import qualified Data.Map.Strict as Map

import Scanner.Token

keywords :: Map.Map String Token
keywords = Map.fromList [
    ("scan", Scan),
    ("print", Print),
    ("if", If),
    ("else", Else),
    ("while", While),
    ("do", Do)
  ]

punctuation :: Map.Map String Token
punctuation = Map.fromList [
    ("!",  Operator Not),
    ("+",  Operator Add),
    ("-",  Operator Sub),
    ("*",  Operator Mul),
    ("/",  Operator Div),
    ("%",  Operator Mod),
    ("==", Operator Eq),
    ("!=", Operator Ne),
    ("<",  Operator Lt),
    (">=", Operator Ge),
    (">",  Operator Gt),
    ("<=", Operator Le),
    ("&&", Operator And),
    ("||", Operator Or),
    ("{",  LeftBrace),
    ("}",  RightBrace),
    ("(",  LeftParen),
    (")",  RightParen),
    ("=",  Assign),
    (";",  Semicolon)
  ]
