#!/usr/bin/env bash
# ==============================================================================
#  Base Project — Interactive Setup Wizard
#  A beautiful TUI-style configurator for your Django backend project
#  Works on: Linux, macOS, Windows (Git Bash / WSL / MSYS2)
# ==============================================================================

set -e

# ─────────────────────────────────────────────
# OS Detection
# ─────────────────────────────────────────────
detect_os() {
    case "$(uname -s)" in
        Linux*)     OS_TYPE="linux" ;;
        Darwin*)    OS_TYPE="macos" ;;
        CYGWIN*|MINGW*|MSYS*) OS_TYPE="windows" ;;
        *)          OS_TYPE="unknown" ;;
    esac
}

# ─────────────────────────────────────────────
# Colors & Styles
# ─────────────────────────────────────────────
setup_colors() {
    if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
        BOLD='\033[1m'
        DIM='\033[2m'
        RESET='\033[0m'
        RED='\033[31m'
        GREEN='\033[32m'
        YELLOW='\033[33m'
        BLUE='\033[34m'
        MAGENTA='\033[35m'
        CYAN='\033[36m'
        WHITE='\033[37m'
        BR_RED='\033[91m'
        BR_GREEN='\033[92m'
        BR_YELLOW='\033[93m'
        BR_BLUE='\033[94m'
        BR_MAGENTA='\033[95m'
        BR_CYAN='\033[96m'
        BR_WHITE='\033[97m'
        BG_BLUE='\033[44m'
        BG_CYAN='\033[46m'
    else
        BOLD='' DIM='' RESET=''
        RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' WHITE=''
        BR_RED='' BR_GREEN='' BR_YELLOW='' BR_BLUE='' BR_MAGENTA='' BR_CYAN='' BR_WHITE=''
        BG_BLUE='' BG_CYAN=''
    fi
}

# ─────────────────────────────────────────────
# Global Variables
# ─────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME=""
PROJECT_SLUG=""
RUN_MODE=""
DB_CHOICE=""
USE_MINIO="false"
USE_REDIS="false"
ADMIN_USERNAME="admin"
ADMIN_EMAIL="admin@example.com"
ADMIN_PASSWORD="adminpass123"
DB_NAME=""
DB_USER=""
DB_PASSWORD=""
DB_HOST=""
DB_PORT="5432"
SECRET_KEY=""
TOTAL_STEPS=6

# ─────────────────────────────────────────────
# Terminal Helpers
# ─────────────────────────────────────────────
get_term_width() {
    local w
    w=$(tput cols 2>/dev/null || echo 60)
    if [ "$w" -gt 80 ]; then w=80; fi
    if [ "$w" -lt 40 ]; then w=40; fi
    echo "$w"
}

clear_screen() {
    printf '\033[2J\033[H'
}

repeat_char() {
    local char="$1" count="$2"
    local i
    for ((i=0; i<count; i++)); do printf '%s' "$char"; done
}

# ─────────────────────────────────────────────
# Box Drawing
# ─────────────────────────────────────────────
BOX_W=56

box_top()       { printf "  ${CYAN}╭"; repeat_char '─' $BOX_W; printf "╮${RESET}\n"; }
box_bottom()    { printf "  ${CYAN}╰"; repeat_char '─' $BOX_W; printf "╯${RESET}\n"; }
box_sep()       { printf "  ${CYAN}├"; repeat_char '─' $BOX_W; printf "┤${RESET}\n"; }
box_empty()     { printf "  ${CYAN}│${RESET}%-${BOX_W}s${CYAN}│${RESET}\n" ""; }

