#!/usr/bin/env python3
"""
TAP to TZX converter for ZX Spectrum tape files.
TZX format is a superset of TAP with additional block types.
"""

import sys
import struct

def tap_to_tzx(tap_path, tzx_path):
    """Convert TAP file to TZX format."""
    
    with open(tap_path, 'rb') as f:
        tap_data = f.read()
    
    # TZX header
    tzx_header = b'ZXTape!\x1a'  # Signature
    tzx_header += bytes([1, 20])  # Version 1.20
    
    tzx_blocks = []
    
    # Parse TAP blocks and convert to TZX blocks
    pos = 0
    while pos < len(tap_data):
        if pos + 2 > len(tap_data):
            break
            
        # TAP block: 2-byte length + data
        block_len = struct.unpack('<H', tap_data[pos:pos+2])[0]
        pos += 2
        
        if pos + block_len > len(tap_data):
            break
            
        block_data = tap_data[pos:pos+block_len]
        pos += block_len
        
        # Convert to TZX block ID 0x10 (Standard Speed Data Block)
        # Format: ID (1) + Pause (2) + Length (2) + Data
        tzx_block = bytes([0x10])  # Block ID
        tzx_block += struct.pack('<H', 1000)  # Pause after block (1000ms)
        tzx_block += struct.pack('<H', block_len)  # Data length
        tzx_block += block_data
        
        tzx_blocks.append(tzx_block)
    
    # Write TZX file
    with open(tzx_path, 'wb') as f:
        f.write(tzx_header)
        for block in tzx_blocks:
            f.write(block)
    
    print(f"Converted {tap_path} to {tzx_path}")
    print(f"  TAP size: {len(tap_data)} bytes")
    print(f"  TZX size: {len(tzx_header) + sum(len(b) for b in tzx_blocks)} bytes")
    print(f"  Blocks: {len(tzx_blocks)}")

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} input.tap output.tzx")
        sys.exit(1)
    
    tap_to_tzx(sys.argv[1], sys.argv[2])
