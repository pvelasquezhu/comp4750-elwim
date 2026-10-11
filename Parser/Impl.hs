module Parser.Impl (parse) where

import Control.Applicative (many, optional, (<|>))

import Parser.Precedence
import Parser.Ast as Ast

import qualified Stream
import qualified Source
import qualified Scanner
import Scanner (Token(..), PosToken(..))


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
requireToken token =
  Stream.require (parseToken token) ("expected: " ++ show token)


requirePrimary :: Parser Expression
requirePrimary = Stream.require parsePrimary "expected expression"


requireExpression :: Parser Expression
requireExpression = Stream.require parseExpr "expected expression"


requireStatement :: Parser Statement
requireStatement = Stream.require parseStatement "expected statement"


parseVariable :: Parser Expression
parseVariable = do
  Identifier name <- Stream.satisfy isIdentifier
  return (Ast.Variable name)


parseNumber :: Parser Expression
parseNumber = do
  Number value <- Stream.satisfy isNumber
  return (Ast.NumberLiteral value)


parseUnary :: Parser Expression
parseUnary = do
  Operator operator <- Stream.satisfy isUnaryOperator
  expr <- requirePrimary
  return (Ast.UnaryExpression operator expr)


parseNested :: Parser Expression
parseNested = do
  parseToken LeftParen
  expr <- requireExpression
  requireToken RightParen
  return expr


parsePrimary :: Parser Expression
parsePrimary =
  parseNumber <|> parseVariable <|> parseUnary <|> parseNested


parseExpr :: Parser Expression
parseExpr = do
  expr <- parsePrimary
  moreOperators expr 0
  where
    moreOperators lhs minPrecedence = do
      next <- optional Stream.peekNext
      case next of
        Just (Operator op)
          | isBinary op && precedenceOf op > minPrecedence -> do
              Stream.getNext
              rhs <- requirePrimary
              rhsExpanded <- moreOperators rhs (precedenceOf op)
              moreOperators
                (Ast.BinaryExpression op lhs rhsExpanded)
                minPrecedence
        _ -> return lhs


parsePrint :: Parser Statement
parsePrint = do
  parseToken Print
  expr <- requireExpression
  requireToken Semicolon
  return (Ast.PrintStatement expr)


parseScan :: Parser Statement
parseScan = do
  parseToken Scan
  Identifier name <-
    Stream.require (Stream.satisfy isIdentifier) "expected variable"
  requireToken Semicolon
  return (Ast.ScanStatement name)


parseAssignment :: Parser Statement
parseAssignment = do
  Identifier name <- Stream.satisfy isIdentifier
  requireToken Assign
  value <- requireExpression
  requireToken Semicolon
  return (Ast.Assignment name value)


parseBlock :: Parser Statement
parseBlock = do
  parseToken LeftBrace
  stmts <- many parseStatement
  requireToken RightBrace
  return (Ast.Block stmts)


parseIf :: Parser Statement
parseIf = do
  parseToken If
  requireToken LeftParen
  expr <- requireExpression
  requireToken RightParen
  thenStmt <- requireStatement
  maybeElse <- optional parseElse
  case maybeElse of
    Just elseStmt ->
      return (Ast.IfElseStatement expr thenStmt elseStmt)
    Nothing ->
      return (Ast.IfStatement expr thenStmt)
  where
    parseElse = do
      parseToken Else
      requireStatement


parseWhile :: Parser Statement
parseWhile = do
  parseToken While
  requireToken LeftParen
  expr <- requireExpression
  requireToken RightParen
  stmt <- requireStatement
  return (Ast.WhileStatement expr stmt)


parseDoWhile :: Parser Statement
parseDoWhile = do
  parseToken Do
  stmt <- requireStatement
  requireToken While
  requireToken LeftParen
  expr <- requireExpression
  requireToken RightParen
  requireToken Semicolon
  return (Ast.DoWhileStatement stmt expr)


parseStatement :: Parser Statement
parseStatement =
  parsePrint
    <|> parseScan
    <|> parseAssignment
    <|> parseBlock
    <|> parseIf
    <|> parseWhile
    <|> parseDoWhile


parseAll :: Parser Statement
parseAll = do
  statements <- many parseStatement
  eof <- Stream.getEof
  if eof
    then return (Ast.Block statements)
    else do
      token <- Stream.peekNext
      fail ("unexpected: " ++ show token)


parse :: [PosToken] -> Either (Source.Position, String) Statement
parse tokens =
  Stream.processResult parseAll (Scanner.begin tokens)