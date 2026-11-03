PASMO = ../tools/bin/pasmo
PYTHON = python3
PNG2SCR = ../tools/png2scr.py
BIN2TAP = ../tools/bin2tap.py
TAP2TZX = ../tools/tap2tzx.py
MAKE_QR = tools/make_qr_scr.py

SRC = src/demo.asm
BUILD_DIR = build
GFX_DIR = gfx
SPLASH_PNG = ../zxSnake_loading_256x192.png
SPLASH_SCR = $(GFX_DIR)/splash.scr
QR_SCR = $(GFX_DIR)/linkedin_qr.scr
LINKEDIN_URL = https://www.linkedin.com/in/marek-piotrowski-7b5b388a/?locale=en
BIN = $(BUILD_DIR)/zxsnake_demo.bin
TAP = $(BUILD_DIR)/zxsnake_demo.tap
TZX = $(BUILD_DIR)/zxsnake_demo.tzx
START_ADDR = 32768
NAME = zxsndemo

.PHONY: all tzx run clean

all: $(TAP) $(TZX)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(GFX_DIR):
	mkdir -p $(GFX_DIR)

$(SPLASH_SCR): $(SPLASH_PNG) | $(GFX_DIR)
	$(PYTHON) $(PNG2SCR) $(SPLASH_PNG) $(SPLASH_SCR)

$(QR_SCR): $(MAKE_QR) | $(GFX_DIR)
	$(PYTHON) $(MAKE_QR) "$(LINKEDIN_URL)" $(QR_SCR)

$(BIN): $(SRC) $(SPLASH_SCR) $(QR_SCR) ../src/font.asm | $(BUILD_DIR)
	$(PASMO) --bin $(SRC) $(BIN)
	@echo "Demo binary size: $$(wc -c < $(BIN)) bytes"

$(TAP): $(BIN) $(SPLASH_SCR)
	$(PYTHON) $(BIN2TAP) $(BIN) $(TAP) $(START_ADDR) $(NAME) $(SPLASH_SCR)

tzx: $(TZX)

$(TZX): $(TAP)
	$(PYTHON) $(TAP2TZX) $(TAP) $(TZX)

run: $(TAP)
	@if command -v fuse >/dev/null 2>&1; then \
		fuse $(TAP); \
	elif [ -d "/Applications/Fuse.app" ]; then \
		open -a Fuse $(TAP); \
	else \
		echo "FUSE not found. Open $(TAP) manually."; \
	fi

clean:
	rm -f $(BUILD_DIR)/*.bin $(BUILD_DIR)/*.tap $(BUILD_DIR)/*.tzx $(GFX_DIR)/*.scr
