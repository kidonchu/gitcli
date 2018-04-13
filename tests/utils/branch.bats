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
