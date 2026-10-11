# Comp 4750 Project: Elwim Interpreter

## Overview

For this project we will start with a parser for the
[Elwim](https://cs.harding.edu/gfoust/classes/comp4750/projects/elwim/language) programming language
and convert it into an interpreter.  This will require designing a data type to use as an Abstract
Syntax Tree (AST), updating the parser to use your new type, and then implementing functions that
can execute your new type.

## The Starting Project

The project as you [downloaded](https://github.com/gfoust/comp4750-fgp-elwim-starter) it contains a
scanner and parser for Elwim.  It will read input from the standard input stream, scan it to find
tokens, then parse the tokens to build an AST.  It then prints the AST to the standard output
stream.

The project layout is as follows:
- **[Elwim]** - directory holding example Elwim programs (for testing purposes)
- **[Parser]** - directory holding modules related to parsing
  + **Ast.hs** - definition of simplistic AST type
  + **Impl.hs** - implementation for parsing methods
  + **Precedence.hs** - helper data structures for operator precedence
- **[Scanner]** - directory holding modules related to scanning
  + **Impl.hs** - implementation for scanning methods
  + **Token.hs** - definition of token and operator types
  + **TokenItr.hs** - definition of token iterator type which can be used to iterate over resulting
    tokens
- **[Source]** - directory holding modules related to source text
  + **Position.hs** - definition of type representing a position in the source text
  + **SourceItr.hs** - definition of source iterator type which can be used to iterate over source
    text string
- **Iterator.hs** - type class defining interface for iterator types
- **Main.hs** - application entry point
- **MoreIO.hs** - contains an IO action for reading a single number
- **Parser.hs** - front end to parser modules
- **Scanner.hs** - front end to scanner modules
- **Source.hs** - front end to source modules
- **Stream.hs** - definition of monad used for scanning and parsing


You will need to make a few changes to the existing program.  In particular, the existing AST type
(defined in [Parser/Ast.hs](Parser/Ast.hs)) is oversimplified. It contains only two forms: one for a
leaf node (no children) and one for an internal node (list of children).  This simplistic tree type
would be very difficult to work with: there is nothing distinguishing the different kinds of nodes.

## Project Requirements

### Step 1: Define better AST types

You will need to design and implement better types for representing a program.  You may simply add
your type definitions to [Parser/Ast.hs](Parser/Ast.hs), or you may create additional modules for
them if you prefer.

There are two major syntactic categories in Elwim:  *expressions* and *statements*.  You should
therefore create two different data types: one to represent expressions, and one to represent
statements.  You will notice in the
[Elwim language definition](https://cs.harding.edu/gfoust/classes/comp4750/projects/elwim/language)
that there are four different possible forms an expression can take, and eight different possible
forms a statement can take.  You will need to define a separate constructor for each one of these
forms.

As you define your constructors, consider carefully what data also needs to be stored for each
particular constructor.  Try to store only the data needed to know exactly what that language
structure represents.

Make sure that you can `show` your data types so that they can be printed to the screen.  The
default implementation of `show` will be fine.  You may also define your own if you want it to
look prettier, but make sure that it completely represents the data and structure of your type.

### Step 2: Modify the parser to construct values of your types instead of the `Ast` type

The only file you need to modify for this is [Parser/Impl.hs](Parser/Impl.hs).  Search for every
place an `Ast.Node` or `Ast.Leaf` is created, and modify it to create a value of either your
expression type or your statement type instead.  All the data you need to create your value should
already be in the function, although you may have to pattern match tokens in order to pull out
some of it. (See [Scanner/Token.hs](Scanner/Token.hs) for token definitions.)

As you make changes to parsing functions you will also have to modify their types as well.  The
functions you will be changing all return a value of type `Parser Ast`; you will need to swap out
`Ast` for either your expression type or your statement type depending on the function.

When there are no longer any references to `Ast.Node` or `Ast.Leaf` in
[Parser/Impl.hs](Parser/Impl.hs) then you may safely delete the `Ast` type (and its `Show`
instantiation).

At the end of step 2, you should be able to compile and run the Elwim parser again.  It should now
parse and print your AST types instead of the original `Ast` type.

Note that, while it is possible to view an Elwim program as a list of statements, the parser
actually wraps those statements in an implicit block (as if there were curly braces around the whole
program).  Thus, the return value of the parser is simply a single value (the block), not a list of
values.

### Step 3: Create execute/evaluate functions for your AST types

You will need to be able to evaluate values of your expression type, and execute objects of your
statement type.  I recommend that you not put this code in the `Parser` folder; instead, make a new
module for these functions.

Evaluating expressions is simple and stateless: expressions never perform I/O, and never modify
program state.  They may, however, need to look up the value of variables.  We use the term
*context* to refer to a data structure that allows you to store and retrieve variable values.  A
good data structure for a context is a map from strings to doubles.  You may find it helpful to
define a type alias, like so:

```hs
type Context = Map String Double
```

Then a signature for your evaluate function might look like this:

```hs
evaluate :: Expression -> Context -> Double
```

Statements are more complicated.  For one thing, they can perform I/O; therefore the execution
function will need to be an I/O action.  The file [MoreIO.hs](MoreIO.hs) has a function named
`promptNumber` that can be used to extract the next number from the standard input stream: it's
parameter is the variable name (used for a prompt) and it returns the next number.  Use this to
execute the scan statement.

Also, statements can make modifications to program state; i.e., change the values of variables.
Thus, they will need to not only take a context as a parameter, but also return an updated context
reflecting the resulting values of variables.

All together, that gives an IO action that takes (1) an AST statement, (2) a map of variable values,
and that returns an updated map of variable values.  This suggests something like this:

```hs
execute :: Statement -> Context -> IO Context
```

#### Optional: state monad

You may recognize this function signature as the state pattern, where the state is the map of
variable values. Using a state monad to manage your context can simplify your code.  However, it
might (arguably) make your code harder to understand due to to the raised level of abstraction.  If
you want to pursue this (optional) route, here are some tips:

You should use the `StateT` monad transformer to combine the state and I/O monads.  This will give
you a function something like this:

```hs
execute :: Statement -> StateT Context IO ()
```

Note that there is a difference between this stateful-IO monad and the plain-IO monad.  You can use
`lift` to lift plain-IO actions into your stateful-IO monad.  For example:
```hs
  num <- lift (promptNumber name)
```

While you *can* use the state's `get` accessor function to retrieve the context map, you might
prefer the `gets` function which takes a function from state to value, passes it the state, and
returns the value.  So, for example, if your evaluate function takes a context as the last argument,
you can write something like this:

```hs
  result <- gets (evaluate expr)
```

Additionally, the state's `modify` function takes a function from state to state, passes it the
current state, and then replaces the state with whatever the function returns.  Since the last
argument to `Data.Map.insert` is the map, you can update the map like this:

```hs
  modify (insert name value)
```

To run your stateful-IO monad as a plain-IO action, use the `runStateT` function and pass it the
initial context.  (You can alternatively use `execStateT`, which only returns only the final state.)

```hs
  ((), updatedContext) <- runStateT (execute stmt) initialContext
  -- OR --
  updatedContext <- execStateT (execute stmt) initialContext
```

### Step 4: Modify the application to be an interpreter

Modify main so that your application will now execute Elwim programs instead of simply printing out
their ASTs.  Also, it should now read the Elwim program from a file instead of from the standard
input stream.

Use `getArgs :: IO [String]` to get the list of program arguments.  Treat these as the names of
files that have Elwim programs.  For each file name, read the contents of that file, parse it into
an AST, then execute it.  If a file fails to parse, print the error message and halt (don't execute
any more files).

The value of variables should persist between files.  In other words, the state that results from
executing the first program should become the state of the second program, and so on.

#### Implementation hints:
- Use `promptNumber` in [MoreIO.hs](MoreIO.hs) to implement the "scan" statement.
- Use this function to implement the `%` operator:
  ```hs
  fmod :: Double -> Double -> Double
  fmod x y = x - y * fromIntegral (truncate (x / y))
  ```
