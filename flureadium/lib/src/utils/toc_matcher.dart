import 'package:flureadium_platform_interface/flureadium_platform_interface.dart';

/// Strips leading '/' from a path for consistent comparison.
String normalizePath(String path) {
  return path.startsWith('/') ? path.substring(1) : path;
}

/// Finds the index of the given [locator]'s chapter in the [toc] by
/// matching file paths.
///
/// This is a fallback for when toc= fragment matching is unavailable
/// (e.g. EPUBs without heading element IDs).
///
/// Compares the base file path (without fragment/query) of the locator
/// against each TOC entry's href path.
///
/// When [lastMatch] is true, returns the last matching index (useful for
/// skipToNext — so "next" skips past all sub-sections in the same file).
/// When false, returns the first matching index (useful for skipToPrevious —
/// so "previous" goes before the first sub-section).
///
/// Returns -1 if no match is found.
int findTocIndexByPath(
  Locator locator,
  List<Link> toc, {
  bool lastMatch = false,
}) {
  final locatorPath = normalizePath(locator.hrefPath);

  // Exact path match
  int matchedIndex = -1;
  for (int i = 0; i < toc.length; i++) {
    final tocPath = normalizePath(toc[i].hrefPart);
    if (locatorPath == tocPath) {
      if (!lastMatch) return i;
      matchedIndex = i;
    }
  }
  if (matchedIndex != -1) return matchedIndex;

  // Fallback: match by filename only (last path segment)
  final locatorFilename = locatorPath.split('/').last;
  for (int i = 0; i < toc.length; i++) {
    final tocFilename = normalizePath(toc[i].hrefPart).split('/').last;
    if (locatorFilename == tocFilename) {
      if (!lastMatch) return i;
      matchedIndex = i;
    }
  }

  return matchedIndex;
}
