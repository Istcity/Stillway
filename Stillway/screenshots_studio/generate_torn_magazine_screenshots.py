import os
import math
import random
from PIL import Image, ImageDraw, ImageFont, ImageFilter

CANVAS_WIDTH = 1290
CANVAS_HEIGHT = 2796

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
RAW_DIR = os.path.join(BASE_DIR, "raw")
OUT_DIR = os.path.join(BASE_DIR, "output_torn_magazine")

for l in ["en", "ja", "tr"]:
    os.makedirs(os.path.join(OUT_DIR, l), exist_ok=True)

# Typography paths
DIDOT_FONT = "/System/Library/Fonts/Supplemental/Didot.ttc"
BODONI_FONT = "/System/Library/Fonts/Supplemental/Bodoni 72.ttc"
NEWYORK_FONT = "/System/Library/Fonts/NewYork.ttf"
SERIF_EN = DIDOT_FONT if os.path.exists(DIDOT_FONT) else (BODONI_FONT if os.path.exists(BODONI_FONT) else NEWYORK_FONT)

SERIF_JA = "/System/Library/Fonts/ヒラギノ明朝 ProN.ttc"
SANS_JA = "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc"
MONO_FONT = "/System/Library/Fonts/Monaco.dfont" if os.path.exists("/System/Library/Fonts/Monaco.dfont") else "/System/Library/Fonts/Menlo.ttc"

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

def generate_torn_edge(x1, x2, y_base, seed=42, amp=18, roughness=3.5, steps=500):
    points = []
    dx = (x2 - x1) / steps
    rng = random.Random(seed)
    for i in range(steps + 1):
        x = x1 + i * dx
        t = i / steps
        # Multi-octave natural paper tear harmonics
        h1 = math.sin(t * math.pi * 3.4) * amp
        h2 = math.sin(t * math.pi * 9.2 + 0.9) * (amp * 0.45)
        h3 = math.sin(t * math.pi * 22.0 + 2.1) * (amp * 0.22)
        # Micro cellulose fiber jitter & occasional deeper nick
        jitter = rng.uniform(-roughness, roughness)
        if rng.random() < 0.08:
            jitter += rng.choice([-roughness * 2.2, roughness * 2.2])
        y = y_base + h1 + h2 + h3 + jitter
        points.append((x, y))
    return points

def create_device_mockup(screenshot_path):
    mockup_w = 1040
    mockup_h = 2240
    corner_radius = 84
    border_thickness = 14

    device_img = Image.new("RGBA", (mockup_w, mockup_h), (0, 0, 0, 0))
    d_draw = ImageDraw.Draw(device_img)

    # Outer Titanium Frame with chamfer
    frame_color = (52, 58, 70, 255)
    d_draw.rounded_rectangle([0, 0, mockup_w, mockup_h], radius=corner_radius, fill=frame_color)
    d_draw.rounded_rectangle([0, 0, mockup_w, mockup_h], radius=corner_radius, outline=(95, 105, 125, 190), width=2)

    # Inner Bezel
    inner_margin = border_thickness
    bezel_rect = [inner_margin, inner_margin, mockup_w - inner_margin, mockup_h - inner_margin]
    d_draw.rounded_rectangle(bezel_rect, radius=corner_radius - 8, fill=(0, 0, 0, 255))

    # Clean UI Screenshot (no status bar)
    if os.path.exists(screenshot_path):
        raw_screen = Image.open(screenshot_path).convert("RGBA")
        screen_w = mockup_w - (inner_margin * 2)
        screen_h = mockup_h - (inner_margin * 2)
        resized_screen = raw_screen.resize((screen_w, screen_h), Image.Resampling.LANCZOS)

        mask = Image.new("L", (screen_w, screen_h), 0)
        mask_draw = ImageDraw.Draw(mask)
        mask_draw.rounded_rectangle([0, 0, screen_w, screen_h], radius=corner_radius - 12, fill=255)

        device_img.paste(resized_screen, (inner_margin, inner_margin), mask)

    # Dynamic Island
    island_w = 176
    island_h = 44
    island_x = (mockup_w - island_w) // 2
    island_y = inner_margin + 18
    d_draw.rounded_rectangle([island_x, island_y, island_x + island_w, island_y + island_h], radius=22, fill=(0, 0, 0, 255))

    # Subtle screen reflection
    reflection = Image.new("RGBA", (mockup_w, mockup_h), (0, 0, 0, 0))
    r_draw = ImageDraw.Draw(reflection)
    r_draw.polygon([(0, 0), (int(mockup_w * 0.75), 0), (0, int(mockup_h * 0.45))], fill=(255, 255, 255, 8))
    device_img = Image.alpha_composite(device_img, reflection)

    return device_img

