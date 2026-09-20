import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

CANVAS_WIDTH = 1290
CANVAS_HEIGHT = 2796

# Base paths
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
RAW_DIR = os.path.join(BASE_DIR, "raw")
OUT_DIR = os.path.join(BASE_DIR, "output")

for l in ["en", "ja", "tr"]:
    os.makedirs(os.path.join(OUT_DIR, l), exist_ok=True)

# System Font Paths
SERIF_EN = "/System/Library/Fonts/NewYork.ttf" if os.path.exists("/System/Library/Fonts/NewYork.ttf") else "/System/Library/Fonts/Times.ttc"
SANS_EN = "/System/Library/Fonts/HelveticaNeue.ttc"
SERIF_JA = "/System/Library/Fonts/ヒラギノ明朝 ProN.ttc"
SANS_JA = "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc"

def get_font(path, size, index=0):
    try:
        return ImageFont.truetype(path, size=size, index=index)
    except Exception:
        return ImageFont.load_default()

def draw_radial_glow(draw, center, radius, color_rgba):
    cx, cy = center
    r, g, b, max_a = color_rgba
    steps = 45
    for i in range(steps, 0, -1):
        cur_r = int(radius * (i / steps))
        alpha = int(max_a * ((1 - (i / steps)) ** 1.6))
        draw.ellipse([cx - cur_r, cy - cur_r, cx + cur_r, cy + cur_r], fill=(r, g, b, alpha))

def create_device_mockup(screenshot_path):
    # Large, crisp iPhone 16/17 Pro chassis
    mockup_w = 1040
    mockup_h = 2240
    corner_radius = 84
    border_thickness = 14

    device_img = Image.new("RGBA", (mockup_w, mockup_h), (0, 0, 0, 0))
    d_draw = ImageDraw.Draw(device_img)

    # 1. Outer Titanium Frame
    frame_color = (52, 56, 68, 255)
    d_draw.rounded_rectangle([0, 0, mockup_w, mockup_h], radius=corner_radius, fill=frame_color)

    # 1b. Titanium Chamfer Edge Highlight
    d_draw.rounded_rectangle([0, 0, mockup_w, mockup_h], radius=corner_radius, outline=(95, 102, 120, 190), width=2)

    # 2. Inner Screen Bezel
    inner_margin = border_thickness
    bezel_rect = [inner_margin, inner_margin, mockup_w - inner_margin, mockup_h - inner_margin]
    d_draw.rounded_rectangle(bezel_rect, radius=corner_radius - 8, fill=(0, 0, 0, 255))

    # 3. Paste Screenshot (Clean UI with NO status bar)
    if os.path.exists(screenshot_path):
        raw_screen = Image.open(screenshot_path).convert("RGBA")
        screen_w = mockup_w - (inner_margin * 2)
        screen_h = mockup_h - (inner_margin * 2)
        resized_screen = raw_screen.resize((screen_w, screen_h), Image.Resampling.LANCZOS)

        # Mask with rounded corners
        mask = Image.new("L", (screen_w, screen_h), 0)
        mask_draw = ImageDraw.Draw(mask)
        mask_draw.rounded_rectangle([0, 0, screen_w, screen_h], radius=corner_radius - 12, fill=255)

        device_img.paste(resized_screen, (inner_margin, inner_margin), mask)

    # 4. Dynamic Island (Sleek pill on top)
    island_w = 176
    island_h = 44
    island_x = (mockup_w - island_w) // 2
    island_y = inner_margin + 18
    d_draw.rounded_rectangle([island_x, island_y, island_x + island_w, island_y + island_h], radius=22, fill=(0, 0, 0, 255))

    # 5. Subtle diagonal screen reflection sheen
    reflection = Image.new("RGBA", (mockup_w, mockup_h), (0, 0, 0, 0))
    r_draw = ImageDraw.Draw(reflection)
    r_draw.polygon([(0, 0), (int(mockup_w * 0.75), 0), (0, int(mockup_h * 0.45))], fill=(255, 255, 255, 8))
    device_img = Image.alpha_composite(device_img, reflection)

    return device_img

