{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NoImplicitPrelude #-}
module Utils.Vigilance.Workers.NotificationRetryWorkerSpec (spec) where

import ClassyPrelude
import Control.Lens

import SpecHelper
import Utils.Vigilance.Workers.NotificationRetryWorker

spec :: Spec
spec = parallel $ do
  describe "renderFail" $ do
    it "renders EmailNotification" $
      renderFail emailFail `shouldBe` "Watch whatever failed to notify after 2 retries on EmailNotification foo@example.com: FailedByException \"crap\""
    it "renders HTTPNotification" $
      renderFail httpFail `shouldBe` "Watch whatever failed to notify after 2 retries on HTTPNotification example.com: FailedByCode 500"
  describe "failuresToRetry" $ do
    it "removes fns that are on the border or over" $
      let ok      = baseFN
          limited = baseFN & retries .~ 2
          tooMany = baseFN & retries .~ 3
      in failuresToRetry 2 [ok, limited, tooMany] `shouldBe` [ok]

emailFail :: FailedNotification
emailFail = httpFail & update
  where update = (failedPref .~ (EmailNotification $ EmailAddress "foo@example.com")) . (failedLastError .~ FailedByException "crap")

httpFail :: FailedNotification
httpFail = baseFN & retries .~ 2