#!/bin/bash
set -e

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -f "${SCRIPT_PATH}/.version.sh" ]; then
	source ${SCRIPT_PATH}/.version.sh
else
	VERSION="UNKNOWN VERSION"
fi

echo "Release scripts (release, version: ${VERSION})"

if [ -f "${SCRIPT_PATH}/.common-util.sh" ]; then
	source ${SCRIPT_PATH}/.common-util.sh
else
	echo 'Missing file .common-util.sh. Aborting'
	exit -1
fi

SUPPORT_BRANCH=$1
RELEASE_VERSION=$2
NEXT_VERSION=$3

if [ $# -ne 3 ]
then
  echo 'Usage: support_release.sh <support-branch> <release-version> <next-snapshot-version>'
  echo 'For example: support_release.sh support-3.x 3.2 3.3'
  exit 2
fi

if ! is_branch_existing ${SUPPORT_BRANCH} && ! is_branch_existing remotes/${REMOTE_REPO}/${SUPPORT_BRANCH}
then
  echo "Cannot find branch '${SUPPORT_BRANCH}'"
  echo 'Usage: support_release.sh <support-branch> <release-version> <next-snapshot-version>'
  echo 'For example: support_release.sh support-3.x 3.2 3.3'
  exit 2
fi


RELEASE_BRANCH=`format_release_branch_name "$RELEASE_VERSION"`

if [ ! "${CURRENT_BRANCH}" = "${SUPPORT_BRANCH}" ]
then
  echo "Please checkout the branch '${SUPPORT_BRANCH}' before processing this release script."
  exit 1
fi

check_local_workspace_state "release"

git checkout ${SUPPORT_BRANCH} && git pull ${REMOTE_REPO}
git checkout -b ${RELEASE_BRANCH}

build_snapshot_modules
cd ${GIT_REPO_DIR}
git reset --hard

set_modules_version ${RELEASE_VERSION}
cd ${GIT_REPO_DIR}

if ! git diff-files --quiet --ignore-submodules --
then
  # commit release versions
  git commit -am "Prepare release ${RELEASE_VERSION}"
else
  echo "Nothing to commit..."
fi

build_release_modules
cd ${GIT_REPO_DIR}
git reset --hard

# create release tag on release branch
RELEASE_TAG=`format_release_tag "${RELEASE_VERSION}"`
git tag -a "${RELEASE_TAG}" -m "Release ${RELEASE_VERSION}"

git checkout ${SUPPORT_BRANCH}

NEXT_SNAPSHOT_VERSION=`format_snapshot_version "${NEXT_VERSION}"`
set_modules_version "${NEXT_SNAPSHOT_VERSION}"
cd ${GIT_REPO_DIR}

if ! git diff-files --quiet --ignore-submodules --
then
  # Commit next snapshot versions into develop
  git commit -am "Start next iteration with ${NEXT_SNAPSHOT_VERSION}"
else
  echo "Nothing to commit..."
fi

if git merge --no-edit ${RELEASE_BRANCH}
then
  # Nope, doing that automtically is too dangerous. But the command is great!
  echo "# Okay, now you've got a new tag and commits on ${RELEASE_BRANCH} and ${SUPPORT_BRANCH}."
  echo "# Please check if everything looks as expected and then push."
  echo "# Use this command to push all at once or nothing, if anything goes wrong:"
  echo "git push --atomic ${REMOTE_REPO} ${RELEASE_BRANCH} ${SUPPORT_BRANCH} --follow-tags # all or nothing"
else
  echo "# Okay, you have got a conflict while merging onto ${SUPPORT_BRANCH}"
  echo "# but don't panic, in most cases you can easily resolve the conflicts (in some cases you even do not need to merge all)."
  echo "# Please do so and finish the release process with the following command:"
  echo "git push --atomic ${REMOTE_REPO} ${RELEASE_BRANCH} ${SUPPORT_BRANCH} --follow-tags # all or nothing"
fi
