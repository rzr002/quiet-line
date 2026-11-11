#!/usr/bin/env python3
"""Generate illustrative README artwork. Requires Pillow; never captures the desktop."""
from pathlib import Path
from math import sin, pi
from html import escape
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "docs" / "assets"
OUT.mkdir(parents=True, exist_ok=True)
PAPER, INK, MUTED, LINE = "#f6f4ef", "#303a33", "#7f857d", "#70786f"
# Illustrative normalized shape, deliberately unrelated to a live quote.
VALUES = [0.42, .38, .44, .36, .35, .49, .57, .61, .59, .67, .70, .68, .64, .69, .65, .55,
          .51, .54, .46, .50, .57, .61, .58, .49, .45, .48, .39, .34, .37, .29, .22, .31,
          .43, .38, .32, .35, .26, .23, .30, .27, .20, .24, .18, .21, .16, .19, .24, .21]


def curve(x, y, width, height):
    return [(x + i * width / (len(VALUES) - 1), y + value * height) for i, value in enumerate(VALUES)]


def font(size, serif=False, mono=False):
    candidates = (["/System/Library/Fonts/Supplemental/Georgia.ttf"] if serif else
                  ["/System/Library/Fonts/SFNSMono.ttf"] if mono else
                  ["/System/Library/Fonts/SFNS.ttf", "/System/Library/Fonts/Supplemental/Arial.ttf"])
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


