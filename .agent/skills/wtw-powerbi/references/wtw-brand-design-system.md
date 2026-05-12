# WTW Data Visualization — Official Brand Design System

> **Source**: WTW Data Visualization Guidelines (brand book PDF, captured 2026-05-12).
> **Status**: Authoritative. Where this file conflicts with other references in this skill, this file wins.

---

## 1. Color Philosophy

Color is used strategically to (a) keep data visible and accessible, (b) align with WTW brand, (c) align with existing templates and tools.

Always use:
- **WTW Ultraviolet** (preferred single color), OR
- One of the **three color combinations**, OR
- Limited other uses as outlined.

Never produce a "candy" palette (random multi-color charts). This does not read as WTW.

---

## 2. WTW Ultraviolet Scale (Primary Brand Color)

Scale runs 0 (white) to 990 (near-black). Lower number = lighter. Brand purple `#7F35B2` sits at level **600**.

| Level | Hex      | Contrast on white |
|-------|----------|-------------------|
| 0     | #FFFFFF  | 1:1               |
| 50    | (light)  | 1.1:1             |
| 100   | (light)  | 1.19:1            |
| 200   | (light)  | 1.61:1            |
| 300   | (light)  | 2.2:1             |
| 400   | #b07bd6  | 3.15:1            |
| 450   | #a56bcd  | 3.76:1            |
| 500   | #995bc5  | 4.5:1             |
| 550   | #8e4bbd  | 5.39:1            |
| 600   | #7f35b2  | 6.87:1 (brand)    |
| 650   | #742ca5  | 7.93:1            |
| 700   | #611e90  | 10:1              |
| 750   | #521380  | 11.9:1            |
| 800   | #41056d  | 14.3:1            |
| UV Dark | #48086f | (single shade, alt to 750) |

### Contrast rules from the scale

- **3:1 graphic objects on white** → use level **400** or higher.
- **3:1 graphic objects on gray** (Base-50 / Gray Matter Light) → use level **450** or higher.
- **4.5:1 text on white** → use level **500** or higher.
- **3:1 graphic objects on gray** → use level **550** or higher.
- Below 500 → use **BLACK text on top** to meet 4.5:1.
- 500 and above → use **WHITE text on top** to meet 4.5:1.

> **Working rule**: most data visualizations use **levels 400–900** to retain accessibility on white and gray backgrounds.

---

## 3. The Three Official Color Combinations

When more than one color is needed, pick **one** combination per report and stick to it.

### Combination 1 — Ultraviolet + Fireworks + Coral Reef

| Color       | 400      | 500      | 550      | 600      | 650      | 700      | 750      | 800      |
|-------------|----------|----------|----------|----------|----------|----------|----------|----------|
| Ultraviolet | b07bd6   | 995bc5   | 8e4bbd   | 7f35b2   | 742ca5   | 611e90   | 521380   | 41056d   |
| Fireworks   | —        | d124b8   | —        | —        | 940d81   | —        | —        | 530247   |
| Coral Reef  | f75784   | db3363   | ca2254   | —        | a0113d   | —        | —        | 5a031f   |

### Combination 2 — Ultraviolet + Stratosphere + Infinity

| Color        | 400      | 500      | 550     | 650      | 700      | 800      |
|--------------|----------|----------|---------|----------|----------|----------|
| Stratosphere | —        | 1a71ef   | —       | 074cad   | 043e8e   | 01285d   |
| Infinity     | 24a19b   | 208382   | 1d7575  | —        | —        | 0f2f31   |

### Combination 3 — Ultraviolet + Submarine + Mandarin

| Color     | 400      | 500      | 550     | 650      | 700      | 800      |
|-----------|----------|----------|---------|----------|----------|----------|
| Submarine | ca8100   | a76900   | 965d00  | —        | —        | 3e2400   |
| Mandarin  | —        | c25700   | —       | 8b3700   | 742c00   | 3e2400   |

### Categorical color ORDER rule (9 colors)

When applying a combination to a categorical chart, apply in this fixed order so the most recognizable WTW tones lead:

**For Combination 1:**
1. UV 750 → 2. FW 500 → 3. CR 400 → 4. UV 600 → 5. FW 700 → 6. CR 550 → 7. UV 450 → 8. FW 650 → 9. CR 800

