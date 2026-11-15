# CodexSkin

Skill cho **Codex desktop trên Windows 11**: chuẩn bị nền ảnh hoặc video lặp, chỉnh độ trong suốt và khởi chạy qua [Backdrop for Codex](https://github.com/TogawaSakiko-desuwa/backdrop-for-codex).

**Đây là skill điều phối một công cụ cộng đồng, không phải tính năng chính thức của OpenAI.** Gói không sửa `app.asar` hay thư mục WindowsApps. Nền chỉ được xem là áp dụng thành công sau khi kiểm tra trong cửa sổ Codex thực tế.

## Có gì trong gói?

- Chọn ảnh PNG/JPEG/WebP hoặc video MP4/WebM của bạn.
- Tạo/cập nhật preset, giữ các profile khác và sao lưu settings trước khi thay thế.
- Tải Backdrop v1.5.3 từ GitHub Releases, kiểm tra SHA-256 trước khi giải nén.
- Khởi chạy thông thường hoặc chờ người dùng thoát Codex để mở bằng chế độ có nền.
- Hướng dẫn khôi phục và chẩn đoán lỗi “Codex already running”.

Gói **không kèm ảnh anime, video cá nhân, tài khoản, cookie, API key hay binary của Backdrop**. Người sử dụng chọn media của họ. Hãy kiểm tra quyền sử dụng trước khi công khai artwork hoặc video.

## Cài skill vào Codex

Tải hoặc clone repository, rồi copy thư mục `skills/codex-skin` vào thư mục `skills` trong Codex home đang dùng. Mặc định trên Windows là `%USERPROFILE%\.codex\skills`; nếu đã đặt `CODEX_HOME`, dùng `%CODEX_HOME%\skills`.

Ví dụ trong PowerShell, tại thư mục repository:

```powershell
$codexSkinHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
$skillDestination = Join-Path $codexSkinHome 'skills\codex-skin'
if (Test-Path -LiteralPath $skillDestination) { throw 'Skill đã tồn tại. Sao lưu hoặc chọn cách cập nhật trước khi copy.' }
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $skillDestination) | Out-Null
Copy-Item -LiteralPath '.\skills\codex-skin' -Destination $skillDestination -Recurse
```

Mở chat mới hoặc tải lại Codex nếu skill chưa xuất hiện. Gọi skill:

```text
Dùng $codex-skin để làm theme Codex với video D:\Wallpapers\night.mp4,
tông tối, panel bán trong suốt. Kiểm tra nền thật sau khi khởi chạy.
```

Nếu muốn chạy script trực tiếp, xem [hướng dẫn runtime](skills/codex-skin/references/runtime.md).

## Yêu cầu và giới hạn

- Windows 11 x64, PowerShell 5.1 trở lên và Codex bản Store/MSIX chính thức.
- Cần mạng khi tải engine; bản portable là dependency riêng, được tải về máy của người dùng.
- Backdrop v1.5.3 được pin để tái lập, không bảo đảm tương thích mọi phiên bản Codex mới. Xem [release gốc](https://github.com/TogawaSakiko-desuwa/backdrop-for-codex/releases/tag/v1.5.3).
- Video có chuyển động thực phải là MP4/WebM có nội dung chuyển động. Skill không có mô hình tạo video tích hợp.
- Phiên Codex mở bằng icon thường có thể cần thoát hoàn toàn rồi mở qua companion. **Không coi preview là bằng chứng nền đã hoạt động.**
- Khi Backdrop chạy bằng CDP, phần mềm khác trên máy có thể tiếp cận giao diện debug có quyền cao. Người dùng tự đọc và xử lý thông báo của companion; script không tự chấp nhận. Thoát hoàn toàn Codex và Backdrop để kết thúc phiên debug.

## Kiểm tra trước khi phát hành

```powershell
& .\tests\Test-Helpers.ps1
```

Bộ kiểm tra dùng thư mục tạm riêng trong repository, không sửa settings thật và không khởi chạy Codex. Nó kiểm tra phân loại media, tính lặp lại của preset, backup, giữ nguyên xác nhận debug, từ chối schema lạ và `-WhatIf`. Chạy thử một nền trong Codex thật vẫn là bước kiểm chứng riêng.


## Nguồn và giấy phép

- Scripts và nội dung skill trong repository này: [MIT](LICENSE).
- [Backdrop for Codex](https://github.com/TogawaSakiko-desuwa/backdrop-for-codex): dependency độc lập, Apache-2.0; giữ nguyên giấy phép/notice khi sử dụng bản tải về.


Không có quan hệ tài trợ, chứng nhận hay liên kết chính thức với OpenAI, Anthropic hoặc các dự án upstream. Xem [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
