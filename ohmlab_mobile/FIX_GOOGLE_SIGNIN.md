# Hướng dẫn sửa lỗi Google Sign-In (ApiException: 10)

## Vấn đề hiện tại
- SHA-1 Fingerprint đã thêm vào Firebase: `ff:3b:d3:d5:d3:f6:57:9d:0f:7c:92:fd:0b:38:70:fb:88:5d:6f:f3`
- Vẫn gặp lỗi `ApiException: 10` (DEVELOPER_ERROR)
- OAuth Client ID trong code: `747574732204-fb83aashk3iitkulln90134qactf87cu.apps.googleusercontent.com`

## Nguyên nhân có thể
Lỗi `ApiException: 10` thường do **OAuth Client ID chưa được cấu hình đúng trong Google Cloud Console**, không chỉ Firebase.

## Các bước khắc phục

### Bước 1: Kiểm tra OAuth Client ID trong Google Cloud Console

1. Truy cập: https://console.cloud.google.com/
2. Chọn project của bạn (cùng project với Firebase)
3. Vào **APIs & Services** > **Credentials**
4. Tìm OAuth Client ID: `747574732204-fb83aashk3iitkulln90134qactf87cu`
5. **QUAN TRỌNG**: Đảm bảo đây là **Android OAuth Client ID**, không phải Web Client ID

### Bước 2: Kiểm tra và cấu hình Android OAuth Client ID

Nếu OAuth Client ID này là **Web Client ID**:
- ❌ **Sai**: Đang dùng Web Client ID cho Android
- ✅ **Đúng**: Cần tạo Android OAuth Client ID riêng

#### Cách tạo Android OAuth Client ID mới:

1. Trong Google Cloud Console > **Credentials**
2. Click **+ CREATE CREDENTIALS** > **OAuth client ID**
3. Chọn **Application type**: **Android**
4. Nhập thông tin:
   - **Name**: `Android Client - ohmlab_mobile` (hoặc tên bạn muốn)
   - **Package name**: `com.fuhcm.ohmlab`
   - **SHA-1 certificate fingerprint**: `ff:3b:d3:d5:d3:f6:57:9d:0f:7c:92:fd:0b:38:70:fb:88:5d:6f:f3`
5. Click **CREATE**
6. **Copy OAuth Client ID mới** (dạng: `xxxxx-xxxxx.apps.googleusercontent.com`)

### Bước 3: Cập nhật code với OAuth Client ID đúng

Cập nhật file `lib/screens/login.dart` với OAuth Client ID mới (Android Client ID).

**Nếu OAuth Client ID hiện tại là Android Client ID:**
- Kiểm tra xem SHA-1 fingerprint đã được thêm vào chưa
- Trong Google Cloud Console > Credentials > Click vào OAuth Client ID
- Kiểm tra phần **SHA certificate fingerprints**
- Nếu chưa có, click **+ ADD SHA-1** và thêm: `ff:3b:d3:d5:d3:f6:57:9d:0f:7c:92:fd:0b:38:70:fb:88:5d:6f:f3`

### Bước 4: Kiểm tra Package Name

Đảm bảo package name trong code khớp:
- **Android**: `com.fuhcm.ohmlab` (trong `android/app/build.gradle.kts`)
- **OAuth Client ID**: `com.fuhcm.ohmlab` (trong Google Cloud Console)

### Bước 5: Rebuild và test

1. Xóa app trên thiết bị/emulator
2. Clean build:
   ```bash
   flutter clean
   flutter pub get
   ```
3. Rebuild app:
   ```bash
   flutter run
   ```
4. Đợi 5-10 phút để cấu hình có hiệu lực
5. Thử đăng nhập Google lại

## Kiểm tra nhanh

Sau khi cấu hình, kiểm tra:

✅ **Firebase Console**:
- SHA-1 fingerprint đã được thêm: `ff:3b:d3:d5:d3:f6:57:9d:0f:7c:92:fd:0b:38:70:fb:88:5d:6f:f3`
- Package name: `com.fuhcm.ohmlab`

✅ **Google Cloud Console**:
- Android OAuth Client ID tồn tại
- Package name: `com.fuhcm.ohmlab`
- SHA-1 fingerprint: `ff:3b:d3:d5:d3:f6:57:9d:0f:7c:92:fd:0b:38:70:fb:88:5d:6f:f3`
- OAuth Client ID trong code khớp với Android OAuth Client ID

✅ **Code**:
- OAuth Client ID đúng (Android Client ID, không phải Web)
- Package name khớp

## Lưu ý quan trọng

1. **SHA-1 cần được thêm vào CẢ HAI nơi**:
   - Firebase Console (đã thêm ✓)
   - Google Cloud Console > OAuth Client ID (cần kiểm tra!)

2. **OAuth Client ID phải là Android Client ID**, không phải Web Client ID

3. **Thời gian áp dụng**: Sau khi thêm SHA-1, có thể mất 5-10 phút để có hiệu lực

4. **Nếu vẫn lỗi**: Kiểm tra xem có đang dùng **release keystore** không. Nếu có, cần thêm SHA-1 của release keystore vào cả Firebase và Google Cloud Console.

