#!/bin/bash
set -e

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_PARENT_PATH="$( dirname ${SCRIPT_PATH} )"


source ${SCRIPT_PATH}/.hooks-default.sh
if [ -f "${SCRIPT_PARENT_PATH}/.release-scripts-hooks.sh" ]; then
	echo "Found .release-scripts-hooks.sh. Using it as master hooks"
	source "${SCRIPT_PARENT_PATH}/.release-scripts-hooks.sh"
else
	source ${SCRIPT_PATH}/hooks.sh
fi

REMOTE_REPO=`get_remote_repo_name`
DEVELOP_BRANCH=`get_develop_branch_name`
MASTER_BRANCH=`get_master_branch_name`
CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
GIT_REPO_DIR=`git rev-parse --show-toplevel`

function check_local_workspace_state {
	if ! git diff-index --quiet HEAD --
	then
		echo "This script is only safe when your have a clean workspace."
		echo "Please clean your workspace by stashing or committing and pushing changes before processing this $1 script."
		exit 1
	fi
}

function is_branch_existing {
  if git branch -a --list | grep "$1"
  then
    return 0
  else
    return 1
  fi
}

function is_workspace_clean {
  if git diff-files --quiet --ignore-submodules --
  then
    return 0
  else
    return 1
  fi
}

function is_workspace_synced {
  if test "$(git rev-parse @{u})" = "$(git rev-parse HEAD)"
  then
    return 0
  else
    return 1
  fi
}

