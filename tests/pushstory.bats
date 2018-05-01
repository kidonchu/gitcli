#!/usr/bin/env bats

load test_helper
load ../src/pushstory

setup() {
	_setup_git
	_cd_git
}

teardown() {
	cd ..
	_teardown_git
}

@test "it should push to default remote target if no remote target is provided" {
	run git config story.remotetarget remote1
	run git checkout -b feature/branch-tracking-remote1
	run pushstory
	[ "$status" -eq 0 ]
	run git status -sb
	[[ "$output" =~ feature/branch-tracking-remote1\.\.\.remote1/feature/branch-tracking-remote1 ]]
}

@test "it should push to provided remote target" {
	run git config story.remotetarget remote1
	run git checkout -b feature/branch-tracking-remote2
	run pushstory -r remote2
	[ "$status" -eq 0 ]
	run git status -sb
	[[ "$output" =~ feature/branch-tracking-remote2\.\.\.remote2/feature/branch-tracking-remote2 ]]
}

@test "it should push to 'origin' remote if no remote target exists in git config" {
	run git checkout -b feature/branch-tracking-origin
	run pushstory
	[ "$status" -eq 0 ]
	run git status -sb
	[[ "$output" =~ feature/branch-tracking-origin\.\.\.origin/feature/branch-tracking-origin ]]
}
