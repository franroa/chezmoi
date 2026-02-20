# Swarm Debugging Skill

Use when investigating complex bugs that benefit from multiple perspectives.

## When to Use
- Bug has multiple possible root causes
- Issue spans multiple systems/files
- Previous single-agent debugging failed
- Need to explore competing theories simultaneously

## Workflow

### 1. Spawn Investigation Subagents (3-5 depending on complexity)

| Agent | Focus Area | Task |
|-------|------------|------|
| Agent 1 | Error Analysis | Analyze error logs, stack traces, exception details |
| Agent 2 | Code History | Review recent changes via git blame/log, find regression point |
| Agent 3 | Test Analysis | Check related test failures, identify broken assumptions |
| Agent 4 | Dependencies | Investigate external services, library versions, config changes |
| Agent 5 | Pattern Matching | Search for similar past issues, known bugs, workarounds |

### 2. Each Agent Reports Findings

Each subagent must provide:
- **Hypothesis**: What they believe is the root cause
- **Evidence**: Supporting facts from their investigation
- **Contradictions**: Any evidence that weakens their hypothesis
- **Confidence**: Low / Medium / High
- **Next Steps**: What would confirm or refute their theory

### 3. Synthesize Findings

The lead agent:
1. Compares all hypotheses
2. Identifies consensus or conflicts between agents
3. Weighs evidence strength
4. Proposes fix based on strongest evidence
5. If no consensus, proposes targeted experiments to narrow down

## Example Prompts

**Basic:**
```
Investigate this bug using swarm debugging: [describe bug]
```

**Detailed:**
```
Use swarm debugging to investigate why [specific behavior].
- Error message: [paste error]
- Started happening: [when]
- Affected area: [files/services]
```

## Anti-Patterns

- Don't use for simple, obvious bugs (overkill)
- Don't spawn more than 5 agents (diminishing returns)
- Don't skip the synthesis step (agents may have conflicting findings)

## Related Skills

- `systematic-debugging` - Single-agent structured debugging
- `root-cause-tracing` - Trace bugs backward through call stack
