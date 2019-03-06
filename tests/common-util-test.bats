#!/usr/bin/env bats

load tests_common

@test "support branch becomes prefix defined in hooks" {
  ls -la
  source .release-scripts-hooks.sh
  SUPPORT_NAME=`format_support_branch_name 29.x`
  [[ "${SUPPORT_NAME}" == "support-29.x" ]]
}
