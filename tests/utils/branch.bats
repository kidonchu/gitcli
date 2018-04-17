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

@test "it should error out when branch is not specified" {
	run add_recent_branch
	[ "$status" -eq 1 ]
	[[ "$output" =~ "please specify branch to add to recent list" ]]
}

@test "it should add branch to empty recent branch list" {
	run add_recent_branch feature/test-branch
	[ "$status" -eq 0 ]
	run git config story.recent
	[ "$output" = "feature/test-branch" ]
}

@test "it should add branch to the beginning of existing recent branch list" {
	run git config story.recent "feature/hello-world feature/hi-world"
	run add_recent_branch feature/test-branch
	[ "$status" -eq 0 ]
	run git config story.recent
	[ "$output" = "feature/test-branch feature/hello-world feature/hi-world" ]
}

@test "it should remove duplicates before adding branch to the recent branch list" {
	run git config story.recent "feature/hello-world feature/test-branch feature/hi-world"
	run add_recent_branch feature/test-branch
	[ "$status" -eq 0 ]
	run git config story.recent
	[ "$output" = "feature/test-branch feature/hello-world feature/hi-world" ]
}

@test "it should error out when branch to pop is not specified" {
	run drop_recent_branch
	[ "$status" -eq 1 ]
	[[ "$output" =~ "branch to pop from recent branch list is not specified" ]]
}

@test "it should error out when recent branch list is empty" {
	run drop_recent_branch feature/hello-world
	[ "$status" -eq 1 ]
	[[ "$output" =~ "no branch exists in recent branch list" ]]

	run git config story.recent ""
	run drop_recent_branch feature/hello-world
	[ "$status" -eq 1 ]
	[[ "$output" =~ "no branch exists in recent branch list" ]]
}

@test "it should notify when popping out non-existent branch from recent branch list" {
	run git config story.recent "feature/hello-another-world"
	run drop_recent_branch feature/hello-another
	[ "$status" -eq 0 ]
	[[ "$output" =~ "branch ".+" does not exist" ]]
}

@test "it should pop out branch when branch exists in recent branch list" {
	run git config story.recent "feature/hello-world feature/test-branch feature/hi"
	run drop_recent_branch feature/test-branch
	[ "$status" -eq 0 ]
	run git config story.recent
	[ "$output" = "feature/hello-world feature/hi" ]
}

@test "it should remove all duplicate branch when multiple branches exists in recent branch list" {
	run git config story.recent "feature/hello-world feature/test-branch feature/hi feature/test-branch"
	run drop_recent_branch feature/test-branch
	[ "$status" -eq 0 ]
	run git config story.recent
	[ "$output" = "feature/hello-world feature/hi" ]
}

@test "it should return empty if recent branch list is empty" {
	run git config story.recent
	run get_recent_branch_list
	[ "$status" -eq 0 ]
	[ "$output" = "" ]

	run git config story.recent ""
	run get_recent_branch_list
	[ "$status" -eq 0 ]
	[ "$output" = "" ]
}

@test "it should return recent branch list" {
	run git config story.recent "feature/hello-world feature/test-branch feature/hi feature/test-branch"
	run get_recent_branch_list
	[ "$status" -eq 0 ]
	[ "$output" = "feature/hello-world feature/test-branch feature/hi feature/test-branch" ]
}
