import qualified Scanner
import qualified Parser
import qualified Data.Map.Strict as Map
import System.Environment (getArgs)
import Interpreter (Context, execute)


main :: IO ()
main = do
  fileNames <- getArgs
  runFiles fileNames Map.empty


runFiles :: [String] -> Context -> IO ()
runFiles [] _ = return ()
runFiles (fileName : remainingFiles) context = do
  input <- readFile fileName
  case Scanner.scan input >>= Parser.parse of
    Left (position, message) ->
      putStrLn (fileName ++ " " ++ show position ++ ": " ++ message)
    Right statement -> do
      updatedContext <- execute statement context
      runFiles remainingFiles updatedContext