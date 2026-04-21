-- | Building the final test report and computing statistics.
--
-- This module assembles a 'TestReport' from the results of test execution,
-- computes aggregate statistics, and builds the per-category success-rate
-- histogram.
module SOLTest.Report
  ( buildReport,
    groupByCategory,
    computeStats,
    computeHistogram,
    rateToBin,
  )
where

import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import SOLTest.Types
import Data.List (find)
-- ---------------------------------------------------------------------------
-- Top-level report assembly
-- ---------------------------------------------------------------------------

-- | Assemble the complete 'TestReport'.
--
-- Parameters:
--
-- * @discovered@ – all 'TestCaseDefinition' values that were successfully parsed.
-- * @unexecuted@ – tests that were not executed for any reason (filtered, malformed, etc.).
-- * @executionResults@ – 'Nothing' in dry-run mode; otherwise the map of test
--   results keyed by test name.
-- * @selected@ – the tests that were selected for execution (used for stats).
-- * @foundCount@ – total number of @.test@ files discovered on disk.
buildReport ::
  [TestCaseDefinition] ->
  Map String UnexecutedReason ->
  Maybe (Map String TestCaseReport) ->
  [TestCaseDefinition] ->
  Int ->
  TestReport
buildReport discovered unexecuted mResults selected foundCount =
  let mCategoryResults = fmap (groupByCategory selected) mResults
      stats = computeStats foundCount (length discovered) (length selected) mCategoryResults
   in TestReport
        { trDiscoveredTestCases = discovered,
          trUnexecuted = unexecuted,
          trResults = mCategoryResults,
          trStats = stats
        }

-- ---------------------------------------------------------------------------
-- Grouping and category reports
-- ---------------------------------------------------------------------------

-- | Group a flat map of test results into a map of 'CategoryReport' values,
-- one per category.
--
-- The @definitions@ list is used to look up each test's category and points.
--
-- FLP: Implement this function. The following functions may (or may not) come in handy:
--      @Map.fromList@, @Map.foldlWithKey'@, @Map.empty@, @Map.lookup@, @Map.insertWith@,
--      @Map.map@, @Map.fromList@
groupByCategory ::
  [TestCaseDefinition] ->
  Map String TestCaseReport ->
  Map String CategoryReport
groupByCategory definitions results = Map.foldlWithKey' accumulate Map.empty results
  where
    accumulate accMap testName report =
      case find (\d -> tcdName d == testName) definitions of
        Nothing -> accMap
        Just def ->
          let catName = tcdCategory def
              points = tcdPoints def
              isPassed = case tcrResult report of
                           Passed -> True   
                           _    -> False  
              
              newReport = CategoryReport
                { crTotalPoints = points
                , crPassedPoints = if isPassed then points else 0
                , crTestResults = Map.singleton testName report
                }
          in Map.insertWith mergeReports catName newReport accMap

    mergeReports new old = CategoryReport
      { crTotalPoints = crTotalPoints old + crTotalPoints new
      , crPassedPoints = crPassedPoints old + crPassedPoints new
      , crTestResults = Map.union (crTestResults old) (crTestResults new)
      }


-- ---------------------------------------------------------------------------
-- Statistics
-- ---------------------------------------------------------------------------

-- | Compute the 'TestStats' from available information.
--
-- FLP: Implement this function. You'll use @computeHistogram@ here.
computeStats ::
  -- | Total @.test@ files found on disk.
  Int ->
  -- | Number of successfully parsed tests.
  Int ->
  -- | Number of tests selected after filtering.
  Int ->
  -- | Category reports (Nothing in dry-run mode).
  Maybe (Map String CategoryReport) ->
  TestStats
computeStats foundCount loadedCount selectedCount mCategoryResults = 
  let histogram = case mCategoryResults of 
                    Nothing -> Map.fromList [(rateToBin i, 0) | i <- [0.0..0.9]]
                    Just categoryResults -> computeHistogram categoryResults
      passedCount = case mCategoryResults of
                      Nothing -> 0
                      Just mCategoryResults -> sum [crPassedPoints cr | cr <- Map.elems mCategoryResults, crTotalPoints cr > 0]
  in TestStats
      { tsFoundTestFiles = foundCount,
        tsLoadedTests = loadedCount,
        tsSelectedTests = selectedCount,
        tsPassedTests = passedCount,
        tsHistogram = histogram
      }
-- ---------------------------------------------------------------------------
-- Histogram
-- ---------------------------------------------------------------------------

-- | Compute the success-rate histogram from the category reports.
--
-- For each category, the relative pass rate is:
--
-- @rate = passed_test_count \/ total_test_count@
--
-- The rate is mapped to a bin key (@\"0.0\"@ through @\"0.9\"@) and the count
-- of categories in each bin is accumulated. All ten bins are always present in
-- the result, even if their count is 0.
--
-- FLP: Implement this function.
computeHistogram :: Map String CategoryReport -> Map String Int
computeHistogram categories = 
  let initialHistogram = Map.fromList [(rateToBin (fromIntegral passed / fromIntegral total), 0) | (_, CategoryReport total passed _) <- Map.toList categories]
      histogram = foldl updateHistogram initialHistogram (Map.toList categories)
  in histogram
  where
    updateHistogram hist (_, CategoryReport total passed _) =
      let rate = if total > 0 then fromIntegral passed / fromIntegral total else 0
          binKey = rateToBin rate
      in Map.insertWith (+) binKey 1 hist

-- | Map a pass rate in @[0, 1]@ to a histogram bin key.
--
-- Bins are defined as @[0.0, 0.1)@, @[0.1, 0.2)@, ..., @[0.9, 1.0]@.
-- A rate of exactly @1.0@ maps to the @\"0.9\"@ bin.
rateToBin :: Double -> String
rateToBin rate =
  let binIndex = min 9 (floor (rate * 10) :: Int)
      -- Format as "0.N" for bin index N
      whole = binIndex `div` 10
      frac = binIndex `mod` 10
   in show whole ++ "." ++ show frac
