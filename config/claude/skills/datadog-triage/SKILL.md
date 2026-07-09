---
name: datadog-triage
description: Triage a single Datadog alert or monitor - pull monitor state, linked dashboards/notebooks, and recent logs/metrics, then summarize likely cause and next steps. Use when the user pastes an alert, names a monitor, or says "triage this alert", "why is X firing", "datadog triage". For a weekly oncall summary use the chime-targeting oncall-report skill instead.
allowed-tools: mcp__datadog-mcp, Read, Grep
context: fork
---

Triage one alert. Goal: a cause hypothesis backed by evidence, plus concrete next steps - not a data dump.

## Input

$ARGUMENTS - an alert body, monitor name/ID, or service name.

## Procedure

1. **Load Datadog domain skills first.** Per the Datadog MCP protocol, call `load_datadog_skill` for the relevant domain (e.g. `datadog/monitors`, `datadog/logs`, `datadog/traces`) and `list_datadog_skills` with topic keywords before other calls. Skip only if already loaded this session.
2. **Find the monitor.** Resolve the monitor from $ARGUMENTS; get its current state, query, and thresholds.
3. **Pull linked context.** Search dashboards and notebooks tied to the service/monitor; open the most relevant.
4. **Look at the signal.** Query recent logs and the alerting metric over the firing window. For p13n services, check iterator age / throughput / error-rate as relevant.
5. **Correlate.** Recent deploys, related monitors also firing, upstream/downstream services.

## Output

- **Alert**: monitor name, what it measures, current state.
- **Likely cause**: one hypothesis, with the evidence that supports it.
- **Evidence**: the specific log lines / metric shifts / deploy (link each).
- **Next steps**: 1-3 concrete actions, most likely first.
- **Links**: monitor, dashboard, notebook.

State uncertainty plainly. Do not assert a cause the evidence does not support.
