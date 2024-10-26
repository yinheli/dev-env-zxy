HELMFILE := helmfile

ifeq ($(shell which $(HELMFILE)),)
$(info $(HELMFILE) not found. Do you want to install it? [y/N])
INSTALL_HELMFILE := $(shell read -p "" yn; echo $$yn)
ifeq ($(INSTALL_HELMFILE),y)
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	@echo "Installing helmfile for Linux..."
	@curl -fsSL -o get_helmfile.sh https://raw.githubusercontent.com/helmfile/helmfile/main/scripts/get-helmfile.sh
	@chmod 700 get_helmfile.sh
	@./get_helmfile.sh
	@rm get_helmfile.sh
else ifeq ($(UNAME_S),Darwin)
	@echo "Installing helmfile for macOS..."
	@brew install helmfile
else
	$(error Unsupported operating system: $(UNAME_S))
endif
else
	$(error helmfile is required but not installed. Please install it manually.)
endif
endif

.PHONY: all
all: lint

.PHONY: lint
lint: prepare-env
	$(HELMFILE) lint

.PHONY: sync
sync: prepare-env
	$(HELMFILE) sync

.PHONY: apply
apply: prepare-env
	$(HELMFILE) apply

.PHONY: diff
diff: prepare-env
	$(HELMFILE) diff

.PHONY: destroy
destroy: prepare-env
	$(HELMFILE) destroy

.PHONY: template
template: prepare-env
	@if [ -d "$(CURDIR)/tmp/output" ]; then \
		echo "Cleaning up existing output directory..."; \
		rm -rf $(CURDIR)/tmp/output; \
	fi
	@mkdir -p $(CURDIR)/tmp/output
	$(HELMFILE) template --output-dir $(CURDIR)/tmp/output --debug

.PHONY: fetch
fetch: prepare-env
	@echo "Fetching Helm charts for current directory..."
	$(HELMFILE) fetch --output-dir $(CURDIR)/tmp || exit 1
	@echo "All Helm charts have been fetched to $(CURDIR)/tmp directory"


.PHONY: prepare-env
prepare-env:
	cp $(CURDIR)/values/env-template.yaml $(CURDIR)/values/.env-default.yaml
	@echo "Updating hostPath in env-default.yaml..."
	@parent_dir=$$(realpath $(CURDIR)/..); \
	sed -i.bak "s|hostPath: \.\./|hostPath: $$parent_dir/|g" $(CURDIR)/values/.env-default.yaml
	@rm $(CURDIR)/values/.env-default.yaml.bak
	@echo "Paths updated successfully."

# Help command
.PHONY: help
help:
	@echo "Available helmfile commands:"
	@echo "  make lint    - Run helmfile lint to check configuration"
	@echo "  make sync    - Run helmfile sync to synchronize configuration"
	@echo "  make apply   - Run helmfile apply to apply configuration"
	@echo "  make diff    - Run helmfile diff to view differences"
	@echo "  make destroy - Run helmfile destroy to delete resources"
