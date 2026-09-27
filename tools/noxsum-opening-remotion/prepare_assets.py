"""Prepare Studio WEBP assets from canonical NOX art."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

project = Path(__file__).resolve().parents[2]
target = Path(__file__).resolve().parent / "public" / "nox"
target.mkdir(parents=True, exist_ok=True)

source = project / "assets" / "nox" / "v0.1" / "board"
for pose in ("sit", "stand", "walk"):
    with Image.open(source / f"nox_{pose}.png") as image:
        image.convert("RGBA").save(target / f"nox_{pose}.webp", "WEBP", quality=92, method=6)
    print(f"nox_{pose}.png -> nox_{pose}.webp")

# Isolate the seated rear-view NOX already used in HOME.
# Mask coordinates are relative to the crop; the shadow and room stay outside.
with Image.open(project / "assets" / "nox" / "v0.6" / "archive_puzzle_window.png") as home:
    cat = home.crop((120, 440, 650, 1100)).convert("RGBA")
mask = Image.new("L", cat.size, 0)
draw = ImageDraw.Draw(mask)
draw.polygon([
    (51, 534), (55, 480), (69, 426), (96, 367), (144, 305),
    (179, 268), (199, 238), (190, 203), (184, 164), (188, 113),
    (185, 66), (194, 59), (225, 82), (245, 71), (270, 43),
    (285, 33), (301, 44), (312, 91), (335, 103), (351, 125),
    (358, 155), (353, 206), (350, 247), (352, 297), (355, 359),
    (367, 423), (379, 474), (388, 507), (419, 516), (451, 519),
    (470, 529), (481, 552), (483, 585),
    (465, 606), (421, 624), (370, 638), (291, 642), (179, 641),
    (117, 633), (81, 618), (61, 582)
], fill=255)
cat.putalpha(mask.filter(ImageFilter.GaussianBlur(1.2)))
cat.save(target / "nox_window.webp", "WEBP", quality=94, method=6)
print("archive_puzzle_window.png -> nox_window.webp (transparent NOX cutout)")



room = Path(__file__).resolve().parent / "public" / "room"
room.mkdir(parents=True, exist_ok=True)
with Image.open(project / "assets" / "nox" / "v0.6" / "archive_puzzle_window.png") as home:
    home.crop((570, 180, 1080, 875)).save(room / "window_city.webp", "WEBP", quality=88, method=6)
print("archive_puzzle_window.png -> window_city.webp (cat-free city crop)")
