#!/usr/bin/env python3
"""
makescreen.py - Generate ZX Spectrum loading screen (.SCR format)
Creates a simple loading screen with text and basic graphics
"""

import struct
from pathlib import Path


# ZX Spectrum color constants
BLACK = 0
BLUE = 1
RED = 2
MAGENTA = 3
GREEN = 4
CYAN = 5
YELLOW = 6
WHITE = 7

BRIGHT = 0x40
FLASH = 0x80


def make_attr(ink: int, paper: int, bright: bool = False, flash: bool = False) -> int:
    """Create attribute byte from ink, paper, bright, flash"""
    attr = (paper << 3) | ink
    if bright:
        attr |= BRIGHT
    if flash:
        attr |= FLASH
    return attr


class ScreenBuffer:
    """ZX Spectrum screen buffer (256x192 pixels + attributes)"""
    
    def __init__(self):
        self.bitmap = bytearray(6144)
        self.attrs = bytearray(768)
        # Default: white on black
        for i in range(768):
            self.attrs[i] = make_attr(WHITE, BLACK)
    
    def get_pixel_addr(self, x: int, y: int) -> int:
        """Calculate bitmap address for pixel (x, y)"""
        # ZX Spectrum has weird screen layout
        # Address = 0x4000 + ((y & 0xC0) << 5) + ((y & 0x07) << 8) + ((y & 0x38) << 2) + (x >> 3)
        addr = ((y & 0xC0) << 5) | ((y & 0x07) << 8) | ((y & 0x38) << 2) | (x >> 3)
        return addr
    
    def set_pixel(self, x: int, y: int, on: bool = True):
        """Set or clear a single pixel"""
        if x < 0 or x >= 256 or y < 0 or y >= 192:
            return
        addr = self.get_pixel_addr(x, y)
        bit = 7 - (x & 7)
        if on:
            self.bitmap[addr] |= (1 << bit)
        else:
            self.bitmap[addr] &= ~(1 << bit)
    
    def set_attr(self, cx: int, cy: int, attr: int):
        """Set attribute for character cell (cx, cy)"""
        if cx < 0 or cx >= 32 or cy < 0 or cy >= 24:
            return
        self.attrs[cy * 32 + cx] = attr
    
    def draw_char(self, cx: int, cy: int, char_data: bytes, attr: int = None):
        """Draw 8x8 character at character position (cx, cy)"""
        if attr is not None:
            self.set_attr(cx, cy, attr)
        
        px, py = cx * 8, cy * 8
        for row, byte in enumerate(char_data):
            for bit in range(8):
                if byte & (0x80 >> bit):
                    self.set_pixel(px + bit, py + row)
    
    def fill_rect(self, x: int, y: int, w: int, h: int):
        """Fill rectangle with pixels"""
        for py in range(y, y + h):
            for px in range(x, x + w):
                self.set_pixel(px, py)
    
    def draw_box(self, x: int, y: int, w: int, h: int, thickness: int = 1):
        """Draw rectangle outline"""
        # Top
        self.fill_rect(x, y, w, thickness)
        # Bottom
        self.fill_rect(x, y + h - thickness, w, thickness)
        # Left
        self.fill_rect(x, y, thickness, h)
        # Right
        self.fill_rect(x + w - thickness, y, thickness, h)
    
    def set_attr_rect(self, cx: int, cy: int, cw: int, ch: int, attr: int):
        """Set attributes for rectangle of character cells"""
        for y in range(cy, cy + ch):
            for x in range(cx, cx + cw):
                self.set_attr(x, y, attr)
    
    def to_bytes(self) -> bytes:
        """Export as 6912-byte .SCR format"""
        return bytes(self.bitmap) + bytes(self.attrs)
    
    def save(self, filename: str):
        """Save to .SCR file"""
        with open(filename, 'wb') as f:
            f.write(self.to_bytes())
        print(f"Saved {filename} (6912 bytes)")


