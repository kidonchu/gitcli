#!/usr/bin/env bats

load test_helper
load ../src/deletestory

function setup() {
	_setup_git
	_cd_git
}

function teardown() {
	cd ..
	_teardown_git
}

@test "incorrect option" {
	run deletestory -d
	[ "$status" -eq 1 ]
	[[ "$output" =~ "usage: " ]]
}

@test "it should error out when no pattern is provided" {
	run deletestory -p
	[ "$status" -eq 1 ]
	[[ "$output" =~ "please specify pattern" ]]
}

@test "it should not error out when no branch matching pattern is found" {
	run deletestory -p "non-existent-"
	[ "$status" -eq 0 ]
	[[ "$output" =~ "no branch found that matches the pattern" ]]
}

@test "it should delete given local branch" {
	run git branch feature/issue-1
	run delete_branch "feature/issue-1"
	[ "$status" -eq 0 ]

	run git rev-parse --verify feature/issue-1
	[ "$status" -gt 0 ]
}

@test "it should delete remote branch if remote is origin" {
	run git checkout -b feature/issue-1
	run git push -u origin feature/issue-1
	run git checkout feature/test-branch
	run delete_branch "feature/issue-1"
	[ "$status" -eq 0 ]

	run git config "branch.feature/issue-1.remote"
	[ "$status" -ne 0 ]

	run git rev-parse --verify feature/issue-1
	[ "$status" -ne 0 ]
}
