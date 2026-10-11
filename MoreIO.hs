module MoreIO (getNumber, promptNumber) where

import System.IO ( hLookAhead, hFlush, isEOF, stdin, stdout )
import System.IO.Error ( catchIOError )
import Data.Char ( isSpace )
import Control.Monad ( when )

-- IO action that throws away whitespace characters
skipWs :: IO ()
skipWs = do
  c <- hLookAhead stdin
  when (isSpace c) $ do
      _ <- getChar
      skipWs


-- IO action that reads one word
getToken :: IO String
getToken = do
  skipWs
  restToken
  where
    restToken = do
      c <- hLookAhead stdin
      if isSpace c
        then return []
        else do
          _ <- getChar
          eof <- isEOF
          if eof
            then return [c]
            else do
              rest <- restToken
              return (c : rest)


-- IO action that reads one number
getNumber :: IO Double
getNumber =
  (read <$> getToken)
  `catchIOError` \_ -> return 0


promptNumber :: String -> IO Double
promptNumber name = do
  putStr (name ++ "? ")
  hFlush stdout
  getNumber
