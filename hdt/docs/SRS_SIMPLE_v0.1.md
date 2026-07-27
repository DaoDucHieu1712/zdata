# Đặc tả Yêu cầu Phần mềm (SRS)
## BongStudio Simple — v0.1
**Phiên bản tài liệu:** 0.1
**Nguồn tham chiếu:** SRS_v1.4.md (bản đầy đủ) — rút gọn phạm vi
**Ngày:** 2026-07-27
**Tóm tắt:** Đây là phiên bản **đơn giản hóa** của AnimeStudio AI. Mục tiêu: một ứng dụng
**chỉ dùng React** (front-end), **chạy local cho mục đích cá nhân**, cho phép người dùng tạo
nhanh **phim ngắn, vlog, video** bằng **AI đám mây (Cloud AI)**. Đã lược bỏ toàn bộ hạ tầng
AI cục bộ (Ollama, ComfyUI, F5-TTS, Celery, Redis, FastAPI), **cơ sở dữ liệu máy chủ**, quản
lý sản xuất/hợp đồng, kiểm duyệt, cổng phê duyệt và các tính năng dành cho studio. Chỉ giữ
lại luồng sáng tạo tối thiểu: **ý tưởng → kịch bản → phân cảnh → hình ảnh/video → lồng tiếng
→ xuất video**.

**Điểm nhấn giao diện (v0.1):**
- **React Flow** được dùng cho **cả hai** màn hình node-graph: (1) **Storyboard phân cảnh**
  (mỗi cảnh là một node, nối bằng edge chuyển cảnh) và (2) **Cấu hình pipeline AI** (nối từng
  công đoạn LLM/Image/Video/TTS tới Cloud AI Provider bằng cách kéo dây).
- **Cấu hình Cloud AI bằng giao diện trực quan**, không sửa file/JSON thủ công.
- **Không dùng cơ sở dữ liệu máy chủ (MariaDB/…);** dữ liệu lưu ngay trong trình duyệt để
  chạy local cá nhân.

---

## Mục lục

