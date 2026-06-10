#!/usr/bin/env bash
# skill-install.sh — Gemini/Codex CLI 스킬 인스톨러
#
# 대화형 모드 (기본):
#   skill-install.sh
#
# 비대화형 모드 (에이전트용):
#   skill-install.sh --skills "claude-api,postgresql" --dest project-gemini
#
# --dest 옵션: project-gemini | global-gemini | project-codex | global-codex | global-skill-manager

set -euo pipefail

SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$SOURCE_ROOT/skill-categories.json"
SKILL_MANAGER_HOME="${SKILL_MANAGER_HOME:-$HOME/.skill-manager}"

# --- 인자 파싱 ---
AUTO_SKILLS=""
AUTO_DEST=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skills) AUTO_SKILLS="$2"; shift 2 ;;
    --dest)   AUTO_DEST="$2";   shift 2 ;;
    *) echo "알 수 없는 옵션: $1" >&2; exit 1 ;;
  esac
done

AUTO_MODE=false
[[ -n "$AUTO_SKILLS" && -n "$AUTO_DEST" ]] && AUTO_MODE=true

# --- 사전 조건 확인 ---
if ! command -v jq >/dev/null 2>&1; then
  echo "jq 가 필요합니다. brew install jq" >&2; exit 1
fi
if [[ "$AUTO_MODE" == false ]] && ! command -v fzf >/dev/null 2>&1; then
  cat >&2 <<'EOF'
✗ 인터랙티브 모드에는 fzf 가 필요합니다.
  설치: brew install fzf  /  apt install fzf

또는 비대화형 모드를 사용하세요:
  --skills "name1,name2" --dest <project-gemini|global-gemini|project-codex|global-codex|project-agents|global-agents|global-skill-manager>

예시:
  skill-install.sh --skills "claude-api,postgresql" --dest project-gemini
EOF
  exit 1
fi
if [[ ! -f "$MANIFEST" ]]; then
  echo "매니페스트가 없습니다: $MANIFEST" >&2; exit 1
fi

# --- 설치 대상 경로 결정 ---
resolve_dest() {
  case "$1" in
    gemini-global|global-gemini)   echo "$HOME/.gemini/skills" ;;
    gemini-project|project-gemini) echo "$PWD/.gemini/skills" ;;
    codex-global|global-codex)     echo "$HOME/.codex/skills" ;;
    codex-project|project-codex)   echo "$PWD/.codex/skills" ;;
    global-agents|agents-global)   echo "$HOME/.agents" ;;
    global-skill-manager|skill-manager-global) echo "__SKILL_MANAGER_GLOBAL__" ;;
    project-agents|agents-project)
      local agents_dir="$PWD/.agents"
      mkdir -p "$agents_dir"
      for cli_dir in .gemini .codex; do
        mkdir -p "$PWD/$cli_dir"
        local link="$PWD/$cli_dir/skills"
        if [[ ! -e "$link" ]]; then
          ln -s "$agents_dir" "$link"
          echo "  링크: $link → $agents_dir" >&2
        fi
      done
      echo "$agents_dir"
      ;;
    *) echo "알 수 없는 dest: $1" >&2; exit 1 ;;
  esac
}

# --- 번들 조회 (전체 카테고리 검색) ---
find_bundle() {
  local skill_name="$1"
  jq -r --arg name "$skill_name" \
    '[to_entries[] | .value[] | select(.name == $name)] | first | .bundle // empty' \
    "$MANIFEST"
}

# --- 디렉토리 검색 ---
find_skill_dir() {
  local bundle="$1" skill_name="$2"
  local search_root skill_md
  if [[ "$bundle" == "." ]]; then
    search_root="$SOURCE_ROOT"
  elif [[ -d "$SOURCE_ROOT/bundles/$bundle" ]]; then
    search_root="$SOURCE_ROOT/bundles/$bundle"
  else
    search_root="$SOURCE_ROOT/$bundle"
  fi
  skill_md=$(find "$search_root" -path "*/${skill_name}/SKILL.md" -print -quit 2>/dev/null)
  [[ -n "$skill_md" ]] && dirname "$skill_md" || echo ""
}