def render_screenshot_card(lang, config):
    # High resolution canvas
    canvas = Image.new("RGBA", (CANVAS_WIDTH, CANVAS_HEIGHT), config["bg_color"])
    glow_layer = Image.new("RGBA", (CANVAS_WIDTH, CANVAS_HEIGHT), (0, 0, 0, 0))
    g_draw = ImageDraw.Draw(glow_layer)

    # Ambient radial glows centered behind the phone & title
    draw_radial_glow(g_draw, config["glow_pos"], config["glow_radius"], config["glow_rgba"])
    draw_radial_glow(g_draw, (CANVAS_WIDTH // 2, 380), int(config["glow_radius"] * 0.7), (config["glow_rgba"][0], config["glow_rgba"][1], config["glow_rgba"][2], int(config["glow_rgba"][3] * 0.65)))
    canvas = Image.alpha_composite(canvas, glow_layer)

    draw = ImageDraw.Draw(canvas)

    # 1. Punchy Centered Editorial Title (Two-tone / Accent glow)
    # NO meta tags, NO sub_text descriptions, pure bold focus
    title_text = config[f"title_{lang}"]
    serif_font_path = SERIF_JA if lang == "ja" else SERIF_EN
    title_size = config.get("title_size", 84)
    title_font = get_font(serif_font_path, title_size)
    accent_rgb = config.get("accent_rgb", (255, 255, 255))

    title_lines = title_text.split("\n")
    line_h = title_size + 14
    total_text_h = len(title_lines) * line_h

    # Center title vertically in top header zone (y: 110 to 410)
    start_y = 135 if len(title_lines) > 1 else 175

    for idx, line in enumerate(title_lines):
        # Calculate line bounding box for exact horizontal centering
        bbox = title_font.getbbox(line)
        line_w = bbox[2] - bbox[0]
        line_x = (CANVAS_WIDTH - line_w) // 2
        line_y = start_y + (idx * line_h)

        # Line 1: Pure crisp white; Line 2: Themed glowing accent color
        color = (255, 255, 255, 255) if idx == 0 else (accent_rgb[0], accent_rgb[1], accent_rgb[2], 255)

        # Drop shadow for clean 3D separation
        draw.text((line_x + 2, line_y + 3), line, font=title_font, fill=(0, 0, 0, 180))
        draw.text((line_x, line_y), line, font=title_font, fill=color)

    # 2. Large Device Mockup positioned below title
    raw_img_path = os.path.join(RAW_DIR, f"{lang}_{config['id']}.png")
    if not os.path.exists(raw_img_path):
        raw_img_path = os.path.join(RAW_DIR, f"{config['id']}.png")

    mockup_img = create_device_mockup(raw_img_path)
    mock_x = (CANVAS_WIDTH - mockup_img.width) // 2
    mock_y = 430

    # Ambient soft shadow under the phone
    shadow_overlay = Image.new("RGBA", (CANVAS_WIDTH, CANVAS_HEIGHT), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow_overlay)
    s_draw.rounded_rectangle([mock_x + 10, mock_y + 25, mock_x + mockup_img.width - 10, mock_y + mockup_img.height + 25], radius=90, fill=(0, 0, 0, 160))
    shadow_overlay = shadow_overlay.filter(ImageFilter.GaussianBlur(radius=32))
    canvas = Image.alpha_composite(canvas, shadow_overlay)

    # Paste Device Mockup
    canvas.paste(mockup_img, (mock_x, mock_y), mockup_img)

    # Save final high-res card
    out_dir = os.path.join(OUT_DIR, lang)
    out_file = os.path.join(out_dir, f"{config['index']}_{config['name']}.png")
    canvas.convert("RGB").save(out_file, "PNG", quality=100)
    print(f"[{lang.upper()}] Generated: {out_file}")

# 5 THEMES & AMBIANCES CONFIGURATION
CONFIGS = [
    {
        "index": "01",
        "name": "the_sanctuary",
        "id": "01_main_commute",
        "bg_color": (5, 14, 12, 255),
        "glow_pos": (645, 620),
        "glow_radius": 800,
        "glow_rgba": (0, 230, 118, 125),
        "accent_rgb": (0, 230, 118),
        "title_size": 84,
        "title_en": "FIND STILLNESS\nIN MOTION",
        "title_ja": "移動を、\n静寂の聖域へ。",
        "title_tr": "HAREKETİN İÇİNDE\nDERİN SESSİZLİK"
    },
    {
        "index": "02",
        "name": "sound_curation",
        "id": "02_sound_mixer",
        "bg_color": (16, 10, 4, 255),
        "glow_pos": (645, 640),
        "glow_radius": 800,
        "glow_rgba": (255, 140, 20, 125),
        "accent_rgb": (255, 167, 38),
        "title_size": 84,
        "title_en": "CURATE YOUR\nHARMONY",
        "title_ja": "音を、自在に\n編み上げる。",
        "title_tr": "KENDİ ARMONİNİ\nÖZGÜRCE YARAT"
    },
    {
        "index": "03",
        "name": "living_timer",
        "id": "03_reset_timer",
        "bg_color": (2, 14, 20, 255),
        "glow_pos": (645, 620),
        "glow_radius": 800,
        "glow_rgba": (0, 229, 255, 125),
        "accent_rgb": (0, 229, 255),
        "title_size": 84,
        "title_en": "FLOW WITH\nLIVING TIME",
        "title_ja": "時を忘れ、\n深く整う。",
        "title_tr": "YAŞAYAN ZAMANLA\nYENİDEN DOĞ"
    },
    {
        "index": "04",
        "name": "polar_aurora",
        "id": "04_aurora_sleep",
        "bg_color": (8, 6, 20, 255),
        "glow_pos": (645, 640),
        "glow_radius": 800,
        "glow_rgba": (140, 90, 255, 125),
        "accent_rgb": (186, 104, 200),
        "title_size": 84,
        "title_en": "DRIFT INTO\nDEEP REST",
        "title_ja": "至福の眠りへ、\n漂う。",
        "title_tr": "KUTUP AURORASIYLA\nDERİN UYKU"
    },
    {
        "index": "05",
        "name": "lifetime_sanctuary",
        "id": "05_paywall",
        "bg_color": (18, 14, 4, 255),
        "glow_pos": (645, 620),
        "glow_radius": 800,
        "glow_rgba": (255, 200, 60, 135),
        "accent_rgb": (255, 215, 64),
        "title_size": 84,
        "title_en": "YOUR LIFETIME\nSANCTUARY",
        "title_ja": "一生モノの静寂を、\nその手に。",
        "title_tr": "ÖMÜR BOYU\nKESİNTİSİZ HUZUR"
    }
]

if __name__ == "__main__":
    print("--- Starting Clean Editorial App Store Generation ---")
    for lang in ["en", "ja", "tr"]:
        print(f"\n================ Rendering Language: {lang.upper()} ================")
        for cfg in CONFIGS:
            render_screenshot_card(lang, cfg)
    print("\n--- ALL CLEAN APP STORE SCREENSHOTS GENERATED SUCCESSFULLY ---")
