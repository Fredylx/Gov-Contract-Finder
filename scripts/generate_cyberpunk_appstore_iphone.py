#!/usr/bin/env python3
"""
Generate cyberpunk marketing screenshots for App Store iPhone or iPad uploads.

Examples:
  python3 scripts/generate_cyberpunk_appstore_iphone.py \
    --input "/Users/you/Documents/AppStore_iPhone_Source_Attached" \
    --output "/Users/you/Documents/AppStore_iPhone_Marketing_Cyberpunk"

  python3 scripts/generate_cyberpunk_appstore_iphone.py \
    --device ipad \
    --input "/Users/you/Documents/AppStore_iPad_Ready" \
    --output "/Users/you/Documents/AppStore_iPad_Marketing_Cyberpunk"
"""

from __future__ import annotations

import argparse
import glob
import os
from typing import List, Tuple

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps


IPHONE_TARGET = (1284, 2778)
IPAD_TARGETS = {
    "portrait": (2048, 2732),
    "landscape": (2732, 2048),
}

IPHONE_HEADLINES = [
    ("INTERCEPT\nNEW CONTRACTS", "Neon-fast filters cut through live federal noise."),
    ("TRIAGE THE\nBID PIPELINE", "Watchlists keep high-signal opportunities at the front."),
    ("CATCH EVERY\nDEADLINE SHIFT", "Track amendments, dates, and status changes without lag."),
    ("SEARCH TO\nACTION MODE", "Move from discovery to notes, tasks, and follow-up in one flow."),
    ("CONTACT DATA\nWITHOUT FRICTION", "Pull the context you need before outreach momentum drops."),
    ("BUILT LIKE A\nNIGHT CITY CONSOLE", "High-contrast workflow designed for speed, pressure, and focus."),
]

IPAD_HEADLINES = [
    ("COMMAND THE\nBID GRID", "Use a larger tactical view to sweep contracts faster."),
    ("RUN A WIDE\nAGENCY SWEEP", "Compare agencies, NAICS, and due dates in one pass."),
    ("TURN SEARCH\nINTO OPS", "Pipeline state, alerts, and notes stay visible at once."),
    ("LANDSCAPE\nWAR ROOM", "A high-signal dashboard built for deep contract review."),
    ("FEDERAL SEARCH\nAFTER DARK", "Sharper neon visuals make the workspace feel intentional, not generic."),
]


def load_font(size: int, bold: bool = False) -> ImageFont.ImageFont:
    candidates: List[str] = []
    if bold:
        candidates.extend(
            [
                "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
                "/System/Library/Fonts/Supplemental/Arial Narrow Bold.ttf",
                "/System/Library/Fonts/Supplemental/Helvetica Bold.ttf",
            ]
        )
    else:
        candidates.extend(
            [
                "/System/Library/Fonts/Supplemental/Arial.ttf",
                "/System/Library/Fonts/Supplemental/Arial Narrow.ttf",
                "/System/Library/Fonts/Supplemental/Helvetica.ttf",
            ]
        )
    for path in candidates:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size=size)
            except Exception:
                pass
    return ImageFont.load_default()


def collect_images(input_dir: str) -> List[str]:
    exts = ("*.png", "*.jpg", "*.jpeg", "*.heic")
    paths: List[str] = []
    for ext in exts:
        paths.extend(glob.glob(os.path.join(input_dir, ext)))
    paths = [p for p in paths if os.path.isfile(p)]
    paths.sort(key=os.path.getmtime)
    return paths


def target_size_for_image(image: Image.Image, device: str) -> Tuple[int, int]:
    if device == "iphone":
        return IPHONE_TARGET
    orientation = "landscape" if image.width >= image.height else "portrait"
    return IPAD_TARGETS[orientation]


def fit_to_target(image: Image.Image, target_size: Tuple[int, int]) -> Image.Image:
    target_landscape = target_size[0] >= target_size[1]
    im = image.convert("RGB")
    image_landscape = im.width >= im.height
    if image_landscape != target_landscape:
        im = im.rotate(90, expand=True)
    return ImageOps.fit(im, target_size, method=Image.Resampling.LANCZOS, centering=(0.5, 0.5))


