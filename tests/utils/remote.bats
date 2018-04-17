#!/usr/bin/env bats

load ../test_helper
load ../../src/utils/remote

function setup() {
	_setup_git
	_cd_git
}

function teardown() {
	cd ..
	# _teardown_git
}

@test "it should error out when no branch is given" {
	run get_remote_from_branch
	[ "$status" -eq 1 ]
	[[ "$output" =~ "branch to get remote from must be provided" ]]
}

@test "it should error out when provided branch has invalid format" {
	run get_remote_from_branch test-incorrect-format
	[ "$status" -eq 1 ]
	[[ "$output" =~ "format of branch doesn't match" ]]
}

@test "it should return remote name when provided branch has valid format" {
	run get_remote_from_branch upstream/feature/test-branch
	[ "$status" -eq 0 ]
	[ "$output" = "upstream" ]
}

@test "it should error out when given branch is not tracking any remote" {
	run git branch feature/hello-world
	run get_tracking_remote_from_branch feature/hello-world
	[ "$status" -eq 1 ]
	[[ "$output" =~ [^[:space:]]+" is not tracking any remote" ]]
}

@test "it should return tracking remote for given branch" {
	run get_tracking_remote_from_branch feature/test-branch
	[ "$status" -eq 0 ]
	[ "$output" = "upstream" ]
}
