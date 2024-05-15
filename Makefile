include make/golang.mk

BUILD_DIR = build
VERSION   = "UNKNOWN"
GOOSARCH  = $(shell go tool dist list | grep -v android)

.DEFAULT_GOAL :=
default: clean fmt lint test integ gobinsec

integ: build # Run integration test
	$(title)
	-@$(BUILD_DIR)/gobinsec test/binary > $(BUILD_DIR)/report.yml
	@test $? || (echo "ERROR should have exited with code 1" && exit 1)
	@cmp test/report.yml $(BUILD_DIR)/report.yml
	@cat test/config.yml | envsubst > $(BUILD_DIR)/config.yml
	@$(BUILD_DIR)/gobinsec -verbose -config $(BUILD_DIR)/config.yml test/binary > $(BUILD_DIR)/report-config.yml
	@cmp test/report-config.yml $(BUILD_DIR)/report-config.yml

release: clean lint test integ binaries # Perform release (must pass VERSION=X.Y.Z on command line)
	$(title)
	@if [ "$(VERSION)" = "UNKNOWN" ]; then \
		echo "ERROR you must pass VERSION=X.Y.Z on command line"; \
		exit 1; \
	fi
	@git diff-index --quiet HEAD -- || (echo "ERROR There are uncommitted changes" && exit 1)
	@test `git rev-parse --abbrev-ref HEAD` = 'main' || (echo "ERROR You are not on branch main" && exit 1)
	@git tag -a $(VERSION) -m "Release $(VERSION)"
	@git push origin --tags

memcached: # Start memcached
	$(title)
	@docker-compose up -d memcached
