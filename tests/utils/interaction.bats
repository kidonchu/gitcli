#!/usr/bin/env bats

load ../test_helper
load ../../src/utils/interaction

function setup() {
	_setup_git
	_cd_git
	export GITCLI_ENV=test
}

function teardown() {
	cd ..
	_teardown_git
	unset GITCLI_ENV
}

@test "it should error out when no options are given to choose one from" {
	run choose_one
	[ "$status" -eq 1 ]
	[[ "$output" =~ "nothing to choose one from" ]]
}

@test "it should return first element in given array during bats test when choosing one from multiple" {
	run choose_one "first second"
	[ "$status" -eq 0 ]
	[ "$output" = "first" ]
}

@test "it should error out when no options are given to choose multiple from" {
	run choose_multiple
	[ "$status" -eq 1 ]
	[[ "$output" =~ "nothing to choose one from" ]]
}

@test "it should return first element in given array during bats test when choosing one from multiple" {
	run choose_multiple "first second third fourth"
	[ "$status" -eq 0 ]
	[ "$output" = "first third" ]
}
