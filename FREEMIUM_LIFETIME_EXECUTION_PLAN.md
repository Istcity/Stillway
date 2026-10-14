# Stillway — Freemium & Lifetime Tek Seferlik Ödeme Dönüşüm Planı (v1.1)

Bu döküman, **Stillway: Neural Ambient Audio** uygulamasının mevcut "Peşin $19.99 (Upfront Paid)" modelinden, yüksek dönüşüm sağlayan **"Ücretsiz İndirme + Tek Seferlik Ömür Boyu Satın Alma ($8.99 Lifetime IAP)"** modeline geçişi ve tespit edilen tüm UX/Vitrin eksikliklerinin giderilmesi için hazırlanmış eksiksiz uygulama planıdır.

Evdeki Mac bilgisayarınızda **Antigravity**'ye *"FREEMIUM_LIFETIME_EXECUTION_PLAN.md planını uygula"* dediğinizde, agent aşağıdaki adımları sırasıyla otomatik olarak gerçekleştirecektir.

---

## 📌 Yönetici Özeti (Neden Bu Değişiklik Yapılıyor?)
1. **Mevcut Durum:** Uygulama mağazada peşin $19.99 olduğu için 600 kişi mağaza sayfasına bakmış ancak sıfır yorum, peşin fiyat bariyeri ve soyut vitrin metinleri nedeniyle indirme ve satış 0 kalmıştır.
2. **Hedeflenen Model:**
   * **İndirme:** Ücretsiz (Kapı tamamen açık).
   * **Ücretsiz Kanca (Hook):** Kullanıcı en az 1-2 atmosferi (örn. *Deep Train*, *Tokyo Rain*, *Study Cat*, *Aurora Ocean*) sınırsız dinleyebilir.
   * **Hemen Ses (Time-to-Sound < 3s):** Uygulama açıldığı anda kullanıcıyı izinlerle boğmadan arka planda derin ses yavaşça yükselir.
   * **Gizlilik Güveni:** Konum izni istenmeden önce kullanıcıya cihazda kaldığı ve takip edilmediği açıkça anlatılır.
   * **Fayda Odaklı Vitrin:** Ekran görüntüleri şiirsel edebiyat yerine doğrudan müşteri problemini çözen net fonksiyonel başlıklarla yenilenir.
   * **Gelir Modeli:** Sıfır Abonelik. Tek seferlik ömür boyu kilit açma: **$8.99 / 299 TL / ¥1,500 (Non-Consumable IAP)**.
   * **Puanlama (Rating):** Kullanıcı kesintisiz 3 dakika ses dinlediğinde otomatik Apple değerlendirme kutucuğu açılır.
   * **Reklam (ASA Basic):** $50 bütçe ile tavan indirme maliyeti (Max CPI) $1.10 olarak ayarlanır.

---

## FAZ 1: Swift & SwiftUI Kod Değişiklikleri (Mac Antigravity Görevleri)

### 1.1 `PurchaseManager.swift` Düzenlemesi
**Dosya:** `Stillway/Core/Store/PurchaseManager.swift`
* **Sorun:** Mevcut kodda `var isPro = true` varsayılan olarak `true` başlatılıyor ve `refreshEntitlements` içinde entitlement bulunamazsa `isPro` kapatılmıyor.
* **Yapılacak Değişiklik:**
  1. `var isPro = false` olarak başlatılacak.
  2. `refreshEntitlements()` metodu StoreKit 2'den gelen doğrulanmış işlemleri kontrol edecek; eğer `com.sinannergiz.stillway.pro` satın alınmışsa `isPro = true`, alınmamışsa `isPro = false` yapacak.
  3. `purchase()` ve `restorePurchases()` akışları kullanıcı tercihlerine (`UserPreferences.isPro`) senkronize edilecek.

```swift
// GÜNCELLENECEK refreshEntitlements():
private func refreshEntitlements() async {
    if StillwayTesting.unlockAllFeatures || UserDefaults.standard.bool(forKey: "stillway.isPro.debug") {
        isPro = true
        return
    }
    
    var hasProAccess = false
    for await entitlement in Transaction.currentEntitlements {
        if case .verified(let transaction) = entitlement, transaction.productID == Self.proProductID {
            hasProAccess = true
            break
        }
    }
    self.isPro = hasProAccess
}
```

---

### 1.2 `StillwayApp.swift` İçindeki Sabit Pro Zorlamasını Kaldırma
**Dosya:** `Stillway/App/StillwayApp.swift`
* **Sorun:** 44-45. satırlarda upfront paid model için `prefs.isPro = true` hardcoded bırakılmış.
* **Yapılacak Değişiklik:**
  * 44 ve 45. satırlardaki `prefs.isPro = true` kaldırılacak.
  * Yerine StoreKit `PurchaseManager` durumuna bağlanacak veya başlangıçta `prefs.isPro = store.isPro` olarak ayarlanacak.

