module Main where

import Test.HUnit (runTestTT, Test(..), Counts(..))
import System.Exit (exitSuccess, exitFailure)
import System.IO

import HaddockBackend.Api
import Options
import DocTest

import qualified Interpreter

main :: IO ()
main = do
  (options, files) <- getOptions
  let ghciArgs = ghcOptions options ++ files
  Interpreter.withInterpreter ghciArgs $ \repl -> do

    -- get examples from Haddock comments
    let haddockFlags = haddockOptions options
    docTests <- getDocTests haddockFlags files

    let (tCount, iCount) = (length docTests, length (concatMap interactions docTests))
    hPutStrLn stderr (formatTestAndInteractionCount tCount iCount)

    if DumpOnly `elem` options
      then do
        -- dump to stdout
        print docTests
      else do
        -- map to unit tests
        let tests = TestList $ map (toTestCase repl) docTests
        Counts _ _ errCount failCount <- runTestTT tests
        if errCount == 0 && failCount == 0
          then exitSuccess
          else exitFailure


formatTestAndInteractionCount :: Int -> Int -> String
formatTestAndInteractionCount 1 1           = "There is one test, with one single interaction."
formatTestAndInteractionCount 1 iCount      = "There is one test, with " ++ show iCount ++ " interactions."
formatTestAndInteractionCount tCount iCount = "There are " ++ show tCount ++ " tests, with " ++ show iCount ++ " total interactions."