points = curve(88, 390, 1424, 236)
path = "M " + " L ".join(f"{x:.1f},{y:.1f}" for x, y in points)
x, y = points[-1]
svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="760" viewBox="0 0 1600 760" role="img" aria-labelledby="title desc">
<title id="title">Quiet Line: one market curve on your desktop</title>
<desc id="desc">Illustrative market curve on a warm paper background with a small endpoint. Not a live quote or desktop capture.</desc>
<rect width="1600" height="760" rx="24" fill="{PAPER}"/>
<path d="M 88 83 l 12 -8 11 14 14 -22 13 11" stroke="{INK}" stroke-width="2.4" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
<text x="158" y="91" fill="{INK}" font-family="Georgia,serif" font-size="36">quiet line</text>
<text x="1512" y="87" text-anchor="end" fill="{MUTED}" font-family="monospace" font-size="16" letter-spacing="2">macOS 14+ / SOURCE DEMO</text>
<text x="86" y="239" fill="{INK}" font-family="Georgia,serif" font-size="88" letter-spacing="-3">One market curve.</text>
<text x="86" y="337" fill="{INK}" font-family="Georgia,serif" font-size="88" letter-spacing="-3">On your desktop.</text>
<text x="1512" y="330" text-anchor="end" fill="{MUTED}" font-family="PingFang SC,sans-serif" font-size="30">屏幕上，只留一条线。</text>
<path d="{escape(path)}" fill="none" stroke="{LINE}" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>
<circle cx="{x}" cy="{y}" r="8" fill="{LINE}" opacity=".10"/><circle cx="{x}" cy="{y}" r="3.5" fill="{LINE}"/>
<line x1="88" y1="674" x2="1512" y2="674" stroke="{INK}" stroke-opacity=".12"/>
<text x="88" y="714" fill="{MUTED}" font-family="monospace" font-size="15" letter-spacing="1">CHOOSE A SYMBOL / DRAG TO PLACE / DOUBLE-CLICK TO HIDE</text>
<text x="1512" y="714" text-anchor="end" fill="{MUTED}" font-family="monospace" font-size="12">ILLUSTRATION</text>
</svg>'''
(OUT / "hero.svg").write_text(svg, encoding="utf-8")

# A separate, directly drawn social preview for GitHub's 2:1 image slot.
social = Image.new("RGB", (1280, 640), PAPER)
draw = ImageDraw.Draw(social)
draw.text((66, 44), "quiet line", font=font(34, serif=True), fill=INK)
draw.text((66, 139), "One market curve.", font=font(77, serif=True), fill=INK)
draw.text((66, 226), "On your desktop.", font=font(77, serif=True), fill=INK)
draw.text((68, 570), "macOS 14+  /  source demo  /  interaction illustration", font=font(16, mono=True), fill=MUTED)
p = curve(70, 340, 1140, 180)
draw.line(p, fill=LINE, width=3, joint="curve")
ex, ey = p[-1]
draw.ellipse((ex-4, ey-4, ex+4, ey+4), fill=LINE)
social.save(OUT / "social-preview.png", optimize=True)

frames = []
for index in range(76):
    frame = Image.new("RGB", (1120, 500), PAPER)
    d = ImageDraw.Draw(frame)
    d.text((42, 25), "quiet line", font=font(29, serif=True), fill=INK)
    d.text((790, 37), "INTERACTION ILLUSTRATION", font=font(12, mono=True), fill=MUTED)
    # Faint document strokes suggest a desktop without fabricating a screenshot.
    for yy, length in [(118, 160), (143, 225), (168, 190), (218, 245), (243, 180), (268, 210)]:
        d.line((44, yy, 44+length, yy), fill="#e5e4de", width=4)
    if index < 18:
        dx, dy, caption = 0, 0, "Choose a symbol. Place the curve."
    elif index < 32:
        t = (index-18)/13
        eased = t*t*(3-2*t)
        dx, dy, caption = 95*eased, -30*eased, "Drag it into a corner."
    elif index < 42:
        dx, dy, caption = 95, -30, "Double-click the curve to hide it."
    elif index < 57:
        dx, dy, caption = 95, -30, "The curve stays hidden."
    else:
        dx, dy, caption = 95, -30, "Restore it from settings."
    visible = index < 42 or index >= 64
    if visible:
        shape = curve(230+dx, 160+dy, 690, 152)
        d.line(shape, fill=LINE, width=2, joint="curve")
        ex, ey = shape[-1]
        breath = (sin(index*0.09*pi*2/2.6)+1)/2
        radius = 4+breath*3
        shade = int(237 - breath*10)
        d.ellipse((ex-radius,ey-radius,ex+radius,ey+radius), fill=(shade,shade,shade-3))
        d.ellipse((ex-2.5,ey-2.5,ex+2.5,ey+2.5), fill=LINE)
    if 33 <= index < 42:
        cx, cy = 900, 222
        radius = 9 + (index % 4)*4
        d.ellipse((cx-radius,cy-radius,cx+radius,cy+radius), outline="#b9c4b8", width=2)
    if index >= 57:
        d.rounded_rectangle((828, 91, 1046, 139), radius=8, fill=INK)
        d.text((861, 104), "Show curve", font=font(18), fill=PAPER)
    d.line((42, 382, 1078, 382), fill="#dedfd6", width=1)
    d.text((42, 409), caption, font=font(27, serif=True), fill=INK)
    d.text((42, 466), "EXAMPLE SHAPE / NOT LIVE MARKET DATA", font=font(11, mono=True), fill=MUTED)
    frames.append(frame.convert("P", palette=Image.Palette.ADAPTIVE, colors=64))
frames[0].save(OUT / "interaction.gif", save_all=True, append_images=frames[1:],
               duration=[90]*75+[1200], loop=0, optimize=True, disposal=2)
print("Generated:", ", ".join(p.name for p in OUT.iterdir()))

# Finder icon for the downloadable app. This only draws the project's own curve artwork.
icon = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
idraw = ImageDraw.Draw(icon)
idraw.rounded_rectangle((24, 24, 1000, 1000), radius=210, fill=PAPER)
shape = curve(140, 270, 744, 550)
idraw.line(shape, fill=INK, width=18, joint="curve")
ex, ey = shape[-1]
idraw.ellipse((ex-17, ey-17, ex+17, ey+17), fill=INK)
icon.save(ROOT / "Resources/AppIcon.icns", format="ICNS")
print("Generated Resources/AppIcon.icns")
