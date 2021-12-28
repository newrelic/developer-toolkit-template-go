#!/bin/bash

SRCDIR=${SRCDIR:-"."}
GOBIN=$(go env GOPATH)/bin
VER_PACKAGE="internal/version"
VER_CMD=${GOBIN}/svu
VER_BUMP=${GOBIN}/gobump
CHANGELOG_CMD=${GOBIN}/git-chglog
REL_CMD=${GOBIN}/goreleaser
RELEASE_NOTES_FILE=${SRCDIR}/tmp/relnotes.md

# Compare versions
VER_CURR=$(${VER_CMD} current --strip-prefix)
VER_NEXT=$(${VER_CMD} next --strip-prefix)

# Github Enterprise work-around for Goreleaser
export GITHUB_TOKEN="${GITHUB_TOKEN:-$GHE_TOKEN}"

if [ "${VER_CURR}" != "${VER_NEXT}" ]; then
  echo "Generating release for v${VER_NEXT}"
  # Bump package version
  ${VER_BUMP} set ${VER_NEXT} -r -w ${VER_PACKAGE}

  # Auto-generate CHANGELOG updates
  ${CHANGELOG_CMD} --next-tag v${VER_NEXT} -o CHANGELOG.md

  GIT_USER=$(git config user.name)
  GIT_EMAIL=$(git config user.email)
  #[ -z "${GIT_USER}" ]  && git config --global user.name "goreleaser"
  #[ -z "${GIT_EMAIL}" ] && git config --global user.email "youremail@example.com"

  # Commit CHANGELOG updates
  git add CHANGELOG.md ${VER_PACKAGE}/

  git commit -m "chore(release): Releasing v${VER_NEXT}"
  git tag v${VER_NEXT}
  git push origin HEAD:master --tags

  # Make release notes
  ${CHANGELOG_CMD} --silent -o ${RELEASE_NOTES_FILE} v${VER_NEXT}

  # Publish the release
  ${REL_CMD} release --release-notes=${RELEASE_NOTES_FILE}
else
  echo "No new version recommended, skipping"
fi

