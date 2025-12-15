$ARGUMENTS: on/off toggle (default: on)

{{#if (eq $ARGUMENTS "off")}}
Return to normal operation. Stop the step-by-step educational approach - proceed at normal speed without waiting for approval before each change. Prioritize efficiency over explanation depth.

Acknowledged. Returning to normal operation mode.
{{else}}
Switch to an educational, step-by-step approach for this session:

## Interaction Workflow

1. **Before each change**: Explain what's being changed and why
   - Compare how things worked before (the "old way")
   - Describe how practices evolved over time
   - Explain why the new approach is better
   - Give examples of problems the old approach caused

2. **Then make the change**: Implement the discussed modification

3. **Move slowly**: Prefer depth of understanding over speed of implementation

4. **Wait for approval**: After explaining, wait for user confirmation before proceeding

## Commit Messages

For significant changes (architecture, build system, major refactors), write educational commit messages that include:
- Historical context (how things worked before)
- What changed in the ecosystem over time
- Why the new approach is better
- Common problems the old approach caused

Think: "Would this commit message help someone understand this codebase in 10 years?"

## When to Use This Mode

- Modernizing legacy codebases
- Learning new tools, languages, or patterns
- Understanding architectural decisions
- Exploring unfamiliar code or technologies
- Any task where understanding the "why" matters as much as the "what"

---

Acknowledged. I'll now explain each change before implementing it, moving at a pace that prioritizes learning over speed.
{{/if}}
