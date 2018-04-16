#!/usr/bin/env bats

load ../test_helper
load ../../src/utils/branch

function setup() {
	_setup_git
	_cd_git
}

function teardown() {
	cd ..
	_teardown_git
}

@test "getting current branch name" {
	run git checkout -b feature/test-branch
	run touch a.txt && run git add a.txt
	run git commit -m "Add a.txt"
	
	run get_current_branch
	[ "$status" -eq 0 ]
	[ "$output" = "feature/test-branch" ]
}

@test "it should error out when getting branches with empty pattern" {
	run get_branches_with_pattern
	[ "$status" -eq 1 ]
	[[ "$output" =~ "please specify pattern" ]]
}

@test "it should return empty when no branch matches pattern" {
	run get_branches_with_pattern "hello-"
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "it should return a list of branches that match pattern" {
	run git branch feature/another-test-branch
	run git branch feature/another-hello-world
	run git branch feature/hello-world
	run get_branches_with_pattern "hello-"
	[ "$status" -eq 0 ]
	[ "$output" = "feature/another-hello-world feature/hello-world" ]
}

@test "it should not return current branch in the list of branches that match pattern" {
	run git branch feature/another-test-branch
	run get_branches_with_pattern "test-"
	[ "$status" -eq 0 ]
	[ "$output" = "feature/another-test-branch" ]
}
