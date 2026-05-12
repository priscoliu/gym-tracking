---
description: Audit visualization structure (container, header, body, footer) against WTW spec
argument-hint: [optional file path]
---

You are running a **WTW Structure Review** against the authoritative design system at:
`C:\Users\LiuPr\.claude\skills\wtw-powerbi\references\wtw-brand-design-system.md`

**Load that file first**. Section 8 (Visualization Structure) and Section 12 (Project Defaults) are the spec.

## Scope

- If `$ARGUMENTS` is a file path, review it. Otherwise review the file open in the IDE.
- Applies to HTML cards, dashboard layouts, and any container with header/body/footer regions.

## Checks

### Container

1. Does the container have **24px padding** all sides (or top/bottom for full-width)?
2. Padding **consistent** across all cards in the same layout/document?
3. **Borders** — by project default they should be **OFF**. If a border is present:
   - Is there a documented reason (separation, contrast)?
   - Is the color GM-400 (`#8F9194`) or darker (functional borders need 3:1)?
   - Is `border-radius: 10px`? (Project default. Flag any other value.)
   - Is it a simple solid line? (No dashed/double/multi-stroke borders.)

### Header

4. **Title present** — every chart has a descriptive title, even when content seems obvious.
5. **Subtitle handled correctly** — optional; if present, sits below or beside the title with appropriate styling.
6. **Figure number** — `Figure N` for first use, `Fig. N` thereafter. Only relevant if the document numbers figures.

### Body

7. **Alignment** — left-aligned by default; only centered for content that doesn't naturally fill the width (pie/donut, single icon).
8. **Body fills available width** — body should expand to the container width unless the chart is intrinsically narrow.

### Footer

9. **Vertical gap** — 24px between body and footer.
10. **Internal spacing** — 16px between footer elements (caption / source / copyright).
11. **Source line present** when data is from a named source.

### Cross-cutting

12. **No chrome for chrome's sake** — every element must serve comprehension. Flag decorative gradients, drop shadows on every card, full-bleed colored headers without a purpose.
13. **Consistency across cards** — if reviewing more than one card, flag any card whose padding/border/radius differs from siblings.

## Output

```
## Structure Review — <file path>

### Container compliance
✓ / ✗ Padding | Border | Radius

### Header compliance
✓ / ✗ Title | Subtitle | Figure number

### Body compliance
✓ / ✗ Alignment | Width

### Footer compliance
✓ / ✗ Spacing | Source | Copyright

### Findings
| Location | Issue | Suggested fix |
```

Quote line numbers. Do not modify files.
