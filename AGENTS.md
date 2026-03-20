[Flureadium Docs Index]|root: ./flureadium/docs
|getting-started:{installation.md,quick-start.md,concepts.md}
|architecture:{overview.md}
|api-reference:{flureadium-class.md,reader-widget.md,preferences.md,publication.md,locator.md,decorations.md,streams-events.md}
|guides:{epub-reading.md,audiobook-playback.md,text-to-speech.md,highlights-annotations.md,saving-progress.md,preferences.md,error-handling.md}
|platform-specific:{ios.md,android.md,macos.md,web.md}
|05-testing:{integration-tests.md,ios-unit-tests.md}
|also:{troubleshooting.md}

|IMPORTANT: Any implementation plan for FLureadium must include updates to the example app and to the integration tests.
[Flureadium Tests]|unit: ./flureadium/test/{reader,streams,utils,web,widget}/|platform-interface: ./flureadium_platform_interface/test/{exceptions,extensions,models,reader,shared,util,integration}/|integration: ./flureadium/example/integration_test/{audiobook_test,epub_test,epub_tts_test,launch_test,webpub_test}.dart|example: ./flureadium/example/test/widget_test.dart|command: flutter test > /dev/null 2>&1 && echo "TESTS PASSED" || echo "TESTS FAILED"|command to detect failing tests: flutter test -r failures-only
|IMPORTANT: Keep changes to flureadium/ and flureadium_platform_interface/ in separate commits.

[Android Unit Tests]
Kotlin/Robolectric JVM tests — separate from `flutter test`. No gradlew in android/; use cached Gradle directly.

```sh
cd /Users/mulev/Documents/projects/flureadium/flureadium/android && \
  GRADLE_BIN=$(find /Users/mulev/.gradle/wrapper/dists/gradle-8.14-all -name "gradle" -type f 2>/dev/null | head -1) && \
  JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
  "$GRADLE_BIN" testDebugUnitTest 2>&1 | tail -35
```

|java: /Applications/Android Studio.app/Contents/jbr/Contents/Home
|gradle: ~/.gradle/wrapper/dists/gradle-8.14-all/ (use find — hash subfolder varies)
|cwd: flureadium/flureadium/android/
|task: testDebugUnitTest

[iOS Unit Tests]
Swift/XCTest tests — separate from `flutter test`. Run via `xcodebuild` against the example app workspace.
Tests live in `flureadium/example/ios/RunnerTests/`. New files must be registered in `project.pbxproj`.
Requires one-time `flutter build ios --simulator --debug` in `flureadium/example/` before first run.

```sh
# Find a simulator (pick any iPhone from the output)
xcrun simctl list devices available | grep iPhone

# Run all iOS unit tests (replace <simulator-name>)
cd flureadium/example/ios && \
  xcodebuild test \
    -workspace Runner.xcworkspace \
    -scheme Runner \
    -configuration Debug \
    -destination 'platform=iOS Simulator,name=<simulator-name>' \
    -only-testing:RunnerTests \
    2>&1 | grep -E '(Test Case|TEST |Executed|error:)' | tail -30

# Run a single test class
cd flureadium/example/ios && \
  xcodebuild test \
    -workspace Runner.xcworkspace \
    -scheme Runner \
    -configuration Debug \
    -destination 'platform=iOS Simulator,name=<simulator-name>' \
    -only-testing:RunnerTests/FlutterTTSNavigatorTests \
    2>&1 | grep -E '(Test Case|TEST |Executed|error:)' | tail -30
```

|cwd: flureadium/example/ios/
|prereq: `flutter build ios --simulator --debug` (once, re-run when Flutter deps change)
|test files: flureadium/example/ios/RunnerTests/*.swift
|deployment target: IPHONEOS_DEPLOYMENT_TARGET in RunnerTests configs must match flureadium package (currently 13.4)
|docs: flureadium/docs/05-testing/ios-unit-tests.md

<!-- BEGIN BEADS INTEGRATION -->
## Issue Tracking with bd (beads)

**IMPORTANT**: This project uses **bd (beads)** for ALL issue tracking. Do NOT use markdown TODOs, task lists, or other tracking methods.

### Why bd?

- Dependency-aware: Track blockers and relationships between issues
- Git-friendly: Dolt-powered version control with native sync
- Agent-optimized: JSON output, ready work detection, discovered-from links
- Prevents duplicate tracking systems and confusion

### Quick Start

**Check for ready work:**

```bash
bd ready --json
```

**Create new issues:**

```bash
bd create "Issue title" --description="Detailed context" -t bug|feature|task -p 0-4 --json
bd create "Issue title" --description="What this issue is about" -p 1 --deps discovered-from:bd-123 --json
```

**Claim and update:**

```bash
bd update <id> --claim --json
bd update bd-42 --priority 1 --json
```

**Complete work:**

```bash
bd close bd-42 --reason "Completed" --json
```

### Issue Types

- `bug` - Something broken
- `feature` - New functionality
- `task` - Work item (tests, docs, refactoring)
- `epic` - Large feature with subtasks
- `chore` - Maintenance (dependencies, tooling)

### Priorities

- `0` - Critical (security, data loss, broken builds)
- `1` - High (major features, important bugs)
- `2` - Medium (default, nice-to-have)
- `3` - Low (polish, optimization)
- `4` - Backlog (future ideas)

### Workflow for AI Agents

1. **Check ready work**: `bd ready` shows unblocked issues
2. **Claim your task atomically**: `bd update <id> --claim`
3. **Work on it**: Implement, test, document
4. **Discover new work?** Create linked issue:
   - `bd create "Found bug" --description="Details about what was found" -p 1 --deps discovered-from:<parent-id>`
5. **Complete**: `bd close <id> --reason "Done"`

### Auto-Sync

bd automatically syncs via Dolt:

- Each write auto-commits to Dolt history
- Use `bd dolt push`/`bd dolt pull` for remote sync
- No manual export/import needed!

### Important Rules

- ✅ Use bd for ALL task tracking
- ✅ Always use `--json` flag for programmatic use
- ✅ Link discovered work with `discovered-from` dependencies
- ✅ Check `bd ready` before asking "what should I work on?"
- ❌ Do NOT create markdown TODO lists
- ❌ Do NOT use external issue trackers
- ❌ Do NOT duplicate tracking systems

For more details, see README.md and docs/QUICKSTART.md.

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd dolt push
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds

<!-- END BEADS INTEGRATION -->
