#!/bin/bash
# .qa/lib/semver.sh — semver parsing helpers

# parse_semver <version> → sets SEMVER_MAJOR, SEMVER_MINOR, SEMVER_PATCH
# Accepts optional leading "v" (e.g. "v1.20.0" or "1.20.0").
parse_semver() {
  local raw="${1#v}"
  SEMVER_MAJOR="${raw%%.*}"
  local rest="${raw#*.}"
  SEMVER_MINOR="${rest%%.*}"
  SEMVER_PATCH="${rest#*.}"
  SEMVER_PATCH="${SEMVER_PATCH%%-*}"  # strip pre-release suffix
}

# is_patch_release <version> → exits 0 if patch (z bump), 1 otherwise
# A "patch release" is one where minor and major are unchanged from the
# previous release — i.e. only SEMVER_PATCH > 0 matters as a heuristic.
# We define patch as: minor == 0 in the tag fragment OR patch > 0 AND minor > 0
# In practice: a release is a patch if it's vX.Y.Z with Z > 0 but Y is same as
# last tag. Since we don't have git context here, we use the simpler rule:
# SEMVER_PATCH > 0 AND it's NOT a minor release indicator (minor changed).
# Callers should pass the version string; they interpret the result.
is_patch_release() {
  parse_semver "$1"
  [ "$SEMVER_PATCH" -gt 0 ] && [ "$SEMVER_MINOR" -gt 0 ] && return 0
  # 1.0.1, 1.0.2 etc. are also patches
  [ "$SEMVER_PATCH" -gt 0 ] && [ "$SEMVER_MINOR" -eq 0 ] && return 0
  return 1
}

# is_minor_or_major_release <version> → exits 0 for minor or major bumps
is_minor_or_major_release() {
  parse_semver "$1"
  [ "$SEMVER_PATCH" -eq 0 ] && return 0
  return 1
}