---

### 1.3 `MainView.swift` İçindeki Pro Değerlerini Düzeltme
**Dosya:** `Stillway/Views/Main/MainView.swift`
* **Sorun:** 542 ve 546. satırlarda ilk başlangıçta `isPro = true` set ediliyor.
* **Yapılacak Değişiklik:**
  * Zoraki `isPro = true` atamaları temizlenecek. Kullanıcının pro durumu StoreKit verisine bırakılacak.

---

### 1.4 `ProPaywallView.swift` Fiyat ve "Sıfır Abonelik" Damgası
**Dosya:** `Stillway/Views/Sheets/ProPaywallView.swift`
* **Yapılacak Değişiklik:**
  1. Fallback fiyatlar güncellenecek:
     * TR: `"299 TL"` (veya `"249 TL"`)
     * JA: `"¥1,500"`
     * US/Global: `"$8.99"`
  2. Paywall'un en üstüne net ve çarpıcı bir rozet eklenecek:
     > **"❌ SIFIR ABONELİK • ❌ SIFIR GİZLİ ÜCRET"**  
     > **" TEK SEFERLİK ÖDEME — ÖMÜR BOYU KULLANIN"**
  3. Satın alma butonunun altına açıkça *"One-time purchase. Never renews. Family Sharing enabled."* yazılacak.

---

### 1.5 `Stillway.storekit` Test Dosyası Güncellemesi
**Dosya:** `Stillway.storekit`
* `displayPrice`: `"8.99"` olarak güncellenecek.
* Xcode StoreKit test ortamında simülasyonun $8.99 olarak çalışması sağlanacak.

---

### 1.6 Otomatik Puan İsteme (App Store Review Prompt)
**Dosya:** `Stillway/Views/Main/MainView.swift`
* **Hedef:** Kullanıcıyı rahatsız etmeden, sesi kesintisiz 3 dakika (180 sn) dinlediğinde (ürünü beğendiği rahatlama anında) Apple'ın yerel puanlama kutucuğunu çıkarmak.
* **Kod:**
  ```swift
  import StoreKit

  @Environment(\.requestReview) private var requestReview

  // Ses oynatılırken timer ile 180 saniye dolduğunda ve daha önce sorulmadıysa:
  if continuousPlaybackSeconds >= 180 && !hasRequestedReview {
      requestReview()
      hasRequestedReview = true
      UserDefaults.standard.set(true, forKey: "hasRequestedAppReview")
  }
  ```

---

### 1.7 İlk Ses Kancası (Immediate Sound Fade-In — Time to Sound < 3s)
**Dosya:** `Stillway/App/StillwayApp.swift` & `Stillway/Views/Main/MainView.swift`
* **Sorun:** Kullanıcı uygulamayı ilk açtığında izinler veya sessiz bir boşlukla karşılaşırsa sabırsızlıkla uygulamadan çıkabilir.
* **Yapılacak Değişiklik:**
  * Uygulama ilk açıldığı anda ücretsiz kütüphaneden varsayılan bir ses (*Deep Train* veya *Tokyo Rain*) 0.1 volümden başlayarak 2 saniye içinde 0.6 volüme yavaşça yükselsin (smooth fade-in).
  * Kullanıcı kulaklığını taktığı anda anında o 48kHz stereo derinliği hissetsin.

---

### 1.8 Konum ve Hareket İzinleri Öncesi Gizlilik/Güven Kartı (Pre-Permission Privacy Primer)
**Dosya:** `Stillway/Views/Onboarding/OnboardingView.swift` veya izin tetikleyicisi
* **Sorun:** Sistem seviyesindeki *"Stillway konumunuza her zaman erişmek istiyor"* kutucuğu kullanıcıda "casus yazılım / takip" şüphesi yaratır.
* **Yapılacak Değişiklik:**
  * Apple'ın sistem izni kutucuğu çıkmadan önce şık bir cam (glassmorphic) bilgi kartı gösterilsin:
    > **🔒 %100 Cihaz İçi & Sıfır Bulut Takibi**  
    > *"Konumunuz ve hareketiniz asla telefonunuzdan dışarı çıkmaz, sunucuya gönderilmez. Sadece metroya veya trene bindiğinizi anlayıp arka planda sesi otomatik başlatmak için cihaz üzerinde işlenir."*
  * Kullanıcı bu karta "Anladım, Devam Et" dediğinde Apple'ın sistem izin penceresi tetiklensin.

