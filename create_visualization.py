from PIL import Image, ImageDraw
import re

# Read your file
with open("write_mem.txt", "r") as f:
    data = f.read()

# Split into frames
frames = re.split(r"---- REPLACE triggered.*?----", data)
frames = [f.strip() for f in frames if "Row" in f]

images = []

SCALE = 16  # Scale factor (larger = bigger pixels)
MARGIN = 1  # Add 1-pixel border around the 8x8 area

for f in frames:
    rows = []
    for line in f.splitlines():
        if line.startswith("Row"):
            hexdata = line.split(":")[1].strip()
            row = [int(hexdata[i : i + 2], 16) for i in range(0, len(hexdata), 2)]
            rows.append(row)

    h = len(rows)
    w = len(rows[0])

    # Create a slightly larger image with margin
    img = Image.new("L", (w + 2 * MARGIN, h + 2 * MARGIN), color=0)  # black background

    # Paste the 8×8 data in the middle
    for y in range(h):
        for x in range(w):
            img.putpixel((x + MARGIN, y + MARGIN), rows[y][x])

    # Convert to RGB so we can draw color
    img_rgb = img.convert("RGB")

    # Draw bounding box *around* the 8×8 area (not on top)
    draw = ImageDraw.Draw(img_rgb)
    box = [MARGIN - 1, MARGIN - 1, w + MARGIN, h + MARGIN]
    draw.rectangle(box, outline=(255, 0, 0), width=1)

    # Scale up (nearest neighbor = pixel-perfect)
    img_scaled = img_rgb.resize(
        ((w + 2 * MARGIN) * SCALE, (h + 2 * MARGIN) * SCALE), Image.NEAREST
    )

    images.append(img_scaled)

# Show the first frame
images[0].show()

# Save animation
images[0].save(
    "visualized_glider.gif",
    save_all=True,
    append_images=images[1:],
    duration=500,
    loop=0,
)

print(
    f"Saved {len(images)} frames with visible border area to write_mem_bounded_margin.gif"
)