def gradient_layer(
    size: Tuple[int, int],
    start: Tuple[int, int, int],
    end: Tuple[int, int, int],
    horizontal: bool = False,
) -> Image.Image:
    gradient = Image.linear_gradient("L")
    if horizontal:
        gradient = gradient.rotate(90, expand=True)
    gradient = gradient.resize(size)
    return ImageOps.colorize(gradient, start, end).convert("RGBA")


def rounded_mask(size: Tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask


def glow_alpha(color: Tuple[int, int, int], alpha: int) -> Tuple[int, int, int, int]:
    return (color[0], color[1], color[2], alpha)


def draw_glow_panel(
    base: Image.Image,
    box: Tuple[int, int, int, int],
    radius: int,
    fill: Tuple[int, int, int, int],
    outline: Tuple[int, int, int, int],
    glow: Tuple[int, int, int],
    blur_radius: int,
) -> None:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.rounded_rectangle(box, radius=radius, outline=glow_alpha(glow, 210), width=4)
    d.rounded_rectangle(
        (box[0] + 6, box[1] + 6, box[2] - 6, box[3] - 6),
        radius=max(0, radius - 8),
        outline=glow_alpha((255, 255, 255), 70),
        width=1,
    )
    base.alpha_composite(layer.filter(ImageFilter.GaussianBlur(blur_radius)))

    d = ImageDraw.Draw(base)
    d.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=2)


def draw_glow_text(
    base: Image.Image,
    xy: Tuple[int, int],
    text: str,
    font: ImageFont.ImageFont,
    fill: Tuple[int, int, int, int],
    glow: Tuple[int, int, int],
    blur_radius: int,
    spacing: int = 6,
    align: str = "left",
) -> None:
    glow_layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow_layer)
    gd.multiline_text(xy, text, font=font, fill=glow_alpha(glow, 210), spacing=spacing, align=align)
    base.alpha_composite(glow_layer.filter(ImageFilter.GaussianBlur(blur_radius)))

    d = ImageDraw.Draw(base)
    d.multiline_text(xy, text, font=font, fill=fill, spacing=spacing, align=align)


