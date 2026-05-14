
IMAGE_NAME = opencode-sandbox
BIN_DIR = /usr/local/bin
SCRIPT = runner.sh
LINK_NAME = opencode

.PHONY: all build install update clean

all: install

build:
	podman build --no-cache -t $(IMAGE_NAME) -f Containerfile .

install: build
	chmod +x $(SCRIPT)
	mkdir -p state
	sudo ln -sf $(shell pwd)/$(SCRIPT) $(BIN_DIR)/$(LINK_NAME)

update:
	podman build --no-cache -t $(IMAGE_NAME) -f Containerfile .

clean:
	sudo rm -f $(BIN_DIR)/$(LINK_NAME)
	podman rmi $(IMAGE_NAME) || true
