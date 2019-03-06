#!/usr/bin/env bats

load tests_common

@test "run release script from support branch" {
	./release-scripts/release.sh 32.1 33.0
	git push --atomic origin master develop --follow-tags

  git tag | grep v32.1

	git checkout v32.1
	git branch support-32.x

	git checkout develop
	echo "some 33-related work" >> somefile
	git add somefile
	git commit -m "Do some 33-related work"
	./release-scripts/release.sh 33.0 33.1
	git push --atomic origin master develop --follow-tags

	git tag | grep v33.0

	git checkout develop
	[[ "$(cat version.txt)" == "33.1-SNAPSHOT" ]] || cat version.txt "Incorrect next snapshot version"

  git checkout support-32.x
  echo "some 32-support work" >> somefile
  git add somefile
  git commit -m "Do some 32-support related work"

  ./release-scripts/support_release.sh 32.x 32.2 32.3
  git push --atomic origin master-32.x support-32.x --follow-tags

  git tag | grep v32.2

  git checkout v32.2
	[[ "$(cat version.txt)" == "32.2" ]] || cat version.txt "Incorrect support tag version"
	cat somefile | grep "some 32-support work" > /dev/null

  git checkout master-32.x
	[[ "$(cat version.txt)" == "32.2" ]] || cat version.txt "Incorrect support master version"
	cat somefile | grep "some 32-support work" > /dev/null

	git checkout support-32.x
	[[ "$(cat version.txt)" == "32.3-SNAPSHOT" ]] || cat version.txt "Incorrect support branch snapshot version"
	cat somefile | grep "some 32-support work" > /dev/null

  git checkout master
	[[ "$(cat version.txt)" == "33.0" ]] || cat version.txt "Incorrect master version"
	[[ "$(grep "some 32-support work" somefile)" != "0" ]]
}

