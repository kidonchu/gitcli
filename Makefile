TESTS = $(shell find tests -name '*.bats' -type f)

define testtarget

.PHONY: $(1)

$(1):
	bats -p $(1)

endef

$(foreach i,$(TESTS),$(eval $(call testtarget,$(i))))
