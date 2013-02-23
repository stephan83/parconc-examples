{-# LANGUAGE CPP, RankNTypes #-}
import Control.Concurrent.Async
import Control.Monad
import System.Environment

import Control.Concurrent.Chan
import Control.Concurrent.STM

import TQueue
import TBQueue

-- Using CPP rather than a runtime choice between channel types,
-- because we want the compiler to be able to optimise the calls.

-- #define CHAN
-- #define TCHAN
-- #define TQUEUE
-- #define TBQUEUE

#ifdef CHAN
newc = newChan
readc c = readChan c
writec c x = writeChan c x
#elif defined(TCHAN)
newc = newTChanIO
readc c = atomically $ readTChan c
writec c x = atomically $ writeTChan c x
#elif defined(TQUEUE)
newc = atomically $ newTQueue
readc c = atomically $ readTQueue c
writec c x = atomically $ writeTQueue c x
#elif defined(TBQUEUE)
newc = atomically $ newTBQueue 4096
readc c = atomically $ readTBQueue c
writec c x = atomically $ writeTBQueue c x
#endif

-- Invoke this program with two command-line parameters.
-- The first should be 0, 1, or 2, specifying one of three
-- different benchmarks. The second specifies the size of the
-- test.

main = do
  [stest,sn] <- getArgs -- 2000000 is a good number
  let n = read sn :: Int
      test = read stest :: Int
  runtest n test

runtest :: Int -> Int -> IO ()
runtest n test = do
  c <- newc
  case test of
    0 -> do
      a <- async $ replicateM_ n $ writec c (1 :: Int)
      b <- async $ replicateM_ n $ readc c
      waitBoth a b
      return ()
    1 -> do
      replicateM_ n $ writec c (1 :: Int)
      replicateM_ n $ readc c
    2 -> do
      let n10 = n `quot` 1000
      replicateM_ 1000 $ do
        replicateM_ n10 $ writec c (1 :: Int)
        replicateM_ n10 $ readc c
