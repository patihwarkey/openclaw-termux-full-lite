#!/usr/bin/env bash
set -euo pipefail

APP_NAME="OpenClaw Termux Full-Lite"
PROJECT_DIR="$HOME/.openclaw-termux-full-lite"
BIN_DIR="$HOME/.local/bin"
PROFILE="$HOME/.bashrc"
MARK_BEGIN="# >>> openclaw-termux-full-lite >>>"
MARK_END="# <<< openclaw-termux-full-lite <<<"

c_green='\033[0;32m'; c_yellow='\033[1;33m'; c_red='\033[0;31m'; c_blue='\033[0;34m'; c_reset='\033[0m'
ok(){ printf "${c_green}[OK]${c_reset} %s\n" "$*"; }
info(){ printf "${c_blue}[INFO]${c_reset} %s\n" "$*"; }
warn(){ printf "${c_yellow}[WARN]${c_reset} %s\n" "$*"; }
fail(){ printf "${c_red}[FAIL]${c_reset} %s\n" "$*"; exit 1; }
ask(){ read -r -p "$1 [y/N] " ans </dev/tty || ans=""; [[ "$ans" =~ ^[Yy]$ ]]; }

printf "\n=== %s ===\n\n" "$APP_NAME"
[ -n "${PREFIX:-}" ] || fail "Jalankan di Termux biasa. Jangan di proot dulu."
command -v pkg >/dev/null 2>&1 || fail "pkg tidak ditemukan. Install Termux dari F-Droid."

ARCH="$(uname -m || true)"
case "$ARCH" in
  aarch64|arm64) ok "Arsitektur: $ARCH" ;;
  *) warn "Arsitektur $ARCH belum tentu didukung penuh. Paling aman aarch64/arm64." ;;
esac

mkdir -p "$PROJECT_DIR/scripts" "$PROJECT_DIR/backup" "$BIN_DIR"

printf "\nStep 1/6: Update dan install dependency dasar...\n"
pkg update -y
pkg install -y git curl bash coreutils findutils sed grep tar unzip openssl nodejs-lts
ok "Dependency dasar siap"

printf "\nStep 2/6: Optional build tools ringan...\n"
if ask "Install build tools? Disarankan kalau npm package native gagal, tapi agak berat"; then
  pkg install -y make clang python pkg-config
  ok "Build tools terpasang"
else
  warn "Build tools dilewati. Kalau install npm gagal nanti bisa install manual: pkg install make clang python pkg-config"
fi

printf "\nStep 3/6: Install OpenClaw core...\n"
if command -v openclaw >/dev/null 2>&1; then
  ok "OpenClaw sudah ada: $(openclaw --version 2>/dev/null || echo installed)"
else
  npm install -g openclaw@latest --no-fund --no-audit
  ok "OpenClaw terpasang"
fi

printf "\nStep 4/6: Buat helper command oa...\n"
cat > "$PROJECT_DIR/oa-full-lite.sh" <<'OAEOF'
#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$HOME/.openclaw-termux-full-lite"
SCRIPT_DIR="$PROJECT_DIR/scripts"
usage(){
  cat <<HELP
OpenClaw Termux Full-Lite helper

Usage:
  oa --status       Cek instalasi, storage, process
  oa --start        Jalankan openclaw gateway langsung
  oa --tmux         Jalankan gateway di tmux session 'openclaw'
  oa --stop         Stop tmux session openclaw
  oa --install      Menu optional tools
  oa --update       Update OpenClaw npm package
  oa --backup       Backup ~/.openclaw ke folder helper
  oa --restore      Restore backup terakhir
  oa --uninstall    Hapus helper ini
  oa --help         Bantuan
HELP
}
case "${1:---help}" in
  --status) bash "$SCRIPT_DIR/status.sh" ;;
  --start) exec openclaw gateway ;;
  --tmux) bash "$SCRIPT_DIR/start-tmux.sh" ;;
  --stop) bash "$SCRIPT_DIR/stop.sh" ;;
  --install) bash "$SCRIPT_DIR/install-tools.sh" ;;
  --update) bash "$SCRIPT_DIR/update.sh" ;;
  --backup) bash "$SCRIPT_DIR/backup.sh" ;;
  --restore) bash "$SCRIPT_DIR/restore.sh" ;;
  --uninstall) bash "$SCRIPT_DIR/uninstall.sh" ;;
  --help|-h|help) usage ;;
  *) echo "Unknown command: $1"; usage; exit 1 ;;
