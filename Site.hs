{-# LANGUAGE OverloadedStrings #-}

import Control.Monad (forM_)
import Data.Aeson
import Data.Maybe (fromJust, fromMaybe)
import Data.Monoid (mappend)
import Debug.Trace (traceM, traceShow)
import Hakyll
import Text.Blaze.Html.Renderer.Pretty (renderHtml)
import Text.Blaze.Html5 ((!))
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as HA

main :: IO ()
main =
  do
    hakyllWith defaultConfiguration {destinationDirectory = "docs"} $ do
      match "style.css" $ do
        route idRoute
        compile copyFileCompiler

      match "favicon.svg" $ do
        route $ setExtension "ico"
        compile copyFileCompiler

      match "fonts/*" $ do
        route idRoute
        compile copyFileCompiler

      match "images/*" $ do
        route idRoute
        compile copyFileCompiler

      match "pdfs/*" $ do
        route idRoute
        compile copyFileCompiler

      match "templates/*" $ compile templateBodyCompiler

      create ["index.html"] $ do
        route idRoute
        compile $
          let titleContext = constField "title" "about" <> defaultContext
           in makeItem ""
                >>= loadAndApplyTemplate "templates/about.html" titleContext
                >>= loadAndApplyTemplate "templates/default.html" titleContext
                >>= relativizeUrls

      create ["projects.html"] $ do
        route idRoute
        compile $
          do
            projects <- parseProjects
            let titleContext = constField "title" "projects" <> defaultContext
            makeItem (renderHtml $ projectpage projects)
              >>= loadAndApplyTemplate "templates/default.html" defaultContext
              >>= relativizeUrls

      create ["posts.html"] $ do
        route idRoute
        compile $
          do
            posts <- recentFirst =<< loadAll "posts/*"
            let postContext =
                  constField "title" "posts"
                    <> listField "posts" defaultContext (return posts)
                    <> defaultContext
            makeItem ""
              >>= loadAndApplyTemplate "templates/post-list.html" postContext
              >>= loadAndApplyTemplate "templates/default.html" postContext
              >>= relativizeUrls

      match "posts/*" $ do
        route $ setExtension "html"
        compile $
          pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html" defaultContext
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

data Project = Project {pTitle, pDescription, pUrl :: String, pTags :: [String]} deriving (Show)

instance FromJSON Project where
  parseJSON = withObject "Project" $ \v ->
    Project
      <$> v .: "title"
      <*> v .: "description"
      <*> v .: "url"
      <*> v .: "tags"

parseProjects :: Compiler [Project]
parseProjects =
  unsafeCompiler $
    do
      projects <- eitherDecodeFileStrict "projects.json"
      case projects of
        Left err -> error err
        Right p -> pure p

data Post = Post {poTitle, poDate, poUrl :: String}

projectpage :: [Project] -> H.Html
projectpage projects = H.docTypeHtml $ do
  H.article $ H.div ! HA.class_ "projects-grid" $ mconcat (map mkProject projects)

mkProject :: Project -> H.Html
mkProject project = do
  H.div $ do
    H.h3 $ H.a ! HA.href (H.toValue $ pUrl project) $ H.toHtml (pTitle project)
    H.p $ H.toHtml (pDescription project)
    H.div $
      mconcat $
        ((H.span ! HA.class_ "project-tag") . H.toHtml) <$> pTags project
