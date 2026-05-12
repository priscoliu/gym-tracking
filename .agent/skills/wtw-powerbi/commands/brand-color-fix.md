---
description: Replace off-brand colors in a file with the closest official WTW equivalents
argument-hint: [file path] [optional: --combo=1|2|3|uv-only]
---

You are running **WTW Brand Color Fix** — an action, not a review. You will modify the target file to replace every non-brand color with the closest official equivalent from:
`C:\Users\LiuPr\.claude\skills\wtw-powerbi\references\wtw-brand-design-system.md`

**Load that file first**.

## Required: confirm with the user before editing

Before making changes, present:
1. The list of hex codes found in the file.
2. For each, the proposed official replacement (level, name, hex).
3. The chosen combination context (UV-only by default; UV+FW+CR for combo 1; UV+ST+IN for combo 2; UV+SU+MA for combo 3 — accept `--combo=N` argument; if not supplied and the file uses non-UV brand families, infer or ask).
4. Any hex codes that have no clean equivalent (flag, ask user how to handle).

**Wait for user confirmation** ("yes" / "go" / "apply") before editing. If they say no, stop without changes.

## Mapping rules

1. **Hex matches an official level exactly** → keep as-is (no change needed).
2. **Hex within 8 ΔE of an official level** → replace with the official level. Note the visual delta in your report.
3. **Sequential ramp** (multiple hexes that grow lighter→darker):
   - Map the ramp to evenly-spaced UV levels in the **400–800** range (or 0/white at the bottom if the lowest value semantically represents zero/no-data).
   - Preserve the count of stops if reasonable; collapse near-duplicates.
4. **Categorical palette** (3+ distinct hues):
   - Apply the **official 9-color order** for the chosen combination: UV 750, partner-A 500, partner-B 400, UV 600, partner-A 700, partner-B 550, UV 450, partner-A 650, partner-B 800.
   - If the source has fewer colors than 9, take the first N from the order.
5. **Text-over-fill colors** — after replacing fills, validate the contrast rule: black text below level 500, white text at 500+. Update text colors as needed in the same pass.

## Output

Before edit, post a **dry-run report** to the user:

```
## Brand Color Fix — Dry Run for <file path>

Chosen palette: <UV-only | Combination 1 | 2 | 3>

### Replacement table
| Line | Old | New | Level/name | Notes |

### Adjusted text colors
| Line | Old text | New text | Reason |

### Unmapped (need direction)
| Line | Hex | Suggested approach |

**Apply these changes? (yes / adjust / no)**
```

Once confirmed, use `Edit` to apply each replacement (use `replace_all: true` per hex so every occurrence is updated consistently). After editing, post a short confirmation showing total replacements + any unmapped entries left in the file.

## Safety

- **Never** edit a file the user hasn't named or that isn't currently open.
- **Never** auto-apply without confirmation — even if the user has previously approved similar fixes.
- Do not touch hex codes that aren't colors (e.g. hex inside string literals that are clearly identifiers, lineage tags, or non-visual). When in doubt, ask.
