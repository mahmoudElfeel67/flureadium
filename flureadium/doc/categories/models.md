# Models

Data models representing publications and their content.

## Publication

The [Publication] class represents a Readium Web Publication Manifest (RWPM).
It contains:
- [Metadata] - title, authors, language, etc.
- [readingOrder] - content documents in reading sequence
- [resources] - images, stylesheets, fonts
- [tableOfContents] - navigation structure

## Locator

The [Locator] class precisely identifies a position within a publication.
Use locators for:
- Saving and restoring reading position
- Bookmarks and highlights
- Search results
- Navigation targets

## Link

The [Link] class represents a reference to content or resources.
Links are used throughout the publication structure for navigation and resource access.
