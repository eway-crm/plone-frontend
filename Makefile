## Defensive settings for make:
#     https://tech.davis-hansson.com/p/make/
SHELL:=bash
.ONESHELL:
.SHELLFLAGS:=-xeu -o pipefail -O inherit_errexit -c
.SILENT:
.DELETE_ON_ERROR:
MAKEFLAGS+=--warn-undefined-variables
MAKEFLAGS+=--no-builtin-rules

NIGHTLY_IMAGE_TAG=nightly

# We like colors
# From: https://coderwall.com/p/izxssa/colored-makefile-for-golang-projects
RED=`tput setaf 1`
GREEN=`tput setaf 2`
RESET=`tput sgr0`
YELLOW=`tput setaf 3`

# Current version
MAIN_IMAGE_NAME=plone/plone-frontend
BASE_IMAGE_NAME=plone/frontend
VOLTO_VERSION=$$(cat version.txt)
IMAGE_TAG=${VOLTO_VERSION}
NIGHTLY_IMAGE_TAG=nightly


.PHONY: all
all: help

# Add the following 'help' target to your Makefile
# And add help text after each target name starting with '\#\#'
.PHONY: help
help: # This help message
	@grep -E '^[a-zA-Z_-]+:.*?# .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?# "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: show-image
show-image: ## Print Version
	@echo "$(MAIN_IMAGE_NAME):$(IMAGE_TAG)"
	@echo "$(MAIN_IMAGE_NAME):$(NIGHTLY_IMAGE_TAG)"
	@echo "$(BASE_IMAGE_NAME)-(builder|dev|prod):$(IMAGE_TAG)"

.PHONY: image-builder
image-builder:  ## Build Base Image
	@echo "Building $(BASE_IMAGE_NAME)-builder:$(IMAGE_TAG)"
	@docker buildx build . --build-arg VOLTO_VERSION=${VOLTO_VERSION} -t $(BASE_IMAGE_NAME)-builder:$(IMAGE_TAG) -f Dockerfile.builder --load

.PHONY: image-dev
image-dev:  ## Build Dev Image
	@echo "Building $(BASE_IMAGE_NAME)-dev:$(IMAGE_TAG)"
	@docker buildx build . --build-arg VOLTO_VERSION=${VOLTO_VERSION} -t $(BASE_IMAGE_NAME)-dev:$(IMAGE_TAG) -f Dockerfile.dev --load

.PHONY: image-prod
image-prod:  ## Build Prod Image
	@echo "Building $(BASE_IMAGE_NAME)-prod:$(IMAGE_TAG)"
	@docker buildx build . --build-arg VOLTO_VERSION=${VOLTO_VERSION} -t $(BASE_IMAGE_NAME)-prod:$(IMAGE_TAG) -f Dockerfile.prod --load

.PHONY: image-main
image-main:  ## Build main image
	@echo "Building $(MAIN_IMAGE_NAME):$(IMAGE_TAG)"
	@docker buildx build . --build-arg VOLTO_VERSION=${VOLTO_VERSION} -t $(MAIN_IMAGE_NAME):$(IMAGE_TAG) -f Dockerfile --load

.PHONY: image-nightly
image-nightly:  ## Build Docker Image Nightly
	@echo "Building $(MAIN_IMAGE_NAME):$(NIGHTLY_IMAGE_TAG)"
	@docker build . -t $(MAIN_IMAGE_NAME):$(NIGHTLY_IMAGE_TAG) -f Dockerfile.nightly

.PHONY: build-images
build-images:  ## Build Images
	@echo "Building $(BASE_IMAGE_NAME)-(builder|dev|prod):$(IMAGE_TAG) images"
	$(MAKE) image-builder
	$(MAKE) image-dev
	$(MAKE) image-prod
	@echo "Building $(MAIN_IMAGE_NAME):$(IMAGE_TAG)"
	$(MAKE) image-main

create-tag: # Create a new tag using git
	@echo "Creating new tag $(VOLTO_VERSION)"
	if git show-ref --tags v$(VOLTO_VERSION) --quiet; then echo "$(VOLTO_VERSION) already exists";else git tag -a v$(VOLTO_VERSION) -m "Release $(VOLTO_VERSION)" && git push && git push --tags;fi

commit-and-release: # Commit new version change and create tag
	@echo "Commiting changes"
	@git commit -am "Use Volto $(VOLTO_VERSION)"
	make create-tag
