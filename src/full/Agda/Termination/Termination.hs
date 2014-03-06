{-# LANGUAGE ImplicitParams #-}

-- | Termination checker, based on
--     \"A Predicative Analysis of Structural Recursion\" by
--     Andreas Abel and Thorsten Altenkirch (JFP'01),
--   and
--     \"The Size-Change Principle for Program Termination\" by
--     Chin Soon Lee, Neil Jones, and Amir Ben-Amram (POPL'01).

module Agda.Termination.Termination
  ( terminates
  , terminatesFilter
  , idempotent
  , Agda.Termination.Termination.tests
  ) where

import Agda.Termination.CallGraph  hiding (tests)
import Agda.Termination.CallMatrix hiding (tests)
import Agda.Termination.Order      hiding (tests)
import Agda.Termination.SparseMatrix

import Agda.Utils.Either
import Agda.Utils.List
import Agda.Utils.Maybe
import Agda.Utils.TestHelpers
import Agda.Utils.QuickCheck

import qualified Data.Array as Array
import Data.Set (Set)
import qualified Data.Set as Set
import Data.Monoid
import Data.List (partition)

-- | TODO: This comment seems to be partly out of date.
--
-- @'terminates' cs@ checks if the functions represented by @cs@
-- terminate. The call graph @cs@ should have one entry ('Call') per
-- recursive function application.
--
-- @'Right' perms@ is returned if the functions are size-change terminating.
--
-- If termination can not be established, then @'Left' problems@ is
-- returned instead. Here @problems@ contains an
-- indication of why termination cannot be established. See 'lexOrder'
-- for further details.
--
-- Note that this function assumes that all data types are strictly
-- positive.
--
-- The termination criterion is taken from Jones et al.
-- In the completed call graph, each idempotent call-matrix
-- from a function to itself must have a decreasing argument.
-- Idempotency is wrt. matrix multiplication.
--
-- This criterion is strictly more liberal than searching for a
-- lexicographic order (and easier to implement, but harder to justify).

terminates :: (Monoid cinfo, ?cutoff :: CutOff) => CallGraph cinfo -> Either cinfo ()
terminates cs = let ccs = complete cs
                in
                  checkIdems $ toList ccs

terminatesFilter :: (Monoid cinfo, ?cutoff :: CutOff) =>
  (Index -> Bool) -> CallGraph cinfo -> Either cinfo ()
terminatesFilter f cs = checkIdems $ filter f' $ toList $ complete cs
  where f' (c,m) = f (source c) && f (target c)

checkIdems :: (Monoid cinfo, ?cutoff :: CutOff) => [(Call,cinfo)] -> Either cinfo ()
checkIdems calls = caseMaybe (mhead offending) (Right ()) $ \ (c,m) -> Left m
  where
    (idems, other) = partition (idempotent . fst) calls
    -- Every idempotent call must have decrease, otherwise it offends us.
    offending = filter (not . hasDecrease . fst) idems

{- Convention (see TermCheck):
   Guardedness flag is in position (0,0) of the matrix,
   it is always present even if the functions are all recursive.
   The examples below do not include the guardedness flag, though.
 -}

checkIdem :: (?cutoff :: CutOff) => Call -> Bool
checkIdem c = if idempotent c then hasDecrease c else True
{-
checkIdem c = let
  b = target c == source c
  -- c0 = fmap collapseO c -- does not help for issue 787
  idem = (c >*< c) `notWorse` c
  -- WAS: idem = (c >*< c) == c
  diag =  Array.elems $ diagonal (mat (cm c))
  hasDecr = any isDecr $ diag
  in
    (not b) || (not idem) || hasDecr
-}

-- | A call @c@ is idempotent if it is an endo (@'source' == 'target'@)
--   of order 1.
--   (Endo-calls of higher orders are e.g. argument permutations).
--   We can test idempotency by self-composition.
--   Self-composition @c >*< c@ should not make any parameter-argument relation
--    worse.
idempotent  :: (?cutoff :: CutOff) => Call -> Bool
idempotent c = target c == source c
  && (c >*< c) `notWorse` c


hasDecrease :: (?cutoff :: CutOff) => Call -> Bool
hasDecrease = any isDecr . diagonal

------------------------------------------------------------------------
-- Some examples

-- | The call graph instantiation used by the examples below.

type CG = CallGraph (Set Integer)

-- | Constructs a call graph suitable for use with the 'R' monoid.

buildCallGraph :: [Call] -> CG
buildCallGraph = fromList . flip zip (map Set.singleton [1 ..])

-- | The example from the JFP'02 paper.

example1 :: CG
example1 = buildCallGraph [c1, c2, c3]
  where
  flat = 1
  aux  = 2
  c1 = Call { source = flat, target = aux
            , cm = CallMatrix $ fromLists (Size 2 1) [[lt], [lt]]
            }
  c2 = Call { source = aux,  target = aux
            , cm = CallMatrix $ fromLists (Size 2 2) [ [lt, unknown]
                                                     , [unknown, le]]
            }
  c3 = Call { source = aux,  target = flat
            , cm = CallMatrix $ fromLists (Size 1 2) [[unknown, le]]
            }

prop_terminates_example1 ::  (?cutoff :: CutOff) => Bool
prop_terminates_example1 = isRight $ terminates example1

-- | An example which is now handled by this algorithm: argument
-- swapping addition.
--
-- @S x + y = S (y + x)@
--
-- @Z   + y = y@

example2 :: CG
example2 = buildCallGraph [c]
  where
  plus = 1
  c = Call { source = plus, target = plus
           , cm = CallMatrix $ fromLists (Size 2 2) [ [unknown, le]
                                                    , [lt, unknown] ]
           }

prop_terminates_example2 ::  (?cutoff :: CutOff) => Bool
prop_terminates_example2 = isRight $ terminates example2

-- | A related example which is anyway handled: argument swapping addition
-- using two alternating functions.
--
-- @S x + y = S (y +' x)@
--
-- @Z   + y = y@
--
-- @S x +' y = S (y + x)@
--
-- @Z   +' y = y@

example3 :: CG
example3 = buildCallGraph [c plus plus', c plus' plus]
  where
  plus  = 1
  plus' = 2
  c f g = Call { source = f, target = g
               , cm = CallMatrix $ fromLists (Size 2 2) [ [unknown, le]
                                                        , [lt, unknown] ]
               }

prop_terminates_example3 ::  (?cutoff :: CutOff) => Bool
prop_terminates_example3 = isRight $ terminates example3

-- | A contrived example.
--
-- @f (S x) y = f (S x) y + g x y@
--
-- @f Z     y = y@
--
-- @g x y = f x y@
--
-- TODO: This example checks that the meta information is reported properly
-- when an error is encountered.

example4 :: CG
example4 = buildCallGraph [c1, c2, c3]
  where
  f = 1
  g = 2
  c1 = Call { source = f, target = f
            , cm = CallMatrix $ fromLists (Size 2 2) [ [le, unknown]
                                                     , [unknown, le] ]
            }
  c2 = Call { source = f, target = g
            , cm = CallMatrix $ fromLists (Size 2 2) [ [lt, unknown]
                                                     , [unknown, le] ]
            }
  c3 = Call { source = g, target = f
            , cm = CallMatrix $ fromLists (Size 2 2) [ [le, unknown]
                                                     , [unknown, le] ]
            }

prop_terminates_example4 ::  (?cutoff :: CutOff) => Bool
prop_terminates_example4 = isLeft $ terminates example4

-- | This should terminate.
--
-- @f (S x) (S y) = g x (S y) + f (S (S x)) y@
--
-- @g (S x) (S y) = f (S x) (S y) + g x (S y)@

example5 :: CG
example5 = buildCallGraph [c1, c2, c3, c4]
  where
  f = 1
  g = 2
  c1 = Call { source = f, target = g
            , cm = CallMatrix $ fromLists (Size 2 2) [ [lt, unknown]
                                                     , [unknown, le] ]
            }
  c2 = Call { source = f, target = f
            , cm = CallMatrix $ fromLists (Size 2 2) [ [unknown, unknown]
                                                     , [unknown, lt] ]
            }
  c3 = Call { source = g, target = f
            , cm = CallMatrix $ fromLists (Size 2 2) [ [le, unknown]
                                                     , [unknown, le] ]
            }
  c4 = Call { source = g, target = g
            , cm = CallMatrix $ fromLists (Size 2 2) [ [lt, unknown]
                                                     , [unknown, le] ]
            }

prop_terminates_example5 ::  (?cutoff :: CutOff) => Bool
prop_terminates_example5 = isRight $ terminates example5

-- | Another example which should fail.
--
-- @f (S x) = f x + f (S x)@
--
-- @f x     = f x@
--
-- TODO: This example checks that the meta information is reported properly
-- when an error is encountered.

example6 :: CG
example6 = buildCallGraph [c1, c2, c3]
  where
  f = 1
  c1 = Call { source = f, target = f
            , cm = CallMatrix $ fromLists (Size 1 1) [ [lt] ]
            }
  c2 = Call { source = f, target = f
            , cm = CallMatrix $ fromLists (Size 1 1) [ [le] ]
            }
  c3 = Call { source = f, target = f
            , cm = CallMatrix $ fromLists (Size 1 1) [ [le] ]
            }

prop_terminates_example6 ::  (?cutoff :: CutOff) => Bool
prop_terminates_example6 = isLeft $ terminates example6

-- See issue 1055.
-- (The following function was adapted from Lee, Jones, and Ben-Amram,
-- POPL '01).
--
-- p : ℕ → ℕ → ℕ → ℕ
-- p m n        (succ r) = p m r n
-- p m (succ n) zero     = p zero n m
-- p m zero     zero     = m

example7 :: CG
example7 = buildCallGraph [call1, call2]
  where
    call1 = Call 1 1 $ CallMatrix $ fromLists (Size 3 3)
      [ [le, le, le]
      , [un, lt, un]
      , [le, un, un]
      ]
    call2 = Call 1 1 $ CallMatrix $ fromLists (Size 3 3)
      [ [le, un, un]
      , [un, un, lt]
      , [un, le, un]
      ]
    un = unknown

prop_terminates_example7 ::  (?cutoff :: CutOff) => Bool
prop_terminates_example7 = isRight $ terminates example7

------------------------------------------------------------------------
-- All tests

tests :: IO Bool
tests = runTests "Agda.Termination.Termination"
  [ quickCheck' prop_terminates_example1
  , quickCheck' prop_terminates_example2
  , quickCheck' prop_terminates_example3
  , quickCheck' prop_terminates_example4
  , quickCheck' prop_terminates_example5
  , quickCheck' prop_terminates_example6
  , quickCheck' prop_terminates_example7
  ]
  where ?cutoff = CutOff 0 -- all these examples are with just lt,le,unknown
