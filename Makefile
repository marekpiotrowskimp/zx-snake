# Makefile for zxSnake - ZX Spectrum game
# Requirements: pasmo (Z80 assembler), python3

PASMO ?= pasmo
PYTHON = python3
BIN2TAP = tools/bin2tap.py
TAP2TZX = tools/tap2tzx.py
MAKESCREEN = tools/makescreen.py

SRC_DIR = src
BUILD_DIR = build
GFX_DIR = gfx

# Output files
TARGET = $(BUILD_DIR)/zxsnake.tap
BIN = $(BUILD_DIR)/zxsnake.bin
SCR = $(GFX_DIR)/loading.scr
RELEASE_TAP = release/zxsnake_v1.0.tap
RELEASE_TZX = release/zxsnake_v1.0.tzx

# Source files
MAIN_SRC = $(SRC_DIR)/main.asm
SRCS = $(wildcard $(SRC_DIR)/*.asm) $(wildcard $(SRC_DIR)/data/*.asm)

# Game parameters
START_ADDR = 32768
GAME_NAME = zxsnake
MAX_CODE_SIZE = 49152

.PHONY: all clean run screen test release check-size help

all: $(TARGET)

# Create loading screen
$(SCR): $(MAKESCREEN)
	@echo "Creating loading screen..."
	$(PYTHON) $(MAKESCREEN) $(SCR)

# Compile Z80 assembly to binary
$(BIN): $(SRCS)
	@echo "Assembling Z80 code..."
	@mkdir -p $(BUILD_DIR)
	$(PASMO) --bin $(MAIN_SRC) $(BIN)
	@echo "Binary size: $$(wc -c < $(BIN)) bytes"

# Create TAP file with loader and screen
$(TARGET): $(BIN) $(SCR) $(BIN2TAP)
	@echo "Creating TAP file..."
	$(PYTHON) $(BIN2TAP) $(BIN) $(TARGET) $(START_ADDR) $(GAME_NAME) $(SCR)

# Just create the screen
screen: $(SCR)

# Compile without screen (faster testing)
test: $(BIN)
	@echo "Creating test TAP (no loading screen)..."
	$(PYTHON) $(BIN2TAP) $(BIN) $(BUILD_DIR)/test.tap $(START_ADDR) $(GAME_NAME)

check-size: $(BIN)
	@size=$$(wc -c < $(BIN)); \
	if [ $$size -gt $(MAX_CODE_SIZE) ]; then \
		echo "Binary too large: $$size bytes (limit: $(MAX_CODE_SIZE))"; \
		exit 1; \
	fi; \
	echo "Binary size OK: $$size bytes / $(MAX_CODE_SIZE) bytes"

release: $(TARGET) check-size $(TAP2TZX)
	@echo "Creating release artifacts..."
	@mkdir -p release
	cp $(TARGET) $(RELEASE_TAP)
	$(PYTHON) $(TAP2TZX) $(RELEASE_TAP) $(RELEASE_TZX)

# Run in FUSE emulator (macOS)
run: $(TARGET)
	@echo "Launching FUSE emulator..."
	@if command -v fuse >/dev/null 2>&1; then \
		fuse $(TARGET); \
	elif [ -d "/Applications/Fuse.app" ]; then \
		open -a Fuse $(TARGET); \
	else \
		echo "FUSE not found. Please install FUSE emulator or open $(TARGET) manually."; \
	fi

clean:
	rm -f $(BUILD_DIR)/*.bin $(BUILD_DIR)/*.tap
	rm -f $(GFX_DIR)/*.scr

# Show help
help:
	@echo "zxSnake Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  all     - Build complete TAP with loading screen (default)"
	@echo "  test    - Build TAP without loading screen (faster)"
	@echo "  release - Build TAP and TZX release artifacts"
	@echo "  check-size - Verify binary fits ZX Spectrum 48K code budget"
	@echo "  screen  - Generate loading screen only"
	@echo "  run     - Build and run in FUSE emulator"
	@echo "  clean   - Remove build artifacts"
	@echo "  help    - Show this help"
	@echo ""
	@echo "Files:"
	@echo "  $(TARGET) - Final TAP file"
	@echo "  $(BIN) - Raw Z80 binary"
	@echo "  $(SCR) - Loading screen"
