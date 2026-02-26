SHELL := /bin/bash

.PHONY: check-public-safety

check-public-safety:
	@"./scripts/public/check-public-safety.sh"