1. [Giới thiệu](#1-giới-thiệu)
2. [Mô tả tổng quan](#2-mô-tả-tổng-quan)
3. [Yêu cầu chức năng](#3-yêu-cầu-chức-năng)
   - 3.1 [Quản lý dự án](#31-quản-lý-dự-án)
   - 3.2 [Tạo kịch bản bằng AI](#32-tạo-kịch-bản-bằng-ai)
   - 3.3 [Phân cảnh (Storyboard)](#33-phân-cảnh-storyboard)
   - 3.4 [Sinh hình ảnh & video bằng Cloud AI](#34-sinh-hình-ảnh--video-bằng-cloud-ai)
   - 3.5 [Lồng tiếng & âm thanh](#35-lồng-tiếng--âm-thanh)
   - 3.6 [Cấu hình Cloud AI](#36-cấu-hình-cloud-ai)
   - 3.7 [Xuất video](#37-xuất-video)
4. [Yêu cầu phi chức năng](#4-yêu-cầu-phi-chức-năng)
5. [Giao diện ngoài](#5-giao-diện-ngoài)
6. [Yêu cầu dữ liệu](#6-yêu-cầu-dữ-liệu)
7. [Ràng buộc & Giả định](#7-ràng-buộc--giả-định)

---

## 1. Giới thiệu

### 1.1 Mục đích

Tài liệu này đặc tả yêu cầu cho **BongStudio Simple v0.1** — một ứng dụng web đơn giản giúp
người dùng cá nhân tạo **phim ngắn, vlog, video** bằng AI đám mây. Tài liệu dành cho lập
trình viên, QA và các bên liên quan.

### 1.2 Phạm vi

BongStudio Simple là một **ứng dụng React thuần (SPA)** chạy trên trình duyệt, **local cho
cá nhân**. Ứng dụng gọi trực tiếp các **nhà cung cấp AI đám mây** (Cloud AI) để sinh kịch
bản, hình ảnh, video và giọng nói. Không có AI cục bộ, không có backend, **không có cơ sở dữ
liệu máy chủ** — dữ liệu lưu trong trình duyệt.

**Trong phạm vi:**
- Tạo và quản lý dự án video (loại: `film` / `vlog` / `video`)
- Sinh kịch bản thô từ ý tưởng bằng Cloud LLM
- **Phân cảnh trực quan trên canvas React Flow** (cảnh = node, chuyển cảnh = edge)
- Sinh hình ảnh cho từng cảnh bằng Cloud AI (text-to-image)
- Sinh video clip ngắn cho từng cảnh bằng Cloud AI (image-to-video / text-to-video)
- Sinh giọng đọc (TTS) bằng Cloud AI cho lời thoại/thuyết minh
- **Cấu hình Cloud AI bằng giao diện trực quan**, gồm màn hình **node-graph React Flow** nối
  công đoạn ↔ provider (endpoint, API key, model)
- Xuất video hoàn chỉnh (ghép các cảnh)

**Ngoài phạm vi:**
- AI cục bộ (Ollama, ComfyUI, F5-TTS…) và mọi hạ tầng localhost
- Backend đầy đủ và **cơ sở dữ liệu máy chủ (MariaDB, PostgreSQL, …)**
- Nhiều người dùng / cộng tác thời gian thực
- Quản lý sản xuất: khách hàng, hợp đồng, ngân sách, mốc thời gian
- Kiểm duyệt nội dung/độ tuổi, kiểm tra bản quyền
- Cổng phê duyệt (approval gate) giữa các công đoạn
- Thư viện nhân vật/vật thể/animation nâng cao (chỉ giữ nhân vật đơn giản, tùy chọn)
- Ứng dụng di động gốc, huấn luyện mô hình AI riêng

### 1.3 Định nghĩa

| Thuật ngữ | Định nghĩa |
|---|---|
| **Dự án (Project)** | Thực thể cấp cao nhất chứa toàn bộ cảnh, kịch bản và cấu hình của một video |
| **Loại dự án** | `film` (phim ngắn nhiều cảnh), `vlog` (video kiểu nhật ký/thuyết minh), `video` (video ngắn tự do) |
| **Cảnh (Scene)** | Một đơn vị phân cảnh, tương ứng một shot/clip ngắn; hiển thị dưới dạng thẻ trong danh sách/lưới |
| **Kịch bản (Script)** | Văn bản kịch bản thô do AI sinh hoặc người dùng nhập, là đầu vào để tạo phân cảnh |
| **Cloud AI Provider** | Một API AI bên ngoài (LLM, image, video, TTS) truy cập qua HTTPS, định nghĩa bằng endpoint + API key + model_id |
| **Công đoạn (Stage)** | Một loại tác vụ AI: `llm` (kịch bản), `image` (hình ảnh), `video` (video), `tts` (giọng nói) |
| **Media mode** | Chế độ mỗi cảnh: `video` (sinh clip chuyển động) hoặc `image` (giữ ảnh tĩnh trong `duration_sec`) |
| **duration_sec** | Thời lượng cảnh tính bằng giây |
| **Job** | Một tác vụ gọi Cloud AI đang chạy (sinh ảnh/video/audio/kịch bản), có trạng thái tiến độ |

### 1.4 Tài liệu tham chiếu

- `docs/SRS_v1.4.md` — SRS bản đầy đủ (nguồn rút gọn)
- `docs/SRD_SIMPLE_v0.1.md` — Tài liệu thiết kế tương ứng
- Tài liệu React (`react`, `@xyflow/react` tùy chọn)
- Tài liệu API của các nhà cung cấp Cloud AI được cấu hình

---

## 2. Mô tả tổng quan

### 2.1 Bối cảnh sản phẩm

BongStudio Simple là **ứng dụng phía client (React SPA)**. Mọi dữ liệu dự án được lưu trong
trình duyệt (IndexedDB/localStorage). Các lời gọi AI đi thẳng từ trình duyệt tới Cloud AI
Provider (hoặc qua một proxy mỏng tùy chọn để bảo vệ API key — xem §7).

```
Trình duyệt (React SPA)
    │  HTTPS
    ▼
Cloud AI Provider(s)
    ├── Cloud LLM        (sinh kịch bản)
    ├── Cloud Image AI   (text-to-image)
    ├── Cloud Video AI   (image/text-to-video)
    └── Cloud TTS        (giọng nói)

Lưu trữ cục bộ trong trình duyệt:
    ├── IndexedDB  (dự án, cảnh, kịch bản, asset đã tải về)
    └── localStorage (cấu hình Cloud AI — API key mã hóa nhẹ)
```

### 2.2 Tóm tắt chức năng sản phẩm

| Nhóm chức năng | Mô tả |
|---|---|
| Quản lý dự án | Tạo, mở, đổi tên, xóa dự án; chọn loại `film`/`vlog`/`video` |
| Tạo kịch bản AI | Sinh kịch bản thô từ ý tưởng bằng Cloud LLM; chỉnh sửa được |
| Phân cảnh | Danh sách/lưới cảnh; thêm/xóa/sắp xếp cảnh; sinh cảnh tự động từ kịch bản |
| Sinh hình ảnh/video | Sinh ảnh rồi sinh clip cho từng cảnh bằng Cloud AI; chế độ ảnh tĩnh hoặc video |
| Lồng tiếng | Sinh giọng đọc bằng Cloud TTS cho lời thoại/thuyết minh |
| Cấu hình Cloud AI | Khai báo provider theo từng công đoạn (endpoint, key, model) |
| Xuất video | Ghép các cảnh thành một video hoàn chỉnh để tải về |

### 2.3 Đặc điểm người dùng

Người dùng mục tiêu là **cá nhân sáng tạo nội dung** (nhà làm phim ngắn, vlogger, người làm
video), biết dùng trình duyệt web và có sẵn API key của ít nhất một nhà cung cấp Cloud AI.

### 2.4 Môi trường vận hành

| Thành phần | Yêu cầu |
|---|---|
| Trình duyệt | Chrome 110+, Firefox 115+, Safari 16+ |
| Kết nối Internet | **Bắt buộc** (mọi xử lý AI đều trên đám mây) |
| Cloud AI | Ít nhất một provider hợp lệ cho mỗi công đoạn cần dùng |
| Thiết bị | Máy tính để bàn/laptop (khuyến nghị màn hình ≥1280px) |

---

## 3. Yêu cầu chức năng

Ưu tiên: **P1** = bắt buộc cho MVP, **P2** = quan trọng, **P3** = nên có.

---

### 3.1 Quản lý dự án

**FR-PM-01** *(P1)* Hệ thống cho phép tạo dự án mới với các trường: `name` (tên), `type`
(`film` / `vlog` / `video`), `language` (mặc định `vi`).

**FR-PM-02** *(P1)* Hệ thống lưu toàn bộ dữ liệu dự án trong trình duyệt (IndexedDB); không
gửi dữ liệu ra ngoài trừ khi gọi Cloud AI.

**FR-PM-03** *(P1)* Hệ thống hỗ trợ liệt kê, mở, đổi tên và xóa dự án từ màn hình danh sách
dự án.

**FR-PM-04** *(P2)* Người dùng có thể xuất/nhập một dự án dưới dạng tệp JSON để sao lưu hoặc
chuyển máy (không bao gồm API key).

**FR-PM-05** *(P3)* Mỗi loại dự án cung cấp một khung mẫu (template) mặc định: `film` (nhiều
cảnh, có nhân vật), `vlog` (một người dẫn, chuỗi cảnh thuyết minh), `video` (tự do, ít cảnh).

---

### 3.2 Tạo kịch bản bằng AI

**FR-SG-01** *(P1)* Hệ thống cung cấp panel **Tạo kịch bản** nhận: ý tưởng/tóm tắt (văn bản
tự do, bắt buộc), tùy chọn thẻ tone (`vui`, `kịch tính`, `cảm động`, `hài`, …), độ dài mục
tiêu (`ngắn` / `vừa` / `tùy chỉnh số từ`).

**FR-SG-02** *(P1)* Khi bấm tạo, hệ thống gọi **Cloud LLM** để sinh kịch bản thô có cấu trúc
(phần mở đầu, thân, kết / hoặc theo cảnh) bằng ngôn ngữ của dự án (mặc định `vi`).

**FR-SG-03** *(P1)* Kịch bản sinh ra được lưu trong dự án và **chỉnh sửa được** trực tiếp
trong trình soạn thảo văn bản trước khi dùng.

**FR-SG-04** *(P2)* Với yêu cầu dài, hệ thống stream kết quả theo từng phần để người dùng đọc
được phần đầu trong khi phần sau đang sinh.

**FR-SG-05** *(P1)* Có nút **"Tạo phân cảnh từ kịch bản"** để chuyển kịch bản hiện tại sang
bước phân cảnh tự động (§3.3).

**FR-SG-06** *(P3)* Người dùng có thể yêu cầu AI viết lại một đoạn kịch bản đã chọn với hướng
dẫn tùy chỉnh (ví dụ: "làm đoạn này kịch tính hơn").

---

### 3.3 Phân cảnh (Storyboard)

**FR-SB-01** *(P1)* Phân cảnh hiển thị trên một **canvas React Flow**: mỗi cảnh là một
**node** (`StoryboardNode`), các cảnh nối với nhau bằng **edge** thể hiện thứ tự chuyển cảnh.
Mỗi node hiển thị: số thứ tự, tiêu đề, ảnh xem trước, thời lượng, mô tả ngắn, trạng thái và
nút hành động (Sinh / Sửa).

**FR-SB-02** *(P1)* Trên canvas, người dùng có thể **thêm, xóa, sửa cảnh**, **kéo-thả di
chuyển node**, và **nối/gỡ edge** để thay đổi thứ tự chuyển cảnh. Vị trí node và viewport
được tự động lưu.

**FR-SB-02b** *(P2)* Thứ tự ghép/xuất video (`order`) được suy ra từ chuỗi edge nối các node;
nếu không có edge, dùng thứ tự tạo cảnh.

**FR-SB-03** *(P1)* Mỗi cảnh có các trường: `title`, `duration_sec`, `prompt` (mô tả hình
ảnh), `camera_note` (ghi chú chuyển động, tùy chọn), `media_mode` (`video`/`image`),
`dialogue` (lời thoại/thuyết minh, tùy chọn), `status`.

**FR-SB-04** *(P1)* **Tạo phân cảnh tự động:** từ kịch bản, hệ thống gọi Cloud LLM để tách
thành danh sách cảnh, mỗi cảnh gồm tiêu đề, mô tả hình ảnh, thời lượng gợi ý và lời thoại.

**FR-SB-05** *(P2)* Với dự án loại `vlog`, phân cảnh mặc định gán một "người dẫn" xuyên suốt
và tạo lời thuyết minh cho từng cảnh thay vì hội thoại nhiều nhân vật.

**FR-SB-06** *(P3)* (Tùy chọn) Người dùng có thể định nghĩa **nhân vật đơn giản** (tên +
mô tả hình ảnh) để tái sử dụng mô tả trong prompt của nhiều cảnh, giúp nhất quán hình ảnh.

---

### 3.4 Sinh hình ảnh & video bằng Cloud AI

**FR-GP-01** *(P1)* Với mỗi cảnh, người dùng bấm **Sinh hình ảnh** để gọi Cloud Image AI
(text-to-image) tạo ảnh từ `prompt` của cảnh.

**FR-GP-02** *(P1)* Sau khi có ảnh (`image_status = done`), người dùng có thể bấm **Sinh
video** để gọi Cloud Video AI (image-to-video hoặc text-to-video) tạo clip ngắn.

**FR-GP-03** *(P1)* Người dùng có thể **tải ảnh lên thủ công** (PNG/JPEG/WebP, tối đa 20 MB)
để thay cho ảnh do AI sinh, rồi tiếp tục sinh video từ ảnh đó.

**FR-GP-04** *(P1)* Mỗi cảnh có `media_mode`:
- `video`: sinh clip chuyển động; `duration_sec` giới hạn theo model video (thường 3–10 s).
- `image`: giữ ảnh tĩnh trong `duration_sec` (không giới hạn), không sinh video.

**FR-GP-05** *(P1)* Mỗi lời gọi sinh (image/video/audio/kịch bản) được theo dõi dưới dạng
**Job** với trạng thái: `queued → running → done | error`, kèm tiến độ và thông báo lỗi.

**FR-GP-06** *(P1)* Kết quả (ảnh/video) được **tải về và lưu trong IndexedDB** của trình
duyệt để hiển thị và ghép xuất về sau; hiển thị được ngay khi Job hoàn thành.

**FR-GP-07** *(P2)* Người dùng có thể **sinh lại (regen)** hình ảnh hoặc video của một cảnh
bất kỳ; kết quả mới thay thế kết quả cũ.

**FR-GP-08** *(P2)* Nút **"Sinh tất cả"** cho phép xếp hàng và chạy tuần tự việc sinh cho mọi
cảnh chưa hoàn thành, hiển thị tiến độ tổng.

---

### 3.5 Lồng tiếng & âm thanh

**FR-VA-01** *(P1)* Với các cảnh có `dialogue`, người dùng bấm **Sinh giọng đọc** để gọi
Cloud TTS tạo audio từ văn bản lời thoại/thuyết minh.

**FR-VA-02** *(P1)* Người dùng chọn được **giọng đọc (voice)** và tốc độ đọc từ danh sách
giọng mà provider TTS cung cấp.

**FR-VA-03** *(P2)* Người dùng có thể tải lên một **file nhạc nền (BGM)** cho toàn dự án; khi
xuất, nhạc nền được trộn dưới lớp giọng đọc ở mức âm lượng thấp hơn.

**FR-VA-04** *(P3)* Người dùng nghe thử (preview) audio của một cảnh trước khi xuất.

---

### 3.6 Cấu hình Cloud AI (giao diện trực quan)

Toàn bộ việc cấu hình AI được thực hiện **bằng giao diện**, không sửa file/JSON thủ công.

**FR-MC-01** *(P1)* Người dùng khai báo một hoặc nhiều **Cloud AI Provider** qua **form giao
diện**, mỗi provider gồm: `name`, `category` (`llm` / `image` / `video` / `tts`),
`endpoint_url`, `api_key`, `model_id`.

**FR-MC-02** *(P1)* Với mỗi công đoạn (`llm`, `image`, `video`, `tts`), người dùng **chọn
provider** sẽ dùng. Nếu công đoạn chưa có provider hợp lệ, hệ thống chặn thao tác sinh tương
ứng và hiển thị cảnh báo cấu hình.

**FR-MC-03** *(P1)* **Màn hình cấu hình pipeline AI bằng React Flow (node-graph):** hiển thị
4 node công đoạn (`LLM`, `Image`, `Video`, `TTS`) ở một phía và các node **Provider** ở phía
kia. Người dùng **kéo dây (edge)** từ một công đoạn tới một provider để gán provider cho công
đoạn đó. Mỗi công đoạn chỉ nối tới **một** provider hợp lệ (cùng `category`); nối sai
`category` bị từ chối và báo lỗi trực quan.

**FR-MC-04** *(P1)* **API key được lưu cục bộ** (mã hóa nhẹ trong localStorage), **không bao
giờ hiển thị lại nguyên văn** sau khi lưu — chỉ hiển thị dạng che (ví dụ `sk-****1234`).

**FR-MC-05** *(P1)* Hệ thống cung cấp nút **Kiểm tra kết nối** trên mỗi node provider để xác
nhận endpoint + key hoạt động; node đổi màu theo trạng thái (xanh = OK, đỏ = lỗi).

**FR-MC-06** *(P2)* Hệ thống chỉ hỗ trợ **Cloud AI** — không có tùy chọn AI cục bộ. (Đây là
điểm khác biệt cốt lõi so với bản đầy đủ v1.4 vốn hỗ trợ local/cloud/hybrid.)

**FR-MC-07** *(P3)* Người dùng có thể lưu nhiều provider cùng `category` và **đổi dây** trên
canvas để chuyển nhanh công đoạn sang provider khác.

---

### 3.7 Xuất video

**FR-EX-01** *(P1)* Hệ thống ghép các cảnh theo thứ tự thành **một video MP4** duy nhất:
- Cảnh `video`: dùng clip đã sinh.
- Cảnh `image`: chuyển ảnh tĩnh thành đoạn video theo `duration_sec`.
- Trộn audio giọng đọc của từng cảnh (và BGM nếu có).

**FR-EX-02** *(P1)* Việc ghép/xuất được thực hiện **phía client** bằng `ffmpeg.wasm` trong
trình duyệt; kết quả là một tệp MP4 để **tải về**.

**FR-EX-03** *(P2)* Người dùng chọn được **độ phân giải** đầu ra (720p / 1080p) và **khung
hình** (24 / 30 fps).

**FR-EX-04** *(P3)* Người dùng có thể xuất từng cảnh riêng lẻ (một clip mỗi cảnh) thay vì
ghép toàn bộ.

---

## 4. Yêu cầu phi chức năng

**NFR-P-01** *(P1)* Giao diện phải phản hồi thao tác người dùng (thêm/sửa cảnh, mở panel)
trong < 200 ms; các tác vụ AI chạy nền và không được khóa UI.

**NFR-P-02** *(P2)* Tiến độ Job phải cập nhật lên UI ngay khi có kết quả từ Cloud AI (không
cần tải lại trang).

**NFR-R-01** *(P1)* Khi một lời gọi Cloud AI thất bại, hệ thống hiển thị lỗi rõ ràng và cho
phép thử lại; các cảnh khác không bị ảnh hưởng.

**NFR-R-02** *(P2)* Dữ liệu dự án phải được tự động lưu cục bộ sau mỗi thay đổi để tránh mất
dữ liệu khi đóng trình duyệt.

**NFR-S-01** *(P1)* API key không được ghi log, không hiển thị nguyên văn, và không đưa vào
tệp xuất dự án (FR-PM-04).

**NFR-S-02** *(P2)* Mọi endpoint Cloud AI phải dùng `https://`; hệ thống từ chối endpoint
`http://`.

**NFR-U-01** *(P1)* Ứng dụng dùng tiếng Việt làm ngôn ngữ giao diện mặc định.

**NFR-C-01** *(P2)* Ứng dụng là SPA tĩnh, có thể triển khai trên bất kỳ static host nào
(không cần máy chủ ứng dụng).

---

## 5. Giao diện ngoài

### 5.1 Giao diện người dùng

- **Màn hình danh sách dự án** — tạo/mở/xóa dự án.
- **Không gian làm việc dự án** — gồm: thanh công cụ (Tạo kịch bản, Tạo phân cảnh, Sinh tất
  cả, Xuất video, Cấu hình AI), **canvas React Flow phân cảnh** (node cảnh + edge chuyển
  cảnh), panel chỉnh sửa cảnh, và **canvas React Flow cấu hình pipeline AI** (node công đoạn
  ↔ node provider).

### 5.2 Giao diện với Cloud AI

- Giao tiếp qua HTTPS REST tới các Cloud AI Provider do người dùng cấu hình.
- Định dạng request/response tuân theo tài liệu của từng provider; hệ thống dùng một lớp
  adapter chung (xem SRD).

---

## 6. Yêu cầu dữ liệu

Dữ liệu lưu trong trình duyệt:

- **Project**: `id`, `name`, `type`, `language`, `created_at`, `updated_at`.
- **Script**: `project_id`, `full_text`, `updated_at`.
- **Scene**: `id`, `project_id`, `order`, `title`, `prompt`, `camera_note`, `media_mode`,
  `duration_sec`, `dialogue`, `status`.
- **Asset**: `scene_id`, `image_blob`, `video_blob`, `audio_blob`, các trạng thái tương ứng.
- **Character (tùy chọn)**: `id`, `project_id`, `name`, `description`.
- **CloudProviderConfig**: `id`, `name`, `category`, `endpoint_url`, `api_key` (mã hóa),
  `model_id`, `node_position` (vị trí trên canvas cấu hình) — lưu trong localStorage.
- **StageSelection**: ánh xạ mỗi công đoạn (`llm`/`image`/`video`/`tts`) tới một provider
  (suy ra từ các edge trên canvas cấu hình pipeline AI — FR-MC-03).
- **CanvasLayout (storyboard)**: vị trí các node cảnh, các edge chuyển cảnh và viewport của
  canvas React Flow (FR-SB-01..02).
- **PipelineGraphLayout**: vị trí node công đoạn/provider và edge gán provider trên canvas
  cấu hình AI.

> **Lưu ý:** Bản v0.1 **không dùng cơ sở dữ liệu máy chủ (MariaDB/…)**; toàn bộ dữ liệu trên
> đây lưu trong trình duyệt (IndexedDB + localStorage) để chạy local cá nhân. Cấu trúc dữ
> liệu được thiết kế để có thể chuyển sang MariaDB về sau nếu cần nhiều máy/đồng bộ.

---

## 7. Ràng buộc & Giả định

- **Chỉ React, chỉ Cloud AI:** không backend nặng, không AI cục bộ. Toàn bộ xử lý AI do các
  Cloud AI Provider thực hiện.
- **Cần Internet:** ứng dụng không hoạt động khi ngoại tuyến.
- **Bảo mật API key:** khi gọi Cloud AI trực tiếp từ trình duyệt, API key có thể lộ trong
  request phía client. Với môi trường nhạy cảm, khuyến nghị dùng một **proxy mỏng** (tùy
  chọn, ngoài phạm vi MVP) để giữ key ở phía máy chủ.
- **CORS:** provider phải cho phép gọi từ trình duyệt (CORS); nếu không, cần proxy.
- **Giới hạn thời lượng clip** phụ thuộc model video của provider được cấu hình.
- **Xuất video bằng ffmpeg.wasm** giới hạn theo bộ nhớ trình duyệt; video rất dài có thể cần
  xuất theo từng cảnh (FR-EX-04).