box_line() {
    local text="$1"
    local pad=$((BOX_W - ${#text}))
    [ "$pad" -lt 0 ] && pad=0
    printf "  ${CYAN}│${RESET} %s%*s${CYAN}│${RESET}\n" "$text" "$((pad - 1))" ""
}

box_center() {
    local text="$1"
    local len=${#text}
    local left=$(( (BOX_W - len) / 2 ))
    local right=$(( BOX_W - len - left ))
    printf "  ${CYAN}│${RESET}%*s%s%*s${CYAN}│${RESET}\n" "$left" "" "$text" "$right" ""
}

box_header() {
    local text="$1"
    local len=${#text}
    local left=$(( (BOX_W - len - 2) / 2 ))
    local right=$(( BOX_W - len - 2 - left ))
    printf "  ${CYAN}│${BG_BLUE}${BR_WHITE}${BOLD}%*s %s %*s${RESET}${CYAN}│${RESET}\n" "$left" "" "$text" "$right" ""
}

# ─────────────────────────────────────────────
# Progress Bar
# ─────────────────────────────────────────────
show_progress() {
    local current="$1"
    local total="$2"
    local bar_width=$((BOX_W - 12))
    local filled=$(( (current * bar_width) / total ))
    local empty=$((bar_width - filled))

    printf "  ${CYAN}│${RESET}  "
    printf "${BR_CYAN}"
    repeat_char '█' "$filled"
    printf "${DIM}"
    repeat_char '░' "$empty"
    printf "${RESET}"
    printf " ${BOLD}%d/%d" "$current" "$total"
    local right=$((BOX_W - bar_width - 8))
    printf "%*s${CYAN}│${RESET}\n" "$right" ""
}

# ─────────────────────────────────────────────
# Step Header
# ─────────────────────────────────────────────
step_header() {
    local step="$1"
    local title="$2"
    clear_screen
    printf "\n"
    box_top
    show_progress "$step" "$TOTAL_STEPS"
    box_sep
    box_header "$title"
    box_bottom
    printf "\n"
}

# ─────────────────────────────────────────────
# UI Components
# ─────────────────────────────────────────────
print_success() { printf "  ${BR_GREEN}✓${RESET} ${GREEN}%s${RESET}\n" "$1"; }
print_warning() { printf "  ${BR_YELLOW}⚠${RESET} ${YELLOW}%s${RESET}\n" "$1"; }
print_error()   { printf "  ${BR_RED}✗${RESET} ${RED}%s${RESET}\n" "$1"; }
print_info()    { printf "  ${BR_BLUE}ℹ${RESET} ${DIM}%s${RESET}\n" "$1"; }
print_arrow()   { printf "  ${BR_MAGENTA}›${RESET} ${WHITE}%s${RESET}\n" "$1"; }

prompt_input() {
    local prompt="$1" default="$2" var_name="$3"
    if [ -n "$default" ]; then
        printf "  ${BR_CYAN}?${RESET} ${BOLD}%s${RESET} ${DIM}(%s)${RESET}: " "$prompt" "$default"
    else
        printf "  ${BR_CYAN}?${RESET} ${BOLD}%s${RESET}: " "$prompt"
    fi
    read -r input
    [ -z "$input" ] && [ -n "$default" ] && input="$default"
    eval "$var_name='$input'"
}

prompt_password() {
    local prompt="$1" default="$2" var_name="$3"
    if [ -n "$default" ]; then
        printf "  ${BR_CYAN}?${RESET} ${BOLD}%s${RESET} ${DIM}(hidden, default set)${RESET}: " "$prompt"
    else
        printf "  ${BR_CYAN}?${RESET} ${BOLD}%s${RESET} ${DIM}(hidden)${RESET}: " "$prompt"
    fi
    read -rs input
    printf "\n"
    [ -z "$input" ] && [ -n "$default" ] && input="$default"
    eval "$var_name='$input'"
}

# FIXED: All display output goes to stderr so subshell capture works
prompt_choice() {
    local prompt="$1"
    shift
    local options=("$@")
    local count=${#options[@]}
    local choice=""

    printf "\n" >&2
    printf "  ${BR_CYAN}?${RESET} ${BOLD}%s${RESET}\n" "$prompt" >&2
    printf "\n" >&2

    for i in "${!options[@]}"; do
        local num=$((i + 1))
        printf "     ${CYAN}┌─${RESET}\n" >&2
        printf "     ${CYAN}│${RESET} ${BOLD}${BR_WHITE} %d ${RESET}  %b\n" "$num" "${options[$i]}" >&2
        printf "     ${CYAN}└─${RESET}\n" >&2
    done

    printf "\n" >&2
    printf "  ${DIM}Enter choice [1-%d]:${RESET} " "$count" >&2
    read -r choice

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$count" ]; then
        choice=1
    fi

    echo "$choice"
}

prompt_yes_no() {
    local prompt="$1" default="${2:-y}" hint answer
    [ "$default" = "y" ] && hint="Y/n" || hint="y/N"
    printf "  ${BR_CYAN}?${RESET} ${BOLD}%s${RESET} ${DIM}[%s]${RESET}: " "$prompt" "$hint"
    read -r answer
    [ -z "$answer" ] && answer="$default"
    case "$answer" in
        [Yy]*) return 0 ;;
        *) return 1 ;;
    esac
}

# ─────────────────────────────────────────────
# Animated Spinner
# ─────────────────────────────────────────────
spinner() {
    local pid=$1 msg="$2"
    local frames=('⣾' '⣽' '⣻' '⢿' '⡿' '⣟' '⣯' '⣷')
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${BR_CYAN}%s${RESET} %s" "${frames[$i]}" "$msg"
        i=$(( (i + 1) % ${#frames[@]} ))
        sleep 0.1
    done
    printf "\r  ${BR_GREEN}✓${RESET} %s\n" "$msg"
}

generate_secret_key() {
    python3 -c "import secrets; print(''.join(secrets.choice('abcdefghijklmnopqrstuvwxyz0123456789_-') for _ in range(50)))" 2>/dev/null || \
    head -c 50 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 50
}

# ─────────────────────────────────────────────
# Banner
# ─────────────────────────────────────────────
show_banner() {
    clear_screen
    printf "\n"
    printf "${BR_CYAN}${BOLD}"
    printf "    ____                      ___    ____  ____\n"
    printf "   / __ )____ _________      /   |  / __ \\/  _/\n"
    printf "  / __  / __ \`/ ___/ _ \\    / /| | / /_/ // /  \n"
    printf " / /_/ / /_/ (__  )  __/   / ___ |/ ____// /   \n"
    printf "/_____/\\__,_/____/\\___/   /_/  |_/_/   /___/   \n"
    printf "${RESET}\n"

    box_top
    box_header "Django Backend Setup Wizard"
    box_sep
    box_empty
    box_line "  Configure | Rename | Launch"
    box_line "  your project from one place."
    box_empty
    box_sep

    local os_label=""
    case "$OS_TYPE" in
        linux)   os_label="Linux" ;;
        macos)   os_label="macOS" ;;
        windows) os_label="Windows (Git Bash)" ;;
        *)       os_label="Unknown OS" ;;
    esac
    box_line "  System: ${os_label}  |  $(date '+%Y-%m-%d %H:%M')"
    box_bottom
    printf "\n"
    printf "  ${DIM}Press ${BOLD}Enter${RESET}${DIM} to begin setup...${RESET}"
    read -r
}

# ═══════════════════════════════════════════════
# STEP 1 — Project Identity
# ═══════════════════════════════════════════════
step_project_name() {
    step_header 1 "Project Identity"

    print_info "Rename all 'base_project' references in your codebase."
    print_info "Use lowercase letters, digits and underscores."
    printf "\n"

    while true; do
        prompt_input "Project name" "base_project" PROJECT_SLUG

        if [[ ! "$PROJECT_SLUG" =~ ^[a-z][a-z0-9_]*$ ]]; then
            print_error "Invalid! Use lowercase + underscores, starting with a letter."
            continue
        fi

        local dash="${PROJECT_SLUG//_/-}"
        local title
        title=$(echo "$PROJECT_SLUG" | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')
        local cap
        cap=$(echo "$PROJECT_SLUG" | sed 's/_/ /g' | sed 's/^./\U&/')

        printf "\n"
        printf "  ${DIM}Replacements:${RESET}\n"
        printf "  ${CYAN}base_project${RESET}  →  ${BR_GREEN}%s${RESET}\n" "$PROJECT_SLUG"
        printf "  ${CYAN}base-project${RESET}  →  ${BR_GREEN}%s${RESET}\n" "$dash"
        printf "  ${CYAN}Base Project${RESET}  →  ${BR_GREEN}%s${RESET}\n" "$title"
        printf "  ${CYAN}Base project${RESET}  →  ${BR_GREEN}%s${RESET}\n" "$cap"
        printf "\n"

        if prompt_yes_no "Confirm this name?"; then
            PROJECT_NAME="$title"
            break
        fi
    done

    print_success "Project: ${PROJECT_SLUG}"
    sleep 0.3
}

# ═══════════════════════════════════════════════
# STEP 2 — Run Mode
# ═══════════════════════════════════════════════
step_run_mode() {
    step_header 2 "Run Mode"

    local choice
    choice=$(prompt_choice "How will you run this project?" \
        "Docker Compose  ${DIM}— containerized, recommended${RESET}" \
        "Manual Setup    ${DIM}— local venv, install yourself${RESET}")

    case $choice in
        1) RUN_MODE="docker" ;;
        2) RUN_MODE="manual" ;;
    esac

    printf "\n"
    print_success "Mode: ${RUN_MODE}"
    sleep 0.3
}

# ═══════════════════════════════════════════════
# STEP 3 — Database
# ═══════════════════════════════════════════════
step_database() {
    step_header 3 "Database"

    local choice
    if [ "$RUN_MODE" = "docker" ]; then
        choice=$(prompt_choice "Database engine?" \
            "PostgreSQL  ${DIM}— production-ready, runs in container${RESET}" \
            "SQLite      ${DIM}— lightweight, file-based${RESET}")
    else
        choice=$(prompt_choice "Database engine?" \
            "PostgreSQL  ${DIM}— requires local PostgreSQL install${RESET}" \
            "SQLite      ${DIM}— zero setup, perfect for dev${RESET}")
    fi

    case $choice in
        1) DB_CHOICE="postgresql" ;;
        2) DB_CHOICE="sqlite" ;;
    esac

    if [ "$DB_CHOICE" = "postgresql" ]; then
        printf "\n"
        print_info "PostgreSQL credentials:"
        printf "\n"

        prompt_input "Database name" "${PROJECT_SLUG}_db" DB_NAME
        prompt_input "Database user" "${PROJECT_SLUG}_user" DB_USER
        prompt_password "Database password" "strong_password_123" DB_PASSWORD

        if [ "$RUN_MODE" = "manual" ]; then
            prompt_input "Host" "localhost" DB_HOST
            prompt_input "Port" "5432" DB_PORT
        else
            DB_HOST="db_postgres"
            DB_PORT="5432"
        fi
    else
        DB_NAME="${PROJECT_SLUG}_db"
        DB_USER="${PROJECT_SLUG}_user"
        DB_PASSWORD="strong_password_123"
        DB_HOST="localhost"
    fi

    printf "\n"
    print_success "Database: ${DB_CHOICE}"
    sleep 0.3
}

