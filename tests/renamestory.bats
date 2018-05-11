#!/usr/bin/env bats

load test_helper
load ../src/renamestory

function setup() {
	_setup_global
	_setup_git
	_cd_git
}

function teardown() {
	cd ..
	_teardown_git
	_teardown_global
}

@test "incorrect option" {
	run renamestory -d
	[ "$status" -eq 1 ]
	[[ "$output" =~ "usage: " ]]
}

@test "no new branch name is specified" {
	run renamestory
	[ "$status" -eq 1 ]
	[[ "$output" =~ "new branch name was not provided" ]]

	run rename_branch
	[ "$status" -eq 1 ]
	[[ "$output" =~ "new branch name was not provided" ]]
}

@test "should create new branch with given name" {
	run rename_branch feature/renamed-branch
	[ "$status" -eq 0 ]

	run git rev-parse --verify feature/renamed-branch
	[ "$status" -eq 0 ]
}

@test "new branch should be on the same commit as old branch" {
	run git rev-parse feature/test-branch
	oldBranchHash="$output"

	run rename_branch feature/renamed-branch
	[ "$status" -eq 0 ]

	run git rev-parse feature/renamed-branch
	newBranchHash="$output"

	[[ "$oldBranchHash" == "$newBranchHash" ]]
}

@test "should checkout new branch" {
	run rename_branch feature/renamed-branch
	[ "$status" -eq 0 ]

	run git rev-parse --abbrev-ref HEAD
	[ "$output" == "feature/renamed-branch" ]
}

@test "should delete local old branch" {
	run rename_branch feature/renamed-branch
	[ "$status" -eq 0 ]

	run sh -c 'git br | grep feature/test-branch'
	[ "$status" -ne 0 ]
}

@test "should delete remote old branch if origin is remote" {
	run git checkout -b feature/to-be-deleted
	run git push -u origin feature/to-be-deleted

	run sh -c 'git br -r | grep origin/feature/to-be-deleted'
	[ "$status" -eq 0 ]

	run rename_branch feature/renamed-branch
	[ "$status" -eq 0 ]

	run sh -c 'git br -r | grep origin/feature/to-be-deleted'
	[ "$status" -ne 0 ]
}

@test "should not delete remote old branch if origin is not remote" {
	run git checkout -b feature/to-be-deleted
	run git push -u upstream feature/to-be-deleted

	run sh -c 'git br -r | grep upstream/feature/test-branch'
	[ "$status" -eq 0 ]

	run rename_branch feature/renamed-branch
	[ "$status" -eq 0 ]

	run sh -c 'git br -r | grep upstream/feature/test-branch'
	[ "$status" -eq 0 ]
}

@test "new branch should track same remote as old branch" {
	run git checkout -b feature/to-be-deleted
	run git push -u remote2 feature/to-be-deleted

	run rename_branch feature/renamed-branch
	[ "$status" -eq 0 ]

	run sh -c 'git br -r | grep remote2/feature/renamed-branch'
	[ "$status" -eq 0 ]
}

@test "should keep local changes after renaming" {
	echo "text change 1" >> a.txt
	run git diff
	oldDiff="$output"

	run rename_branch feature/renamed-branch
	[ "$status" -eq 0 ]

	run git diff
	newDiff="$output"

	[[ "$oldDiff" == "$newDiff" ]]
}