# Simple 8x8 font for uppercase letters (A-Z, 0-9, some symbols)
FONT = {
    'A': bytes([0x3C, 0x42, 0x42, 0x7E, 0x42, 0x42, 0x42, 0x00]),
    'B': bytes([0x7C, 0x42, 0x7C, 0x42, 0x42, 0x42, 0x7C, 0x00]),
    'C': bytes([0x3C, 0x42, 0x40, 0x40, 0x40, 0x42, 0x3C, 0x00]),
    'D': bytes([0x78, 0x44, 0x42, 0x42, 0x42, 0x44, 0x78, 0x00]),
    'E': bytes([0x7E, 0x40, 0x7C, 0x40, 0x40, 0x40, 0x7E, 0x00]),
    'F': bytes([0x7E, 0x40, 0x7C, 0x40, 0x40, 0x40, 0x40, 0x00]),
    'G': bytes([0x3C, 0x42, 0x40, 0x4E, 0x42, 0x42, 0x3C, 0x00]),
    'H': bytes([0x42, 0x42, 0x7E, 0x42, 0x42, 0x42, 0x42, 0x00]),
    'I': bytes([0x3E, 0x08, 0x08, 0x08, 0x08, 0x08, 0x3E, 0x00]),
    'J': bytes([0x1E, 0x04, 0x04, 0x04, 0x04, 0x44, 0x38, 0x00]),
    'K': bytes([0x42, 0x44, 0x78, 0x48, 0x44, 0x42, 0x42, 0x00]),
    'L': bytes([0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x7E, 0x00]),
    'M': bytes([0x42, 0x66, 0x5A, 0x42, 0x42, 0x42, 0x42, 0x00]),
    'N': bytes([0x42, 0x62, 0x52, 0x4A, 0x46, 0x42, 0x42, 0x00]),
    'O': bytes([0x3C, 0x42, 0x42, 0x42, 0x42, 0x42, 0x3C, 0x00]),
    'P': bytes([0x7C, 0x42, 0x42, 0x7C, 0x40, 0x40, 0x40, 0x00]),
    'Q': bytes([0x3C, 0x42, 0x42, 0x42, 0x4A, 0x44, 0x3A, 0x00]),
    'R': bytes([0x7C, 0x42, 0x42, 0x7C, 0x48, 0x44, 0x42, 0x00]),
    'S': bytes([0x3C, 0x42, 0x40, 0x3C, 0x02, 0x42, 0x3C, 0x00]),
    'T': bytes([0x7F, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x00]),
    'U': bytes([0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x3C, 0x00]),
    'V': bytes([0x42, 0x42, 0x42, 0x42, 0x42, 0x24, 0x18, 0x00]),
    'W': bytes([0x42, 0x42, 0x42, 0x42, 0x5A, 0x66, 0x42, 0x00]),
    'X': bytes([0x42, 0x42, 0x24, 0x18, 0x24, 0x42, 0x42, 0x00]),
    'Y': bytes([0x41, 0x22, 0x14, 0x08, 0x08, 0x08, 0x08, 0x00]),
    'Z': bytes([0x7E, 0x02, 0x04, 0x18, 0x20, 0x40, 0x7E, 0x00]),
    '0': bytes([0x3C, 0x42, 0x46, 0x5A, 0x62, 0x42, 0x3C, 0x00]),
    '1': bytes([0x08, 0x18, 0x08, 0x08, 0x08, 0x08, 0x1C, 0x00]),
    '2': bytes([0x3C, 0x42, 0x02, 0x0C, 0x30, 0x40, 0x7E, 0x00]),
    '3': bytes([0x3C, 0x42, 0x02, 0x1C, 0x02, 0x42, 0x3C, 0x00]),
    '4': bytes([0x04, 0x0C, 0x14, 0x24, 0x7E, 0x04, 0x04, 0x00]),
    '5': bytes([0x7E, 0x40, 0x7C, 0x02, 0x02, 0x42, 0x3C, 0x00]),
    '6': bytes([0x1C, 0x20, 0x40, 0x7C, 0x42, 0x42, 0x3C, 0x00]),
    '7': bytes([0x7E, 0x02, 0x04, 0x08, 0x10, 0x10, 0x10, 0x00]),
    '8': bytes([0x3C, 0x42, 0x42, 0x3C, 0x42, 0x42, 0x3C, 0x00]),
    '9': bytes([0x3C, 0x42, 0x42, 0x3E, 0x02, 0x04, 0x38, 0x00]),
    ' ': bytes([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
    '.': bytes([0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x18, 0x00]),
    ',': bytes([0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x08, 0x10]),
    '!': bytes([0x08, 0x08, 0x08, 0x08, 0x08, 0x00, 0x08, 0x00]),
    '?': bytes([0x3C, 0x42, 0x02, 0x0C, 0x08, 0x00, 0x08, 0x00]),
    '-': bytes([0x00, 0x00, 0x00, 0x7E, 0x00, 0x00, 0x00, 0x00]),
    ':': bytes([0x00, 0x18, 0x18, 0x00, 0x18, 0x18, 0x00, 0x00]),
    '(': bytes([0x04, 0x08, 0x10, 0x10, 0x10, 0x08, 0x04, 0x00]),
    ')': bytes([0x20, 0x10, 0x08, 0x08, 0x08, 0x10, 0x20, 0x00]),
    '/': bytes([0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x00]),
}


def draw_text(scr: ScreenBuffer, cx: int, cy: int, text: str, attr: int = None):
    """Draw text string at character position"""
    for i, char in enumerate(text.upper()):
        if char in FONT:
            scr.draw_char(cx + i, cy, FONT[char], attr)


def create_zxsnake_loading_screen() -> ScreenBuffer:
    """Create the zxSnake loading screen"""
    scr = ScreenBuffer()
    
    # Fill background black
    scr.set_attr_rect(0, 0, 32, 24, make_attr(WHITE, BLACK))
    
    # Draw border frame
    scr.draw_box(0, 0, 256, 192, 2)
    scr.set_attr_rect(0, 0, 32, 1, make_attr(GREEN, BLACK, bright=True))
    scr.set_attr_rect(0, 23, 32, 1, make_attr(GREEN, BLACK, bright=True))
    for y in range(24):
        scr.set_attr(0, y, make_attr(GREEN, BLACK, bright=True))
        scr.set_attr(31, y, make_attr(GREEN, BLACK, bright=True))
    
    # Draw "zxSnake" title - large blocky letters
    # Position: centered around row 3-6
    title_y = 3
    
    # "zxSnake" in big block letters (2x2 chars each)
    title_attr = make_attr(GREEN, BLACK, bright=True)
    
    # Draw title "ZXSNAKE" 
    draw_text(scr, 12, title_y, "ZXSNAKE", title_attr)
    
    # Draw larger version below
    large_title_y = 5
    # Draw decorative lines
    for x in range(8, 24):
        scr.set_pixel(x * 8 + 3, large_title_y * 8 - 2, True)
        scr.set_pixel(x * 8 + 4, large_title_y * 8 - 2, True)
    
    # Draw a snake graphic in the middle
    snake_y = 10
    snake_attr = make_attr(GREEN, BLACK, bright=True)
    
    # Snake body - S-shape
    snake_pattern = [
        "    ################    ",
        "   ##              ##   ",
        "  ##                ##  ",
        " ##        ####      ## ",
        " #        ##  ##      # ",
        " #       ##    ##     # ",
        " #       #      #     # ",
        " ##     ##      ##   ## ",
        "  ##   ##        ## ##  ",
        "   ## ##          ###   ",
        "    ###            #    ",
    ]
    
    for row, pattern in enumerate(snake_pattern):
        for col, char in enumerate(pattern):
            if char == '#':
                px = 4 * 8 + col * 2
                py = snake_y * 8 + row * 2
                scr.set_pixel(px, py)
                scr.set_pixel(px + 1, py)
                scr.set_pixel(px, py + 1)
                scr.set_pixel(px + 1, py + 1)
    
    # Set snake area attributes
    scr.set_attr_rect(4, snake_y, 24, 6, snake_attr)
    
    # Draw apple (red)
    apple_cx, apple_cy = 22, 12
    apple_attr = make_attr(RED, BLACK, bright=True)
    apple = bytes([0x18, 0x24, 0x7E, 0xFF, 0xFF, 0x7E, 0x3C, 0x18])
    scr.draw_char(apple_cx, apple_cy, apple, apple_attr)
    
    # Draw snake head with eyes
    head_cx, head_cy = 6, 11
    head_attr = make_attr(GREEN, BLACK, bright=True)
    head = bytes([0x3C, 0x7E, 0xDB, 0xFF, 0xFF, 0xBD, 0x7E, 0x3C])
    scr.draw_char(head_cx, head_cy, head, head_attr)
    
    # "LOADING..." text
    loading_attr = make_attr(YELLOW, BLACK, bright=True)
    draw_text(scr, 11, 18, "LOADING...", loading_attr)
    
    # Controls hint
    hint_attr = make_attr(CYAN, BLACK)
    draw_text(scr, 6, 20, "QAOP WASD KEMPSTON", hint_attr)
    
    # Copyright
    copy_attr = make_attr(WHITE, BLACK)
    draw_text(scr, 10, 22, "(C) 2026", copy_attr)
    
    return scr


def main():
    import sys
    
    output = sys.argv[1] if len(sys.argv) > 1 else "gfx/loading.scr"
    
    print("Creating zxSnake loading screen...")
    scr = create_zxsnake_loading_screen()
    scr.save(output)
    print("Done!")


if __name__ == '__main__':
    main()
