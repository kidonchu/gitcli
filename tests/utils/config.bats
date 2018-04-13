#!/usr/bin/env bats

load ../test_helper
load ../../src/utils/config

function setup() {
	_setup_git
	_cd_git
}

function teardown() {
	cd ..
	_teardown_git
}

@test "setting git config" {
	run set_config
	[ "$status" -eq 1 ]
	[ "$output" = "error: key must not be empty" ]

	run set_config ""
	[ "$status" -eq 1 ]
	[ "$output" = "error: key must not be empty" ]

	run set_config "test.key1"
	[ "$status" -eq 1 ]
	[ "$output" = "error: value must be set" ]

	run set_config "test.key1" "value1"
	[ "$status" -eq 0 ]

	run git config "test.key1"
	[ "$status" -eq 0 ]
	[ "$output" = "value1" ]
}

@test "getting git config" {
	run get_config
	[ "$status" -eq 1 ]
	[ "$output" = "error: key must not be empty" ]

	run get_config "test.key2"
	[ "$status" -eq 1 ]
	[ "$output" = "error: unable to retrieve config with 'test.key2'" ]

	run git config "test.key1" "value1"
}
