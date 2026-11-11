"""Camel Claus UI icons: 12x12 pixel art + 1 px navy outline (saved 4x = 56 px) from text maps, palette colors only (docs/ART_DIRECTION.md).
Writes assets/ui/icons/<name>.png; <name> matches the upgrade/item .tres file name, so the menu
finds an icon from the resource path. Run: python art_src/tools/make_icons.py
"""
import os
from PIL import Image

SCALE = 4  # saved at 56x56 (14 px incl. outline x4); UI shows them at 56 (cards) or 28 (HUD)
OUTLINE = "#22304F"
PROJ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
COLORS = {
    "W": "#F4F8FF", "S": "#C9DAF0", "B": "#8FA9D1", "I": "#7FD6F2", "N": "#4E6A9E", "K": "#22304F",
    "T": "#E8C48E", "C": "#C98F55", "D": "#8A5A33", "R": "#D9343F", "M": "#8E1F2E", "G": "#3E9A5B",
    "P": "#1F5A43", "Y": "#F2B53B", "O": "#5B3A2A", "V": "#9B4FD1",
}
ICONS = {
    "swift_hooves": """
............
.......CCC..
......CCCC..
......CCCC..
..B...CCCC..
.BB..CCCCC..
..B.CCCCCC..
.BB.CCCCCC..
....DDDDDDD.
....OOOOOOO.""",
    "extra_hump": """
............
..RR....RR..
.RRRR..RRRR.
RRWRRRRRRRRR
RWRRRRRRRRRR
RRRRRRRRRRRR
.RRRRRRRRRR.
..RRRRRRRR..
...RRRRRR...
....RRRR....
.....RR.....""",
    "magnet_scarf": """
............
.RRR....NNN.
.RRR....NNN.
.RRR....NNN.
.RRR....NNN.
.RRR....NNN.
.RRR....NNN.
.RRRR..NNNN.
..RRRRNNNN..
...RRRNNN...""",
    "heavier_gifts": """
.....Y......
....YYY.....
...YYYYY....
.....Y......
.RRRRYRRRR..
.RRRRYRRRR..
.YYYYYYYYY..
.RRRRYRRRR..
.RRRRYRRRR..
.MMMMYMMMM..""",
    "faster_wrapping": """
............
...WWWWWW...
..WSSSSSSW..
.WSSSKSSSSW.
.WSSSKSSSSW.
.WSSSKSSSSW.
.WSSSKKKSSW.
.WSSSSSSSSW.
..WSSSSSSW..
...WWWWWW...""",
    "double_gift": """
............
.......Y.Y..
......RRYRR.
..Y.Y.RRYRR.
.RRYRRYYYYY.
.RRYRRRRYRR.
.YYYYYMMYMM.
.RRYRR......
.MMYMM......""",
    "weapon_gift_toss": """
....Y..Y....
.....YY.....
.RRRRYYRRRR.
.RRRRYYRRRR.
.RRRRYYRRRR.
.YYYYYYYYYY.
.RRRRYYRRRR.
.RRRRYYRRRR.
.MMMMYYMMMM.
.MMMMYYMMMM.""",
    "weapon_candy_cane_orbit": """
...RRWW.....
..W....RR...
.WW.....RW..
.R.......WR.
.........RW.
.........WR.
.........RW.
.........WR.
.........RW.
.........WR.
.........RW.""",
    "weapon_jingle_pulse": """
.....YY.....
....YYYY....
...YYYYYY...
...YWYYYY...
..YWYYYYYY..
..YYYYYYYY..
..YYYYYYYY..
.YYYYYYYYYY.
.DDDDDDDDDD.
.....OO.....""",
    "spiced_dates": """
............
............
...DD.......
..DCCD......
..DCCD..DD..
..DCCD.DCCD.
..DDCD.DCCD.
...DD..DCCD.
.......DDCD.
........DD..""",
    "sleigh_bells": """
............
OOOOOOOOOOOO
..Y.....Y...
.YYY...YYY..
YWYYY.YWYYY.
YYYYY.YYYYY.
YYKYY.YYKYY.
.YYY...YYY..""",
    "santas_sack": """
....YY......
....DD......
...RRRR.....
..RRRRRR....
.RRRRRRRR...
.RRWRRRRRR..
.RRRRRRRRR..
.RRRRRRRRR..
.MRRRRRRRM..
..MMMMMMM...""",
    "hay_bale": """
............
.YYYYYYYYYY.
.YTYYTYYTYY.
.YDYYYYYYDY.
.YDYYTYYYDY.
.YDYYYYTYDY.
.YDYTYYYYDY.
.YYYYYYYYYY.
.TTTTTTTTTT.""",
    "fruitcake": """
............
...WWWWWW...
..WWWWWWWW..
.DDWDDDWDDD.
.DRDDGDDRDD.
.DDDGDDRDGD.
.DGDDDRDDDD.
.DDDRDDDGDD.
.ODDDDDDDDO.
..OOOOOOOO..""",
    "christmas_cracker": """
............
.R........R.
.RR..YY..RR.
.RRRRYYRRRR.
.RRRRWYRRRR.
.RRRRYYRRRR.
.RR..YY..RR.
.R........R.""",
    "icicle": """
.SSSSSSSSSS.
..IIIIIIII..
..IWIIIIII..
...IWIIII...
...IIIIII...
....IWII....
....IIII....
.....II.....
.....II.....
.....I......""",
    "naughty_list": """
............
.TTTTTTTTT..
.DTTTTTTTTD.
..TKKKKKT...
..TTTTTTT...
..TKKKKT....
..TTTTTTT...
..TKRRRKT...
..TTTTTTT...
.DTTTTTTTTD.
.TTTTTTTTT..""",
    "snow_globe": """
...SSSSS....
..SIIIIIS...
.SIIWIIIIS..
.SIIIIGIIS..
.SIIIGGGIS..
.SIIWGGGIS..
..SIIOIIS...
...SSSSS....
..DDDDDDD...
..OOOOOOO...""",
    "chimney_draft": """
.Y........Y.
..Y......Y..
...Y....Y...
....YYYY....
..MMMMMMMM..
..RRRRRRRR..
..MRRMRRMR..
..RRRRRRRR..
..RMRRMRRM..
..RRRRRRRR..
..MMMMMMMM..""",
    "lump_of_coal": """
............
....BBB.....
..BBNNNBB...
.BNNKNNNNB..
BNNKNNNNNNB.
BNNNNNKNNNB.
BNNNNNNNNNB.
.BNNNNNNNB..
..BBNNNBB...
....BBB.....""",
    "weapon_gift_toss_evo": """
W....Y..Y..W
.....RYYR...
..W...RR....
.YYYYYRRYYY.
.YYYYYRRYYY.
.RRRRRRRRRR.
.YYYYYRRYYY.
.YYYYYRRYYY.
.CCCCCRRCCC.
.CCCCCRRCCC.
W..........W""",
    "weapon_jingle_pulse_evo": """
.......WW...
.......W.W..
..YY...W....
.YYYY.WW....
.YWYY.WW....
YYYYYY......
YYYYYY.YY...
DDDDDD.YYY..
..OO..YWYYY.
......YYYYY.
......DDDDD.
........OO..""",
    "evolution": """
.....YY.....
.....YY.....
....YYYY....
YYYYYYYYYYYY
.YYYYWYYYYY.
..YYYYYYYY..
...YYYYYY...
..YYYYYYYY..
..YYY..YYY..
.YYY....YYY.
.YY......YY.""",
}


