#!/usr/bin/env bats

load test_helper
load ../src/newstory

function setup() {
	_setup_git
	_cd_git
}

function teardown() {
	cd ..
	_teardown_git
}

@test "incorrect option" {
	run newstory -d
	[ "$status" -eq 1 ]
	[[ "$output" =~ "usage: " ]]
}

@test "no branch provided" {
	run newstory
	[ "$status" -eq 1 ]
	[[ "$output" =~ "new branch name was not provided" ]]
}

@test "it should error out when story source branch is incorrectly configured" {
	git config story.source.test upstream/feature/non-existent
	run newstory -b feature/newstory-branch -s test
	[ "$status" -eq 1 ]
	[[ "$output" =~ "could not create new branch" ]]
}

@test "it should create new branch from preconfigured source when source branch is configured" {
	git config story.source.test upstream/feature/test-branch
	run newstory -b feature/newstory-branch -s test
	[ "$status" -eq 0 ]
	run git rev-parse --abbrev-ref HEAD
	[ "$output" = "feature/newstory-branch" ]
}

@test "it should use given source branch as-is when story source branch is not configured" {
	run newstory -b feature/newstory-branch -s upstream/feature/test-branch
	[ "$status" -eq 0 ]
	run git rev-parse --abbrev-ref HEAD
	[ "$output" = "feature/newstory-branch" ]
}

@test "it should push to remote after creating a new branch" {
	run newstory -b feature/newstory-branch -s upstream/feature/test-branch
	[ "$status" -eq 0 ]
	run git status -sb
	[[ "$output" =~ feature/newstory-branch\.\.\.upstream/feature/newstory-branch ]]
}
