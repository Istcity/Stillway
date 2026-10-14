# Stillway — Freemium & Lifetime Tek Seferlik Ödeme Dönüşüm Planı (v1.1)

Bu döküman, **Stillway: Neural Ambient Audio** uygulamasının mevcut "Peşin $19.99 (Upfront Paid)" modelinden, yüksek dönüşüm sağlayan **"Ücretsiz İndirme + Tek Seferlik Ömür Boyu Satın Alma ($8.99 Lifetime IAP)"** modeline geçişi için hazırlanmış eksiksiz uygulama planıdır.

Evdeki Mac bilgisayarınızda **Antigravity**'ye *"FREEMIUM_LIFETIME_EXECUTION_PLAN.md planını uygula"* dediğinizde, agent aşağıdaki adımları sırasıyla otomatik olarak gerçekleştirecektir.

---

## 📌 Yönetici Özeti (Neden Bu Değişiklik Yapılıyor?)
1. **Mevcut Durum:** Uygulama mağazada peşin $19.99 olduğu için 600 kişi mağaza sayfasına bakmış ancak sıfır yorum ve peşin fiyat bariyeri nedeniyle indirme ve satış 0 kalmıştır.
2. **Hedeflenen Model:**
   * **İndirme:** Ücretsiz (Kapı tamamen açık).
   * **Ücretsiz Kanca (Hook):** Kullanıcı en az 1-2 atmosferi (örn. *Deep Train*, *Tokyo Rain*, *Study Cat*, *Aurora Ocean*) sınırsız dinleyebilir.
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

### 1.4 `ProPaywallView.swift` Fiyat ve Metin Güncellemesi
**Dosya:** `Stillway/Views/Sheets/ProPaywallView.swift`
* **Yapılacak Değişiklik:**
  1. Fallback fiyatlar güncellenecek:
     * TR: `"299 TL"` (veya `"249 TL"`)
     * JA: `"¥1,500"`
     * US/Global: `"$8.99"`
  2. Paywall üzerindeki metinlerde **"NO SUBSCRIPTIONS. PAY ONCE, KEEP FOREVER."** (Abonelik Yok, Bir Kez Öde Sonsuza Dek Sahip Ol) mesajı belirginleştirilecek.
  3. Satın alma butonunun altına *"One-time payment. Never renews."* ibaresi eklenecek.

---

### 1.5 `Stillway.storekit` Test Dosyası Güncellemesi
**Dosya:** `Stillway.storekit`
* `displayPrice`: `"8.99"` olarak güncellenecek.
* Xcode StoreKit test ortamında simülasyonun $8.99 olarak çalışması sağlanacak.

---

### 1.6 Otomatik Puan İsteme (App Store Review Prompt)
**Dosya:** `Stillway/Views/Main/MainView.swift` & `Stillway/Core/Audio/AudioEngine.swift`
* **Hedef:** Kullanıcıyı rahatsız etmeden, sesi kesintisiz 3 dakika (180 sn) dinlediğinde (yani ürünü beğendiği anda) Apple'ın resmi puanlama ekranını çıkarmak.
* **Kod:**
  ```swift
  import StoreKit

  // MainView içinde:
  @Environment(\.requestReview) private var requestReview

  // Ses oynatılırken timer ile 180 saniye dolduğunda ve daha önce sorulmadıysa:
  if continuousPlaybackSeconds >= 180 && !hasRequestedReview {
      requestReview()
      hasRequestedReview = true
      UserDefaults.standard.set(true, forKey: "hasRequestedAppReview")
  }
  ```

---

## FAZ 2: App Store Connect Güncellemeleri (Sizin Yapacağınız Adımlar)

Uygulamanın yeni kodunu Xcode'dan göndermeden önce veya gönderirken App Store Connect panelinde yapılması gereken 4 işlem:

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
  > • Performance enhancements and refined haptic breathing rhythms.

* **What's New (Türkçe):**
  > **Stillway artık Ücretsiz İndirilebilir!**  
  > Akustik sığınaklarımızı ve 48kHz derin seslerimizi hemen keşfedin.  
  > • Temel odaklanma ve uyku atmosferleri tamamen ücretsiz.  
  > • Lansmana özel: Tek seferlik $8.99 (299 TL) ile ömür boyu tam erişim (Abonelik yok).  
  > • Haptik nefes rehberi ve ses motoru optimizasyonları.

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

> *"FREEMIUM_LIFETIME_EXECUTION_PLAN.md dosyasındaki FAZ 1 kod değişikliklerini (PurchaseManager, StillwayApp, MainView, ProPaywallView, Stillway.storekit ve Review Prompt) projeye uygula, derleme kontrolünü yap ve hazır hale getir."*
