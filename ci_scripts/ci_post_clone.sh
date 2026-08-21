#!/bin/zsh
# Xcode Cloud runs this automatically right after cloning the repo and
# before resolving/building the project. We don't commit DinoCode.xcodeproj
# (it's generated from project.yml - see README.md), so this is what
# materializes it in the cloud build environment. Without this script,
# Xcode Cloud would clone a repo with no .xcodeproj in it and have nothing
# to build.
set -e

echo "ci_post_clone: installing XcodeGen"
brew install xcodegen

echo "ci_post_clone: generating DinoCode.xcodeproj"
cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate

echo "ci_post_clone: done"
