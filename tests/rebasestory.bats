#!/usr/bin/env bats

load test_helper
load ../src/rebasestory

setup() {
	_setup_global
	_setup_git
	_cd_git
}

teardown() {
	cd ..
	_teardown_git
	_teardown_global
}

@test "it should error out if no source and no pattern are given" {
	run rebasestory -s
	[ "$status" -eq 1 ]
	[[ "$output" =~ "please specify source or pattern" ]]
}

@test "it should not error out when no branch matching pattern is found" {
	run rebasestory -p "non-existent-"
	[ "$status" -eq 0 ]
	[[ "$output" =~ "no branch found that matches the pattern" ]]
}

@test "it should rebase on given local branch when pattern matches one result" {
	run git checkout -b feature/behind-branch

	run git checkout feature/test-branch
	touch b.txt && run git add b.txt
	run git commit -m "add b.txt"

	run git checkout feature/behind-branch

	run ls
	[[ ! "$output" =~ "b.txt" ]]

	run rebasestory -p "test-branch"
	[ "$status" -eq 0 ]

	run ls
	[[ "$output" =~ "b.txt" ]]
}

@test "it should rebase on given local branch when pattern matches multiple results" {
	run git checkout -b feature/behind-branch

	run git checkout -b feature/rebase-branch1
	touch b.txt && run git add b.txt
	run git commit -m "add b.txt"

	run git checkout -b feature/rebase-branch2

	run git checkout feature/behind-branch

	run ls
	[[ ! "$output" =~ "b.txt" ]]

	run rebasestory -p "rebase-branch"
	[ "$status" -eq 0 ]

	run ls
	[[ "$output" =~ "b.txt" ]]
}

@test "it should error out if current branch has uncommitted changes" {
	run git checkout -b feature/behind-branch

	run git checkout -b feature/rebase-branch1
	touch b.txt && run git add b.txt
	run git commit -m "add b.txt"

	run git checkout feature/behind-branch
	touch b.txt && run git add b.txt

	run rebasestory -p "rebase-branch"
	[ "$status" -eq 1 ]
	[[ "$output" =~ "uncommitted changes" ]]
}

@test "it should rebase on given source" {
	run git checkout -b feature/behind-branch

	run git checkout -b feature/rebase-branch
	touch b.txt && run git add b.txt
	run git commit -m "add b.txt"
	run git push -u upstream feature/rebase-branch

	run git checkout feature/behind-branch

	run ls
	[[ ! "$output" =~ "b.txt" ]]

	run git config story.source.rebasesource upstream/feature/rebase-branch
	run rebasestory -s rebasesource
	[ "$status" -eq 0 ]

	run ls
	[[ "$output" =~ "b.txt" ]]
}

@test "it should fetch remote before rebasing on given source" {
	run git checkout -b feature/behind-branch

	run git checkout -b feature/rebase-branch
	touch b.txt && run git add b.txt
	run git commit -m "add b.txt"
	run git push -u upstream feature/rebase-branch
	run git reset --hard
	[ "$status" -eq 0 ]

	run git checkout feature/behind-branch

	run ls
	[[ ! "$output" =~ "b.txt" ]]

	run git config story.source.rebasesource upstream/feature/rebase-branch
	run rebasestory -s rebasesource
	[ "$status" -eq 0 ]

	run ls
	[[ "$output" =~ "b.txt" ]]
}

@test "it should rebase on given source as branch name if source doesn't exist" {
	run git checkout -b feature/behind-branch

	run git checkout -b feature/rebase-branch
	touch b.txt && run git add b.txt
	run git commit -m "add b.txt"
	run git push -u upstream feature/rebase-branch

	run git checkout feature/behind-branch

	run ls
	[[ ! "$output" =~ "b.txt" ]]

	run rebasestory -s upstream/feature/rebase-branch
	[ "$status" -eq 0 ]

	run ls
	[[ "$output" =~ "b.txt" ]]
}
