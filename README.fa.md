# RahVPN

[فارسی](README.fa.md) | [English](README.md)

RahVPN یک کلاینت غیررسمی برای هسته [Aether](https://github.com/CluvexStudio/Aether) است.

```
bash tools/android/setup.sh
```

این اسکریپت پروژه اندروید را آماده می‌کند و وابستگی‌های لازم را پیکربندی می‌کند.

```
flutter pub get
flutter devices
flutter run
```

برای ساخت APK دیباگ به‌جای اجرای مستقیم:

```
flutter build apk --debug
```

## امضای APK

APKهای نسخهٔ انتشار RahVPN با گواهی RSA ۴۰۹۶ بیتی امضا می‌شوند.

| Property             | Value                                                                                               |
| -------------------- | --------------------------------------------------------------------------------------------------- |
| Alias                | `rahvpn`                                                                                          |
| Key algorithm        | RSA 4096-bit                                                                                        |
| Signature algorithm  | SHA384withRSA                                                                                       |
| APK signature scheme | v2                                                                                                  |
| Certificate SHA-256  | `DF:9B:1D:C7:36:40:0E:69:28:2C:2A:D1:DA:75:71:58:9B:53:50:B4:A7:E2:2C:69:0B:58:63:89:30:40:66:46` |
| Certificate SHA-1    | `39:43:83:EA:68:5D:91:42:37:67:3D:5A:06:BA:4C:24:46:EE:B1:1B`                                     |
| Certificate validity | `2026-10-08 → 2054-02-23`                                                                        |

از ابزار apksigner اندروید (موجود در Android SDK Build Tools) برای تأیید امضا و نمایش جزئیات گواهی استفاده کن:

```
apksigner verify --verbose --print-certs app-arm64-v8a-release.apk
```

## اجرا روی لینوکس

بیلد دسکتاپ لینوکس به GTK 3، CMake، Ninja، Clang و کتابخانه‌های توسعهٔ Ayatana AppIndicator نیاز دارد. روی اوبونتو یا دبیان این‌ها را نصب کن:

```
sudo apt update
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev libayatana-appindicator3-dev liblzma-dev iptables iproute2 util-linux pkexec polkitd
```

هدف دسکتاپ لینوکس Flutter را فعال کن، باینری‌های لینوکس Aether/helper را برای ماشین خودت دانلود کن و برنامه را اجرا کن:

```
build/runtime deps (Debian/Ubuntu)
./tools/linux/setup_linux.sh      # در صورت نبودن، linux/ را می‌سازد و Aether + hev-socks5-tunnel را دانلود می‌کند
./tools/linux/install_linux_tun.sh # پیش‌نیازهای runtime مربوط به TUN را بررسی می‌کند
flutter run -d linux        # حالت توسعه
./tools/linux/package_linux.sh tar  # آرشیو قابل حمل: dist/rahvpn-linux-.tar.gz
./tools/linux/package_linux.sh deb  # پکیج دبیان/اوبونتو در dist/
./tools/linux/package_linux.sh rpm  # پکیج فدورا/RHEL در dist/
```


## 📥 Download APK

| Architecture | Download                                                                                                        |
| ------------ | --------------------------------------------------------------------------------------------------------------- |
| ARM64-v8a    | [**Download APK**](https://github.com/RahVPN/rah-app/releases/download/v0.2.3/app-arm64-v8a-release.apk)   |
| ARMv7        | [**Download APK**](https://github.com/RahVPN/rah-app/releases/download/v0.2.3/app-armeabi-v7a-release.apk) |
| x86_64       | [**Download APK**](https://github.com/RahVPN/rah-app/releases/download/v0.2.3/app-x86_64-release.apk)      |
| Universal    | [**Download APK**](https://github.com/RahVPN/rah-app/releases/download/v0.2.3/app-release.apk)             |

## 📥 Download Linux

| Architecture  | Download                                                                                                       |
| ------------- | -------------------------------------------------------------------------------------------------------------- |
| Debian/Ubuntu | [**Download APK**](https://github.com/RahVPN/rah-app/releases/download/v0.2.3/rahvpn_0.2.3_amd64.deb)     |
| Fedora/RHEL   | [**Download APK**](https://github.com/RahVPN/rah-app/releases/download/v0.2.3/rahvpn-0.2.3.x86_64.rpm)    |
|  tar.gz      | [**Download APK**](https://github.com/RahVPN/rah-app/releases/download/v0.2.3/rahvpn-linux-x86_64.tar.gz) |
