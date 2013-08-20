{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
module Utils.Vigilance.Workers.NotificationWorker (runWorker) where

import ClassyPrelude
import Control.Monad ( sequence
                     , when )
import Control.Monad.Trans (lift)
import Control.Lens
import Data.Acid (AcidState)

import Utils.Vigilance.Logger
import Utils.Vigilance.TableOps
import Utils.Vigilance.Types

sendNotifications :: [EWatch] -> [Notifier] -> LogCtxT IO ()
sendNotifications ws = sequence_ . map ($ ws)

runWorker :: AcidState AppState -> [Notifier] -> LogCtxT IO ()
runWorker acid notifiers = renameLogCtx "Notifier Worker" $ do
                              watches <- getNotifyingS acid
                              when (not . null $ watches) $ pushLog $ notifyingMsg watches
                              sendNotifications watches notifiers
                              completeNotifyingS acid $ map (view watchName) watches

notifyingMsg :: [EWatch] -> Text
notifyingMsg watches = mconcat ["Notifying for ", length' watches, " watches: ", names]
  where length' = show . length
        names   = intercalate ", " $ map (view (watchName . unWatchName)) watches
