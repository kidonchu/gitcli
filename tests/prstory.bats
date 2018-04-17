#!/usr/bin/env bats

load test_helper
load ../src/prstory

function setup() {
	_setup_git
	_cd_git
}

function teardown() {
	cd ..
	_teardown_git
}

@test "incorrect option" {
	run prstory -d
	[ "$status" -eq 1 ]
	[[ "$output" =~ "usage: " ]]
}

@test "it should use preconfigured source when source branch is configured" {
	# Give a new branched checked out that tracks origin remote
	run git checkout -b feature/hello-world
	run git push -u origin feature/hello-world
	# And correct git@github.com remote URLs
	run git config remote.upstream.url "git@github.com:kidonchu-upstream/non-existent.git"
	run git config remote.origin.url "git@github.com:kidonchu-origin/non-existent.git"
	# And source `test` configured to point to upstream's branch
	run git config story.source.test upstream/feature/test-branch
	# And a mock `open` function that echos out generated PR url
	function open() {
		echo ${1:-}
	}

	# When I run the command
	run prstory -s test
	echo "output:" "$output"


	# Then I should see success
	[ "$status" -eq 0 ]
	# And I should see correctly generated URL
	[ "$output" = "https://github.com/kidonchu-upstream/non-existent/compare/feature/test-branch...kidonchu-origin:feature/hello-world?expand=1" ]
}

@test "it should use given source branch as-is when story source branch is not configured" {
	# Give a new branched checked out that tracks origin remote
	run git checkout -b feature/hello-world
	run git push -u origin feature/hello-world
	# And correct git@github.com remote URLs
	run git config remote.upstream.url "git@github.com:kidonchu-upstream/non-existent.git"
	run git config remote.origin.url "git@github.com:kidonchu-origin/non-existent.git"
	# And source `test` configured to point to upstream's branch
	# And a mock `open` function that echos out generated PR url
	function open() {
		echo ${1:-}
	}

	# When I run the command
	run prstory -s upstream/feature/test-branch

	# Then I should see success
	[ "$status" -eq 0 ]
	# And I should see correctly generated URL
	[ "$output" = "https://github.com/kidonchu-upstream/non-existent/compare/feature/test-branch...kidonchu-origin:feature/hello-world?expand=1" ]
}

@test "it should error out when generating PR url with empty branch given" {
	run get_pr_url
	[ "$status" -eq 1 ]
	[[ "$output" =~ "base branch is not provided" ]]
}

@test "it should error out when something is wrong with base settings" {
	run git push -u origin feature/test-branch
	run git checkout -b feature/hello-world
	run git push -u upstream feature/hello-world
	run git config remote.upstream.url "git@github.com:kidonchu/non-existent.git"
	run git config remote.origin.url ""
	run get_pr_url origin/feature/test-branch
	[ "$status" -eq 1 ]
	[[ "$output" =~ "something is wrong with base settings" ]]
}

@test "it should error out when something is wrong with head settings" {
	run git branch feature/hello-world
	run git branch --set-upstream=origin/feature/hello-world
	run git config remote.origin.url "git@github.com:kidonchu/non-existent.git"
	run git config remote.upstream.url ""
	run get_pr_url origin/feature/hello-world
	[ "$status" -eq 1 ]
	echo "output:" "$output"
	
	[[ "$output" =~ "something is wrong with head settings" ]]
}

@test "it should generate PR url" {
	run git checkout -b feature/hello-world
	run git push -u upstream feature/hello-world
	run git config remote.upstream.url "git@github.com:kidonchu/non-existent.git"
	run get_pr_url upstream/feature/test-branch
	[ "$status" -eq 0 ]
	[ "$output" = "https://github.com/kidonchu/non-existent/compare/feature/test-branch...kidonchu:feature/hello-world?expand=1" ]
}