def main():
    out_dir = os.path.join(PROJ, "assets", "ui", "icons")
    os.makedirs(out_dir, exist_ok=True)
    for name, art in ICONS.items():
        rows = [r for r in art.split("\n") if r != ""]
        # 14x14 canvas: the 12x12 art plus a 1 px navy outline so icons read on snow and on panels.
        img = Image.new("RGBA", (14, 14), (0, 0, 0, 0))
        for y, row in enumerate(rows[:12]):
            for x, ch in enumerate(row[:12]):
                if ch in COLORS:
                    h = COLORS[ch]
                    img.putpixel((x + 1, y + 1), tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) + (255,))
        outline = tuple(int(OUTLINE[i:i + 2], 16) for i in (1, 3, 5)) + (255,)
        solid = {(x, y) for x in range(14) for y in range(14) if img.getpixel((x, y))[3] > 0}
        for x, y in [(x, y) for x in range(14) for y in range(14) if (x, y) not in solid]:
            if any((x + dx, y + dy) in solid for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                img.putpixel((x, y), outline)
        img.resize((14 * SCALE, 14 * SCALE), Image.NEAREST).save(os.path.join(out_dir, name + ".png"))
    print(f"{len(ICONS)} icons -> {os.path.relpath(out_dir, PROJ)}")


if __name__ == "__main__":
    main()
