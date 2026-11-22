# ---------------------------------------------------------
# Default Target
# ---------------------------------------------------------

# Set the default goal.
.DEFAULT_GOAL := clean

# Set the app name.
APP_NAME := terraform-provider-canopy

# Set the build directory.
BUILD_DIR := build

# Set the base directory.
BASE_DIR := v2

# ---------------------------------------------------------
# Setup
# ---------------------------------------------------------

.PHONY: setup
.SILENT: setup

# Execute formatter.
setup: 
	@echo "[*] Setting up..."
	cd $(BASE_DIR) &&\
	go mod tidy

# ---------------------------------------------------------
# QA
# ---------------------------------------------------------

.PHONY: qa/format qa/lint qa
.SILENT: qa/format qa/lint qa

# Execute formatter.
qa/format: 
	@echo "[*] Formatting..."
	cd $(BASE_DIR) &&\
	go fmt ./...

# Execute linter.
qa/lint: 
	@echo "[*] Linting..."
	cd $(BASE_DIR) &&\
	golangci-lint run --fix

# Execute all quality assurance tools.
qa: qa/format qa/lint

# ---------------------------------------------------------
# Test
# ---------------------------------------------------------

.PHONY: test dev/test
.SILENT: test dev/test

# Execute unit tests with test coverage.
test: 
	@echo "[*] Testing with coverage report..."
	cd $(BASE_DIR) &&\
	go test -p 1 -v -cover -coverprofile=coverage.out ./...

# Execute  unit tests without test coverage.
dev/test: 
	@echo "[*] Testing without coverage report..."
	cd $(BASE_DIR) &&\
	go test -p 1 ./...

# ---------------------------------------------------------
# Build
# ---------------------------------------------------------

.PHONY: build
.SILENT: build

build: setup qa test
	@echo "[*] Building..."
	cd $(BASE_DIR) &&\
	go build -ldflags="-s -w" -o ../$(BUILD_DIR)/$(APP_NAME) main.go

# ---------------------------------------------------------
# Release
# ---------------------------------------------------------

.SILENT: release

release: build
	cp $(BUILD_DIR)/$(APP_NAME) .

# ---------------------------------------------------------
# Clean
# ---------------------------------------------------------

.SILENT: clean

# Clean build.
clean: release
	@echo "[*] Cleaning up..."
	rm -rf $(BUILD_DIR)
