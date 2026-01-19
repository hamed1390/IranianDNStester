# DNS Tester

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**A simple and fast DNS server tester for DNSTT tunnel usage**

[English](#english) | [فارسی](#فارسی)

</div>

---

## English

### Overview

DNS Tester is a Flutter application designed to test DNS servers for optimal performance with DNSTT (DNS Tunnel) connections. It helps users find the fastest and most reliable DNS servers from a list of 7,800+ public DNS servers.

### Features

- ✅ **Fast DNS Testing** - Tests DNS servers using real UDP packets
- 🎲 **Random Selection** - Randomizes server selection for unbiased results
- 📊 **IP Range Filter** - Select specific IP ranges to test (2.x.x.x, 5.x.x.x, etc.)
- 📋 **One-tap Copy** - Copy DNS IP addresses with a single tap
- 🏆 **Best DNS Highlight** - Automatically shows the fastest server
- 🎨 **Clean UI** - Minimalist white & navy design
- 🌍 **Persian Support** - Full RTL and Farsi language support
- 📖 **Built-in Guide** - Step-by-step HTTP Injector setup instructions

### Installation

#### Prerequisites
- Flutter SDK 3.0+
- Android Studio / Xcode

#### Build from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/dns_tester_app.git
cd dns_tester_app

# Install dependencies
flutter pub get

# Run on device/emulator
flutter run

# Build release APK
flutter build apk --release
```

The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

### Usage

1. **Select Count** - Enter how many servers to test (default: 50)
2. **Filter Ranges** - Tap "انتخاب رنج" to select specific IP ranges
3. **Start Test** - Tap "شروع تست" to begin
4. **View Results** - Successful servers appear with green checkmarks
5. **Copy Best DNS** - Tap the copy icon next to the best result

### Using with HTTP Injector

1. Open HTTP Injector
2. Go to Settings → DNS Settings
3. Set Custom DNS 1 to the copied IP
4. Set Custom DNS 2 to `8.8.8.8` (backup)
5. Go back and tap Start

### Project Structure

```
dns_tester_app/
├── lib/
│   └── main.dart          # Main application code
├── assets/
│   └── dns_list.txt       # 7,800+ DNS server list
├── fonts/
│   ├── Vazirmatn-Regular.ttf
│   ├── Vazirmatn-Medium.ttf
│   └── Vazirmatn-Bold.ttf
└── pubspec.yaml
```

### How It Works

The app sends a standard DNS query (A record for google.com) to each server and measures the response time:

```dart
// 1. Create UDP socket
socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

// 2. Build DNS query packet
final packet = _buildDnsQuery(transactionId, "google.com");

// 3. Send to DNS server on port 53
socket.send(packet, serverAddress, 53);

// 4. Measure time until response
latency = stopwatch.elapsedMilliseconds;
```

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### License

This project is licensed under the MIT License.

---

## فارسی

### معرفی

DNS Tester یک برنامه Flutter برای تست سرورهای DNS با هدف استفاده بهینه در تونل‌های DNSTT است. این برنامه به شما کمک می‌کند تا سریع‌ترین و قابل اعتمادترین سرور DNS را از بین بیش از ۷۸۰۰ سرور عمومی پیدا کنید.

### ویژگی‌ها

- ✅ **تست سریع DNS** - تست سرورها با پکت‌های UDP واقعی
- 🎲 **انتخاب تصادفی** - انتخاب رندوم سرورها برای نتایج بی‌طرف
- 📊 **فیلتر رنج IP** - انتخاب رنج‌های خاص IP برای تست
- 📋 **کپی با یک کلیک** - کپی آدرس IP با یک لمس
- 🏆 **نمایش بهترین** - نمایش خودکار سریع‌ترین سرور
- 🎨 **طراحی ساده** - طراحی مینیمال سفید و سرمه‌ای
- 🌍 **پشتیبانی فارسی** - کاملا راست‌چین با زبان فارسی
- 📖 **راهنمای داخلی** - آموزش گام‌به‌گام تنظیمات HTTP Injector

### نصب

```bash
# کلون کردن مخزن
git clone https://github.com/yourusername/dns_tester_app.git
cd dns_tester_app

# نصب وابستگی‌ها
flutter pub get

# اجرا روی دستگاه/شبیه‌ساز
flutter run

# ساخت APK نهایی
flutter build apk --release
```

### نحوه استفاده

1. **تعداد را وارد کنید** - چند سرور تست شود (پیش‌فرض: ۵۰)
2. **رنج را انتخاب کنید** - روی "انتخاب رنج" بزنید
3. **تست را شروع کنید** - روی "شروع تست" بزنید
4. **نتایج را ببینید** - سرورهای موفق با تیک سبز نمایش داده می‌شوند
5. **کپی کنید** - روی آیکون کپی بزنید

### استفاده در HTTP Injector

1. HTTP Injector را باز کنید
2. به Settings → DNS Settings بروید
3. Custom DNS 1 را به IP کپی شده تنظیم کنید
4. Custom DNS 2 را به `8.8.8.8` تنظیم کنید
5. برگردید و روی Start بزنید

### عیب‌یابی

**همه تست‌ها ناموفق هستند:**
- اینترنت خود را بررسی کنید
- VPN را خاموش کنید
- تعداد کمتر (مثلا ۲۰) تست کنید

**برنامه کند است:**
- تعداد تست را کاهش دهید
- گوشی را ریستارت کنید

### لایسنس

این پروژه تحت لایسنس MIT منتشر شده است.

---

<div align="center">

**Made with ❤️ using Flutter**

⭐ اگر این پروژه مفید بود، لطفا استار بدهید!

</div>