Same pattern for Combinations 2 and 3 (replace FW/CR with the combo's two partners).

For **9 colors with Ultraviolet only** (single-hue categorical):
UV 750, 500, 400, 600, 700, 550, 450, 650, 800.

---

## 4. WTW Gray Matter

| Element                   | Hex      | Notes                  |
|---------------------------|----------|------------------------|
| Gray Matter Light (10%)   | #e6e6e6  | Subtle background      |
| Gray Matter (25%)         | #bfbfbf  | Standard brand gray    |
| Gray Matter Dark (50%)    | #808080  | Stronger gray for axis |
| Gray Matter 400           | #8F9194  | **3:1 on white — minimum for functional borders** |
| Gray Matter 700           | #414244  | Source / copyright text |
| Gray Matter 900           | #171718  | Body / title text       |

Full GM scale runs 10 → 990 in same level system as Ultraviolet. Same contrast properties.

### Highlighting with a second color (Gray Matter + accent)

Use Gray Matter as the chart primary, then a single brand color at **level 400+** to draw attention. For Ultraviolet highlights, use UV-400 or above.

---

## 5. WTW Semantic Colors

| Role     | Color name      |
|----------|-----------------|
| Success  | WTW Success (teal/green) |
| Caution  | WTW Submarine (amber)    |
| Error    | WTW Error (red)          |

Each has a 0–990 scale. Use level 400+ on white, 500+ for text. Never rely on color alone — pair with text/icon.

---

## 6. Sequential Palettes (Single-hue)

For heatmaps, choropleths, graduated scales.

- **Lighter = lower, darker = higher**. Always.
- **Working range: levels 400–800** for accessibility on white.
- May start at **white (0)** for true zero / no-data — used cautiously, especially on maps where white is also background.
- **Even spacing**: use level-50 or level-100 increments.
- Use Ultraviolet as preferred. Other combinations have their own sequential scales (FW/CR for combo 1, ST/IN for combo 2, SU/MA for combo 3).

---

## 7. Diverging Palettes

For variance, growth, deviation.

- **Default (most brand-aligned)**: Ultraviolet (negative) ↔ white/GM-25 ↔ Gray Matter (positive)
- **Combination 1**: Ultraviolet ↔ Coral Reef; Coral Reef ↔ Stratosphere; Fireworks ↔ Infinity
- **Combination 2**: Ultraviolet ↔ Stratosphere; Stratosphere ↔ Fireworks; Infinity ↔ Stratosphere
- **Combination 3**: Ultraviolet ↔ Submarine; Submarine ↔ Stratosphere; Mandarin ↔ Stratosphere
- **Special use** (when a specific semantic meaning is needed): green↔red, cool↔hot. Use carefully; may break the rest of the layout's combination.

Decide whether the **midpoint should be white** (absence of data) or **tinted** (continuous transition).

---

## 8. Visualization Structure

Every viz has **four parts**:

1. **Container** — outer shape, padding, optional border.
2. **Header** — figure number (optional), title (required), subtitle (optional).
3. **Body** — the chart itself.
4. **Footer** — caption, source, copyright.

### Container

- Width/height determined by content.
- Padding **consistent** across a document.
- **24px** padding default (top/bottom; sides too where stand-alone).
- Borders are **optional and decorative by default — do NOT add borders unless they serve a purpose**.
- If a border is needed:
  - Decorative: GM Light or Base Gray.
  - Functional (3:1 contrast required): **GM-400 `#8F9194` or darker**.
  - Always a **simple solid line**.
  - **Border radius = 10px** (project default for this workspace).

### Header

- Title — descriptive, succinct, always present even when content is obvious.
- Subtitle — context or key takeaway (optional).
- Figure number — `Figure N` first use, `Fig. N` thereafter; on its own line or beside the title.

### Body

- **Left-aligned** by default, fitting full width of the body.
- **Centered** when content doesn't naturally fill the width (e.g. pie chart).

### Footer

- Caption + Source + Copyright.
- **24px vertical space** between body and footer.
- Multiple footer elements separated by **16px**.

---

## 9. Typography

### Digital (stand-alone, social, in-app)

| Element        | Weight             | Size       | Color                  |
|----------------|--------------------|------------|------------------------|
| Figure number  | Regular / Semibold | 24px/32px  | GM-900 (#171718) or black |
| Chart title    | Semibold           | 24px/32px  | GM-900                 |
| Chart subtitle | Regular            | 18px/24px  | GM-700 (#414244)       |
| Data labels    | Regular / Semibold | 11–18px    | GM-900                 |
| Axis labels    | Regular            | 11–18px    | GM-900                 |
| Legend labels  | Medium             | 11–18px    | GM-900                 |
| Caption        | Regular            | 14px/20px  | GM-900                 |
| Source         | Regular            | 12px/16px  | GM-700                 |
| Copyright      | Regular            | 12px/16px  | GM-700                 |

### InDesign / print collateral

| Element       | Weight     | Size       | Color    |
|---------------|------------|------------|----------|
| Figure number | Regular    | 8px/10px   | GM-700 / black |
| Chart title   | Semibold   | 8pt/10pt   | GM-900 / black |
| Chart subtitle| Regular    | 8pt/10pt   | GM-700   |
| Data/axis     | Regular    | 8pt/10pt   | GM-900   |
| Legend        | Medium     | 8pt/10pt   | GM-900   |
| Caption       | Regular    | 8pt/10pt   | GM-900   |

### Accessibility rules for type

- Minimum **live text**: 16px.
- Minimum **embedded text in image**: 18px.
- Keep text **horizontal** where possible.
- **Do not obscure text** — never place over busy chart areas or grid lines.
- Place text in **high-contrast** zones (solid color fills, white areas, or inside a call-out).

---

## 10. Accessibility Standard (WCAG AA)

### Contrast requirements

| Element              | Minimum contrast |
|----------------------|------------------|
| Normal text (<18pt)  | 4.5:1            |
| Large text (≥18pt or ≥14pt bold) | 3:1 |
| Graphic objects (bars, lines, non-text) | 3:1 |
| Logos / pure decoration | exempt        |

### Solving contrast challenges

- **Use outlines**: add a border in the background color (typically white) around shapes so each color borders the outline, not the next color.
- **No more than 3 solid colors touching** if relying on color contrast alone.
- For complex viz: reduce colors, use **patterns** / hatching, use **different line types** (dotted, dashed), use **markers** (circle/square/triangle), label directly.

### Never rely on color alone

Always pair color with:
- Text labels,
- Icons,
- Patterns or shapes,
- Position/order.

### Alternative paths

For complex viz that can't fully meet contrast:
- Provide a **text data table** as alternative.
- Add **callouts / annotations** for key data points.
- Use **rollovers / tooltips** to expose values on interaction.

---

## 11. Graphic Components

### Legends and keys

- **Prefer direct labels** over legends.
- Legends are optional context; place consistently within a publication.
- **Never** use both a legend and direct labels for the same information.

### Markers

- **Simple shapes only**: circle, square, triangle.
- **Similar sizes** across all markers.
- Large enough to be easily seen; outline if needed to distinguish from data and grid.

### Call-outs

- Shape: **rectangle** with optional **small arrow** pointing to the data.
- Arrow always aligned to the **center of the top, bottom, or side** of the box.
- Colors: white, Gray Matter, or Ultraviolet (level 400+). Brand-palette colors with caution. Semantic colors for change/increase/decrease.
- Optional **drop shadow**: 50% opacity, no offset, 5px size.
- Text must meet contrast on the fill color.

---

## 12. Project-specific Defaults (this workspace)

- **Borders OFF by default**. Only add a border when it serves a purpose (separation, contrast requirement). When used, **`border-radius: 10px`**.
- Use the **Corporate palette** (Ultraviolet) for all WTW-branded reports unless explicit CRM/sales-operations context warrants the Indigo palette.
- No emojis in code, comments, or measure expressions. (Emojis in HTML card OUTPUT are allowed.)
- All HTML cards use `font-family: 'Segoe UI', sans-serif;` — Graphik (print brand font) is not available in Power BI.

---

## 13. Quick Hex Reference (DAX-ready)

```dax
-- WTW Ultraviolet ramp (sequential / categorical)
VAR _uv400 = "#B07BD6"
VAR _uv450 = "#A56BCD"
VAR _uv500 = "#995BC5"
VAR _uv550 = "#8E4BBD"
VAR _uv600 = "#7F35B2"   // brand
VAR _uv650 = "#742CA5"
VAR _uv700 = "#611E90"
VAR _uv750 = "#521380"
VAR _uv800 = "#41056D"

-- Gray Matter
VAR _gmLight = "#E6E6E6"
VAR _gmMid   = "#BFBFBF"
VAR _gmDark  = "#808080"
VAR _gm400   = "#8F9194"
VAR _gm700   = "#414244"
VAR _gm900   = "#171718"

-- Combination 1 partners
VAR _fw500 = "#D124B8"
VAR _fw650 = "#940D81"
VAR _fw800 = "#530247"
VAR _cr400 = "#F75784"
VAR _cr500 = "#DB3363"
VAR _cr550 = "#CA2254"
VAR _cr650 = "#A0113D"
VAR _cr800 = "#5A031F"

-- Combination 2 partners
VAR _st500 = "#1A71EF"
VAR _st650 = "#074CAD"
VAR _st700 = "#043E8E"
VAR _st800 = "#01285D"
VAR _in400 = "#24A19B"
VAR _in500 = "#208382"
VAR _in550 = "#1D7575"
VAR _in800 = "#0F2F31"

-- Combination 3 partners
VAR _su400 = "#CA8100"
VAR _su500 = "#A76900"
VAR _su550 = "#965D00"
VAR _su800 = "#3E2400"
VAR _ma500 = "#C25700"
VAR _ma650 = "#8B3700"
VAR _ma700 = "#742C00"
VAR _ma800 = "#3E2400"
```
