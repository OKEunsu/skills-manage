#!/usr/bin/env bash
# install.sh — skills-manage 스마트 인스톨러 v2 (git 불필요)
#
# 인터뷰 모드 (기본):
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/OKEunsu/skills-manage/master/install.sh)"
#
# 비대화형 모드 (에이전트용):
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/OKEunsu/skills-manage/master/install.sh)" -- \
#     --skills "claude-api,postgresql" --dest project-gemini
#
# 의존성: curl, jq  (git 불필요)

set -euo pipefail

RAW="https://raw.githubusercontent.com/OKEunsu/skills-manage/master"
API="https://api.github.com/repos/OKEunsu/skills-manage/contents"
MANIFEST_URL="$RAW/skill-categories.json"

BOLD='\033[1m'; BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
DIM='\033[2m'; RESET='\033[0m'

# --- 의존성 확인 (curl + jq 만 필요) ---
need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "✗ 필요한 명령어: $1"
    [[ "$1" == "jq" ]] && echo "  설치: brew install jq  /  apt install jq"
    exit 1
  }
}
need curl
need jq

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
[[ -n "$AUTO_SKILLS" && -n "$AUTO_DEST" ]] && AUTO_MODE=true || AUTO_MODE=false

# --- 매니페스트 로드 ---
printf "${DIM}매니페스트 로딩...${RESET}\r"
MANIFEST=$(curl -fsSL "$MANIFEST_URL" 2>/dev/null) || {
  echo "✗ 매니페스트를 가져올 수 없습니다. 네트워크를 확인하세요." >&2
  exit 1
}
printf "                        \r"

# --- 설치 경로 결정 ---
resolve_dest() {
  case "$1" in
    project-agents)
      mkdir -p "$PWD/.agents/skills"
      # Claude Code reads .claude/skills/ — create directory-level symlink
      if [[ ! -e "$PWD/.claude/skills" ]]; then
        mkdir -p "$PWD/.claude"
        ln -sf "../.agents/skills" "$PWD/.claude/skills"
        echo -e "  ${DIM}링크: .claude/skills → .agents/skills${RESET}" >&2
      fi
      echo "$PWD/.agents/skills" ;;
    project-gemini) echo "$PWD/.gemini/skills" ;;
    project-codex)  echo "$PWD/.codex/skills" ;;
    project-claude) echo "$PWD/.claude/skills" ;;
    global-agents)  echo "$HOME/.agents/skills" ;;
    global-gemini)  echo "$HOME/.gemini/skills" ;;
    global-codex)   echo "$HOME/.codex/skills" ;;
    *) echo "✗ 알 수 없는 dest: $1" >&2; exit 1 ;;
  esac
}

# --- GitHub API로 스킬 디렉토리 재귀 다운로드 ---
download_dir() {
  local api_path="$1" local_dest="$2"
  mkdir -p "$local_dest"

  local listing
  listing=$(curl -fsSL "${API}/${api_path}" 2>/dev/null) || return 1

  while IFS= read -r item; do
    local type name
    type=$(echo "$item" | jq -r '.type')
    name=$(echo "$item" | jq -r '.name')
    case "$type" in
      file)
        local url
        url=$(echo "$item" | jq -r '.download_url')
        curl -fsSL "$url" -o "$local_dest/$name" 2>/dev/null
        ;;
      dir)
        download_dir "${api_path}/${name}" "$local_dest/$name"
        ;;
    esac
  done < <(echo "$listing" | jq -c '.[]')
}

# --- 스킬 설치 ---
install_skills() {
  local dest="$1"; shift
  local -a skill_list=("$@")
  local installed=0 failed=0

  mkdir -p "$dest"
  for skill_name in "${skill_list[@]}"; do
    [[ -z "$skill_name" ]] && continue

    local bundle
    bundle=$(echo "$MANIFEST" | jq -r --arg n "$skill_name" \
      '[to_entries[] | .value[] | select(.name==$n)] | first | .bundle // empty')

    if [[ -z "$bundle" ]]; then
      echo -e "  ✗ ${DIM}건너뜀(매니페스트 없음): $skill_name${RESET}"
      failed=$((failed+1)); continue
    fi

    printf "  ↓ %-35s" "$skill_name"
    if download_dir "${bundle}/${skill_name}" "$dest/$skill_name"; then
      echo -e " ${GREEN}✓${RESET}"
      installed=$((installed+1))
    else
      echo -e " ${YELLOW}✗ (다운로드 실패)${RESET}"
      failed=$((failed+1))
    fi
  done

  echo ""
  echo -e "  ${GREEN}${BOLD}${installed}개 설치 완료${RESET}$([ $failed -gt 0 ] && echo -e "  ${YELLOW}${failed}개 실패${RESET}" || true)"
  echo -e "  ${DIM}위치: $dest${RESET}"
}

