OPENSPEC_TOOLS := claude,codex,opencode

.PHONY: setup
setup:
	pnpm install --frozen-lockfile
	pnpm exec openspec init --tools $(OPENSPEC_TOOLS) --profile core --no-animation .
