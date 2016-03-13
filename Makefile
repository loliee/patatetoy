PATH := $(PATH):$(HOME)/.local/bin:$(HOME)/bin:/usr/local/bin

.DEFAULT_GOAL := help

export PATH

help:
	@grep -E '^[a-zA-Z1-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN { FS = ":.*?## " }; { printf "\033[36m%-30s\033[0m %s\n", $$1, $$2 }'

test: ## Test prompt files
	$(info --> Test files)
	@shellcheck -s bash $(PWD)/patatetoy_common.sh
