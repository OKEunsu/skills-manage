---
name: skill-manager
description: "프로젝트의 PRD, README, 설정 파일을 분석해 skills-manage 카탈로그에서 필요한 스킬을 추천하고 설치합니다."
---

# Skill Manager

프로젝트를 분석하고 적합한 스킬을 자동으로 추천·설치하는 메타 스킬입니다.

## 사용법

```
$skill-manager [install|list|help]
```

- `install` (기본) — 현재 프로젝트를 분석해 스킬 추천 및 설치
- `list` — 설치된 스킬 목록 출력
- `help` — 도움말

---

## 동작 방식 (install)

다음 단계를 순서대로 실행하세요.

### 1단계: 프로젝트 컨텍스트 수집

아래 파일들을 읽어 프로젝트를 파악합니다 (있는 것만):

- `PRD.md`, `prd.md`
- `docs/PRD.md`, `docs/prd.md`, `docs/prd-*.md`
- `.omx/plans/prd-*.md`
- `README.md`
- `package.json` / `package-lock.json`
- `requirements.txt` / `pyproject.toml`
- `docker-compose.yml`
- `Dockerfile`
- `*.config.{ts,js,mjs}`
- 최상위 디렉토리 구조 (`ls` 1~2단계)

### 2단계: 스킬 카탈로그 읽기

```bash
cat ~/.skill-manager/skill-categories.json
```

스킬 원본 번들은 `~/.skill-manager/bundles/` 아래에 있습니다. 설치는
`~/.skill-manager/skill-install.sh` 를 사용합니다.

### 3단계: 추천

수집한 프로젝트 정보와 카탈로그를 대조해 **가장 유용한 스킬 3~7개**를 선정합니다.

추천 기준:
- 프로젝트에서 실제로 사용 중인 기술 스택과 직접 일치하는 스킬 우선
- PRD에 명시된 구현 예정 기능과 직접 연결되는 스킬 우선
- 중복 기능 스킬은 1개만 선택
- 현재 프로젝트에 `.agents/`, `.gemini/skills/` 또는 `.codex/skills/` 가 이미 있으면 기설치 항목 제외

추천 결과를 아래 형식으로 사용자에게 제시합니다:

```
추천 스킬 (N개):

  1. skill-name       — 설명 [이유: 왜 이 프로젝트에 필요한지]
  2. skill-name       — 설명 [이유: ...]
  ...

설치 대상:
  [ ] project-agents  →  ./.agents/ + ./.gemini/skills, ./.codex/skills symlink
  [ ] project-gemini  →  ./.gemini/skills/
  [ ] project-codex   →  ./.codex/skills/
  [ ] global-gemini   →  ~/.gemini/skills/
  [ ] global-codex    →  ~/.codex/skills/
```

### 4단계: 사용자 확인

사용자에게 추천 목록과 설치 위치를 확인받습니다.
- 스킬 추가/제외 요청이 있으면 반영합니다.
- 확인이 완료되면 5단계로 진행합니다.

### 5단계: 설치

확정된 스킬과 위치로 `skill-install.sh` 를 비대화형 모드로 실행합니다:

```bash
~/.skill-manager/skill-install.sh \
  --skills "skill1,skill2,skill3" \
  --dest project-agents
```

설치 완료 후 결과를 요약해 출력합니다.

---

## list 모드

현재 디렉토리의 설치된 스킬을 출력합니다:

```bash
echo "=== Gemini ===" && ls .gemini/skills/ 2>/dev/null || echo "(없음)"
echo "=== Codex ===" && ls .codex/skills/ 2>/dev/null || echo "(없음)"
```

---

## 주의사항

- `~/.skill-manager/skill-categories.json` 이 없으면 먼저 `skill-manager` 를 `global-skill-manager` 대상으로 설치해야 합니다.
- `~/.skill-manager/skill-install.sh` 실행 권한이 필요합니다.
- 추천은 참고용입니다. 최종 결정은 항상 사용자가 확인합니다.
