import os
import time
import subprocess

BUNDLE_ID = "com.sinannergiz.stillway"
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
RAW_DIR = os.path.join(BASE_DIR, "raw")
os.makedirs(RAW_DIR, exist_ok=True)

# 5 Screen configurations featuring 5 distinct themes and ambiances
SCREENS = [
    {
        "id": "01_main_commute",
        "args": ["-bypassPaywall", "-context", "commute", "-sound", "tokyo_metro"],
        "wait": 2.6
    },
    {
        "id": "02_sound_mixer",
        "args": ["-bypassPaywall", "-context", "focus", "-sound", "autumn_432hz", "-secondary", "hygge_night", "-screen", "sounds"],
        "wait": 3.0
    },
    {
        "id": "03_reset_timer",
        "args": ["-bypassPaywall", "-context", "reset", "-sound", "rain_window"],
        "wait": 2.6
    },
    {
        "id": "04_aurora_sleep",
        "args": ["-bypassPaywall", "-context", "sleep", "-sound", "aurora_ocean"],
        "wait": 2.6
    },
    {
        "id": "05_paywall",
        "args": ["-forcePaywall"], # Enters ProPaywallView
        "wait": 2.6
    }
]

LANG_LOCALES = {
    "en": "en_US",
    "ja": "ja_JP",
    "tr": "tr_TR",
    "fr": "fr_FR"
}

def run_cmd(cmd):
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return res.stdout, res.stderr

def get_target_device_id():
    if "SIMULATOR_DEVICE_ID" in os.environ:
        return os.environ["SIMULATOR_DEVICE_ID"]
    out, _ = run_cmd("xcrun simctl list devices | grep '(Booted)'")
    for line in out.splitlines():
        if "(" in line and ")" in line:
            parts = line.split("(")
            if len(parts) >= 2:
                dev_id = parts[1].split(")")[0].strip()
                if len(dev_id) == 36:
                    return dev_id
    # Default device
    return "911C9ECF-93D6-49A1-9A5C-B12FE8C273EC"

def ensure_device_booted(device_id):
    out, _ = run_cmd(f"xcrun simctl list devices | grep {device_id}")
    if "(Booted)" not in out:
        print(f"Booting simulator {device_id}...")
        run_cmd(f"xcrun simctl boot {device_id}")
        time.sleep(3.5)

def capture_all():
    device_id = get_target_device_id()
    ensure_device_booted(device_id)
    print(f"=== STARTING RAW SCREENSHOT CAPTURE ON DEVICE {device_id} ===")
    run_cmd(f'xcrun simctl status_bar {device_id} override --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100')

    for lang, locale in LANG_LOCALES.items():
        print(f"\n--- Setting up and capturing for: {lang.upper()} ({locale}) ---")

        for sc in SCREENS:
            target_file = os.path.join(RAW_DIR, f"{lang}_{sc['id']}.png")
            print(f"-> Capturing {sc['id']} in {lang.upper()}...")

            # Terminate running instance
            run_cmd(f"xcrun simctl terminate {device_id} {BUNDLE_ID}")
            time.sleep(0.4)

            # Write UserDefaults directly before launching
            run_cmd(f"xcrun simctl spawn {device_id} defaults write {BUNDLE_ID} AppleLanguages -array {lang}")
            run_cmd(f"xcrun simctl spawn {device_id} defaults write {BUNDLE_ID} selectedLanguage {lang}")
            run_cmd(f"xcrun simctl spawn {device_id} defaults write {BUNDLE_ID} stillway.selectedLanguage {lang}")

            # Assemble launch command with system and in-app language args
            cmd_args = [
                "xcrun", "simctl", "launch", device_id, BUNDLE_ID,
                "-AppleLanguages", f"'({lang})'",
                "-AppleLocale", f"'{locale}'",
                "-language", lang
            ] + sc["args"]

            full_cmd = " ".join(cmd_args)
            run_cmd(full_cmd)

            # Wait for UI animations to settle
            time.sleep(sc["wait"])

            # Capture screenshot
            run_cmd(f"xcrun simctl io {device_id} screenshot {target_file}")
            if os.path.exists(target_file):
                print(f"   [OK] Saved: {target_file} ({os.path.getsize(target_file)} bytes)")
            else:
                print(f"   [ERROR] Failed to save {target_file}")

    print("\n=== ALL RAW SCREENSHOTS CAPTURED SUCCESSFULLY ===")

if __name__ == "__main__":
    capture_all()
