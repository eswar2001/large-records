{-# LANGUAGE CPP                  #-}
{-# LANGUAGE DataKinds            #-}
{-# LANGUAGE FlexibleContexts     #-}
{-# LANGUAGE LambdaCase           #-}
{-# LANGUAGE RecordWildCards      #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE ViewPatterns         #-}

{-# OPTIONS_GHC -Wno-orphans #-}

-- | Thin layer around ghc-tcplugin-api
module Data.Record.Anon.Internal.Plugin.TC.GhcTcPluginAPI (
    -- * Standard exports
    module GHC.TcPlugin.API
  , module GHC.Builtin.Names
  , module GHC.Builtin.Types
  , module GHC.Builtin.Types.Prim
  , module GHC.Core.Make
  , module GHC.Utils.Outputable

    -- * New functonality
  , isCanonicalVarEq
  , getModule
  , pprString
  ) where

import GHC.Stack

#if __GLASGOW_HASKELL__ < 900
import Data.List.NonEmpty (NonEmpty, toList)
#endif

import GHC.TcPlugin.API
import GHC.Builtin.Names
import GHC.Builtin.Types
import GHC.Builtin.Types.Prim
import GHC.Core.Make
import GHC.Utils.Outputable

#if __GLASGOW_HASKELL__ >= 810 &&  __GLASGOW_HASKELL__ < 900
import Constraint (Ct(..))
#endif

#if __GLASGOW_HASKELL__ >= 900 &&  __GLASGOW_HASKELL__ < 902
import GHC.Tc.Types.Constraint (Ct(..))
#endif

#if __GLASGOW_HASKELL__ >= 902
import GHC.Tc.Types.Constraint (Ct(..), CanEqLHS(..))
#endif

isCanonicalVarEq :: Ct -> Maybe (TcTyVar, Type)
#if __GLASGOW_HASKELL__ >= 810 &&  __GLASGOW_HASKELL__ < 902
isCanonicalVarEq = \case
    CTyEqCan{..}  -> Just (cc_tyvar, cc_rhs)
    CFunEqCan{..} -> Just (cc_fsk, mkTyConApp cc_fun cc_tyargs)
    _otherwise    -> Nothing
#endif
#if __GLASGOW_HASKELL__ >= 902
isCanonicalVarEq = \case
    CEqCan{..}
      | TyVarLHS var <- cc_lhs
      -> Just (var, cc_rhs)
      | TyFamLHS tyCon args <- cc_lhs
      , Just var            <- getTyVar_maybe cc_rhs
      -> Just (var, mkTyConApp tyCon args)
    _otherwise
      -> Nothing
#endif

-- TODO: Ideally we would actually show the location information obviously
instance {-# OVERLAPPABLE #-} Outputable CtLoc where
  ppr _ = text "<CtLoc>"

#if __GLASGOW_HASKELL__ < 900
instance {-# OVERLAPPABLE #-} Outputable a => Outputable (NonEmpty a) where
  ppr = ppr . toList
#endif

#if __GLASGOW_HASKELL__ >= 902
instance {-# OVERLAPPABLE #-} (Outputable l, Outputable e) => Outputable (GenLocated l e) where
  ppr (L l e) = parens $ text "L" <+> ppr l <+> ppr e
#endif

getModule :: (HasCallStack, MonadTcPlugin m) => String -> String -> m Module
getModule pkg modl = do
    let modl' = mkModuleName modl
    pkg' <- resolveImport modl' (Just $ fsLit pkg)
    res  <- findImportedModule modl' pkg'
    case res of
      Found _ m  -> return m
      NoPackage _ ->
        error $ concat [
          "getModule: could not find "
        , " package "
        , pkg
        ]
      FoundMultiple x ->
        error $ "getModule: found multiple " ++ (showSDocUnsafe . ppr) x
      (NotFound fr_paths _ _ _ _ _) -> error $ concat [
          "getModule: could not find "
        , modl
        , " in package "
        , pkg
        , " looked at these file paths "
        , show fr_paths
        ]

pprString :: String -> SDoc
pprString = text


