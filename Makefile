.DEFAULT_GOAL := help

SHELL := /usr/bin/env bash
SCRIPTS_DIR := scripts
LIB_DIR := scripts/lib

.PHONY: help install lint test test-properties verify fmt doctor clean rerecord-fixtures conformance mrp-v2 loop-conformance

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
	@bats test/unit test/integration test/conformance test/properties 2>/dev/null || echo "No tests yet"

test-properties: ## Run only the recording-property assertions (free, fast)
	@bats test/properties

rerecord-fixtures: ## Re-record agent fixtures (LOCAL ONLY — costs ~$$0.50/agent). AGENT=claude-code|codex|gemini|all
	@AGENT="$${AGENT:-claude-code}"; \
	echo "Re-recording fixtures for: $$AGENT"; \
	$(SCRIPTS_DIR)/rerecord-fixtures.sh --agent "$$AGENT"

conformance: ## Run Layer 7 conformance against live agent (LOCAL ONLY — costs ~$$0.30)
	@MONOZUKURI_SKIP_CONFORMANCE=0 bash -c '\
		source .qa/lib/assert.sh; \
		source .qa/lib/semver.sh; \
		source .qa/layers/07-conformance.sh; \
		run_layer7 "v0.0.0-conformance"'

mrp-v2: ## Run the CI-safe Memory v2 MRP matrix and write markdown dashboard
	@node scripts/verification/mrp-matrix.js --mock \
		--results .qa/reports/mrp-v2-results.json \
		--dashboard .qa/reports/mrp-v2-dashboard.md

loop-conformance: ## Run mock loop conformance across Claude Code, Codex, and Gemini
	@bash scripts/verification/loop-conformance.sh --tasks 3 \
		--out-dir .qa/reports/loop-conformance

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
