#!/usr/bin/env python3
"""
PNG to ZX Spectrum sprite converter with dithering support.
Converts 16x16 PNG images to assembly DB statements.

Color handling:
- Green (0,255,0): Full pixel ON - main body
- Black (0,0,0): Dithering pattern A - eyes/details (darker)
- Red (255,0,0): Full pixel ON - tongue/tips  
- Yellow (255,255,0): Dithering pattern B - belly/highlights (lighter)
- Transparent: Pixel OFF
"""

from PIL import Image
import sys
import os

# Define known colors and their handling
COLOR_GREEN = (0, 255, 0)      # Main body - solid
COLOR_BLACK = (0, 0, 0)        # Eyes - dither (creates holes)
COLOR_RED = (255, 0, 0)        # Tongue/tips - solid
COLOR_YELLOW = (255, 255, 0)   # Belly - dither inverted

def get_pixel_value(r, g, b, a, x, y, dither_mode=True):
    """
    Determine if pixel should be ON (1) or OFF (0).
    
    Args:
        r, g, b, a: Pixel color components
        x, y: Pixel position (for dithering pattern)
        dither_mode: If True, apply dithering to special colors
    
    Returns:
        1 if pixel should be ON, 0 if OFF
    """
    if a == 0:
        return 0  # Transparent = OFF
    
    color = (r, g, b)
    
    if not dither_mode:
        # Simple mode - any non-transparent pixel is ON
        return 1
    
    # Dithering pattern: checkerboard
    checker = (x + y) % 2
    
    if color == COLOR_GREEN:
        return 1  # Solid green
    elif color == COLOR_RED:
        return 1  # Solid red (tongue)
    elif color == COLOR_BLACK:
        # Eyes: dither pattern - creates "holes" effect
        # checker=0 means OFF (hole), checker=1 means ON
        return checker
    elif color == COLOR_YELLOW:
        # Belly: inverted dither - lighter effect  
        # checker=0 means ON, checker=1 means OFF
        return 1 - checker
    else:
        # Unknown color - treat as solid
        # Check brightness to decide
        brightness = r + g + b
        if brightness > 380:  # Bright colors = solid
            return 1
        elif brightness < 100:  # Dark colors = dither like eyes
            return checker
        else:
            return 1  # Medium = solid


def png_to_sprite(png_path, sprite_name=None, dither_mode=True):
    """Convert a 16x16 PNG to ZX Spectrum sprite data."""
    img = Image.open(png_path).convert('RGBA')
    
    if img.size != (16, 16):
        print(f"Warning: Image is {img.size}, expected 16x16. Resizing...")
        img = img.resize((16, 16), Image.NEAREST)
    
    if sprite_name is None:
        # Extract name from filename
        basename = os.path.basename(png_path)
        sprite_name = basename.replace('.png', '').replace('zxSnake_', 'spr_').replace('_16x16', '')
    
    lines = []
    lines.append(f"; {sprite_name}")
    lines.append(f"{sprite_name}:")
    
    for y in range(16):
        byte1 = 0
        byte2 = 0
        
        # First 8 pixels -> byte1
        for x in range(8):
            r, g, b, a = img.getpixel((x, y))
            if get_pixel_value(r, g, b, a, x, y, dither_mode):
                byte1 |= (0x80 >> x)
        
        # Next 8 pixels -> byte2
        for x in range(8, 16):
            r, g, b, a = img.getpixel((x, y))
            if get_pixel_value(r, g, b, a, x, y, dither_mode):
                byte2 |= (0x80 >> (x - 8))
        
        # Create visual comment
        row_visual = ""
        for x in range(16):
            r, g, b, a = img.getpixel((x, y))
            if get_pixel_value(r, g, b, a, x, y, dither_mode):
                row_visual += "#"
            else:
                row_visual += "."
        
        lines.append(f"        DB ${byte1:02X}, ${byte2:02X}     ; {row_visual}")
    
    lines.append("")
    return "\n".join(lines)


def convert_all_sprites(directory, dither_mode=True):
    """Convert all snake sprite PNGs in directory."""
    sprite_files = [
        ("zxSnake_head_up_16x16.png", "spr_head_up"),
        ("zxSnake_head_down_16x16.png", "spr_head_down"),
        ("zxSnake_head_left_16x16.png", "spr_head_left"),
        ("zxSnake_head_right_16x16.png", "spr_head_right"),
        ("zxSnake_body_h_16x16.png", "spr_body_h"),
        ("zxSnake_body_v_16x16.png", "spr_body_v"),
        ("zxSnake_tail_up_16x16.png", "spr_tail_up"),
        ("zxSnake_tail_down_16x16.png", "spr_tail_down"),
        ("zxSnake_tail_left_16x16.png", "spr_tail_left"),
        ("zxSnake_tail_right_16x16.png", "spr_tail_right"),
    ]
    
    all_output = []
    all_output.append(";; ============================================")
    all_output.append(";; zxSnake - Sprite Data (16x16 pixels each)")
    all_output.append(";; Auto-generated from PNG files")
    all_output.append(";; Each sprite = 32 bytes (16 rows x 2 bytes)")
    if dither_mode:
        all_output.append(";; Dithering enabled for eyes/details")
    all_output.append(";; ============================================")
    all_output.append("")
    
    for filename, sprite_name in sprite_files:
        filepath = os.path.join(directory, filename)
        if os.path.exists(filepath):
            print(f"Converting {filename} -> {sprite_name}", file=sys.stderr)
            all_output.append(png_to_sprite(filepath, sprite_name, dither_mode))
        else:
            print(f"Warning: {filename} not found", file=sys.stderr)
    
    return "\n".join(all_output)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: png2sprite.py <png_file> [sprite_name] [--no-dither]")
        print("   or: png2sprite.py --all <directory> [--no-dither]")
        print("")
        print("Options:")
        print("  --no-dither  Disable dithering (all non-transparent pixels = ON)")
        print("")
        print("Color handling with dithering:")
        print("  Green (0,255,0)   -> Solid ON (body)")
        print("  Black (0,0,0)     -> Dithered (eyes - darker)")
        print("  Red (255,0,0)     -> Solid ON (tongue)")
        print("  Yellow (255,255,0)-> Dithered inverted (belly - lighter)")
        sys.exit(1)
    
    dither_mode = "--no-dither" not in sys.argv
    args = [a for a in sys.argv[1:] if a != "--no-dither"]
    
    if args[0] == "--all":
        directory = args[1] if len(args) > 1 else "."
        output = convert_all_sprites(directory, dither_mode)
        print(output)
    else:
        png_path = args[0]
        sprite_name = args[1] if len(args) > 1 else None
        output = png_to_sprite(png_path, sprite_name, dither_mode)
        print(output)
