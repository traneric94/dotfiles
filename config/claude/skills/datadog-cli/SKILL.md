---
name: datadog-cli
description: Query Datadog from the terminal via the token-lean `ddq` CLI (curl+jq) instead of the Datadog MCP. Use when checking Datadog logs, metrics, monitors, or events - "check datadog", "search the logs", "is X firing", "query this metric", "pull the errors for <service>". The MCP returns verbose JSON that burns tokens; prefer `ddq` for straightforward reads and fall back to the MCP only when it adds something the CLI can't.
---

# Datadog via the `ddq` CLI

`scripts/ddq` (in this dotfiles repo) wraps the Datadog HTTP API with `curl` + `jq` and returns only the fields you ask for. For ordinary reads it costs a fraction of the tokens the Datadog MCP does, because MCP responses are large structured blobs and `ddq`'s default output is one compact line per result.

## CLI-first vs MCP

**Use `ddq` (default) for:**
- Tailing/searching logs for a service or query.
- Reading a metric timeseries (`aws.lambda.errors`, custom metrics, etc.).
- Checking monitor state / searching monitors.
- Scanning the event stream (deploys, alerts).

**Use the Datadog MCP only when it genuinely adds value:**
- `load_datadog_skill` / `list_datadog_skills` — the MCP ships domain guidance (traces, RUM, visualizations) worth loading before a deep investigation.
- Creating/editing **dashboards or notebooks**, or RUM/span **aggregations** `ddq` doesn't wrap.
- When you don't have API/APP keys set and just need a one-off (MCP is OAuth-authed).

Rule of thumb: **reads → `ddq`; authoring, guided workflows, and aggregations → MCP.** Never fan a broad MCP search when a scoped `ddq` query answers it.

## Setup (one time; secrets stay machine-local)

`ddq` reads three env vars and **hardcodes nothing**:

| var | what | where to get it |
|---|---|---|
| `DD_API_KEY` | org API key | Datadog → Organization Settings → API Keys |
| `DD_APP_KEY` | your application key (reads need this) | Datadog → Personal Settings → Application Keys |
| `DD_SITE` | site host (default `datadoghq.com`) | your Datadog URL, e.g. `us5.datadoghq.com`, `datadoghq.eu` |

Put them in a **gitignored** local shell file that `.zshrc` already sources - `~/.chime.sh` or `~/.zshrc.chime` (both are in `.gitignore`). Never commit keys:

```sh
export DD_API_KEY=…            # from a secrets manager / 1Password, not pasted into git
export DD_APP_KEY=…
export DD_SITE=us5.datadoghq.com   # set to Chime's actual site
alias ddq='bash "$HOME/codebase/dotfiles/scripts/ddq"'
```

(The script is invoked via `bash` because the repo's install path doesn't set the execute bit; the alias hides that.)

## Recipes

```sh
ddq logs 'service:member-experience-service status:error' now-1h now 100
ddq logs 'service:per-kinesis-consumer-lambda "Task timed out"' now-6h
ddq metric 'sum:aws.lambda.errors{functionname:per-kinesis-consumer-lambda}.as_count()' -6h
ddq monitors 'notify targeting'          # id / state / name
ddq monitor 1234567                      # one monitor's state + query
ddq events 'tags:deploy service:personalization-platform' now-1d
ddq logs 'service:foo status:error' --raw | jq '.data[0]'   # full JSON when you need a field ddq didn't surface
```

## Token discipline

- Always scope: pass a **time window** (`now-15m`, `-1h`) and a **limit**; don't default to wide windows.
- Default output is already compact (one line/result). Only add `--raw` when you need a field the shaped output drops, and then pipe to a tight `jq` filter - never dump raw JSON wholesale.
- If a query would return hundreds of rows, aggregate (a metric query or a `count` facet) instead of pulling raw logs.

## Notes

- `ddq` is read-only (logs/metrics/monitors/events GET+search). It intentionally has no write/mutate commands - monitor/dashboard changes go through Terraform or the MCP with explicit confirmation.
- Auth failures fail loud (`DD_API_KEY unset …`); a 403 usually means the APP key lacks scope or `DD_SITE` is wrong.
- Complements the `datadog-triage` skill: `datadog-triage` is the *workflow* for a single alert; `ddq` is the *transport* it (and you) should use for the underlying reads.
