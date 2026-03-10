#!/usr/bin/env bash

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)

[ -z "$PROMPT" ] && [ -z "$CWD" ] && exit 0

PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')
CONTEXT=""

route_personalization() {
  CONTEXT="## Project: personalization-platform
- Path: ~/codebase/personalization-platform/
- Stack: Go, DynamoDB, Hawker (event bus), Flink, Protobuf/Twirp
- VCS: Graphite (gt) for stacked PRs
- Testing: testify/suite pattern with mocks
- Key patterns: event orchestration, eligibility graphs, node execution
- Go reference: ~/codebase/100-go-mistakes/"
}

route_otter() {
  CONTEXT="## Project: project-otter
- Path: ~/codebase/project-otter/
- Stack: TypeScript strict, React Native, Redux, Apollo/GraphQL
- Build: yarn only (never npm)
- UI: ChimeKit design system only — no custom components
- Security: HTTPS, cert pinning, biometric auth required"
}

route_schemas() {
  CONTEXT="## Project: chime-schemas
- Path: ~/codebase/chime-schemas/
- Key packages: chime.ranking.v1, chime.ranking.admin.v1
- Codegen output: codegen/go/proto/
- Transport: Twirp v8"
}

route_braze() {
  CONTEXT="## Project: braze-gateway
- Path: ~/codebase/braze-gateway/
- Stack: Ruby, Hawker subscriber, Protobuf
- Pre-commit workflow required"
}

route_atlas() {
  CONTEXT="## Project: chime-atlas
- Path: ~/codebase/chime-atlas/
- Type: Ruby gem
- Features: RequestContext, RequestCache, Flipper integration"
}

route_infra() {
  CONTEXT="## Project: infrastructure
- Terraform: ~/codebase/chime-tf/
- CD pipeline: ~/codebase/chime-cd/"
}

route_dotfiles() {
  CONTEXT="## Project: dotfiles
- Path: ~/codebase/dotfiles/
- Symlinks: ~/.config/nvim, ~/.config/tmux, ~/.config/claude -> dotfiles/config/*
- Packages: Brewfile at root"
}

# CWD-based routing (primary signal)
case "$CWD" in
  */personalization-platform*) route_personalization ;;
  */project-otter*)            route_otter ;;
  */chime-schemas*)            route_schemas ;;
  */braze-gateway*)            route_braze ;;
  */chime-atlas*)              route_atlas ;;
  */chime-tf*|*/chime-cd*)     route_infra ;;
  */dotfiles*)                 route_dotfiles ;;
esac

# Prompt-based routing (secondary — fires only when CWD gave no match)
if [ -z "$CONTEXT" ]; then
  if echo "$PROMPT_LOWER" | grep -qE '\bper-[0-9]+\b|personali|ranking.*service|eligib|hawker|flink|mcda|boost.*strateg'; then
    route_personalization
  elif echo "$PROMPT_LOWER" | grep -qE '\botter\b|react.?native|redux|apollo.*client|mobile.*(ios|android|app)'; then
    route_otter
  elif echo "$PROMPT_LOWER" | grep -qE '\.proto\b|twirp|chime.?schema|proto.*codegen'; then
    route_schemas
  elif echo "$PROMPT_LOWER" | grep -qE '\bbraze\b|braze.?gateway'; then
    route_braze
  elif echo "$PROMPT_LOWER" | grep -qE '\batlas\b|request.?context|request.?cache'; then
    route_atlas
  elif echo "$PROMPT_LOWER" | grep -qE 'terraform|chime.?tf|chime.?cd|\binfra\b'; then
    route_infra
  fi
fi

[ -z "$CONTEXT" ] && exit 0

printf '%s' "$CONTEXT"