# ═══════════════════════════════════════════════
# STEP 4 — Services
# ═══════════════════════════════════════════════
step_services() {
    step_header 4 "Optional Services"

    print_info "Select additional services:"
    printf "\n"

    if prompt_yes_no "Enable MinIO  (S3-compatible file storage)" "n"; then
        USE_MINIO="true"
        print_success "MinIO: ON"
    else
        printf "  ${DIM}  MinIO: OFF — local file storage${RESET}\n"
    fi

    printf "\n"

    if prompt_yes_no "Enable Redis  (cache & sessions)" "n"; then
        USE_REDIS="true"
        print_success "Redis: ON"
    else
        printf "  ${DIM}  Redis: OFF${RESET}\n"
    fi

    printf "\n"
    sleep 0.3
}

# ═══════════════════════════════════════════════
# STEP 5 — Superuser
# ═══════════════════════════════════════════════
step_superuser() {
    step_header 5 "Admin Account"

    print_info "Django admin superuser credentials:"
    printf "\n"

    prompt_input "Username" "admin" ADMIN_USERNAME
    prompt_input "Email" "admin@example.com" ADMIN_EMAIL
    prompt_password "Password" "adminpass123" ADMIN_PASSWORD

    if [ ${#ADMIN_PASSWORD} -lt 8 ]; then
        print_warning "Short password (< 8 chars). Consider a stronger one."
    fi

    printf "\n"
    print_success "Admin: ${ADMIN_USERNAME} (${ADMIN_EMAIL})"
    sleep 0.3
}

# ═══════════════════════════════════════════════
# STEP 6 — Summary
# ═══════════════════════════════════════════════
step_summary() {
    step_header 6 "Review & Confirm"

    local minio_label="OFF"
    local redis_label="OFF"
    [ "$USE_MINIO" = "true" ] && minio_label="${BR_GREEN}ON${RESET}"
    [ "$USE_REDIS" = "true" ] && redis_label="${BR_GREEN}ON${RESET}"

    printf "  ${BOLD}Configuration Summary:${RESET}\n\n"

    printf "  %-18s ${BR_WHITE}%s${RESET}\n" "Project:" "$PROJECT_SLUG"
    printf "  %-18s ${BR_WHITE}%s${RESET}\n" "Mode:" "$RUN_MODE"
    printf "  %-18s ${BR_WHITE}%s${RESET}\n" "Database:" "$DB_CHOICE"
    if [ "$DB_CHOICE" = "postgresql" ]; then
        printf "  %-18s ${BR_WHITE}%s${RESET}\n" "  DB Name:" "$DB_NAME"
        printf "  %-18s ${BR_WHITE}%s${RESET}\n" "  DB User:" "$DB_USER"
        printf "  %-18s ${BR_WHITE}%s${RESET}\n" "  DB Host:" "$DB_HOST"
    fi
    printf "  %-18s %b\n" "MinIO:" "$minio_label"
    printf "  %-18s %b\n" "Redis:" "$redis_label"
    printf "  %-18s ${BR_WHITE}%s${RESET}\n" "Admin:" "$ADMIN_USERNAME"
    printf "  %-18s ${BR_WHITE}%s${RESET}\n" "Email:" "$ADMIN_EMAIL"
    printf "\n"

    if ! prompt_yes_no "Apply this configuration?"; then
        print_warning "Cancelled. No changes made."
        exit 0
    fi
}

# ═══════════════════════════════════════════════
# Apply Changes
# ═══════════════════════════════════════════════
apply_generate_env() {
    print_arrow "Generating .env ..."

    SECRET_KEY=$(generate_secret_key)

    local use_sqlite="False"
    local use_minio_val="False"
    local db_host_val="${DB_HOST:-localhost}"

    [ "$DB_CHOICE" = "sqlite" ] && use_sqlite="True"
    [ "$USE_MINIO" = "true" ] && use_minio_val="True"

    local dash="${PROJECT_SLUG//_/-}"

    cat > "$SCRIPT_DIR/.env" << ENVEOF
# ==============================================================================
# ${PROJECT_SLUG} — Environment Configuration
# Generated by start.sh on $(date '+%Y-%m-%d %H:%M:%S')
# ==============================================================================

# --- Django ---
SECRET_KEY=${SECRET_KEY}
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0
CSRF_TRUSTED_ORIGINS=http://localhost,http://127.0.0.1
ALLOWED_CORS=http://localhost:3000,http://127.0.0.1:3000

# --- Database ---
USE_SQLITE=${use_sqlite}
DB_NAME=${DB_NAME:-${PROJECT_SLUG}_db}
DB_USER=${DB_USER:-${PROJECT_SLUG}_user}
DB_PASSWORD=${DB_PASSWORD:-strong_password_123}
DB_HOST=${db_host_val}
DB_PORT=${DB_PORT:-5432}

# --- Superuser ---
SUPERUSER_USERNAME=${ADMIN_USERNAME}
SUPERUSER_EMAIL=${ADMIN_EMAIL}
SUPERUSER_PASSWORD=${ADMIN_PASSWORD}

# --- MinIO / S3 ---
USE_MINIO=${use_minio_val}
AWS_ACCESS_KEY_ID=minio_admin
AWS_SECRET_ACCESS_KEY=minio_password
AWS_STORAGE_BUCKET_NAME=${dash}-media
AWS_S3_ENDPOINT_URL=http://minio:9000
AWS_S3_MINAIO_ENDPOINT_URL=http://localhost:9000
AWS_S3_USE_SSL=False
AWS_QUERYSTRING_AUTH=True
AWS_S3_CUSTOM_DOMAIN=localhost:9000/${dash}-media
AWS_S3_URL_PROTOCOL=http:
AWS_DEFAULT_ACL=private
AWS_S3_OBJECT_PARAMETERS={"CacheControl": "max-age=86400"}

# --- JWT ---
JWT_ACCESS_LIFETIME_MINUTES=60
JWT_REFRESH_LIFETIME_DAYS=7

# --- Payments ---
NOWPAYMENTS_API_KEY=
NOWPAYMENTS_SANDBOX_API_KEY=
ZARINPAL_MERCHANT_ID=
CALLBACK_URL=https://example.com/payment/verify/
CANCEL_URL=https://example.com/payment/cancel/

# --- Misc ---
ENABLE_FIELD_FILTER_PAGINATION=False
ENVEOF

    print_success ".env generated"
}

apply_rename() {
    if [ "$PROJECT_SLUG" = "base_project" ]; then
        print_info "Name unchanged — skipping rename."
        return
    fi

    print_arrow "Renaming project files..."

    local dash="${PROJECT_SLUG//_/-}"
    local title
    title=$(echo "$PROJECT_SLUG" | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')
    local cap
    cap=$(echo "$PROJECT_SLUG" | sed 's/_/ /g' | sed 's/^./\U&/')

    local files=("docker-compose.yml" "config/settings.py" "config/urls.py" ".env" "scripts/entrypoint.sh")
    local count=0

    for file in "${files[@]}"; do
        local fp="$SCRIPT_DIR/$file"
        [ ! -f "$fp" ] && continue

        local changed=false
        if grep -q "base_project" "$fp" 2>/dev/null; then
            if [ "$OS_TYPE" = "macos" ]; then
                sed -i '' "s/base_project/${PROJECT_SLUG}/g" "$fp"
            else
                sed -i "s/base_project/${PROJECT_SLUG}/g" "$fp"
            fi
            changed=true
        fi
        if grep -q "base-project" "$fp" 2>/dev/null; then
            if [ "$OS_TYPE" = "macos" ]; then
                sed -i '' "s/base-project/${dash}/g" "$fp"
            else
                sed -i "s/base-project/${dash}/g" "$fp"
            fi
            changed=true
        fi
        if grep -q "Base Project" "$fp" 2>/dev/null; then
            if [ "$OS_TYPE" = "macos" ]; then
                sed -i '' "s/Base Project/${title}/g" "$fp"
            else
                sed -i "s/Base Project/${title}/g" "$fp"
            fi
            changed=true
        fi
        if grep -q "Base project" "$fp" 2>/dev/null; then
            if [ "$OS_TYPE" = "macos" ]; then
                sed -i '' "s/Base project/${cap}/g" "$fp"
            else
                sed -i "s/Base project/${cap}/g" "$fp"
            fi
            changed=true
        fi

        if [ "$changed" = true ]; then
            print_success "Updated: ${file}"
            count=$((count + 1))
        fi
    done

    [ $count -eq 0 ] && print_info "No files needed updating."
}

apply_finish() {
    printf "\n"
    box_top
    box_header "Setup Complete!"
    box_sep
    box_empty

    if [ "$RUN_MODE" = "docker" ]; then
        local profiles=""
        [ "$USE_MINIO" = "true" ] && profiles="${profiles} --profile minio"
        [ "$USE_REDIS" = "true" ] && profiles="${profiles} --profile redis"

        box_line "  Start your project:"
        box_empty
        box_line "  docker compose${profiles} up --build"
        box_empty

        if [ "$PROJECT_SLUG" != "base_project" ]; then
            box_sep
            box_line "  Rename folder (optional):"
            box_line "  mv $(basename "$SCRIPT_DIR") ${PROJECT_SLUG}_api"
        fi
    else
        box_line "  Start your project:"
        box_empty
        box_line "  python -m venv venv"
        if [ "$OS_TYPE" = "windows" ]; then
            box_line "  venv\\Scripts\\activate"
        else
            box_line "  source venv/bin/activate"
        fi
        box_line "  pip install -r requirements.txt"
        box_line "  python manage.py migrate"
        box_line "  python manage.py createsuperuser"
        box_line "  python manage.py runserver"
    fi

    box_empty
    box_bottom
    printf "\n"

    if [ "$RUN_MODE" = "docker" ]; then
        if prompt_yes_no "Launch Docker Compose now?" "y"; then
            printf "\n"
            print_arrow "Starting containers..."
            printf "\n"

            local cmd="docker compose"
            [ "$USE_MINIO" = "true" ] && cmd="${cmd} --profile minio"
            [ "$USE_REDIS" = "true" ] && cmd="${cmd} --profile redis"
            cmd="${cmd} up --build"

            printf "  ${DIM}$ %s${RESET}\n\n" "$cmd"
            cd "$SCRIPT_DIR"
            eval "$cmd"
        else
            printf "\n"
            print_info "Run the command above when you're ready."
        fi
    fi

    printf "\n"
    printf "  ${BR_CYAN}${BOLD}Happy coding!${RESET} ${DIM}🎉${RESET}\n\n"
}

# ═══════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════
main() {
    detect_os
    setup_colors

    if [ ! -f "$SCRIPT_DIR/manage.py" ]; then
        print_error "manage.py not found! Run from project root."
        exit 1
    fi

    show_banner
    step_project_name
    step_run_mode
    step_database
    step_services
    step_superuser
    step_summary

    # Apply
    clear_screen
    printf "\n"
    box_top
    box_header "Applying Configuration..."
    box_bottom
    printf "\n"

    apply_generate_env
    apply_rename
    apply_finish
}

main "$@"
