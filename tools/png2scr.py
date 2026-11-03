#!/usr/bin/env python3
"""
png2scr.py - Convert PNG image to ZX Spectrum .SCR format
Supports Floyd-Steinberg dithering for better color approximation

ZX Spectrum screen format:
- 256x192 pixels
- 32x24 attribute cells (8x8 pixels each)
- Each cell can have only 2 colors (INK + PAPER) from 8-color palette
- BRIGHT flag doubles to 15 colors (but both colors in cell share BRIGHT)
- Total: 6144 bytes bitmap + 768 bytes attributes = 6912 bytes
"""

import sys
from pathlib import Path

try:
    from PIL import Image
    import numpy as np
except ImportError:
    print("Error: This script requires PIL and numpy")
    print("Install with: pip3 install Pillow numpy")
    sys.exit(1)


# ZX Spectrum color palette (RGB values)
# Normal colors (BRIGHT=0)
ZX_PALETTE_NORMAL = [
    (0, 0, 0),       # 0 BLACK
    (0, 0, 205),     # 1 BLUE
    (205, 0, 0),     # 2 RED
    (205, 0, 205),   # 3 MAGENTA
    (0, 205, 0),     # 4 GREEN
    (0, 205, 205),   # 5 CYAN
    (205, 205, 0),   # 6 YELLOW
    (205, 205, 205), # 7 WHITE
]

# Bright colors (BRIGHT=1)
ZX_PALETTE_BRIGHT = [
    (0, 0, 0),       # 0 BLACK (same)
    (0, 0, 255),     # 1 BLUE
    (255, 0, 0),     # 2 RED
    (255, 0, 255),   # 3 MAGENTA
    (0, 255, 0),     # 4 GREEN
    (0, 255, 255),   # 5 CYAN
    (255, 255, 0),   # 6 YELLOW
    (255, 255, 255), # 7 WHITE
]


def color_distance(c1, c2):
    """Calculate squared Euclidean distance between two RGB colors"""
    return sum((a - b) ** 2 for a, b in zip(c1, c2))


def find_nearest_zx_color(rgb, palette):
    """Find the nearest ZX Spectrum color index for given RGB"""
    min_dist = float('inf')
    best_idx = 0
    for idx, zx_color in enumerate(palette):
        dist = color_distance(rgb, zx_color)
        if dist < min_dist:
            min_dist = dist
            best_idx = idx
    return best_idx, min_dist


def find_best_pair_for_cell(cell_pixels, use_dithering=True):
    """
    Find the best INK/PAPER pair for an 8x8 cell.
    Returns (ink, paper, bright, pixel_matrix)
    pixel_matrix is 8x8 array of 0 (paper) or 1 (ink)
    """
    # Flatten pixels
    pixels = cell_pixels.reshape(-1, 3)
    
    best_error = float('inf')
    best_result = None
    
    # Try both normal and bright palettes
    for bright, palette in [(0, ZX_PALETTE_NORMAL), (1, ZX_PALETTE_BRIGHT)]:
        # Find the two most common colors in the cell
        # Map each pixel to nearest palette color
        color_counts = {}
        for px in pixels:
            idx, _ = find_nearest_zx_color(tuple(px), palette)
            color_counts[idx] = color_counts.get(idx, 0) + 1
        
        # Get top 2 colors
        sorted_colors = sorted(color_counts.items(), key=lambda x: -x[1])
        if len(sorted_colors) >= 2:
            c1, c2 = sorted_colors[0][0], sorted_colors[1][0]
        elif len(sorted_colors) == 1:
            c1 = c2 = sorted_colors[0][0]
        else:
            c1 = c2 = 0  # Black
        
        # Paper = brighter/lighter color, Ink = darker
        # Or: paper = more common, ink = less common
        paper, ink = (c1, c2) if c1 > c2 else (c2, c1)
        if paper == ink:
            ink = 0 if paper != 0 else 7
        
        # Apply dithering and calculate error
        if use_dithering:
            pixel_matrix, error = apply_dithering(cell_pixels.copy(), ink, paper, palette)
        else:
            pixel_matrix, error = simple_threshold(cell_pixels, ink, paper, palette)
        
        if error < best_error:
            best_error = error
            best_result = (ink, paper, bright, pixel_matrix)
    
    return best_result


def apply_dithering(cell_pixels, ink, paper, palette):
    """Apply Floyd-Steinberg dithering to 8x8 cell"""
    ink_color = np.array(palette[ink], dtype=np.float32)
    paper_color = np.array(palette[paper], dtype=np.float32)
    
    # Work with float for error diffusion
    pixels = cell_pixels.astype(np.float32)
    result = np.zeros((8, 8), dtype=np.uint8)
    total_error = 0
    
    for y in range(8):
        for x in range(8):
            old_pixel = pixels[y, x].copy()
            
            # Choose ink or paper based on distance
            dist_ink = color_distance(tuple(old_pixel), tuple(ink_color))
            dist_paper = color_distance(tuple(old_pixel), tuple(paper_color))
            
            if dist_ink < dist_paper:
                result[y, x] = 1  # Ink
                new_pixel = ink_color
            else:
                result[y, x] = 0  # Paper
                new_pixel = paper_color
            
            # Calculate quantization error
            quant_error = old_pixel - new_pixel
            total_error += np.sum(quant_error ** 2)
            
            # Distribute error to neighbors (Floyd-Steinberg)
            if x + 1 < 8:
                pixels[y, x + 1] += quant_error * 7 / 16
            if y + 1 < 8:
                if x > 0:
                    pixels[y + 1, x - 1] += quant_error * 3 / 16
                pixels[y + 1, x] += quant_error * 5 / 16
                if x + 1 < 8:
                    pixels[y + 1, x + 1] += quant_error * 1 / 16
    
    return result, total_error


