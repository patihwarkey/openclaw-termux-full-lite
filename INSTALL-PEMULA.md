# Cara Install OpenClaw Termux Full-Lite untuk Pemula

## 1. Install Termux

Install Termux dari F-Droid.

## 2. Jalankan command install

Kalau repo sudah diupload ke GitHub public, buka Termux dan paste:

```bash
pkg update -y && pkg upgrade -y
pkg install -y curl bash
curl -L https://raw.githubusercontent.com/patihwarkey/openclaw-termux-full-lite/main/openclaw-termux-full-lite-install.sh -o openclaw-termux-full-lite-install.sh
bash openclaw-termux-full-lite-install.sh
```

Ganti `USERNAME` dengan username GitHub pemilik repo.

Kalau ditanya install build tools, pemula boleh pilih `n` dulu.
Kalau ditanya install tmux, pilih `y`.

## 3. Setelah selesai

```bash
source ~/.bashrc
openclaw onboard
oa --status
oa --tmux
```

## 4. Optional tools

Kalau butuh Gemini/Claude/Codex/code-server/Chromium/Playwright:

```bash
oa --install
```

Pilih seperlunya saja. Jangan install semua kalau storage HP kecil.
