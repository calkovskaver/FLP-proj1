-- | Filtering test cases by include and exclude criteria.
--
-- The filtering algorithm is a two-phase set operation:
--
-- 1. __Include__: if no include criteria are given, all tests are included;
--    otherwise only tests matching at least one include criterion are kept.
--
-- 2. __Exclude__: tests matching any exclude criterion are removed from the
--    included set.
module SOLTest.Filter
  ( filterTests,
    matchesCriterion,
    matchesAny,
    trimFilterId,
  )
where

import Data.Char (isSpace)
import SOLTest.Types

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

-- | Apply a 'FilterSpec' to a list of test definitions.
--
-- Returns a pair @(selected, filteredOut)@ where:
--
-- * @selected@ are the tests that passed both include and exclude checks.
-- * @filteredOut@ are the tests that were removed by filtering.
--
-- The union of @selected@ and @filteredOut@ always equals the input list.

-- FilterSpec {fsIncludes = [], fsExcludes = [], fsUseRegex Bool}
-- excluded = those that were specified no to be included
-- selected  = included \ excluded
filterTests ::
  FilterSpec ->
  [TestCaseDefinition] ->
  ([TestCaseDefinition], [TestCaseDefinition])
filterTests spec tests = do
  let included = if null (fsIncludes spec) then tests else filter (matchesAny False (fsIncludes spec)) tests -- if no includes specified -> all tests are inluded, otherwise choosing only those that were specified and that exist in the list of tests
  let excluded = filter (matchesAny False (fsExcludes spec)) included -- filtering the including set by excluding those specified to be excluded
  (filter (not . (`elem` excluded)) included, excluded) -- selected = included \ excluded, filteredOut = excluded

-- | Check whether a test matches at least one criterion in the list.
matchesAny :: Bool -> [FilterCriterion] -> TestCaseDefinition -> Bool
matchesAny useRegex criteria test =
  any (matchesCriterion useRegex test) criteria

-- | Check whether a test matches a single 'FilterCriterion'.
--
-- When @useRegex@ is 'False', matching is case-sensitive string equality.
-- When @useRegex@ is 'True', the criterion value is treated as a POSIX
-- regular expression matched against the relevant field(s).
--
-- Not implementing the Regex matching extension!
matchesCriterion :: Bool -> TestCaseDefinition -> FilterCriterion -> Bool
matchesCriterion useRegex test criterion = 
  case criterion of -- on the basis of the type of criterion, checking if provided test matches the provided string in criterion
    ByAny s -> tcdName test == s || tcdCategory test == s || s `elem` tcdTags test || s `elem` tcdDescription test
    ByCategory s -> tcdCategory test == s
    ByTag s -> s `elem` tcdTags test

-- | Trim leading and trailing whitespace from a filter identifier.
trimFilterId :: String -> String
trimFilterId = reverse . dropWhile isSpace . reverse . dropWhile isSpace