esac
OAEOF

cat > "$PROJECT_DIR/scripts/status.sh" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
printf "\n=== OpenClaw Termux Full-Lite Status ===\n\n"
printf "OpenClaw : %s\n" "$(openclaw --version 2>/dev/null || echo not-installed)"
printf "Node     : %s\n" "$(node -v 2>/dev/null || echo not-installed)"
printf "npm      : %s\n" "$(npm -v 2>/dev/null || echo not-installed)"
printf "git      : %s\n" "$(git --version 2>/dev/null || echo not-installed)"
printf "tmux     : %s\n" "$(tmux -V 2>/dev/null || echo not-installed)"
printf "dufs     : %s\n" "$(dufs --version 2>/dev/null | head -1 || echo not-installed)"
printf "ttyd     : %s\n" "$(ttyd --version 2>/dev/null | head -1 || echo not-installed)"
printf "\nStorage:\n"
[ -d "$HOME/.openclaw" ] && du -sh "$HOME/.openclaw" 2>/dev/null | sed 's/^/  ~/.openclaw: /' || true
[ -d "$HOME/.openclaw-termux-full-lite" ] && du -sh "$HOME/.openclaw-termux-full-lite" 2>/dev/null | sed 's/^/  helper: /' || true
df -h "$HOME" 2>/dev/null | awk 'NR==1 || NR==2 {print "  "$0}'
printf "\nProcesses:\n"
pgrep -af "openclaw gateway" 2>/dev/null || echo "  no openclaw gateway process found"
EOF2

cat > "$PROJECT_DIR/scripts/start-tmux.sh" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux belum terinstall. Jalankan: pkg install tmux"
  exit 1
fi
if tmux has-session -t openclaw 2>/dev/null; then
  echo "OpenClaw tmux session sudah jalan. Masuk: tmux attach -t openclaw"
else
  tmux new-session -d -s openclaw 'openclaw gateway'
  echo "OpenClaw gateway jalan di tmux session 'openclaw'."
  echo "Masuk: tmux attach -t openclaw"
fi
EOF2

cat > "$PROJECT_DIR/scripts/stop.sh" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
if command -v tmux >/dev/null 2>&1 && tmux has-session -t openclaw 2>/dev/null; then
  tmux kill-session -t openclaw
  echo "tmux session openclaw dihentikan."
else
  echo "Tidak ada tmux session openclaw."
fi
EOF2

cat > "$PROJECT_DIR/scripts/install-tools.sh" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
ask(){ read -r -p "$1 [y/N] " ans </dev/tty || ans=""; [[ "$ans" =~ ^[Yy]$ ]]; }
section(){ printf "\n=== %s ===\n" "$1"; }

section "Optional Tools — pilih seperlunya"
echo "Default tetap ringan. Tool berat tidak dipasang kecuali dipilih."

section "Ringan"
ask "Install tmux?" && pkg install -y tmux
ask "Install android-tools / adb?" && pkg install -y android-tools
ask "Install dufs file server?" && pkg install -y dufs
ask "Install ttyd web terminal? Hati-hati jangan expose publik tanpa proteksi" && pkg install -y ttyd
ask "Install build tools? make clang python pkg-config" && pkg install -y make clang python pkg-config

section "AI CLI"
ask "Install Gemini CLI?" && npm install -g @google/gemini-cli --no-fund --no-audit
ask "Install Claude Code?" && npm install -g @anthropic-ai/claude-code --no-fund --no-audit
ask "Install Codex CLI Termux fork?" && npm install -g @mmmbuto/codex-cli-termux --no-fund --no-audit
ask "Install OpenCode?" && npm install -g opencode-ai --no-fund --no-audit || true

section "Berat / Advanced"
if ask "Install code-server? Berat, hanya kalau perlu VS Code web"; then
  npm install -g code-server --no-fund --no-audit || echo "code-server gagal via npm. Cek dukungan Termux/device."
fi
if ask "Install Chromium? Sangat berat, skip kalau storage pas-pasan"; then
  pkg install -y x11-repo || true
  pkg install -y chromium || echo "chromium tidak tersedia/gagal di repo Termux ini."
