#!/usr/bin/env bats

load test_helper
load ../src/switchstory

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
	run switchstory -d
	[ "$status" -eq 1 ]
	[[ "$output" =~ "usage: " ]]
}

@test "it should error out when no pattern is provided" {
	run switchstory -p
	[ "$status" -eq 1 ]
	[[ "$output" =~ "please specify pattern" ]]
}

@test "it should not error out when no branch matching pattern is found" {
	run switchstory -p "non-existent-"
	[ "$status" -eq 0 ]
	[[ "$output" =~ "no branch found that matches the pattern" ]]
}

@test "it should switch to branch if only one branch matches the pattern" {
	run git branch "feature/hello-world"
	run switchstory -p "hello-"
	[ "$status" -eq 0 ]

	run git rev-parse --abbrev-ref HEAD
	[ "$output" = "feature/hello-world" ]
}

@test "it should display branches to choose from if multiple branches match the pattern" {
	run git branch "feature/hello-another-world"
	run git branch "feature/hello-world"

	run switchstory -p "hello-"
	[ "$status" -eq 0 ]

	run git rev-parse --abbrev-ref HEAD
	[ "$output" = "feature/hello-another-world" ]
}

@test "it should not error out when there is no branch in recent branch list" {
	run switchstory -r
	[ "$status" -eq 0 ]
	[[ "$output" =~ "no branch found in recent branch list" ]]
}

@test "it should switch to branch if only one branch is found in recent branch list" {
	run git branch "feature/hello-world"
	run git config story.recent "feature/hello-world"
	run switchstory -r
	[ "$status" -eq 0 ]

	run git rev-parse --abbrev-ref HEAD
	[ "$output" = "feature/hello-world" ]
}

@test "it should display branches to choose from if multiple branches are in recent branch list" {
	run git branch "feature/hello-another-world"
	run git branch "feature/hello-world"
	run git branch "feature/test-branch"
	run git config story.recent "feature/hello-world feature/test-branch feature/hello-another-world"

	run switchstory -r
	[ "$status" -eq 0 ]

	run git rev-parse --abbrev-ref HEAD
	[ "$output" = "feature/hello-world" ]
}

@test "it should save stash when switching to branch" {
	run touch c.txt
	run git status
	[[ "$output" =~ "Untracked files" ]]

	run git branch "feature/hello-world"
	run switchstory -p "hello-"
	[ "$status" -eq 0 ]

	run git status
	[[ "$output" =~ "working tree clean" ]]

	run git config branch.feature/test-branch.laststash
	[[ "$output" =~ [[:alnum:]]{40} ]]
}

@test "it should add current branch to recent branch list when switching to branch" {
	run git branch "feature/hello-world"
	run git config story.recent "feature/hello-world"
	run switchstory -r
	[ "$status" -eq 0 ]

	run git config story.recent
	[[ "$output" =~ "feature/test-branch" ]]
}

@test "it should remove switched-to branch from recent branch list when switching to branch" {
	run git branch "feature/hello-world"
	run git config story.recent "feature/hello-world"
	run switchstory -r
	[ "$status" -eq 0 ]

	run git config story.recent
	[[ ! "$output" =~ "feature/hello-world" ]]
}

@test "it should not error out when popping stash fails after switching to branch" {
	run git config branch.feature/test-branch.laststash "NONONONONO"
	run git checkout -b "feature/issue-1"
	run switchstory -p "feature/test-branch"
	[ "$status" -eq 0 ]
	[[ "$output" =~ "could not pop saved stash for current branch" ]]
}

@test "it should pop saved stash when switching to branch" {
	touch c.txt
	run git add -A
	run git status
	[[ "$output" =~ "Changes to be committed" ]]

	run git stash
	run git status
	[[ "$output" =~ "working tree clean" ]]

	run git rev-parse stash@\{0\}
	stashhash="$output"
	run git config branch.feature/test-branch.laststash "$stashhash"

	run git checkout -b "feature/issue-1"
	run switchstory -p "feature/test-branch"
	[ "$status" -eq 0 ]

	run git status
	[[ "$output" =~ "Untracked files" ]]
}