def render_torn_magazine_card(lang, config):
    canvas = Image.new("RGBA", (CANVAS_WIDTH, CANVAS_HEIGHT), config["bg_color"])

    # 1. Atmospheric Ambient Glow
    glow_layer = Image.new("RGBA", (CANVAS_WIDTH, CANVAS_HEIGHT), (0, 0, 0, 0))
    g_draw = ImageDraw.Draw(glow_layer)
    draw_radial_glow(g_draw, config["glow_pos"], config["glow_radius"], config["glow_rgba"])
    draw_radial_glow(g_draw, (CANVAS_WIDTH // 2, 1450), int(config["glow_radius"] * 0.7), (config["glow_rgba"][0], config["glow_rgba"][1], config["glow_rgba"][2], int(config["glow_rgba"][3] * 0.55)))
    canvas = Image.alpha_composite(canvas, glow_layer)

    # 2. Render Device Mockup (Positioned so the torn paper header overlaps organically)
    raw_img_path = os.path.join(RAW_DIR, f"{lang}_{config['id']}.png")
    if not os.path.exists(raw_img_path):
        raw_img_path = os.path.join(RAW_DIR, f"{config['id']}.png")

    mockup_img = create_device_mockup(raw_img_path)
    mock_x = (CANVAS_WIDTH - mockup_img.width) // 2
    mock_y = 420

    # Soft ambient phone shadow
    shadow_overlay = Image.new("RGBA", (CANVAS_WIDTH, CANVAS_HEIGHT), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow_overlay)
    s_draw.rounded_rectangle([mock_x + 10, mock_y + 25, mock_x + mockup_img.width - 10, mock_y + mockup_img.height + 25], radius=90, fill=(0, 0, 0, 160))
    shadow_overlay = shadow_overlay.filter(ImageFilter.GaussianBlur(radius=32))
    canvas = Image.alpha_composite(canvas, shadow_overlay)
    canvas.paste(mockup_img, (mock_x, mock_y), mockup_img)

    # 3. Top Torn Magazine Paper Sheet (Yırtılmış Dergi Sayfası Katmanı)
    tear_seed = 100 + int(config["index"])
    tear_y = 475
    edge = generate_torn_edge(0, CANVAS_WIDTH, tear_y, seed=tear_seed, amp=18, roughness=3.8)

    # A. Drop shadow cast from torn paper down onto the phone and background
    paper_shadow = Image.new("RGBA", (CANVAS_WIDTH, CANVAS_HEIGHT), (0, 0, 0, 0))
    ps_draw = ImageDraw.Draw(paper_shadow)
    ps_poly = [(0, 0)] + [(p[0], p[1] + 18) for p in edge] + [(CANVAS_WIDTH, 0)]
    ps_draw.polygon(ps_poly, fill=(0, 0, 0, 215))
    paper_shadow = paper_shadow.filter(ImageFilter.GaussianBlur(radius=22))
    canvas = Image.alpha_composite(canvas, paper_shadow)

    # B. Exposed white cellulose fiber edge (Yırtık kağıt lifleri)
    fiber_fringe = Image.new("RGBA", (CANVAS_WIDTH, CANVAS_HEIGHT), (0, 0, 0, 0))
    ff_draw = ImageDraw.Draw(fiber_fringe)
    ff_poly = [(0, 0)] + [(p[0], p[1] + 5) for p in edge] + [(CANVAS_WIDTH, 0)]
    ff_draw.polygon(ff_poly, fill=(245, 242, 235, 255))
    fiber_fringe = fiber_fringe.filter(ImageFilter.GaussianBlur(radius=1.2))
    canvas = Image.alpha_composite(canvas, fiber_fringe)

    # C. Main Luxury Matte Obsidian Paper Surface
    paper_leaf = Image.new("RGBA", (CANVAS_WIDTH, CANVAS_HEIGHT), (0, 0, 0, 0))
    pl_draw = ImageDraw.Draw(paper_leaf)
    pl_poly = [(0, 0)] + edge + [(CANVAS_WIDTH, 0)]
    pl_draw.polygon(pl_poly, fill=(18, 22, 28, 255))

    # Paper grain / tactile texture
    rng_noise = random.Random(tear_seed * 77)
    for _ in range(7500):
        nx = rng_noise.randint(0, CANVAS_WIDTH)
        ny = rng_noise.randint(0, tear_y + 35)
        pl_draw.point((nx, ny), fill=(255, 255, 255, rng_noise.randint(6, 18)))
    canvas = Image.alpha_composite(canvas, paper_leaf)

    # 4. Editorial Magazine Typography
    draw = ImageDraw.Draw(canvas)

    # A. Masthead / Issue Tag
    masthead_text = config[f"meta_{lang}"]
    masthead_font_path = SANS_JA if lang == "ja" else MONO_FONT
    masthead_font = get_font(masthead_font_path, 25)
    bbox_m = masthead_font.getbbox(masthead_text)
    mw = bbox_m[2] - bbox_m[0]
    draw.text(((CANVAS_WIDTH - mw) // 2, 88), masthead_text, font=masthead_font, fill=(185, 195, 210, 210))

    # B. Main High-Fashion Magazine Title
    serif_font_path = SERIF_JA if lang == "ja" else SERIF_EN
    title_size = config.get("title_size", 84)
    title_font = get_font(serif_font_path, title_size)
    accent_rgb = config.get("accent_rgb", (255, 255, 255))

    title_text = config[f"title_{lang}"]
    lines = title_text.split("\n")
    y_text = 152
    line_h = title_size + 14

    for idx, line in enumerate(lines):
        bbox_l = title_font.getbbox(line)
        lw = bbox_l[2] - bbox_l[0]
        lx = (CANVAS_WIDTH - lw) // 2
        ly = y_text + (idx * line_h)

        col = (252, 252, 250, 255) if idx == 0 else (accent_rgb[0], accent_rgb[1], accent_rgb[2], 255)
        # Stamped ink shadow
        draw.text((lx + 2, ly + 3), line, font=title_font, fill=(0, 0, 0, 175))
        draw.text((lx, ly), line, font=title_font, fill=col)

    # 5. Bottom Ripped Corner Scrap (Magazine Issue & Spec Stamp)
    corner_y = CANVAS_HEIGHT - 125
    c_edge = generate_torn_edge(CANVAS_WIDTH - 440, CANVAS_WIDTH, corner_y, seed=tear_seed + 50, amp=10, roughness=3)

    c_shadow = Image.new("RGBA", (CANVAS_WIDTH, CANVAS_HEIGHT), (0, 0, 0, 0))
    cs_draw = ImageDraw.Draw(c_shadow)
    cs_poly = [(CANVAS_WIDTH - 440, CANVAS_HEIGHT)] + [(p[0], p[1] - 8) for p in c_edge] + [(CANVAS_WIDTH, CANVAS_HEIGHT)]
    cs_draw.polygon(cs_poly, fill=(0, 0, 0, 150))
    c_shadow = c_shadow.filter(ImageFilter.GaussianBlur(radius=16))
    canvas = Image.alpha_composite(canvas, c_shadow)

    c_fringe = Image.new("RGBA", (CANVAS_WIDTH, CANVAS_HEIGHT), (0, 0, 0, 0))
    cf_draw = ImageDraw.Draw(c_fringe)
    cf_poly = [(CANVAS_WIDTH - 440, CANVAS_HEIGHT)] + [(p[0], p[1] - 4) for p in c_edge] + [(CANVAS_WIDTH, CANVAS_HEIGHT)]
    cf_draw.polygon(cf_poly, fill=(245, 242, 235, 255))
    canvas = Image.alpha_composite(canvas, c_fringe)

    c_paper = Image.new("RGBA", (CANVAS_WIDTH, CANVAS_HEIGHT), (0, 0, 0, 0))
    cp_draw = ImageDraw.Draw(c_paper)
    cp_poly = [(CANVAS_WIDTH - 440, CANVAS_HEIGHT)] + c_edge + [(CANVAS_WIDTH, CANVAS_HEIGHT)]
    cp_draw.polygon(cp_poly, fill=(24, 28, 36, 255))
    canvas = Image.alpha_composite(canvas, c_paper)

    # Text on ripped scrap
    draw = ImageDraw.Draw(canvas)
    stamp_text = config[f"badge_{lang}"]
    stamp_font_path = SANS_JA if lang == "ja" else MONO_FONT
    stamp_font = get_font(stamp_font_path, 21)
    bbox_s = stamp_font.getbbox(stamp_text)
    sw = bbox_s[2] - bbox_s[0]
    draw.text((CANVAS_WIDTH - max(sw + 40, 420), CANVAS_HEIGHT - 80), stamp_text, font=stamp_font, fill=(accent_rgb[0], accent_rgb[1], accent_rgb[2], 240))

    # Save final torn magazine card
    out_dir = os.path.join(OUT_DIR, lang)
    out_file = os.path.join(out_dir, f"{config['index']}_{config['name']}.png")
    canvas.convert("RGB").save(out_file, "PNG", quality=100)
    print(f"[TORN MAGAZINE // {lang.upper()}] Saved: {out_file}")

# 5 THEMES & AMBIANCES
CONFIGS = [
    {
        "index": "01",
        "name": "the_sanctuary",
        "id": "01_main_commute",
        "bg_color": (5, 14, 12, 255),
        "glow_pos": (645, 680),
        "glow_radius": 850,
        "glow_rgba": (0, 230, 118, 130),
        "accent_rgb": (0, 230, 118),
        "title_size": 84,
        "meta_en": "STILLWAY EDITORIAL // VOL. 01 • SPATIAL SANCTUARY",
        "meta_ja": "STILLWAY 創刊号 // 第01号 • 移動と静寂の聖域",
        "meta_tr": "STILLWAY DERGİ // SAYI 01 • YOLCULUK SIĞINAĞI",
        "title_en": "FIND STILLNESS\nIN MOTION",
        "title_ja": "移動を、\n静寂の聖域へ。",
        "title_tr": "HAREKETİN İÇİNDE\nDERİN SESSİZLİK",
        "badge_en": "✦ 48kHz STEREO NEURO-ACOUSTIC",
        "badge_ja": "★ 48kHz 立体音響 • 端末内生成",
        "badge_tr": "✦ 48kHz ÇİFT KANALLI STEREO SES"
    },
    {
        "index": "02",
        "name": "sound_curation",
        "id": "02_sound_mixer",
        "bg_color": (16, 10, 4, 255),
        "glow_pos": (645, 700),
        "glow_radius": 850,
        "glow_rgba": (255, 140, 20, 130),
        "accent_rgb": (255, 167, 38),
        "title_size": 84,
        "meta_en": "STILLWAY EDITORIAL // VOL. 02 • LAYERED HARMONY",
        "meta_ja": "STILLWAY 第02号 // 音響編纂 • 二層構造ミキサー",
        "meta_tr": "STILLWAY DERGİ // SAYI 02 • ÇİFT KATMANLI MİKS",
        "title_en": "CURATE YOUR\nHARMONY",
        "title_ja": "音を、自在に\n編み上げる。",
        "title_tr": "KENDİ ARMONİNİ\nÖZGÜRCE YARAT",
        "badge_en": "✦ DUAL-LAYER MIXER • 432Hz HARMONY",
        "badge_ja": "★ 24マスター音源 • 432Hz調律",
        "badge_tr": "✦ ÇİFT KATMANLI MİKSER • 432Hz SOLFEJ"
    },
    {
        "index": "03",
        "name": "living_timer",
        "id": "03_reset_timer",
        "bg_color": (2, 14, 20, 255),
        "glow_pos": (645, 680),
        "glow_radius": 850,
        "glow_rgba": (0, 229, 255, 130),
        "accent_rgb": (0, 229, 255),
        "title_size": 84,
        "meta_en": "STILLWAY EDITORIAL // VOL. 03 • LIVING WATER DIAL",
        "meta_ja": "STILLWAY 第03号 // 命宿る水時計 • 呼吸と時間の循環",
        "meta_tr": "STILLWAY DERGİ // SAYI 03 • YAŞAYAN ZAMAN DÖNGÜSÜ",
        "title_en": "FLOW WITH\nLIVING TIME",
        "title_ja": "時を忘れ、\n深く整う。",
        "title_tr": "YAŞAYAN ZAMANLA\nYENİDEN DOĞ",
        "badge_en": "✦ LIVING WATER & SAND CLOCKS",
        "badge_ja": "★ 命宿る水時計 • 瞑想タイマー",
        "badge_tr": "✦ CANLI SU VE KUM SAATLERİ"
    },
    {
        "index": "04",
        "name": "polar_aurora",
        "id": "04_aurora_sleep",
        "bg_color": (8, 6, 20, 255),
        "glow_pos": (645, 700),
        "glow_radius": 850,
        "glow_rgba": (140, 90, 255, 130),
        "accent_rgb": (186, 104, 200),
        "title_size": 84,
        "meta_en": "STILLWAY EDITORIAL // VOL. 04 • POLAR AURORA NIGHT",
        "meta_ja": "STILLWAY 第04号 // 極北のオーロラ • 究極の回復睡眠",
        "meta_tr": "STILLWAY DERGİ // SAYI 04 • KUTUP AURORASI GECESİ",
        "title_en": "DRIFT INTO\nDEEP REST",
        "title_ja": "至福の眠りへ、\n漂う。",
        "title_tr": "KUTUP AURORASIYLA\nDERİN UYKU",
        "badge_en": "✦ 100% ON-DEVICE • PURE OFFLINE",
        "badge_ja": "★ 完全オフライン • 究極のプライバシー",
        "badge_tr": "✦ SIFIR REKLAM • %100 ÇEVRİMDIŞI"
    },
    {
        "index": "05",
        "name": "lifetime_sanctuary",
        "id": "05_paywall",
        "bg_color": (18, 14, 4, 255),
        "glow_pos": (645, 680),
        "glow_radius": 850,
        "glow_rgba": (255, 200, 60, 135),
        "accent_rgb": (255, 215, 64),
        "title_size": 84,
        "meta_en": "STILLWAY EDITORIAL // VOL. 05 • PERPETUAL SANCTUARY",
        "meta_ja": "STILLWAY 第05号 // 永久ライセンス • 買い切り型アクセス",
        "meta_tr": "STILLWAY DERGİ // SAYI 05 • ÖMÜR BOYU ERİŞİM VE HUZUR",
        "title_en": "YOUR LIFETIME\nSANCTUARY",
        "title_ja": "一生モノの静寂を、\nその手に。",
        "title_tr": "ÖMÜR BOYU\nKESİNTİSİZ HUZUR",
        "badge_en": "✦ LIFETIME ACCESS • ONE-TIME PURCHASE",
        "badge_ja": "★ 買い切り型 • 永久ライセンス",
        "badge_tr": "✦ ÖMÜR BOYU ERİŞİM • TEK SEFERLİK SATIN ALIM"
    }
]

if __name__ == "__main__":
    print("--- Starting Torn Magazine Editorial Screenshot Generation ---")
    for lang in ["en", "ja", "tr"]:
        print(f"\nRendering Torn Magazine Edition for: {lang.upper()}")
        for cfg in CONFIGS:
            render_torn_magazine_card(lang, cfg)
    print("\n--- ALL TORN MAGAZINE SCREENSHOTS GENERATED SUCCESSFULLY ---")
