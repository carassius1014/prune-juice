import Prelude

import Control.Monad (unless)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.State (execStateT, put)
import Data.Foldable (for_, traverse_)
import Data.Text (pack, unpack)
import Data.Traversable (for)
import System.Exit (ExitCode(ExitFailure, ExitSuccess), exitWith)
import qualified Data.Set as Set
import qualified Options.Applicative as Opt

import Data.Prune.Dependency (getPackageDependencyByModule)
import Data.Prune.ImportParser (getCompilableUsedDependencies)
import Data.Prune.Package (parseStackYaml)
import qualified Data.Prune.Types as T

data Opts = Opts
  { optsStackYamlFile :: FilePath
  }

parseArgs :: IO Opts
parseArgs = Opt.execParser (Opt.info (Opt.helper <*> parser) $ Opt.progDesc "Prune a Stack project's dependencies")
  where
    parser = Opts
      <$> Opt.strOption (
        Opt.long "stack-yaml-file"
          <> Opt.metavar "STACK_YAML_FILE"
          <> Opt.help "Location of stack.yaml"
          <> Opt.value "stack.yaml"
          <> Opt.showDefault )

main :: IO ()
main = do
  Opts {..} <- parseArgs
  packages <- parseStackYaml optsStackYamlFile

  -- FIXME include local dependencies eventually
  code <- flip execStateT ExitSuccess $ for_ packages $ \package@T.Package {..} -> do
    dependencyByModule <- liftIO $ getPackageDependencyByModule optsStackYamlFile package
    baseUsedDependencies <- fmap mconcat . for packageCompilables $ \compilable@T.Compilable {..} -> do
      usedDependencies <- liftIO $ getCompilableUsedDependencies dependencyByModule compilable
      let (baseUsedDependencies, otherUsedDependencies) = Set.partition (flip Set.member packageBaseDependencies) usedDependencies
          otherUnusedDependencies = Set.difference compilableDependencies otherUsedDependencies
      unless (Set.null otherUnusedDependencies) $ do
        liftIO . putStrLn . unpack $ "Some unused dependencies for " <> pack (show compilableType) <> " " <> T.unCompilableName compilableName <> " in package " <> packageName
        traverse_ (liftIO . putStrLn . unpack . ("  " <>) . T.unDependencyName) $ Set.toList otherUnusedDependencies
        put $ ExitFailure 1
      pure baseUsedDependencies
    let baseUnusedDependencies = Set.difference packageBaseDependencies baseUsedDependencies
    unless (Set.null baseUnusedDependencies) $ do
      liftIO . putStrLn . unpack $ "Some unused base dependencies for package " <> packageName
      liftIO . traverse_ (putStrLn . unpack . ("  " <>) . T.unDependencyName) $ Set.toList baseUnusedDependencies
      put $ ExitFailure 1
  exitWith code