---

### 1.9 Fayda Odaklı Vitrin Başlıkları (Utility-First Screenshots Generator)
**Dosya:** `Stillway/screenshots_studio/generate_app_store_screenshots.py`
* **Sorun:** Mağaza ekran görüntülerindeki başlıklar fazla felsefi/şiirsel ("Hareketin İçinde Derin Sessizlik", "Yaşayan Zamanla Yeniden Doğ"). Müşteri problemini net anlatmıyor.
* **Yapılacak Değişiklik:** Başlık ve alt başlık konfigürasyonu fonksiyonel faydayla güncellenecek:
  * **Kart 1 (Commute):**
    * *TR:* **METRO & ŞEHİR GÜRÜLTÜSÜNÜ ERİTİN**  
      *Alt Metin:* Tokyo & Paris Metrosu için Akustik Maskeleme • %100 Çevrimdışı
    * *EN:* **DISSOLVE TRANSIT & SUBWAY NOISE**  
      *Sub:* On-device acoustic masking for Tokyo & Paris transit • 100% Offline
    * *JA:* **地下鉄の騒音を、一瞬で溶かす。**  
      *Sub:* 東京メトロ・新幹線対応の音響マスキング • 完全オフライン
  * **Kart 2 (Focus / Mixer):**
    * *TR:* **GERÇEK BINAURAL ODAKLANMA (ALPHA & THETA)**  
      *Alt Metin:* Bilimsel Beyin Dalgası Sentezi ve Çok Katmanlı Yağmur Mikseri
    * *EN:* **REAL BINAURAL FLOW (ALPHA & THETA)**  
      *Sub:* Science-backed neural synthesis with generative rain mixer
  * **Kart 3 (Living Clock & Breath):**
    * *TR:* **HAPTİK KUTU NEFES VE OLED MASA SAATİ**  
      *Alt Metin:* Ekrana bakmadan 4-4-4-4 nefes rehberi ve estetik komodin saati
    * *EN:* **HAPTIC BOX BREATHING & LIVING OLED CLOCK**  
      *Sub:* Eyes-closed 4-4-4-4 mindfulness with minimal StandBy clock
  * **Kart 4 (Sleep):**
    * *TR:* **DERİN UYKU VE KUTUP AURORASI**  
      *Alt Metin:* Düz yüzey komodin tespiti ve gerçek siyah OLED pil tasarrufu
    * *EN:* **RESTORATIVE SLEEP & POLAR AURORA**  
      *Sub:* Bedside flat-surface detection with OLED true-black efficiency
  * **Kart 5 (Lifetime Paywall):**
    * *TR:* **ABONELİK YOK. BİR KEZ ÖDE, ÖMÜR BOYU KULLAN.**  
      *Alt Metin:* Aylık ücret yok. Tek seferlik $8.99 ile tüm akustik sığınaklara tam erişim.
    * *EN:* **NO SUBSCRIPTIONS. PAY ONCE, KEEP FOREVER.**  
      *Sub:* Zero monthly fees. One-time $8.99 unlock for all 12 sanctuaries.
* Bu değişiklik sonrası `python3 generate_app_store_screenshots.py` çalıştırılarak yeni görseller çıktı alınacak.

---

## FAZ 2: App Store Connect Güncellemeleri (Sizin Yapacağınız Adımlar)

Uygulamanın yeni kodunu Xcode'dan göndermeden önce veya gönderirken App Store Connect panelinde yapılması gereken adımlar:

### 2.1 Uygulama Fiyatını "Ücretsiz" Yapma
1. [App Store Connect](https://appstoreconnect.apple.com) → **My Apps** → **Stillway**.
2. Sol menüden **Pricing and Availability (Fiyatlandırma ve Kullanılabilirlik)** sekmesine tıklayın.
3. Fiyatı **$19.99** yerine **Free (Ücretsiz)** olarak değiştirip sağ üstten **Save** deyin.

---

### 2.2 In-App Purchase (Uygulama İçi Satın Alma) Ürünü Ekleme
1. Sol menüden **In-App Purchases (Uygulama İçi Satın Almalar)** sekmesine gelin.
2. **+** butonuna basın ve **Non-Consumable (Tüketilmeyen)** seçeneğini seçin:
   * **Reference Name:** `Stillway Lifetime Sanctuary Pass`
   * **Product ID:** `com.sinannergiz.stillway.pro` (Kodla birebir aynı olmalı!)
3. **Price Schedule (Fiyatlandırma):**
   * Tier seçin: **$8.99** (Türkiye için otomatik ~299 TL civarı çıkacaktır).
4. **Localization (Yerelleştirme):**
   * **English (US):** 
     * Title: `Stillway Pro: Lifetime Sanctuary`
     * Description: `Unlock all 12 ambient atmospheres, generative 3D clocks, and full sleep automation forever. No subscriptions.`
   * **Turkish:** 
     * Title: `Stillway Pro: Ömür Boyu Erişim`
     * Description: `Tüm 12 atmosfer, 3D saatler ve uyku otomasyonu. Tek seferlik ödeme, sıfır abonelik.`
5. **Review Screenshot:** Uygulamanın Paywall ekranının bir ekran görüntüsünü yükleyin.
6. **Save** ve **Submit for Review** (Yeni versiyon gönderirken bu IAP'yi de versiyona iliştirin).

---

### 2.3 Yeni Sürüm (v1.1) Hazırlama & Sürüm Notları (What's New)
Yeni bir sürüm (Version 1.1) oluşturun ve açıklamalara şunu yazın:

* **What's New (İngilizce):**
  > **Stillway is now Free to Download!**  
  > Experience our science-backed neural ambient audio sanctuaries immediately.  
  > • Free access to select deep focus and restorative sleep soundscapes.  
  > • Launch Special: Unlock the full Lifetime Sanctuary Pass for a one-time price of $8.99 (No subscriptions, ever).  
  > • On-device privacy primer and streamlined instant-audio playback.  
  > • Performance enhancements and refined haptic breathing rhythms.

* **What's New (Türkçe):**
  > **Stillway artık Ücretsiz İndirilebilir!**  
  > Akustik sığınaklarımızı ve 48kHz derin seslerimizi hemen keşfedin.  
  > • Temel odaklanma ve uyku atmosferleri tamamen ücretsiz.  
  > • Lansmana özel: Tek seferlik $8.99 (299 TL) ile ömür boyu tam erişim (Abonelik yok).  
  > • Açılışta anında ses deneyimi ve geliştirilmiş cihaz içi gizlilik koruması.  
  > • Haptik nefes rehberi ve ses motoru optimizasyonları.

---

### 2.4 App Preview Video (Önizleme Videosu) Ekleme (Önerilir)
* QuickTime veya iPhone ekran kaydı ile 15-20 saniyelik bir video çekin:
  1. Kulaklık takılı iken dalga formunun akışı (3 sn).
  2. Tokyo Metrosu sesinin ve binaural frekansın açılışı (5 sn).
  3. Gece saati / 3D polar aurora görselinin akışı (5 sn).
  4. Sonda: *"No Subscriptions. 100% Offline."* yazısı (3 sn).
* Bu video mağazada otomatik sesli/sessiz oynayarak sesin kalitesini kullanıcının doğrudan kulağına ulaştıracaktır.

---

## FAZ 3: Apple Search Ads Basic Reklam Stratejisi (50 USD Bütçe)

1. [Apple Search Ads](https://searchads.apple.com) panelinize gidin.
2. **Mevcut kampanyayı düzenleyin veya yeni bir Basic kampanya açın:**
   * **Monthly Budget (Bütçe):** `50 USD`
   * **Max CPI (İndirme Başına Maksimum Teklif):** `1.10 USD` (Apple daha yüksek önerse bile 1.10$ üstüne çıkmayın).
   * **Target Countries (Hedef Ülkeler):** 
     * United States (ABD)
     * United Kingdom (İngiltere)
     * Germany (Almanya)
     * Japan (Japonya) - *Stillway'in Tokyo/Metro teması Japonya'da çok yüksek organik dönüşüm alır.*
3. **Beklenen Sonuç:**
   * ~$1.10 maliyet ile **45 - 50 indirme**.
   * Bu 50 indirmeden uygulamanın içindeki $8.99'lık paketi 5-6 kişi aldığında kampanya kendi maliyetini çıkartır ve ilk 5 yıldızlı mağaza yorumlarınızı kazandırır.

---

## 🚀 Mac Antigravity İçin Hızlı Uygulama Emri

Mac'inizdeki terminalde veya Antigravity IDE'de bu repo açıkken şu komutu verin:

> *"FREEMIUM_LIFETIME_EXECUTION_PLAN.md dosyasındaki FAZ 1 kod ve script değişikliklerinin tümünü (PurchaseManager, StillwayApp, MainView, ProPaywallView, Stillway.storekit, Review Prompt, Time-to-sound fade-in, Gizlilik kartı ve Screenshots script güncellemesi) projeye uygula, derleme kontrolünü yap ve hazır hale getir."*
