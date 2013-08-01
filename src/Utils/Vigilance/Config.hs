{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
module Utils.Vigilance.Config ( configNotifiers
                              , convertConfig
                              , loadConfig) where

import ClassyPrelude hiding (FilePath)
import Control.Applicative ( (<$>)
                           , (<*>) )
import Control.Monad -- ((<=<))
import Control.Lens
import qualified Data.Configurator as C
import qualified Data.Configurator.Types as CT
import Data.Maybe (catMaybes)
import GHC.IO (FilePath)
import qualified Utils.Vigilance.Notifiers.Email as E
import qualified Utils.Vigilance.Notifiers.Log   as L
import Utils.Vigilance.Types

configNotifiers :: Config -> IO [Notifier]
configNotifiers cfg = do logger      <- L.openLogger $ cfg ^. configLogPath
                         let logNotifier    = L.notify logger
                         let mEmailNotifier = E.notify . E.EmailContext <$> cfg ^. configFromEmail
                         return $ catMaybes [Just logNotifier, mEmailNotifier]

loadConfig :: FilePath -> IO Config
loadConfig = convertConfig <=< C.load . return . CT.Required

-- basically no point to this mappend at present
convertConfig :: CT.Config -> IO Config
convertConfig cfg = mempty <> Config <$> lud defaultAcidPath "acid_path"
                                     <*> (toEmailAddress <$> lu "from_email")
                                     <*> lud defaultLogPath "log_path"
  where lu             = C.lookup cfg
        lud d          = C.lookupDefault d cfg
        toEmailAddress = fmap (EmailAddress . pack)