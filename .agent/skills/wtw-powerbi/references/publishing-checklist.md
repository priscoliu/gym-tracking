# Publishing Checklist

End-of-task review before handing a Power BI report to a stakeholder. Run through every item — drift compounds, and each unchecked box is a small thing that makes the report look "off" without being able to point to why.

## Layout & Grid

- [ ] All visuals aligned to the 12-column grid
- [ ] Side margins are 60–80px (matches canvas size — 1280×720 or 1440×1080)
- [ ] Visual padding set to 16px (Corporate) or 32px (Modern)
- [ ] Consistent gutter between visuals (8px Corporate / 24px Modern)

## Typography

- [ ] Consistent font sizes — every label, body, KPI follows the typography scale
- [ ] Hero KPI = 24px / 700 (cards), 36px / 700 (dashboard)
- [ ] Section heading = 13px / 600
- [ ] Body / row text = 12px / 400
- [ ] All text uses Segoe UI with `'Segoe UI', sans-serif` fallback

## Color & Shadows

- [ ] Multi-layer shadows applied (no single soft drop-shadow)
- [ ] All shadow values come from `_shadowOuter` / `_shadowInner` tokens
- [ ] Performance colors follow standard thresholds (115% / 100% / 90% / 80%)
- [ ] No `#7C3AED` or other off-brand purples — only `#7F35B2` (Corporate) or `#4f46e5` (Indigo)

## Hygiene

- [ ] All visuals labeled in the Selection pane (no "Visual 12 (1)")
- [ ] Date range visible on the canvas (slicer or text box)
- [ ] KPIs include comparison context — target, prior period, or both
- [ ] Decimal places appropriate for metric type (% to 1dp, $ to 0dp / $K / $M)
- [ ] No emojis in measure names, comments, or labels — only in HTML output where intentional

## Performance

- [ ] Performance Analyzer run — no visual >3s load
- [ ] Cross-filtering behaviour tested — does clicking visual A correctly filter B/C/D?
- [ ] Bookmarks and selections cleared before publish
- [ ] No unused datasets or hidden tables in the model
