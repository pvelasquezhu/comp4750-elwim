import qualified Scanner
import qualified Parser

main :: IO ()
main = do
  input <- getContents
  case Scanner.scan input >>= Parser.parse of
    Left msg -> print msg
    Right ast -> print ast
