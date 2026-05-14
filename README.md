# OpenClaw Termux Full-Lite

Installer **lebih lengkap tapi tetap ringan** untuk menjalankan OpenClaw di Termux Android.

Tujuannya mirip installer full, tapi default-nya tidak memasang tool berat supaya startup dan storage tetap ringan.

## Fitur

Default install:

- dependency dasar Termux
- Node.js LTS
- OpenClaw via npm
- helper command `oa`
- status checker
- tmux launcher
- update / backup / restore / uninstall

Optional lewat `oa --install`:

- tmux
- android-tools / adb
- dufs
- ttyd
- build tools
- Gemini CLI
- Claude Code
- Codex CLI Termux fork
- OpenCode
- code-server
- Chromium
- Playwright

Tool berat seperti Chromium, Playwright, dan code-server **tidak dipasang otomatis**.

---

## Install dari GitHub

Ganti `USERNAME` dengan username GitHub pemilik repo.

```bash
pkg update -y && pkg upgrade -y
pkg install -y curl bash
curl -L https://raw.githubusercontent.com/patihwarkey/openclaw-termux-full-lite/main/openclaw-termux-full-lite-install.sh -o openclaw-termux-full-lite-install.sh
bash openclaw-termux-full-lite-install.sh
```

Setelah selesai:

```bash
source ~/.bashrc
openclaw onboard
oa --status
oa --tmux
```

---

## Install dari File Download HP

Kalau file installer sudah ada di folder Download HP:

```bash
pkg update -y && pkg upgrade -y
termux-setup-storage
cp /sdcard/Download/openclaw-termux-full-lite-install.sh ~/
cd ~
bash openclaw-termux-full-lite-install.sh
```

Setelah selesai:

```bash
source ~/.bashrc
openclaw onboard
oa --status
oa --tmux
```

---

## Command `oa`

Cek status:

```bash
oa --status
```

Jalankan OpenClaw langsung:

```bash
oa --start
```

Jalankan OpenClaw via tmux:

```bash
oa --tmux
```

Stop tmux OpenClaw:

```bash
oa --stop
```

Install optional tools:

```bash
oa --install
```

Update OpenClaw:

```bash
oa --update
```

Backup data OpenClaw:

```bash
oa --backup
```

Restore backup terakhir:

```bash
oa --restore
```

Uninstall:

```bash
oa --uninstall
```

---

## Rekomendasi Storage

- Core install: 2–3 GB kosong
- Dengan beberapa optional CLI: 3–5 GB kosong
- Dengan Chromium / Playwright / code-server: 5–10 GB kosong

Kalau HP pas-pasan, jangan install Chromium, Playwright, dan code-server.

---

## Catatan Keamanan

- Jangan expose `ttyd`, `dufs`, atau code-server ke internet tanpa password/tunnel aman.
- Jangan simpan private key/wallet/API key penting sebelum yakin setup stabil.
- Installer mengambil OpenClaw dari npm `openclaw@latest`, jadi versi yang dipasang mengikuti npm terbaru.

