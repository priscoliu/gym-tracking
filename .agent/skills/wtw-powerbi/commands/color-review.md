---
description: Audit colors in the target against the official WTW brand design system
argument-hint: [optional file path or 'all']
---

You are running a **WTW Brand Color Review** against the authoritative design system at:
`C:\Users\LiuPr\.claude\skills\wtw-powerbi\references\wtw-brand-design-system.md`

**Load that file first** before reviewing anything. It contains the canonical Ultraviolet scale (0–800), the three official color combinations (UV+FW+CR, UV+ST+IN, UV+SU+MA), the Gray Matter scale, sequential/diverging palettes, and the categorical color-order rule.

## Scope

- If `$ARGUMENTS` is a file path, review that file.
- If `$ARGUMENTS` is `all`, review every changed file in the working tree (git diff).
- Otherwise, review the file the user has open in their IDE (check `<ide_selection>` first; fall back to git status if unclear, and ask if still ambiguous).

## Checks (run all that apply)

1. **Hex-code inventory** — extract every hex color from the target. For each:
   - Is it an exact match for an official WTW level (Ultraviolet, Gray Matter, Fireworks, Coral Reef, Stratosphere, Infinity, Submarine, Mandarin, Success, Error)?
   - If not, what is the **closest** official equivalent?
2. **Sequential ramps** — if the code defines a graduated scale (e.g. `_p0` → `_p5`):
   - Does it run **light → dark** as values increase?
   - Are levels in the 400–800 working range (or starts at white-0 with deliberate intent)?
   - Are the increments evenly spaced (level-50 or level-100)?
3. **Categorical color order** — if multiple categories are colored, do the colors follow the official 9-color order for the chosen combination? (UV 750 → 500 → 400 → 600 → 700 → 550 → 450 → 650 → 800 for combo 1, with partner colors interleaved.)
4. **Text contrast over colored fills** — for every place text sits on a colored cell:
   - Background level < 500 → text MUST be black/GM-900.
   - Background level ≥ 500 → text MUST be white.
5. **Candy palette flag** — flag any chart using more than one brand family without alignment to a documented combination.
6. **Functional borders** — if the design uses a visible border for separation/contrast, the border color must be GM-400 (`#8F9194`) or darker.

## Output

Produce a single markdown report with these sections:

```
## Color Review — <file path>

### Summary
✓ Passing | ✗ Failing | ⚠ Worth fixing

### Findings
| Location | Found | Issue | Suggested fix |
|----------|-------|-------|----------------|
| line N   | #XXX  | ...   | #YYY (UV-N) |

### Off-brand hexes (replacements)
| Used | → | Official equivalent |

### Sequential ramp check
...

### Categorical order check
...
```

Be **specific** — quote line numbers, name the rule that was broken, and reference the section of the design system doc that defines it. Do not modify files. If the user wants the fixes applied, suggest they run `/brand-color-fix`.
