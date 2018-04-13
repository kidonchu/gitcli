#!/usr/bin/env bats

load ../test_helper
load ../../src/utils/checkout

function setup() {
	_setup_git
	_cd_git
}

function teardown() {
	cd ..
	_teardown_git
}

@test "checking out a branch" {
	run git branch feature/test-branch
	
	run checkout
	[ "$status" -eq 1 ]
	[ "$output" = "error: branch to checkout must be specified" ]

	run checkout feature/non-existence
	[ "$status" -eq 1 ]
	[[ "$output" =~ "error: unable to checkout 'feature/non-existence'" ]]

	run checkout feature/test-branch
	[ "$status" -eq 0 ]
}
