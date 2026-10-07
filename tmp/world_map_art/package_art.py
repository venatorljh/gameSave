from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
import json

root = Path(r"C:\Users\ljh\Desktop\game\godot-game\assets\art\world_map")
record = json.loads((root / "generation_prompts.json").read_text(encoding="utf-8"))
atlas = Image.open(root / "atlases/region_icons_source_v1.png").convert("RGBA")
alpha = atlas.getchannel("A")
solid = alpha.point(lambda v: 255 if v >= 128 else 0)
rowcounts = [sum(v != 0 for v in solid.crop((0, y, atlas.width, y + 1)).get_flattened_data()) for y in range(atlas.height)]
colcounts = [sum(v != 0 for v in solid.crop((x, 0, x + 1, atlas.height)).get_flattened_data()) for x in range(atlas.width)]

def choose_gap(counts, lo, hi):
    minimum = min(counts[lo:hi])
    candidates = [n for n in range(lo, hi) if counts[n] == minimum]
    midpoint = (lo + hi) / 2
    return min(candidates, key=lambda n: abs(n - midpoint))

xs = [0] + [choose_gap(colcounts, c - 12, c + 13) for c in [256, 512, 768, 1024, 1280]] + [atlas.width]
ys = [0] + [choose_gap(rowcounts, lo, hi) for lo, hi in [(274, 300), (515, 550), (753, 788)]] + [atlas.height]
for folder in ["icons", "icons_64", "icons_source", "previews"]:
    (root / folder).mkdir(exist_ok=True)
font_path = Path(r"C:\Windows\Fonts\msyh.ttc")
font = ImageFont.truetype(str(font_path), 17)
small_font = ImageFont.truetype(str(font_path), 12)
contact = Image.new("RGB", (960, 720), "#29282f")
draw = ImageDraw.Draw(contact)
icons_meta = []

for index, (key, label) in enumerate(record["region_names"]):
    row, col = divmod(index, 6)
    cell_box = (xs[col], ys[row], xs[col + 1], ys[row + 1])
    cell = atlas.crop(cell_box)
    local_solid = solid.crop(cell_box)
    bbox = local_solid.getbbox()
    if bbox is None:
        raise ValueError(f"Empty sprite region: {key}")
    box = (max(0, bbox[0] - 5), max(0, bbox[1] - 5), min(cell.width, bbox[2] + 5), min(cell.height, bbox[3] + 5))
    extracted = cell.crop(box)
    source_path = f"icons_source/{key}.png"
    extracted.save(root / source_path)

    def normalized_icon(size):
        available = size - 12 if size >= 128 else size - 6
        scale = min(available / extracted.width, available / extracted.height)
        target = (max(1, round(extracted.width * scale)), max(1, round(extracted.height * scale)))
        resized = extracted.resize(target, Image.Resampling.NEAREST)
        canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        offset = ((size - resized.width) // 2, size - (6 if size >= 128 else 3) - resized.height)
        canvas.alpha_composite(resized, offset)
        return canvas, target, offset

    icon, target_size, offset = normalized_icon(128)
    icon_path = f"icons/{key}.png"
    icon.save(root / icon_path)
    small, _, _ = normalized_icon(64)
    small_path = f"icons_64/{key}.png"
    small.save(root / small_path)
    card_x, card_y = col * 160, row * 180
    draw.rectangle((card_x + 4, card_y + 4, card_x + 155, card_y + 175), fill="#34343b", outline="#5c5864")
    contact.paste(icon, (card_x + 16, card_y + 6), icon)
    draw.text((card_x + 80, card_y + 139), label, font=font, fill="#dfd4bc", anchor="mm")
    draw.text((card_x + 80, card_y + 160), f"{index + 1:02d} {key}", font=small_font, fill="#aca79d", anchor="mm")
    icons_meta.append({
        "id": key, "display_name": label, "index": index + 1,
        "atlas_cell_bounds": list(cell_box),
        "source_content_bounds": [cell_box[0] + box[0], cell_box[1] + box[1], cell_box[0] + box[2], cell_box[1] + box[3]],
        "source_file": source_path, "source_size": list(extracted.size),
        "file": icon_path, "size": [128, 128], "small_file": small_path, "small_size": [64, 64],
        "texture_filter": "nearest", "normalized_visible_size": list(target_size), "normalized_offset": list(offset),
        "alpha_range": list(icon.getchannel("A").getextrema())
    })

contact.save(root / "previews/region_icons_contact_sheet.png")
terrain = Image.open(root / "backgrounds/world_terrain_v1.png")
terrain.resize((768, 512), Image.Resampling.NEAREST).save(root / "backgrounds/world_terrain_768x512.png")
manifest = {
    "asset_pack": "medieval_pixel_world_map_v1", "generator": "built-in image_gen",
    "purpose": "art assets only; not integrated into game",
    "terrain": {"file": "backgrounds/world_terrain_v1.png", "size": list(terrain.size), "small_file": "backgrounds/world_terrain_768x512.png", "small_size": [768, 512], "roads_baked_in": False},
    "icon_atlas": {"file": "atlases/region_icons_source_v1.png", "size": list(atlas.size), "mode": "RGBA", "columns": 6, "rows": 4, "extraction_x_boundaries": xs, "extraction_y_boundaries": ys},
    "icon_count": len(icons_meta),
    "default_icon_size": [128, 128], "small_icon_size": [64, 64],
    "contact_preview": "previews/region_icons_contact_sheet.png",
    "icons": icons_meta,
    "notes": [
        "Generation atlas spacing is slightly uneven; extraction follows transparent gutters rather than blindly slicing equal-height rows.",
        "Source PNG alpha is preserved. Resized variants use nearest-neighbor sampling and a common bottom alignment.",
        "The 64px and 128px variants share the same designs; select one size family consistently.",
        "Roads, map node state, region scenes and navigation are not implemented."
    ]
}
(root / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"saved_root": str(root), "icon_count": len(icons_meta), "x_boundaries": xs, "y_boundaries": ys, "preview": str(root / "previews/region_icons_contact_sheet.png")}, ensure_ascii=False))

