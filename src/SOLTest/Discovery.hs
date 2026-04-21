-- | Discovering @.test@ files and their companion @.in@\/@.out@ files.
module SOLTest.Discovery (discoverTests) where

import SOLTest.Types
import System.Directory
  ( doesFileExist,
    listDirectory,
    doesDirectoryExist
  )
import System.FilePath (replaceExtension, takeBaseName, (</>))
import Control.Monad (forM)

-- | Discover all @.test@ files in a directory.
--
-- When @recursive@ is 'True', subdirectories are searched recursively.
-- Returns a list of 'TestCaseFile' records, one per @.test@ file found.
-- The list is ordered by the file system traversal order (not sorted).

-- For each path to a @.test@ file, it checks for the existence of @.in@ and @.out@ files, and using 
-- 'findCompanionFiles' it assembles the files into a single 'TestCaseFile' record. 
-- If recursive is set to 'True', it also checks wether each path is a directory and if so, it calls itself 
-- recursively on this directory.

discoverTests :: Bool -> FilePath -> IO [TestCaseFile]
discoverTests recursive dir = do
  entries <- listDirectory dir
  let fullPaths = map (dir </>) entries
  res <- forM fullPaths $ \entry -> do  -- using forM to iterate over the paths and perform IO actions
    if recursive
      then do
        isDir <- doesDirectoryExist entry
        if isDir
          then discoverTests recursive entry -- recursive call for subdirectory
          else do
            r <-findCompanionFiles entry
            return [r]
      else do
        r <-findCompanionFiles entry
        return [r]
  return (concat res) -- concat the results into a single list of 'TestCaseFile' records
                    
-- | Build a 'TestCaseFile' for a given @.test@ file path, checking for
-- companion @.in@ and @.out@ files in the same directory.
findCompanionFiles :: FilePath -> IO TestCaseFile
findCompanionFiles testPath = do
  let baseName = takeBaseName testPath
      inFile = replaceExtension testPath ".in"
      outFile = replaceExtension testPath ".out"
  hasIn <- doesFileExist inFile
  hasOut <- doesFileExist outFile
  return
    TestCaseFile
      { tcfName = baseName,
        tcfTestSourcePath = testPath,
        tcfStdinFile = if hasIn then Just inFile else Nothing,
        tcfExpectedStdout = if hasOut then Just outFile else Nothing
      }
