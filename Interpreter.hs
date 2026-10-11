module Interpreter where

import qualified Data.Map.Strict as Map
import Parser.Ast
import qualified Scanner
import MoreIO (promptNumber)


type Context = Map.Map String Double


evaluate :: Expression -> Context -> Double
evaluate (NumberLiteral value) _ = value
evaluate (Variable name) context =
  Map.findWithDefault 0 name context
evaluate (UnaryExpression operator expression) context =
  evaluateUnary operator (evaluate expression context)
evaluate (BinaryExpression operator leftExpression rightExpression) context =
  evaluateBinary operator leftValue rightValue
  where
    leftValue = evaluate leftExpression context
    rightValue = evaluate rightExpression context


booleanNumber :: Bool -> Double
booleanNumber value =
  if value
    then 1
    else 0


evaluateUnary :: Scanner.Operator -> Double -> Double
evaluateUnary Scanner.Sub value = -value
evaluateUnary Scanner.Not value = booleanNumber (value == 0)
evaluateUnary _ _ = error "Invalid unary operator"


fmod :: Double -> Double -> Double
fmod x y = x - y * fromIntegral (truncate (x / y))


evaluateBinary :: Scanner.Operator -> Double -> Double -> Double
evaluateBinary operator leftValue rightValue =
  case operator of
    Scanner.Add -> leftValue + rightValue
    Scanner.Sub -> leftValue - rightValue
    Scanner.Mul -> leftValue * rightValue
    Scanner.Div -> leftValue / rightValue
    Scanner.Mod -> fmod leftValue rightValue
    Scanner.Eq -> booleanNumber (leftValue == rightValue)
    Scanner.Ne -> booleanNumber (leftValue /= rightValue)
    Scanner.Lt -> booleanNumber (leftValue < rightValue)
    Scanner.Ge -> booleanNumber (leftValue >= rightValue)
    Scanner.Gt -> booleanNumber (leftValue > rightValue)
    Scanner.Le -> booleanNumber (leftValue <= rightValue)
    Scanner.And -> booleanNumber (leftTruth + rightTruth == 2)
    Scanner.Or -> booleanNumber (leftTruth + rightTruth > 0)
    Scanner.Not -> error "Invalid binary operator"
  where
    leftTruth = booleanNumber (leftValue /= 0)
    rightTruth = booleanNumber (rightValue /= 0)

execute :: Statement -> Context -> IO Context
execute (Assignment name expression) context =
  return (Map.insert name (evaluate expression context) context)

execute (ScanStatement name) context = do
  value <- promptNumber name
  return (Map.insert name value context)

execute (PrintStatement expression) context = do
  print (evaluate expression context)
  return context

execute (Block statements) context =
  executeStatements statements context

execute (IfStatement condition statement) context =
  if evaluate condition context /= 0
    then execute statement context
    else return context

execute (IfElseStatement condition thenStatement elseStatement) context =
  if evaluate condition context /= 0
    then execute thenStatement context
    else execute elseStatement context

execute (WhileStatement condition statement) context =
  if evaluate condition context /= 0
    then do
      updatedContext <- execute statement context
      execute (WhileStatement condition statement) updatedContext
    else return context

execute (DoWhileStatement statement condition) context = do
  updatedContext <- execute statement context
  if evaluate condition updatedContext /= 0
    then execute (DoWhileStatement statement condition) updatedContext
    else return updatedContext


executeStatements :: [Statement] -> Context -> IO Context
executeStatements [] context = return context
executeStatements (statement : remainingStatements) context = do
  updatedContext <- execute statement context
  executeStatements remainingStatements updatedContext