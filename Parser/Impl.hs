module Parser.Impl (parse) where

import Control.Applicative (many, some, optional, (<|>))

import Parser.Precedence
import Parser.Ast as Ast

import qualified Stream
import qualified Source
import qualified Scanner
import Scanner (Token(..), PosToken(..), TokenItr)



-- Token helper functions
isIdentifier :: Token -> Bool
isIdentifier (Identifier _) = True
isIdentifier _ = False

isNumber :: Token -> Bool
isNumber (Number _) = True
isNumber _ = False

isUnaryOperator :: Token -> Bool
isUnaryOperator (Operator op) = isUnary op
isUnaryOperator _ = False



type Parser = Stream.Processor Scanner.TokenItr


parseToken :: Token -> Parser Token
parseToken = Stream.satisfy . (==)


requireToken :: Token -> Parser Token
requireToken token = Stream.require (parseToken token) ("expected: " ++ show token)


requirePrimary :: Parser Ast
requirePrimary = Stream.require parsePrimary "expected expression"


requireExpression :: Parser Ast
requireExpression = Stream.require parseExpr "expected expression"


requireStatement :: Parser Ast
requireStatement = Stream.require parseStatement "expected statement"


parseVariable :: Parser Ast
parseVariable = do
  token <- Stream.satisfy isIdentifier
  return $ Ast.Leaf token


parseNumber :: Parser Ast
parseNumber = do
  token <- Stream.satisfy isNumber
  return $ Ast.Leaf token


parseUnary :: Parser Ast
parseUnary = do
  opToken <- Stream.satisfy isUnaryOperator
  expr <- requirePrimary
  return $ Ast.Node opToken [expr]


parseNested :: Parser Ast
parseNested = do
  parseToken LeftParen
  expr <- requireExpression
  requireToken RightParen
  return expr


parsePrimary :: Parser Ast
parsePrimary = parseNumber <|> parseVariable <|> parseUnary <|> parseNested


parseExpr :: Parser Ast
parseExpr = do
  expr <- parsePrimary
  moreOperators expr 0
  where
    moreOperators lhs minPrecedence = do
      next <- optional Stream.peekNext -- don't consume yet
      case next of
        Just (Operator op)
          | isBinary op && precedenceOf op > minPrecedence -> do
              Stream.getNext -- now we can consume
              rhs <- requirePrimary
              rhsExpanded <- moreOperators rhs (precedenceOf op)
              moreOperators (Ast.Node (Operator op) [lhs, rhsExpanded]) minPrecedence
        _ -> return lhs


parsePrint :: Parser Ast
parsePrint = do
  parseToken Print
  expr <- requireExpression
  requireToken Semicolon
  return $ Ast.Node Print [expr]


parseScan :: Parser Ast
parseScan = do
  parseToken Scan
  var <- Stream.require (Stream.satisfy isIdentifier) "expected variable"
  requireToken Semicolon
  return $ Ast.Node Scan [Ast.Leaf var]


parseAssignment :: Parser Ast
parseAssignment = do
  var <- Stream.satisfy isIdentifier
  requireToken Assign
  value <- requireExpression
  requireToken Semicolon
  return $ Ast.Node Assign [Ast.Leaf var, value]


parseBlock :: Parser Ast
parseBlock = do
  parseToken LeftBrace
  stmts <- many parseStatement
  requireToken RightBrace
  return $ Ast.Node LeftBrace stmts


parseIf :: Parser Ast
parseIf = do
  parseToken If
  requireToken LeftParen
  expr <- requireExpression
  requireToken RightParen
  thenStmt <- requireStatement
  maybeElse <- optional parseElse
  case maybeElse of
    Just elseStmt -> return $ Ast.Node Else [expr, thenStmt, elseStmt]
    Nothing       -> return $ Ast.Node If [expr, thenStmt]
  where
    parseElse = do
      parseToken Else
      requireStatement


parseWhile :: Parser Ast
parseWhile = do
  parseToken While
  requireToken LeftParen
  expr <- requireExpression
  requireToken RightParen
  stmt <- requireStatement
  return $ Ast.Node While [expr, stmt]


parseDoWhile :: Parser Ast
parseDoWhile = do
  parseToken Do
  stmt <- requireStatement
  requireToken While
  requireToken LeftParen
  expr <- requireExpression
  requireToken RightParen
  requireToken Semicolon
  return $ Ast.Node Do [expr, stmt]


parseStatement :: Parser Ast
parseStatement = parsePrint <|> parseScan <|> parseAssignment <|> parseBlock <|> parseIf <|> parseWhile <|> parseDoWhile


parseAll :: Parser Ast
parseAll = do
  statements <- many parseStatement
  eof <- Stream.getEof
  if eof
    then return $ Ast.Node LeftBrace statements
    else do
      token <- Stream.peekNext
      fail $ "unexpected: " ++ show token


parse :: [PosToken] -> Either (Source.Position, String) Ast
parse tokens = Stream.processResult parseAll (Scanner.begin tokens)