def draw_hud_panel(
    base: Image.Image,
    box: Tuple[int, int, int, int],
    label: str,
    body: str,
    accent: Tuple[int, int, int],
) -> None:
    draw_glow_panel(
        base,
        box,
        radius=max(24, (box[3] - box[1]) // 8),
        fill=(7, 14, 32, 228),
        outline=glow_alpha(accent, 180),
        glow=accent,
        blur_radius=max(16, (box[3] - box[1]) // 6),
    )
    label_font = load_font(max(18, (box[3] - box[1]) // 10), bold=True)
    body_font = load_font(max(24, (box[3] - box[1]) // 7), bold=True)
    draw_glow_text(base, (box[0] + 26, box[1] + 20), label, label_font, (180, 205, 232, 255), accent, 6, spacing=4)
    draw_glow_text(base, (box[0] + 26, box[1] + 62), body, body_font, (240, 246, 255, 255), accent, 10, spacing=2)


def make_background(size: Tuple[int, int], index: int, landscape: bool) -> Image.Image:
    w, h = size
    base = gradient_layer(size, (5, 6, 24), (21, 4, 54))
    side = gradient_layer(size, (8, 22, 46), (0, 121, 166), horizontal=True)
    base = Image.blend(base, side, 0.34)

    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    d.polygon(
        [
            (0, int(h * 0.12)),
            (int(w * 0.48), 0),
            (int(w * 0.70), 0),
            (int(w * 0.14), int(h * 0.40)),
        ],
        fill=(255, 40, 160, 34),
    )
    d.polygon(
        [
            (int(w * 0.52), h),
            (w, int(h * 0.40)),
            (w, int(h * 0.18)),
            (int(w * 0.34), h),
        ],
        fill=(36, 235, 255, 28),
    )

    glows = [
        (int(w * 0.12), int(h * 0.18), int(min(w, h) * 0.20), (35, 242, 255, 105)),
        (int(w * 0.82), int(h * 0.14), int(min(w, h) * 0.22), (255, 54, 178, 100)),
        (int(w * 0.24), int(h * 0.82), int(min(w, h) * 0.26), (255, 132, 35, 62)),
        (int(w * 0.84), int(h * 0.78), int(min(w, h) * 0.24), (97, 133, 255, 64)),
    ]
    if landscape:
        glows.append((int(w * 0.58), int(h * 0.50), int(min(w, h) * 0.18), (33, 232, 255, 50)))
    for cx, cy, radius, color in glows:
        d.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=color)

    grid_color = (57, 115, 181, 58)
    spacing = max(64, min(w, h) // 18)
    for x in range(0, w, spacing):
        d.line((x, 0, x, h), fill=grid_color, width=1)
    for y in range(0, h, spacing):
        d.line((0, y, w, y), fill=grid_color, width=1)

    scan_alpha = 20 if landscape else 24
    for y in range(index % 8, h, 8):
        d.line((0, y, w, y), fill=(255, 255, 255, scan_alpha), width=1)

    skyline_top = int(h * (0.78 if landscape else 0.81))
    bar_w = max(36, w // 48)
    gap = max(10, bar_w // 2)
    for bar_index, x in enumerate(range(0, w + bar_w, bar_w + gap)):
        offset = (bar_index * 173 + index * 61) % max(140, int(h * 0.16))
        top = skyline_top - offset
        d.rectangle((x, top, x + bar_w, h), fill=(4, 10, 24, 182))
        edge = (72, 240, 255, 122) if bar_index % 2 == 0 else (255, 76, 178, 95)
        d.rectangle((x, top, x + bar_w, min(h, top + 4)), fill=edge)

    layer = layer.filter(ImageFilter.GaussianBlur(1.2))
    base = Image.alpha_composite(base, layer)

    vignette = Image.new("RGBA", size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    border = max(22, min(w, h) // 18)
    vd.rounded_rectangle((0, 0, w - 1, h - 1), radius=border, outline=(0, 0, 0, 110), width=border)
    return Image.alpha_composite(base, vignette)


def build_device_frame(screenshot: Image.Image, frame_size: Tuple[int, int], device: str) -> Image.Image:
    fw, fh = frame_size
    radius = max(32, int(min(fw, fh) * (0.13 if device == "iphone" else 0.07)))
    inset = max(28, int(min(fw, fh) * (0.035 if device == "iphone" else 0.03)))

    frame = Image.new("RGBA", frame_size, (0, 0, 0, 0))

    glow = Image.new("RGBA", frame_size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.rounded_rectangle((3, 3, fw - 4, fh - 4), radius=radius, outline=(67, 239, 255, 220), width=max(4, min(fw, fh) // 120))
    gd.rounded_rectangle((10, 10, fw - 11, fh - 11), radius=max(0, radius - 8), outline=(255, 64, 177, 170), width=max(2, min(fw, fh) // 180))
    frame.alpha_composite(glow.filter(ImageFilter.GaussianBlur(max(10, min(fw, fh) // 32))))

    d = ImageDraw.Draw(frame)
    d.rounded_rectangle(
        (0, 0, fw - 1, fh - 1),
        radius=radius,
        fill=(5, 8, 19, 255),
        outline=(84, 240, 255, 255),
        width=max(3, min(fw, fh) // 140),
    )
    d.rounded_rectangle(
        (12, 12, fw - 13, fh - 13),
        radius=max(0, radius - 10),
        outline=(255, 76, 190, 188),
        width=max(2, min(fw, fh) // 220),
    )

    sw = fw - inset * 2
    sh = fh - inset * 2
    shot = fit_to_target(screenshot, (sw, sh)).convert("RGBA")
    clipped = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    clipped.paste(shot, (0, 0), rounded_mask((sw, sh), max(18, radius - inset // 2)))
    frame.alpha_composite(clipped, (inset, inset))

    if device == "iphone":
        island_w = int(fw * 0.28)
        island_h = max(24, int(fh * 0.018))
        island_y = max(18, int(fh * 0.02))
        d.rounded_rectangle(
            (fw // 2 - island_w // 2, island_y, fw // 2 + island_w // 2, island_y + island_h),
            radius=island_h // 2,
            fill=(0, 0, 0, 228),
        )
    else:
        dot_r = max(8, int(min(fw, fh) * 0.008))
        dot_y = max(18, int(fh * 0.02))
        d.ellipse((fw // 2 - dot_r, dot_y, fw // 2 + dot_r, dot_y + dot_r * 2), fill=(14, 18, 28, 255), outline=(97, 168, 214, 255))

    return frame


def composite_rotated_frame(base: Image.Image, frame: Image.Image, origin: Tuple[int, int], angle: float) -> None:
    fw, fh = frame.size
    shadow_pad = max(80, min(fw, fh) // 7)
    shadow = Image.new("RGBA", (fw + shadow_pad * 2, fh + shadow_pad * 2), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle(
        (shadow_pad, shadow_pad, shadow_pad + fw, shadow_pad + fh),
        radius=max(36, int(min(fw, fh) * 0.09)),
        fill=(0, 0, 0, 178),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(max(20, min(fw, fh) // 18))).rotate(
        angle,
        resample=Image.Resampling.BICUBIC,
        expand=True,
    )
    sx = origin[0] - (shadow.width - fw) // 2
    sy = origin[1] - (shadow.height - fh) // 2 + max(16, min(fw, fh) // 26)
    base.alpha_composite(shadow, (sx, sy))

    rotated = frame.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)
    fx = origin[0] - (rotated.width - fw) // 2
    fy = origin[1] - (rotated.height - fh) // 2
    base.alpha_composite(rotated, (fx, fy))


def render_phone_card(screenshot: Image.Image, title: str, subtitle: str, index: int) -> Image.Image:
    w, h = IPHONE_TARGET
    base = make_background(IPHONE_TARGET, index, landscape=False)
    cyan = (57, 240, 255)
    pink = (255, 67, 186)

    draw_glow_panel(base, (76, 78, 620, 166), 42, (8, 18, 36, 220), (83, 244, 255, 210), cyan, 18)
    eyebrow_font = load_font(34, bold=True)
    draw_glow_text(base, (108, 102), "NEON OPS // GOV CONTRACT HUNTER", eyebrow_font, (217, 244, 255, 255), cyan, 8, spacing=4)

    title_font = load_font(118, bold=True)
    subtitle_font = load_font(42, bold=False)
    draw_glow_text(base, (80, 220), title, title_font, (240, 247, 255, 255), cyan, 22, spacing=4)
    draw_glow_text(base, (86, 520), subtitle, subtitle_font, (184, 203, 228, 255), pink, 10, spacing=6)

    phone_h = 1830
    phone_w = int(phone_h * 0.485)
    phone_x = (w - phone_w) // 2
    phone_y = 720
    phone = build_device_frame(screenshot, (phone_w, phone_h), "iphone")
    composite_rotated_frame(base, phone, (phone_x, phone_y), -3.5 if index % 2 else 3.2)

    draw_hud_panel(base, (58, 1008, 314, 1242), "LIVE FEED", "SAM.GOV\nINTAKE", cyan)
    draw_hud_panel(base, (972, 1170, 1228, 1404), "STACK", "WATCHLIST\nALERTS", pink)

    footer = "TACTICAL SEARCH // FILTER // TRACK // EXECUTE"
    draw_glow_panel(base, (116, h - 196, w - 116, h - 100), 48, (9, 18, 40, 228), (83, 244, 255, 190), cyan, 22)
    footer_font = load_font(38, bold=True)
    draw_glow_text(base, (154, h - 168), footer, footer_font, (220, 246, 255, 255), cyan, 8, spacing=4)

    return base.convert("RGB")


def render_ipad_card(
    screenshot: Image.Image,
    title: str,
    subtitle: str,
    index: int,
    target_size: Tuple[int, int],
) -> Image.Image:
    w, h = target_size
    landscape = w > h
    base = make_background(target_size, index, landscape=landscape)
    cyan = (57, 240, 255)
    pink = (255, 67, 186)

    if landscape:
        draw_glow_panel(base, (130, 100, 820, 210), 48, (8, 18, 36, 220), (83, 244, 255, 210), cyan, 20)
        eyebrow_font = load_font(44, bold=True)
        draw_glow_text(base, (170, 132), "WAR ROOM // GOV CONTRACT HUNTER", eyebrow_font, (217, 244, 255, 255), cyan, 8, spacing=4)

        title_font = load_font(168, bold=True)
        subtitle_font = load_font(58, bold=False)
        draw_glow_text(base, (144, 278), title, title_font, (240, 247, 255, 255), cyan, 24, spacing=8)
        draw_glow_text(base, (152, 760), subtitle, subtitle_font, (184, 203, 228, 255), pink, 12, spacing=8)

        frame_w = 1490
        frame_h = int(frame_w * 0.75)
        frame_x = w - frame_w - 160
        frame_y = 360
        ipad = build_device_frame(screenshot, (frame_w, frame_h), "ipad")
        composite_rotated_frame(base, ipad, (frame_x, frame_y), 1.6 if index % 2 else -1.4)

        draw_hud_panel(base, (154, 1120, 550, 1384), "MULTI-VIEW", "FILTERS\nPIPELINE", cyan)
        draw_hud_panel(base, (570, 1120, 978, 1384), "ALERTS", "DATES\nAMENDMENTS", pink)
        draw_glow_panel(base, (146, h - 214, 1130, h - 108), 52, (9, 18, 40, 228), (83, 244, 255, 190), cyan, 24)
        footer_font = load_font(46, bold=True)
        draw_glow_text(base, (186, h - 182), "LANDSCAPE SWEEP // SEARCH WIDER // DECIDE FASTER", footer_font, (220, 246, 255, 255), cyan, 8, spacing=4)
    else:
        draw_glow_panel(base, (114, 96, 860, 212), 48, (8, 18, 36, 220), (83, 244, 255, 210), cyan, 20)
        eyebrow_font = load_font(46, bold=True)
        draw_glow_text(base, (154, 130), "TACTICAL TABLET // GOV CONTRACT HUNTER", eyebrow_font, (217, 244, 255, 255), cyan, 8, spacing=4)

        title_font = load_font(168, bold=True)
        subtitle_font = load_font(56, bold=False)
        draw_glow_text(base, (124, 290), title, title_font, (240, 247, 255, 255), cyan, 24, spacing=8)
        draw_glow_text(base, (134, 780), subtitle, subtitle_font, (184, 203, 228, 255), pink, 12, spacing=8)

        frame_w = 1420
        frame_h = int(frame_w * 1.333)
        frame_x = (w - frame_w) // 2
        frame_y = 900
        ipad = build_device_frame(screenshot, (frame_w, frame_h), "ipad")
        composite_rotated_frame(base, ipad, (frame_x, frame_y), -1.6 if index % 2 else 1.4)

        draw_hud_panel(base, (108, 1210, 418, 1460), "WIDE VIEW", "LIVE\nINTEL", cyan)
        draw_hud_panel(base, (w - 418, 1378, w - 108, 1628), "FLOW", "TASKS\nNOTES", pink)
        draw_glow_panel(base, (152, h - 228, w - 152, h - 116), 54, (9, 18, 40, 228), (83, 244, 255, 190), cyan, 24)
        footer_font = load_font(48, bold=True)
        draw_glow_text(base, (196, h - 192), "PORTRAIT RAID // REVIEW HARDER // SHIP FASTER", footer_font, (220, 246, 255, 255), cyan, 8, spacing=4)

    return base.convert("RGB")


def render_card(
    screenshot: Image.Image,
    title: str,
    subtitle: str,
    index: int,
    device: str,
    target_size: Tuple[int, int],
) -> Image.Image:
    if device == "iphone":
        return render_phone_card(screenshot, title, subtitle, index)
    return render_ipad_card(screenshot, title, subtitle, index, target_size)


def main(default_device: str = "iphone") -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, help="Folder containing source screenshots")
    parser.add_argument("--output", required=True, help="Folder where styled screenshots will be written")
    parser.add_argument("--device", choices=("iphone", "ipad"), default=default_device, help="Marketing layout preset to use")
    args = parser.parse_args()

    in_dir = os.path.expanduser(args.input)
    out_dir = os.path.expanduser(args.output)
    os.makedirs(out_dir, exist_ok=True)

    images = collect_images(in_dir)
    if not images:
        raise SystemExit(f"No source images found in {in_dir}")

    headlines = IPHONE_HEADLINES if args.device == "iphone" else IPAD_HEADLINES

    for idx, path in enumerate(images, start=1):
        screenshot = Image.open(path)
        target_size = target_size_for_image(screenshot, args.device)
        title, subtitle = headlines[(idx - 1) % len(headlines)]
        out = render_card(screenshot, title, subtitle, idx, args.device, target_size)
        out_name = f"{idx:02d}_cyberpunk_{target_size[0]}x{target_size[1]}.png"
        out_path = os.path.join(out_dir, out_name)
        out.save(out_path, format="PNG", optimize=True)
        print(f"WROTE {out_path}")

    print(f"OUTPUT_DIR {out_dir}")


if __name__ == "__main__":
    main()