fi
if ask "Install Playwright? Berat dan bisa butuh browser tambahan"; then
  npm install -g playwright --no-fund --no-audit || echo "playwright gagal."
fi

echo "Selesai optional tools."
EOF2

cat > "$PROJECT_DIR/scripts/update.sh" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
echo "Updating OpenClaw..."
npm install -g openclaw@latest --no-fund --no-audit
echo "Done: $(openclaw --version 2>/dev/null || echo installed)"
EOF2

cat > "$PROJECT_DIR/scripts/backup.sh" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$HOME/.openclaw-termux-full-lite"
BACKUP_DIR="$PROJECT_DIR/backup"
mkdir -p "$BACKUP_DIR"
if [ ! -d "$HOME/.openclaw" ]; then
  echo "Data ~/.openclaw belum ada. Tidak ada yang dibackup."
  exit 0
fi
STAMP="$(date +%Y%m%d-%H%M%S)"
tar -czf "$BACKUP_DIR/openclaw-$STAMP.tar.gz" -C "$HOME" .openclaw
echo "Backup dibuat: $BACKUP_DIR/openclaw-$STAMP.tar.gz"
EOF2

cat > "$PROJECT_DIR/scripts/restore.sh" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$HOME/.openclaw-termux-full-lite"
BACKUP_DIR="$PROJECT_DIR/backup"
LATEST="$(ls -t "$BACKUP_DIR"/openclaw-*.tar.gz 2>/dev/null | head -1 || true)"
if [ -z "$LATEST" ]; then
  echo "Backup tidak ditemukan di $BACKUP_DIR"
  exit 1
fi
read -r -p "Restore backup $LATEST ke ~/.openclaw? Ini bisa overwrite data. [y/N] " ans </dev/tty || ans=""
[[ "$ans" =~ ^[Yy]$ ]] || { echo "Dibatalkan."; exit 0; }
tar -xzf "$LATEST" -C "$HOME"
echo "Restore selesai."
EOF2

cat > "$PROJECT_DIR/scripts/uninstall.sh" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$HOME/.openclaw-termux-full-lite"
BIN_DIR="$HOME/.local/bin"
PROFILE="$HOME/.bashrc"
MARK_BEGIN="# >>> openclaw-termux-full-lite >>>"
MARK_END="# <<< openclaw-termux-full-lite <<<"
ask(){ read -r -p "$1 [y/N] " ans </dev/tty || ans=""; [[ "$ans" =~ ^[Yy]$ ]]; }
rm -f "$BIN_DIR/oa"
[ -f "$PROFILE" ] && sed -i "/$MARK_BEGIN/,/$MARK_END/d" "$PROFILE"
rm -rf "$PROJECT_DIR"
echo "Helper full-lite dihapus."
ask "Hapus package OpenClaw global juga?" && npm uninstall -g openclaw || true
if [ -d "$HOME/.openclaw" ] && ask "Hapus data ~/.openclaw? Bisa berisi config/token/session"; then rm -rf "$HOME/.openclaw"; fi
EOF2

chmod +x "$PROJECT_DIR/oa-full-lite.sh" "$PROJECT_DIR/scripts"/*.sh
ln -sf "$PROJECT_DIR/oa-full-lite.sh" "$BIN_DIR/oa"
ok "Command oa dibuat"

printf "\nStep 5/6: Update PATH...\n"
[ -f "$PROFILE" ] && sed -i "/$MARK_BEGIN/,/$MARK_END/d" "$PROFILE"
cat >> "$PROFILE" <<PROFILE_EOF
$MARK_BEGIN
export PATH="\$HOME/.local/bin:\$PATH"
export OPENCLAW_TERMUX_FULL_LITE=1
$MARK_END
PROFILE_EOF
export PATH="$BIN_DIR:$PATH"
ok "PATH siap"

printf "\nStep 6/6: Optional tmux...\n"
if ask "Install tmux? Disarankan supaya gateway tetap jalan"; then
  pkg install -y tmux
  ok "tmux terpasang"
else
  warn "tmux dilewati"
fi

printf "\n${c_green}Selesai.${c_reset}\n"
printf "Jalankan sekarang:\n"
printf "  source ~/.bashrc\n"
printf "  openclaw onboard\n"
printf "  oa --status\n"
printf "  oa --tmux\n\n"
