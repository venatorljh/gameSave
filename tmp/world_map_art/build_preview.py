from pathlib import Path
import base64, json
root=Path(r"C:\Users\ljh\Desktop\game\godot-game\assets\art\world_map")
destination=Path(r"C:\Users\ljh\.codex\visualizations\2026\10\01\01a0f79a-d5c4-76d3-9af5-6c702c687db1\medieval-world-map-art.html")
template=Path(r"C:\Users\ljh\Desktop\game\tmp\world_map_art\world-map-preview.template.html").read_text(encoding="utf-8")
def image_data(path):
    return "data:image/png;base64,"+base64.b64encode(path.read_bytes()).decode("ascii")
nodes=[
("village",345,822),("forest",276,536),("cemetery",635,791),("church",677,486),
("mine",268,171),("farm",594,638),("traveler_camp",755,168),("monastery",1051,478),
("ruined_castle",1252,153),("boss_citadel",1165,586)
]
lines=[]
for key,x,y in nodes:
    lines.append(f'<img src="{image_data(root / "icons" / (key+".png"))}" style="left:{x/1536*100:.4f}%;top:{y/1024*100:.4f}%;" alt="">')
for x,y in [(809,480),(860,542)]:
    lines.append(f'<img class="world-art-bridge" src="{image_data(root / "icons" / "stone_bridge.png")}" style="left:{x/1536*100:.4f}%;top:{(y+28)/1024*100:.4f}%;" alt="">')
fragment=template.replace("__BACKGROUND_DATA__",image_data(root/"backgrounds/world_terrain_384x256.png")).replace("__REGION_IMAGES__","\n".join(lines))
destination.write_text(fragment,encoding="utf-8")
(root / "previews/world_map_layout_preview.fragment.html").write_text(fragment,encoding="utf-8")
manifest=json.loads((root/"manifest.json").read_text(encoding="utf-8"))
manifest["terrain"]["pixel_file"]="backgrounds/world_terrain_384x256.png"
manifest["terrain"]["pixel_size"]=[384,256]
manifest["assembled_preview"]={"file":"previews/world_map_layout_preview.html","type":"standalone browser art preview","regions":[{"id":key,"x":x,"y":y} for key,x,y in nodes],"roads":"illustrative only; multiple cycles; no navigation implementation","images":"uses the delivered background and icon PNG assets","fragment_file":"previews/world_map_layout_preview.fragment.html"}
(root/"manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print({"fragment":str(destination),"bytes":destination.stat().st_size})

