# skills-manage

AI 에이전트용 스킬 카탈로그 & 인스톨러. Codex CLI · Gemini CLI · Claude Code 지원.

**328개 스킬 / 49개 카테고리** — `curl` + `jq`만으로 설치. git 불필요.

---

## 에이전트 사용 방법

### 스킬 설치 (비대화형)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/OKEunsu/skills-manage/master/install.sh)" -- \
  --skills "SKILL_NAME" --dest DEST
```

여러 스킬:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/OKEunsu/skills-manage/master/install.sh)" -- \
  --skills "claude-api,postgresql,react-nextjs-development" --dest project-agents
```

### --dest 옵션

| 값 | 설치 경로 | 플랫폼 |
|----|----------|--------|
| `project-agents` | `.agents/skills/` + `.claude/skills/` 심볼릭 링크 | Codex + Agy + Claude Code (권장) |
| `project-claude` | `.claude/skills/` | Claude Code 단독 |
| `global-agents` | `~/.agents/skills/` | Codex + Agy 전역 |

### 스킬 이름 찾기

```bash
curl -fsSL https://raw.githubusercontent.com/OKEunsu/skills-manage/master/skill-categories.json | jq 'keys'
curl -fsSL https://raw.githubusercontent.com/OKEunsu/skills-manage/master/skill-categories.json | jq '.[카테고리명][].name'
```

전체 목록: [SKILL-INVENTORY.md](./SKILL-INVENTORY.md)

---

## skill-manager (메타 스킬)

프로젝트를 분석해 필요한 스킬을 자동 추천·설치하는 메타 스킬.

### 전역 설치 (최초 1회)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/OKEunsu/skills-manage/master/install.sh)" -- \
  --skills "skill-manager" --dest global-skill-manager
```

설치 후 각 플랫폼에서:
- Claude Code: `/skill-manager`
- Codex: `$skill-manager`
- Gemini: `@skill-manager`

---

## 동작 방식

1. `install.sh`를 GitHub raw에서 메모리로 실행
2. `skill-categories.json` 매니페스트 fetch (경량)
3. `--skills` 플래그로 스킬 확정 (또는 인터뷰 모드)
4. GitHub API로 해당 스킬 디렉토리만 다운로드
5. `project-agents`면 각 플랫폼 디렉토리에 심볼릭 링크 생성

의존성: `curl`, `jq`

---

## 번들

| 번들 | 스킬 수 | 내용 |
|------|--------|------|
| `frontend-ux-bundle/` | 53 | React/Next.js, Angular, 모바일, UX |
| `marketing-growth-bundle/` | 59 | SEO, 콘텐츠, 그로스, AI 이미지 |
| `infra-ai-bundle/` | 112 | AWS/GCP, K8s, AI 에이전트, ML |
| `automation-bundle/` | 89 | Slack, HubSpot, Stripe, Notion |
| `solopreneur-ko-bundle/` | 14 | 한국 결제, n8n, PM, 법무 |
| `skill-manager/` | 1 | 프로젝트 분석 → 스킬 자동 추천 |
