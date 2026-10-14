# Stillway — Freemium + Lifetime Access (Ömür Boyu) Uygulama ve Dağıtım Planı

Stillway için "Ömür Boyu Tek Seferlik Ödeme (Lifetime In-App Purchase)" ve "Ücretsiz İndirme + Freemium Deneyim" mimarisi planı ve uygulama durumudur.

---

## 🎯 MODEL ÖZETİ
- **İndirme:** Ücretsiz (App Store Free Download)
- **Ücretsiz Katman (Free Tier):** 12 temel master atmosfer (Tokyo Rain, Siber Neon Duman, Kıyı Dalgaları, Kuzey Işıkları, Kar Vadisi, Gece Ekspresi vb.), haptik nefes rehberi ve temel zamanlayıcı.
- **Stillway Pro (Lifetime Pass):** `com.sinannergiz.stillway.pro` (Non-Consumable, Ömür Boyu Tek Seferlik Satın Alma).
- **Fiyatlandırma:** $19.99 (US) / 999 TL (TR) / ¥3,000 (JA) / 19,99 € (FR/AB). Abonelik yok, gizli ücret yok, aile paylaşımı destekli.

---

## 🚀 FAZ 1: Freemium Temelleri & StoreKit 2 Entegrasyonu (TAMAMLANDI)

### 1. StoreKit 2 & Freemium Durum Yönetimi
- [x] **StoreKit Configuration (`Stillway.storekit`):**
  - Non-consumable Product: `com.sinannergiz.stillway.pro`
  - Çoklu dil ürün başlık ve açıklamaları (EN, TR, JA, FR).
  - Standart Lifetime fiyatlandırması: $19.99, 999 TL, ¥3,000, 19,99 €.
- [x] **Satın Alma Motoru (`PurchaseManager.swift`):**
  - Freemium için varsayılan `isPro = false`.
  - StoreKit 2 `Transaction.currentEntitlements` ve `Transaction.updates` ile anında yetki doğrulama.
  - App Store Satın Alımları Geri Yükleme (`restorePurchases()` / `AppStore.sync()`).
  - Simulator / Test ortamları için `-bypassPaywall` ve `-unlockPro` ile debug bypass desteği.

### 2. Modern & Kapatılabilir Paywall (`ProPaywallView.swift`)
- [x] **Soft Paywall Deneyimi:**
  - Sağ üstte kapatma butonu (`xmark.circle.fill`) ile modal ve tam ekran sunumlarda serbestçe kapatılabilme (App Store Review Kılavuzu 3.1.2 uyumlu).
  - Satın alma veya geri yükleme tamamlandığında otomatik kapanma.
  - Dinamik StoreKit fiyat formatı (yerel para birimi veya dil fallback'leri).
  - App Store zorunlu yasal linkleri: Gizlilik Politikası (`privacy.html`), Kullanım Koşulları (`terms.html`), Satın Alımları Geri Yükle.

### 3. Gizlilik Kartı & Besin Etiketi (`SettingsSheet.swift` & `PrivacyInfo.xcprivacy`)
- [x] **Gelişmiş Gizlilik Kartı (`SettingsSheet.swift`):**
  - Özel ikonlu vitrin: "100% OFFLINE", "On-Device", "Zero Tracking", "No Account".
  - Kullanıcı dostu gizlilik beyanı (`privacy_body`).
  - Doğrudan Gizlilik Politikası ve Kullanım Koşulları web bağlantıları (`openURL`).
- [x] **Apple Privacy Manifest (`PrivacyInfo.xcprivacy`):**
  - NSPrivacyTracking = false
  - Sıfır üçüncü parti izleyici, sıfır veri toplama beyanı.

### 4. Time-to-sound Fade-in & Akustik Yumuşaklık (`AudioEngine.swift`)
- [x] **Sıfır Patlama & Yumuşak Başlatma:**
  - `play(sound:fadeDuration:)` çağrıldığında mixer ses seviyesi anında 0.0'a çekilir, ardından belirlenen sürede (`fadeDuration: 1.2s`) logaritmik/lineer yumuşaklıkla hedeflenen seviyeye yükselir (pop/click seslerini tamamen engeller).
- [x] **Sesler Arası Geçiş (Crossfade):**
  - Çalışan bir ses varken yeni bir ses seçildiğinde `crossfade(to:duration:)` ile önceki ses yumuşakça sönümlenir ve yeni ses akıcı şekilde yükselir.

### 5. Akıllı Değerlendirme & Yorum İstemi (`StillwayReviewPrompter`)
- [x] **Döngüsel İstemler (`PurchaseManager.swift`):**
  - Başarılı tamamlanan 2. ve 5. seans sonrasında otomatik `SKStoreReviewController.requestReview(in: windowScene)` tetiklemesi.
  - Sürüm kontrolü ile aynı sürümde gereksiz tekrar istem yapılmaması.
- [x] **Ayarlar Ekranında Doğrudan Bağlantı:**
  - Ayarlar ekranı Gizlilik bölümünde "App Store'da Değerlendir / Rate Stillway" butonu (`openAppStoreReview()`).

### 6. Otomatik Ekran Görüntüsü Stüdyosu (`screenshots_studio/capture_all_screens.py`)
- [x] **Dinamik Simülatör & 4 Dil Desteği:**
  - Açık olan (Booted) simülatörü otomatik tespit etme veya hedef cihazı kendiliğinden başlatma (`ensure_device_booted`).
  - 4 dil desteği: İngilizce (`en_US`), Japonca (`ja_JP`), Türkçe (`tr_TR`), Fransızca (`fr_FR`).
  - Komut satırı argümanları ile ekranları (`-bypassPaywall`, `-forcePaywall`, `-sound`, `-context`) hatasız yakalama.
  - App Store Connect için hazır boyutlar (1290x2796 iPhone ve 2048x2732 13" iPad).

---

## 🔮 FAZ 2: Gelişmiş Özellik Kilitleme & Dönüşüm Artırıcılar (Gelecek Aşama)
- [ ] Ücretsiz kullanıcılar için 24 saatlik "Günün Premium Sesi" önizlemesi.
- [ ] Ses mikserinde ikincil katman için Pro kilit göstergesi ve önizleme modu.
- [ ] StandBy / Yatay masaüstü stüdyo modunda Pro rozeti entegrasyonu.

---

## 🏁 FAZ 3: Canlı Test & App Store Gönderim Doğrulaması (Gelecek Aşama)
- [ ] TestFlight Sandbox satın alma testi.
- [ ] App Store Connect IAP In-Review onay akışı.
- [ ] Production build (`xcodebuild archive`) ve App Store yükleme.
