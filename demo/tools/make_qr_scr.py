#!/usr/bin/env python3
import sys

import cv2
import numpy as np


def scr_addr(x, y):
    return ((y & 0xC0) << 5) | ((y & 0x07) << 8) | ((y & 0x38) << 2) | (x >> 3)


def make_qr(url):
    params = cv2.QRCodeEncoder_Params()
    params.correction_level = cv2.QRCodeEncoder_CORRECT_LEVEL_M
    params.mode = cv2.QRCodeEncoder_MODE_BYTE
    encoder = cv2.QRCodeEncoder_create(params)
    qr = encoder.encode(url)
    return qr < 128


def write_scr(qr, path):
    modules = qr.shape[0]
    quiet = 4
    scale = min(256 // (modules + quiet * 2), 192 // (modules + quiet * 2))
    full = (modules + quiet * 2) * scale
    ox = (256 - full) // 2
    oy = (192 - full) // 2

    bitmap = bytearray(6144)
    attrs = bytearray([0x78] * 768)  # BRIGHT, PAPER white, INK black

    for y in range(192):
        for x in range(256):
            mx = (x - ox) // scale - quiet
            my = (y - oy) // scale - quiet
            if 0 <= mx < modules and 0 <= my < modules and qr[my, mx]:
                bitmap[scr_addr(x, y)] |= 0x80 >> (x & 7)

    with open(path, "wb") as f:
        f.write(bitmap + attrs)


def main():
    if len(sys.argv) != 3:
        print("Usage: make_qr_scr.py <url> <output.scr>")
        sys.exit(1)
    write_scr(make_qr(sys.argv[1]), sys.argv[2])


if __name__ == "__main__":
    main()
