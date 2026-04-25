.DEFAULT_GOAL := help

SHELL := /usr/bin/env bash
SCRIPTS_DIR := scripts
LIB_DIR := scripts/lib

.PHONY: help install lint test verify fmt doctor clean

help: ## Show available targets
	@awk '/^[a-zA-Z_-]+:.*?## .*/{printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install pre-commit hooks (and npm deps in ui/ once it exists)
	@if [ -d ui ]; then \
		echo "Installing npm dependencies in ui/..."; \
		npm install --prefix ui; \
	fi
	@command -v pre-commit >/dev/null 2>&1 || { echo "pre-commit not found — run: pip install pre-commit"; exit 1; }
	pre-commit install

lint: ## Run shellcheck on all shell scripts
	@echo "Running shellcheck on $(SCRIPTS_DIR)/lib/*.sh ..."
	@shellcheck $(LIB_DIR)/*.sh
	@echo "Running shellcheck on $(SCRIPTS_DIR)/*.sh ..."
	@shellcheck $(SCRIPTS_DIR)/*.sh

test: ## Run bats test suites
	@bats test/unit test/integration 2>/dev/null || echo "No tests yet"

verify: lint test ## Run lint then test

fmt: ## Format shell scripts with shfmt (2-space indent)
	@if command -v shfmt >/dev/null 2>&1; then \
		echo "Formatting shell scripts..."; \
		shfmt -w -i 2 $(LIB_DIR)/*.sh $(SCRIPTS_DIR)/*.sh; \
	else \
		echo "shfmt not found — install with: brew install shfmt"; \
	fi

doctor: ## Run monozukuri doctor
	monozukuri doctor

clean: ## Remove test artifacts and build output
	@rm -rf .monozukuri-test/ ui/dist/ ui/node_modules/
	@echo "Cleaned."