def simple_threshold(cell_pixels, ink, paper, palette):
    """Simple nearest-color matching without dithering"""
    ink_color = palette[ink]
    paper_color = palette[paper]
    
    result = np.zeros((8, 8), dtype=np.uint8)
    total_error = 0
    
    for y in range(8):
        for x in range(8):
            px = tuple(cell_pixels[y, x])
            dist_ink = color_distance(px, ink_color)
            dist_paper = color_distance(px, paper_color)
            
            if dist_ink < dist_paper:
                result[y, x] = 1
                total_error += dist_ink
            else:
                result[y, x] = 0
                total_error += dist_paper
    
    return result, total_error


def get_scr_bitmap_address(x, y):
    """
    Calculate the byte offset in SCR bitmap for pixel (x, y)
    ZX Spectrum has a weird screen layout!
    """
    # Byte position within the row
    byte_x = x // 8
    
    # The screen is divided into 3 bands of 64 pixel rows each
    # Within each band, rows are interleaved
    band = y // 64
    row_in_band = y % 64
    char_row = row_in_band // 8
    pixel_row = row_in_band % 8
    
    # Address calculation
    addr = (band * 2048) + (pixel_row * 256) + (char_row * 32) + byte_x
    return addr


def pixels_to_bitmap(all_pixels):
    """
    Convert 256x192 array of pixel_matrix (0/1) to ZX bitmap format (6144 bytes)
    all_pixels[cy][cx] = 8x8 matrix of 0/1
    """
    bitmap = bytearray(6144)
    
    for cy in range(24):  # Character rows
        for cx in range(32):  # Character columns
            pixel_matrix = all_pixels[cy][cx]
            
            for row in range(8):
                # Pack 8 pixels into one byte
                byte_val = 0
                for bit in range(8):
                    if pixel_matrix[row, bit]:
                        byte_val |= (0x80 >> bit)
                
                # Calculate screen address
                pixel_y = cy * 8 + row
                pixel_x = cx * 8
                addr = get_scr_bitmap_address(pixel_x, pixel_y)
                bitmap[addr] = byte_val
    
    return bitmap


def make_attribute(ink, paper, bright=0, flash=0):
    """Create ZX attribute byte"""
    return (flash << 7) | (bright << 6) | (paper << 3) | ink


def convert_png_to_scr(input_path, output_path, use_dithering=True):
    """Main conversion function"""
    print(f"Loading {input_path}...")
    
    # Load and prepare image
    img = Image.open(input_path)
    
    # Resize if needed
    if img.size != (256, 192):
        print(f"Resizing from {img.size} to 256x192...")
        img = img.resize((256, 192), Image.Resampling.LANCZOS)
    
    # Convert to RGB
    img = img.convert('RGB')
    pixels = np.array(img)
    
    print(f"Converting with {'dithering' if use_dithering else 'simple threshold'}...")
    
    # Process each 8x8 cell
    all_pixels = [[None for _ in range(32)] for _ in range(24)]
    attributes = bytearray(768)
    
    for cy in range(24):
        for cx in range(32):
            # Extract 8x8 cell
            y1, y2 = cy * 8, (cy + 1) * 8
            x1, x2 = cx * 8, (cx + 1) * 8
            cell = pixels[y1:y2, x1:x2]
            
            # Find best colors and convert
            ink, paper, bright, pixel_matrix = find_best_pair_for_cell(cell, use_dithering)
            
            all_pixels[cy][cx] = pixel_matrix
            attributes[cy * 32 + cx] = make_attribute(ink, paper, bright)
    
    # Convert to bitmap
    print("Generating bitmap...")
    bitmap = pixels_to_bitmap(all_pixels)
    
    # Combine bitmap + attributes
    scr_data = bytes(bitmap) + bytes(attributes)
    
    # Save
    print(f"Saving {output_path} ({len(scr_data)} bytes)...")
    with open(output_path, 'wb') as f:
        f.write(scr_data)
    
    print("Done!")
    return True


def main():
    if len(sys.argv) < 3:
        print("Usage: png2scr.py <input.png> <output.scr> [--no-dither]")
        print("")
        print("Converts a 256x192 PNG image to ZX Spectrum .SCR format")
        print("Uses Floyd-Steinberg dithering by default for better quality")
        print("")
        print("Options:")
        print("  --no-dither  Disable dithering (faster, but lower quality)")
        sys.exit(1)
    
    input_path = sys.argv[1]
    output_path = sys.argv[2]
    use_dithering = "--no-dither" not in sys.argv
    
    if not Path(input_path).exists():
        print(f"Error: Input file not found: {input_path}")
        sys.exit(1)
    
    convert_png_to_scr(input_path, output_path, use_dithering)


if __name__ == '__main__':
    main()
