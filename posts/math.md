---
title: Math in markdown
date: 2026-09-22
---

$$\alpha + 2 \leq 3$$

```haskell
data Project = Project {pTitle, pDescription, pUrl :: String, pTags :: [String]} deriving (Show)

instance FromJSON Project where
  parseJSON = withObject "Project" $ \v ->
    Project
      <$> v .: "title"
      <*> v .: "description"
      <*> v .: "url"
      <*> v .: "tags"
```
