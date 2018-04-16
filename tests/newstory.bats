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
	echo "output:" "$output"

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

@test "it should push to default remote target after creating a new branch" {
	run git config story.remotetarget remote1
	run newstory -b feature/newstory-branch -s upstream/feature/test-branch
	[ "$status" -eq 0 ]
	run git status -sb
	[[ "$output" =~ feature/newstory-branch\.\.\.remote1/feature/newstory-branch ]]
}

@test "it should push to provided remote target after creating a new branch" {
	run git config story.remotetarget remote1
	run newstory -b feature/newstory-branch -s upstream/feature/test-branch -r remote2
	[ "$status" -eq 0 ]
	run git status -sb
	[[ "$output" =~ feature/newstory-branch\.\.\.remote2/feature/newstory-branch ]]
}

@test "it should save current branch's stash before creating new branch" {
	run touch add c.txt

	run git status
	[[ "$output" =~ "Untracked files" ]]

	run newstory -b feature/newstory-branch -s upstream/feature/test-branch
	[ "$status" -eq 0 ]

	run git status
	[[ "$output" =~ "working tree clean" ]]

	run git config branch.feature/test-branch.laststash
	[[ "$output" =~ [[:alnum:]]{40} ]]
}