# =============================
# 비대화형 모드 (에이전트용)
# =============================
if [[ "$AUTO_MODE" == true ]]; then
  dest=$(resolve_dest "$AUTO_DEST")
  echo -e "${BLUE}[ 자동 설치 ]${RESET} dest=$dest"
  IFS=',' read -ra skills <<< "$AUTO_SKILLS"
  install_skills "$dest" "${skills[@]}"
  exit 0
fi

# =============================
# 인터뷰 모드 (인터랙티브)
# =============================
echo ""
echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  skills-manage — 스마트 인스톨러${RESET}"
echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

# Q1: 무엇을 만드나요?
echo -e "${BOLD}Q1. 무엇을 만들고 있나요?${RESET}"
echo "  1) 웹 / 앱 프론트엔드"
echo "  2) 백엔드 API / 서버"
echo "  3) AI 에이전트 / LLM 앱"
echo "  4) 데이터 분석 / ML"
echo "  5) 자동화 / 워크플로우"
echo "  6) 인프라 / DevOps"
read -rp "▶ " q1

# Q2: 기술 스택
echo ""
q2=""
case "$q1" in
  1) echo -e "${BOLD}Q2. 주요 프레임워크는?${RESET}"
     echo "  1) React / Next.js   2) Angular   3) Vue   4) 모바일 (RN / Flutter)"
     read -rp "▶ " q2 ;;
  2) echo -e "${BOLD}Q2. 주요 언어 / 프레임워크는?${RESET}"
     echo "  1) Node.js   2) Python   3) Go   4) Java / Kotlin"
     read -rp "▶ " q2 ;;
  3) echo -e "${BOLD}Q2. 어떤 AI를 사용하나요?${RESET}"
     echo "  1) Claude API   2) OpenAI   3) LangChain / LangGraph   4) CrewAI"
     read -rp "▶ " q2 ;;
  4) echo -e "${BOLD}Q2. 주로 쓰는 도구는?${RESET}"
     echo "  1) scikit-learn   2) PyTorch   3) Hugging Face   4) SQL 기반"
     read -rp "▶ " q2 ;;
  5) echo -e "${BOLD}Q2. 자동화 도구는?${RESET}"
     echo "  1) n8n   2) Slack 봇   3) GitHub Actions   4) 기타 SaaS"
     read -rp "▶ " q2 ;;
  6) echo -e "${BOLD}Q2. 주로 쓰는 인프라는?${RESET}"
     echo "  1) AWS   2) GCP   3) Kubernetes   4) Docker / 온프레미스"
     read -rp "▶ " q2 ;;
esac

# Q3: 지금 당장 필요한 작업 (복수 선택)
echo ""
echo -e "${BOLD}Q3. 지금 가장 필요한 작업은? ${DIM}(쉼표로 복수 선택 가능)${RESET}"
echo "  1) DB 설계 / 쿼리 최적화"
echo "  2) 인증 / 보안"
echo "  3) 배포 / CI-CD"
echo "  4) UI / 디자인"
echo "  5) AI 기능 추가"
echo "  6) 자동화"
echo "  7) 테스트"
read -rp "▶ " q3

# --- 추천 로직 ---
declare -a RECS=()

