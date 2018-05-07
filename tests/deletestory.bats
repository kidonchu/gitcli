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

@test "it should drop saved stash after deleting a branch" {
	# Given a saved stash
	echo "text change 1" >> a.txt
	run git stash
	run git reflog show stash --pretty=format:%H -n 1
	stashHash="$output"
	run git config branch.feature/test-branch.laststash "$stashHash"

	# And a new branch checked out
	run git checkout -b feature/issue-1

	# When I delete a branch
	run delete_branch "feature/test-branch"
	[ "$status" -eq 0 ]

	run git rev-parse --verify feature/issue-1
	[ "$status" -eq 0 ]
}

@test "it should error out if defaultBranch to switch to is not set when deleting current branch" {
	run git checkout -b feature/issue-1
	run delete_current
	[ "$status" -eq 1 ]
	[[ "$output" =~ "could not get default branch" ]]
}

@test "it should delete current local branch" {
	run git config story.defaultBranch feature/issue-1
	run git checkout -b feature/issue-1
	run git checkout -b feature/issue-2
	run delete_current
	[ "$status" -eq 0 ]

	run git rev-parse --verify feature/issue-2
	[ "$status" -ne 0 ]
}

@test "it should delete current local branch AND remote branch if remote is origin" {
	run git config story.defaultBranch feature/issue-1
	run git checkout -b feature/issue-1
	run git checkout -b feature/issue-2
	run git push -u origin feature/issue-2

	run git config "branch.feature/issue-2.remote"
	[ "$status" -eq 0 ]

	run delete_current
	[ "$status" -eq 0 ]

	run git config "branch.feature/issue-2.remote"
	[ "$status" -ne 0 ]

	run git rev-parse --verify feature/issue-2
	[ "$status" -ne 0 ]
}

@test "it should checkout default branch when deleting current branch" {
	run git config story.defaultBranch feature/issue-1
	run git checkout -b feature/issue-1
	run git checkout -b feature/issue-2

	run delete_current
	[ "$status" -eq 0 ]

	run git rev-parse --verify feature/issue-1
	[ "$status" -eq 0 ]
}

@test "it should delete current local branch but not delete remote branch if remote is not origin" {
	run git config story.defaultBranch feature/issue-1
	run git checkout -b feature/issue-1
	run git checkout -b feature/issue-2
	run git push -u remote1 feature/issue-2

	run sh -c 'git br -r | grep feature/issue-2'
	[ "$status" -eq 0 ]

	run delete_current
	[ "$status" -eq 0 ]

	run sh -c 'git br -r | grep feature/issue-2'
	[ "$status" -eq 0 ]

	run git rev-parse --verify feature/issue-2
	[ "$status" -ne 0 ]
}
