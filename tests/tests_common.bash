#!/usr/bin/env bash

WORKDIR="${BATS_TMPDIR}/release-test-$(date '+%Y-%m-%d_%H-%M-%S')"
LOCALREPO=${WORKDIR}/localrepo
REMOTEREPO=${WORKDIR}/remoterepo

setup() {
	mkdir -p "${LOCALREPO}" "${REMOTEREPO}"
	cd "${REMOTEREPO}" && git init --bare
	git clone "${REMOTEREPO}" "${LOCALREPO}"
	cd "${LOCALREPO}"
	echo "somedata" > somefile
	git add somefile
	git commit -m "add somefile"
	git checkout -b develop
	mkdir release-scripts
	cp -r ${BATS_TEST_DIRNAME}/../. release-scripts/
	rm -rf release-scripts/.git release-scripts/tests
	cp ${BATS_TEST_DIRNAME}/test-hooks.sh .release-scripts-hooks.sh
	git add release-scripts .release-scripts-hooks.sh
	git commit -m "register release-scripts"
	git status
	git push -u origin master develop
}

teardown() {
	cd ..
	[[ -d "${WORKDIR}" ]] && rm -fr "${WORKDIR}"
}
