GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean

BINARY_NAME=your-app-name

-include config.mk

all: build

build:
	$(GOBUILD) -o $(BINARY_NAME) .

install: build
	@if [ -z "$(BINDIR)" ]; then \
		echo "Configuration file 'config.mk' not found."; \
		echo "Please run ./configure first."; \
		exit 1; \
	fi
	@echo "Installing $(BINARY_NAME) to $(BINDIR)..."
	@mkdir -p $(BINDIR)
	@cp $(BINARY_NAME) $(BINDIR)
	@echo "Installation complete."

clean:
	$(GOCLEAN)
	rm -f $(BINARY_NAME)

run: build
	./$(BINARY_NAME)

uninstall:
	@if [ -z "$(BINDIR)" ]; then \
		echo "Configuration file 'config.mk' not found."; \
		echo "Please run ./configure first to determine installation location."; \
		exit 1; \
	fi
	@echo "Uninstalling $(BINARY_NAME) from $(BINDIR)..."
	rm -f $(BINDIR)/$(BINARY_NAME)
	@echo "Uninstallation complete."

config:
	@if [ -f "config.mk" ]; then \
		cat config.mk; \
	else \
		echo "Configuration file 'config.mk' not found."; \
		echo "Please run ./configure first."; \
	fi
