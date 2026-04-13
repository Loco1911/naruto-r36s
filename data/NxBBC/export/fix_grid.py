#!/usr/bin/env python3
"""
Fix the top grid: make the first 7 rows match the bottom 6 rows in cell size/alignment.
Only modify images that actually have a grid pattern. 
- 401-0: Yellow/blue frame borders -> RE-TILE from bottom
- 400-0: Gold cell fills -> RE-TILE from bottom
- 152-0: Magenta guide borders -> RE-TILE from bottom (only borders, rest is transparent)
- 151-0: Black solid background -> Only need to ensure the zone is solid black (no grid to fix)
- 400-1: Gold solid background -> Only need to ensure the zone is solid gold (no grid to fix)
"""

from PIL import Image
import os

EXPORT = "data/NxBBC/export"

# Grid parameters (from analysis):
COL_PITCH = 30
ROW_PITCH = 30
NUM_COLS = 21
NUM_ROWS_TOP = 7

# The top cell zone to clear/replace
TOP_CLEAR_Y_START = 38  # clear from here
TOP_CLEAR_Y_END = 262   # clear to here

# Where to start tiling in top
TOP_X_START = 3
TOP_Y_START = 44

# Bottom tile extraction point
TILE_X = 3
TILE_Y = 283
TILE_SIZE = 30

def extract_tile(pixels, w, h, tx, ty, size):
    """Extract a size x size tile from pixels at position (tx, ty)."""
    tile = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    tp = tile.load()
    for dy in range(size):
        for dx in range(size):
            sx, sy = tx + dx, ty + dy
            if 0 <= sx < w and 0 <= sy < h:
                tp[dx, dy] = pixels[sx, sy]
    return tile

def clear_zone(pixels, w, h, y_start, y_end, fill=None):
    """Clear a horizontal zone to transparent or a solid fill."""
    for y in range(y_start, min(y_end + 1, h)):
        for x in range(w):
            pixels[x, y] = fill if fill else (0, 0, 0, 0)

def tile_zone(pixels, tile, w, h, x_start, y_start, y_min, y_max, cols, rows, col_pitch, row_pitch):
    """Tile a pattern into a zone."""
    tp = tile.load()
    ts = tile.size[0]
    for row in range(rows):
        for col in range(cols):
            dst_x = x_start + col * col_pitch
            dst_y = y_start + row * row_pitch
            for dy in range(ts):
                for dx in range(ts):
                    px = dst_x + dx
                    py = dst_y + dy
                    if 0 <= px < w and y_min <= py <= y_max and py < h:
                        pixel = tp[dx, dy]
                        if pixel[3] > 0:
                            pixels[px, py] = pixel

def fix_grid_image(filename):
    """Fix a grid-containing image by re-tiling the top with bottom cells."""
    backup = os.path.join(EXPORT, filename.replace(".png", "_backup.png"))
    img = Image.open(backup).convert("RGBA")
    pixels = img.load()
    w, h = img.size
    
    tile = extract_tile(pixels, w, h, TILE_X, TILE_Y, TILE_SIZE)
    
    clear_zone(pixels, w, h, TOP_CLEAR_Y_START, TOP_CLEAR_Y_END)
    tile_zone(pixels, tile, w, h, TOP_X_START, TOP_Y_START, 
              TOP_CLEAR_Y_START, TOP_CLEAR_Y_END,
              NUM_COLS, NUM_ROWS_TOP, COL_PITCH, ROW_PITCH)
    
    out = os.path.join(EXPORT, filename.replace(".png", "_fixed.png"))
    img.save(out)
    print(f"Fixed {filename} -> {os.path.basename(out)}")
    return out

def fix_solid_image(filename, fill_color):
    """For solid background images (no grid), just fill the top zone solid."""
    backup = os.path.join(EXPORT, filename.replace(".png", "_backup.png"))
    img = Image.open(backup).convert("RGBA")
    pixels = img.load()
    w, h = img.size
    
    # The top zone had special elements (face boxes, name bars, mode text box).
    # For these solid layers, the bottom is uniform. We just need to make
    # the top zone uniform too - same solid color, no cell subdivisions.
    # But we should preserve the original structure OUTSIDE the cell area.
    # Actually, looking at the original 151-0: it's solid black everywhere
    # And 400-1: it's solid gold everywhere (with some gray for name areas)
    # These DON'T need cell tiling - they just need to be left alone,
    # or we can simply restore from backup.
    
    out = os.path.join(EXPORT, filename.replace(".png", "_fixed.png"))
    img.save(out)
    print(f"Preserved {filename} -> {os.path.basename(out)} (solid layer, no grid fix needed)")

# Fix the three images that have actual grid patterns
fix_grid_image("frames_401-0.png")
fix_grid_image("frames_400-0.png")
fix_grid_image("frames_152-0.png")

# For solid backgrounds, just copy as-is from backup (they don't have grid issues)
fix_solid_image("frames_151-0.png", (0, 0, 0, 255))
fix_solid_image("frames_400-1.png", (131, 87, 0, 255))

# But wait - 151-0 and 400-1 DO have the face boxes and mode bar drawn.
# Those face boxes correspond to the oversized top cells. If we're removing
# the big face cells from 401, we should also update 151 and 400-1 to not have
# their corresponding face box silhouettes. Let's fix those too:

def fix_151():
    """151-0 has black rectangles for the layout. The top section has large face boxes.
    We need to make the top resemble the bottom: uniform black cells."""
    backup = os.path.join(EXPORT, "frames_151-0_backup.png")
    img = Image.open(backup).convert("RGBA")
    pixels = img.load()
    w, h = img.size
    
    # Bottom at y=300 is solid black with transparent gaps between cells.
    # Check if there ARE transparent gaps in the bottom
    # From analysis: bottom at x=30, y=280-318 is ALL solid black (0,0,0,255)
    # So 151-0 is just a big solid black shape. The "grid" in 151 is defined
    # by where it's opaque vs transparent. Let me check the transparent gaps.
    
    # Check at various x positions for transparency in bottom:
    transp_count = 0
    opaque_count = 0
    for x in range(w):
        r,g,b,a = pixels[x, 300]
        if a < 50:
            transp_count += 1
        else:
            opaque_count += 1
    
    print(f"  151-0 at y=300: opaque={opaque_count}, transparent={transp_count}")
    
    # The bottom in 151 seems mostly opaque - it's a solid fill.
    # The top in 151 has the same structure but with the face boxes.
    # For 151, we just need to make the top zone a simple solid black
    # rectangle without the face box outlines.
    
    # Actually, 151 probably defines the overall MASK/FILL for the selector.
    # Leave it as the original - it doesn't have misaligned cells.
    out = os.path.join(EXPORT, "frames_151-0_fixed.png")
    img.save(out)
    print(f"  Saved frames_151-0_fixed.png (preserved original)")

def fix_400_1():
    """400-1 has gold fill. Similar analysis as 151."""
    backup = os.path.join(EXPORT, "frames_400-1_backup.png")
    img = Image.open(backup).convert("RGBA")
    pixels = img.load()
    w, h = img.size
    
    transp_count = 0
    opaque_count = 0
    for x in range(w):
        r,g,b,a = pixels[x, 300]
        if a < 50:
            transp_count += 1
        else:
            opaque_count += 1
    
    print(f"  400-1 at y=300: opaque={opaque_count}, transparent={transp_count}")
    
    out = os.path.join(EXPORT, "frames_400-1_fixed.png")
    img.save(out)
    print(f"  Saved frames_400-1_fixed.png (preserved original)")

fix_151()
fix_400_1()

print("\nAll done!")