# --- skill-manager 전역 런타임 설치 ---
install_global_skill_manager() {
  local runtime="$SKILL_MANAGER_HOME"
  local skills_input="$1"
  local has_skill_manager=false
  local bundle

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    line="${line%% — *}"
    line="${line// /}"
    [[ "$line" == "skill-manager" ]] && has_skill_manager=true
  done <<< "$skills_input"

  if [[ "$has_skill_manager" != true ]]; then
    echo "global-skill-manager 대상은 --skills \"skill-manager\" 전용입니다." >&2
    exit 1
  fi

  mkdir -p "$runtime/bundles"

  echo "[ skill-manager 런타임 설치 ] $runtime"
  rm -rf "$runtime/skill-manager"
  cp -R "$SOURCE_ROOT/skill-manager" "$runtime/skill-manager"
  cp "$MANIFEST" "$runtime/skill-categories.json"
  cp "$SOURCE_ROOT/skill-install.sh" "$runtime/skill-install.sh"
  chmod +x "$runtime/skill-install.sh" 2>/dev/null || true
  jq -r '[to_entries[].value[] | .bundle] | unique[] | select(. != ".")' "$MANIFEST" |
    while IFS= read -r bundle; do
      [[ -z "$bundle" || ! -d "$SOURCE_ROOT/$bundle" ]] && continue
      rm -rf "$runtime/bundles/$bundle"
      cp -R "$SOURCE_ROOT/$bundle" "$runtime/bundles/$bundle"
      echo "  + 번들: $bundle"
    done

  for cli_dest in "$HOME/.codex/skills" "$HOME/.gemini/skills"; do
    mkdir -p "$cli_dest"
    rm -rf "$cli_dest/skill-manager"
    cp -R "$SOURCE_ROOT/skill-manager" "$cli_dest/skill-manager"
    echo "  + CLI 스킬: $cli_dest/skill-manager"
  done

  echo ""
  echo "완료. skill-manager 전역 런타임 설치됨."
  echo "런타임: $runtime"
  echo "카탈로그: $runtime/skill-categories.json"
}

# --- 스킬 설치 공통 함수 ---
install_skills() {
  local dest="$1"
  local skills_input="$2"   # 개행 구분 "name — desc" 또는 단순 name
  local installed=0 skipped=0

  mkdir -p "$dest"

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    # "name — desc" 또는 단순 "name" 둘 다 처리
    skill_name="${line%% — *}"
    skill_name="${skill_name// /}"   # 혹시 모를 앞뒤 공백 제거

    bundle=$(find_bundle "$skill_name")
    if [[ -z "$bundle" ]]; then
      echo "  ✗ 건너뜀(매니페스트에 없음): $skill_name" >&2
      skipped=$((skipped + 1)); continue
    fi

    skill_dir=$(find_skill_dir "$bundle" "$skill_name")
    if [[ -z "$skill_dir" ]]; then
      echo "  ✗ 건너뜀(디렉토리 없음): $bundle/$skill_name" >&2
      skipped=$((skipped + 1)); continue
    fi

    if [[ -e "$dest/$skill_name" ]]; then
      echo "  ⟳ 덮어쓰기: $skill_name"
      rm -rf "$dest/$skill_name"
    else
      echo "  + 설치: $skill_name"
    fi
    cp -R "$skill_dir" "$dest/$skill_name"
    installed=$((installed + 1))
  done <<< "$skills_input"

  echo ""
  echo "완료. ${installed}개 설치, ${skipped}개 건너뜀."
  echo "위치: $dest"
}

# =====================
# 비대화형 모드 (에이전트용)
# =====================
if [[ "$AUTO_MODE" == true ]]; then
  dest=$(resolve_dest "$AUTO_DEST")
  # 쉼표 구분 → 개행 구분으로 변환
  skills_input=$(echo "$AUTO_SKILLS" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  if [[ "$dest" == "__SKILL_MANAGER_GLOBAL__" ]]; then
    install_global_skill_manager "$skills_input"
    exit 0
  fi
  echo "[ 자동 설치 ] dest=$dest"
  install_skills "$dest" "$skills_input"
  exit 0
fi

# =====================
# 대화형 모드 (fzf)
# =====================

# 1) 카테고리 선택
category=$(jq -r 'keys[]' "$MANIFEST" \
  | fzf --prompt="카테고리 선택> " \
        --height=50% --reverse \
        --header="Esc로 취소")
[[ -z "${category:-}" ]] && { echo "취소됨."; exit 0; }

# 2) 스킬 멀티셀렉트
skill_count=$(jq -r --arg cat "$category" '.[$cat] | length' "$MANIFEST")
selected=$(jq -r --arg cat "$category" \
  '.[$cat][] | "\(.name) — \(.desc)"' "$MANIFEST" \
  | fzf -m \
        --prompt="스킬 선택 (Tab 멀티)> " \
        --height=70% --reverse \
        --header="[$category] $skill_count개 · Tab 다중선택, Enter 확정, Esc 취소")
[[ -z "${selected:-}" ]] && { echo "취소됨."; exit 0; }

# 3) 설치 위치 선택
location=$(printf '%s\n' \
  "global-agents   →  ~/.agents/  (Gemini+Codex 공용)" \
  "global-skill-manager → ~/.skill-manager/ + ~/.codex/skills/ + ~/.gemini/skills/" \
  "project-agents  →  ./.agents/  (Gemini+Codex 공용)" \
  "gemini-global   →  ~/.gemini/skills/" \
  "gemini-project  →  $PWD/.gemini/skills/" \
  "codex-global    →  ~/.codex/skills/" \
  "codex-project   →  $PWD/.codex/skills/" \
  | fzf --prompt="설치 위치> " --height=30% --reverse \
        --header="대상 CLI와 범위를 선택하세요")
[[ -z "${location:-}" ]] && { echo "취소됨."; exit 0; }

dest=$(resolve_dest "${location%% *}")

# 4) 설치
if [[ "$dest" == "__SKILL_MANAGER_GLOBAL__" ]]; then
  install_global_skill_manager "$selected"
else
  install_skills "$dest" "$selected"
fi