case "$q1" in
  1)
    case "$q2" in
      1) RECS+=("react-nextjs-development" "typescript-expert" "dark-mode-react-ui") ;;
      2) RECS+=("angular-development-core" "typescript-expert") ;;
      3) RECS+=("typescript-expert") ;;
      4) RECS+=("mobile-development-core") ;;
      *) RECS+=("typescript-expert" "frontend-design") ;;
    esac ;;
  2)
    RECS+=("backend-security" "postgresql")
    case "$q2" in
      2) RECS+=("pydantic-ai") ;;
      3) RECS+=("grpc-go") ;;
    esac ;;
  3)
    case "$q2" in
      1) RECS+=("claude-api") ;;
      2) RECS+=("langchain-langgraph-agents") ;;
      3) RECS+=("langchain-langgraph-agents" "langgraph") ;;
      4) RECS+=("crewai") ;;
      *) RECS+=("claude-api") ;;
    esac
    RECS+=("rag-engineer" "vector-database-engineer") ;;
  4)
    RECS+=("scikit-learn" "polars" "seaborn")
    case "$q2" in
      3) RECS+=("hugging-face-model-trainer" "hugging-face-datasets") ;;
    esac ;;
  5)
    case "$q2" in
      1) RECS+=("n8n-automation" "n8n-workflow-patterns") ;;
      2) RECS+=("slack-automation") ;;
      3) RECS+=("github-actions-templates" "github-workflows") ;;
      *) RECS+=("workflow-automation") ;;
    esac ;;
  6)
    RECS+=("docker-expert")
    case "$q2" in
      1) RECS+=("aws-skills" "aws-serverless") ;;
      2) RECS+=("gcp-cloud-run" "cloud-devops") ;;
      3) RECS+=("kubernetes-architect" "helm-chart-scaffolding") ;;
      *) RECS+=("deployment-engineer") ;;
    esac ;;
esac

# Q3 태스크 기반 추가
IFS=',' read -ra tasks <<< "${q3:-}"
for t in "${tasks[@]}"; do
  t="${t// /}"
  case "$t" in
    1) RECS+=("postgresql" "postgresql-optimization") ;;
    2) RECS+=("backend-security") ;;
    3) RECS+=("github-actions-templates" "deployment-pipeline-design") ;;
    4) RECS+=("frontend-design" "shadcn") ;;
    5) RECS+=("claude-api") ;;
    6) RECS+=("n8n-automation") ;;
    7) RECS+=("playwright-e2e") ;;
  esac
done

# 중복 제거
declare -a UNIQUE_RECS=()
declare -A seen=()
for s in "${RECS[@]}"; do
  [[ -z "${seen[$s]:-}" ]] && { UNIQUE_RECS+=("$s"); seen[$s]=1; }
done

# --- 추천 결과 출력 ---
echo ""
echo -e "${YELLOW}${BOLD}추천 스킬 (${#UNIQUE_RECS[@]}개):${RESET}"
i=1
for s in "${UNIQUE_RECS[@]}"; do
  desc=$(echo "$MANIFEST" | jq -r --arg n "$s" \
    '[to_entries[].value[] | select(.name==$n)] | first | .desc // "-"')
  printf "  ${BOLD}%2d.${RESET} %-35s ${DIM}%s${RESET}\n" "$i" "$s" "$desc"
  i=$((i+1))
done

# --- 수정 ---
echo ""
echo -e "${DIM}추가(+이름) 또는 제외(-이름) 가능. 없으면 Enter.${RESET}"
read -rp "수정 ▶ " adjustments

FINAL_RECS=("${UNIQUE_RECS[@]}")
if [[ -n "${adjustments:-}" ]]; then
  IFS=',' read -ra adj_list <<< "$adjustments"
  for adj in "${adj_list[@]}"; do
    adj="${adj// /}"
    if [[ "$adj" == +* ]]; then
      FINAL_RECS+=("${adj#+}")
    elif [[ "$adj" == -* ]]; then
      remove="${adj#-}"
      declare -a tmp=()
      for s in "${FINAL_RECS[@]}"; do [[ "$s" != "$remove" ]] && tmp+=("$s"); done
      FINAL_RECS=("${tmp[@]}")
    fi
  done
fi

# --- 설치 위치 ---
echo ""
echo -e "${BOLD}설치 위치:${RESET}"
echo -e "  1) project-agents  →  .agents/skills/  + .claude/skills/ 링크 ${BOLD}[추천]${RESET}"
echo "  2) project-claude  →  .claude/skills/"
echo "  3) global-agents   →  ~/.agents/skills/"
read -rp "선택 [1-3, 기본=1] ▶ " dest_choice

case "${dest_choice:-1}" in
  2) DEST="project-claude" ;;
  3) DEST="global-agents" ;;
  *) DEST="project-agents" ;;
esac

dest_path=$(resolve_dest "$DEST")
echo ""
echo -e "${BLUE}설치 시작...${RESET}"
install_skills "$dest_path" "${FINAL_RECS[@]}"
