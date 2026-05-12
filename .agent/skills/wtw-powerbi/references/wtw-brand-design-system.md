# WTW Data Visualization — Official Brand Design System

> **Source**: WTW Data Visualization Guidelines v1.0 (January 2024, full PDF reviewed 2026-05-12).
> **Status**: Authoritative. Where this file conflicts with other references in this skill, this file wins.

---

## 1. Color Philosophy

Color is used strategically to (a) keep data visible and accessible, (b) align with WTW brand, (c) align with existing templates and tools.

Always use:
- **WTW Ultraviolet** (preferred single color), OR
- One of the **three color combinations**, OR
- Limited other uses as outlined.

Never produce a "candy" palette (random multi-color charts). This does not read as WTW.

**Start with one color, add more only as needed.** The goal is to communicate precisely with as few visual elements as possible.

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
| UV Dark | #48086f | 13.63:1 (named brand dark) |

### Contrast rules from the scale

**Contrast levels are identical across all WTW color scales** — any level-400 of any brand color is ~3.15:1 on white, any level-500 is ~4.5:1, regardless of hue.

- **3:1 graphic objects on white** → use level **400** or higher.
- **3:1 graphic objects on GM-50 gray** → use level **450** or higher.
- **4.5:1 text on white** → use level **500** or higher.
- **3:1 graphic objects on GM Light** → use level **550** or higher.
- Below 500 → use **BLACK text on top** to meet 4.5:1.
- 500 and above → use **WHITE text on top** to meet 4.5:1.

> **Working rule**: most data visualizations use **levels 400–800** to retain accessibility on white and gray backgrounds.

---

## 3. The Three Official Color Combinations

When more than one color is needed, pick **one** combination per report and stick to it.

### Combination 1 — Ultraviolet + Fireworks + Coral Reef

| Color       | 400      | 500      | 550      | 600      | 650      | 700      | 750      | 800      |
|-------------|----------|----------|----------|----------|----------|----------|----------|----------|
| Ultraviolet | b07bd6   | 995bc5   | 8e4bbd   | 7f35b2   | 742ca5   | 611e90   | 521380   | 41056d   |
| Fireworks   | —        | d124b8   | —        | —        | 940d81   | 7b086b   | —        | 530247   |
| Coral Reef  | f75784   | db3363   | ca2254   | —        | a0113d   | —        | —        | 5a031f   |

### Combination 2 — Ultraviolet + Stratosphere + Infinity

| Color        | 400      | 500      | 550     | 650      | 700      | 800      |
|--------------|----------|----------|---------|----------|----------|----------|
| Stratosphere | —        | 1a71ef   | —       | 074cad   | 043e8e   | 01285d   |
| Infinity     | 24a19b   | 208382   | 1d7575  | —        | —        | 0f2f31   |

### Combination 3 — Ultraviolet + Submarine + Mandarin

| Color     | 400      | 500      | 550     | 650      | 700      | 800      |
|-----------|----------|----------|---------|----------|----------|----------|
| Submarine | ca8100   | a76900   | 965d00  | 744700   | —        | 3e2400   |
| Mandarin  | —        | c25700   | —       | 8b3700   | 742c00   | 3e2400   |

### Categorical color ORDER rule (9 colors)

Apply in this fixed order so the most recognizable WTW tones lead. Colors are at least 100 levels apart from adjacent colors for adequate contrast.

**Combination 1 (UV + FW + CR):**
UV-750 `#521380` → FW-500 `#d124b8` → CR-400 `#f75784` → UV-600 `#7f35b2` → FW-700 `#7b086b` → CR-550 `#ca2254` → UV-450 `#a56bcd` → FW-650 `#940d81` → CR-800 `#5a031f`

**Combination 2 (UV + ST + IN):**
UV-750 `#521380` → ST-500 `#1a71ef` → IN-400 `#24a19b` → UV-600 `#7f35b2` → ST-700 `#043e8e` → IN-550 `#1d7575` → UV-450 `#a56bcd` → ST-650 `#074cad` → IN-800 `#0f2f31`

**Combination 3 (UV + MA + SU):**
UV-750 `#521380` → MA-500 `#c25700` → SU-400 `#ca8100` → UV-600 `#7f35b2` → MA-700 `#742c00` → SU-550 `#965d00` → UV-450 `#a56bcd` → MA-650 `#8b3700` → SU-800 `#3e2400`

**For 9 colors with Ultraviolet only (single-hue categorical):**
UV-750, UV-500, UV-400, UV-600, UV-700, UV-550, UV-450, UV-650, UV-800

### Extending to 10–12 colors

Insert additional colors after every 3rd position to distribute evenly (level-500 at position 4, level-800 at position 8, level-650 at position 12).

Available extension sets — choose **one** not already in use:

| Color       | 10th (500) | 11th (800) | 12th (650) |
|-------------|------------|------------|------------|
| Fireworks   | #d124b8    | #530247    | #940d81    |
| Coral Reef  | #db3363    | #5a031f    | #a0113d    |
| Stratosphere| #1a71ef    | #01285d    | #074cad    |
| Infinity    | #208382    | #0f2f31    | #1d7575    |
| Submarine   | #a76900    | #3e2400    | #744700    |
| Mandarin    | #c25700    | #3e2400    | #8b3700    |

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

### Gray types (different grays for different contexts)

| Gray              | Purpose                                           |
|-------------------|---------------------------------------------------|
| WTW Gray Matter   | Standard brand gray for collateral and reports   |
| WTW Violet Mist   | UV-tinted gray — for digital design system only  |
| WTW Base Gray     | Cool-tinted gray — for software design system    |
| Black tints       | Unbranded; use for text when needed              |

Use **Gray Matter** for all WTW-branded data visualizations and reports.

### Highlighting with a second color (Gray Matter + accent)

Use Gray Matter as the chart primary, then a single brand color at **level 400+** to draw attention. For Ultraviolet highlights, use UV-400 or above.

---

## 5. WTW Semantic Colors

| Role     | Color name               | Usage |
|----------|--------------------------|-------|
| Success  | WTW Success (teal/green) | Positive outcomes |
| Warning  | WTW Warning (amber/yellow) | Caution — **separate color** from WTW Submarine |
| Error    | WTW Error (red)          | Negative outcomes |

Each has a 0–990 scale. Use level 400+ on white, 500+ for text. Never rely on color alone — pair with text/icon.

> **WTW Warning vs WTW Submarine**: These are different colors. Submarine is a brand combination color (used in Combination 3 charts). Warning is the semantic amber for status/alert meaning only. Do not substitute one for the other.

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

For variance, growth, deviation. Center is white (absence of data) or a level-25 tint (continuous transition).

### Brand-aligned diverging pairs (use by combination)

**Default (most brand-aligned):**
UV ↔ Gray Matter — midpoint: white or GM-25

**Combination 1 pairs:**
- UV ↔ CR — midpoint: white or `#fef7fb`
- CR ↔ ST — midpoint: white or `#fbf8ff`
- FW ↔ IN — midpoint: white or `#f7f8ff`

**Combination 2 pairs:**
- UV ↔ ST — midpoint: white or `#f9f8ff`
- ST ↔ FW — midpoint: white or `#faf8fe`
- IN ↔ ST — midpoint: white or `#f2faff`

**Combination 3 pairs:**
- UV ↔ SU — midpoint: white or `#fff7fa`
- SU ↔ ST — midpoint: white or `#f5faf7`
- MA ↔ ST — midpoint: white or `#f5faf5`

Rules:
- Use darker colors further from center, lighter toward center.
- Use prescribed pairings only — do not mix across combinations.
- Use as many color stops as needed.

### Alternate diverging palettes (special semantic use only)

Use **only** when a specific positive/negative or hot/cold meaning is required and the brand palette cannot express it. These are not WTW brand combinations — use carefully; may conflict with other elements.

**Positive to negative (green ↔ red):**
`#004030` `#005c47` `#00785e` `#1f964a` `#54b545` `#8cd14a` `#cce84f` `#f7f7bf` ← mid → `#faf2de` `#f7d691` `#fcb052` `#fc7833` `#ed4729` `#d11f14` `#9e1730` `#6e1221`

Compact (5-stop): `#004d3b` `#38a645` `#edf08c` `#fac26b` `#de331f`

**Cool to hot (blue ↔ red):**
`#411f86` `#3646ae` `#3464d0` `#3582ef` `#57a4f1` `#7cc8f0` `#a6e6e3` `#e4f7f4` ← mid → `#faf5be` `#f7db14` `#f4b425` `#fb7b2b` `#ee4829` `#d01e14` `#9e1830` `#6e1121`

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

### Background color accessibility thresholds

| Background          | Min color level for graphic objects (3:1) | Min color level for text (4.5:1) |
|---------------------|-------------------------------------------|----------------------------------|
| White               | 400                                       | 500                              |
| Gray Matter-50      | 450                                       | 550                              |
| Gray Matter Light   | 500                                       | 600                              |

Prefer **white backgrounds** for data visualizations. If using gray, use GM-50 (not full GM Light) as it requires smaller color shifts.

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

| Element        | Weight           | Size      | Color    |
|----------------|------------------|-----------|----------|
| Figure number  | Regular          | 8px/10px  | GM-700 / black |
| Chart title    | Semibold         | 8pt/10pt  | GM-900 / black |
| Chart subtitle | Regular          | 8pt/10pt  | GM-700   |
| Data/axis      | Regular          | 8pt/10pt  | GM-900   |
| Legend         | Medium           | 8pt/10pt  | GM-900   |
| Caption        | Regular          | 8pt/10pt  | GM-900   |

### Accessibility rules for type

- Minimum **live text**: 16px.
- Minimum **embedded text in image**: 18px.
- Keep text **horizontal** where possible.
- **Do not obscure text** — never place over busy chart areas or grid lines.
- Place text in **high-contrast** zones (solid color fills, white areas, or inside a call-out).

---

## 10. Accessibility Standard (WCAG AA)

### Contrast requirements

| Element                                  | Minimum contrast |
|------------------------------------------|------------------|
| Normal text (<18pt)                      | 4.5:1            |
| Large text (≥18pt or ≥14pt bold)         | 3:1              |
| Graphic objects (bars, lines, non-text)  | 3:1              |
| Logos / pure decoration                  | exempt           |

### Multi-color chart rules

- **Maximum 3 solid colors touching** (including background) without a divider.
- For 4+ colors: add a **white/background-color outline** (3px preferred) around each shape — each color then only needs to contrast against the outline, not each other.
- Any two colors ≥400 levels apart automatically meet the 3:1 requirement.

### Power BI specific limitation

**Power BI does not reproduce outlines around shapes.** Therefore:
- Designs should use colors that meet contrast requirements without relying on outlines.
- Ensure colors touching each other are ≥400 levels apart.
- Include a data table as an accessibility alternative for complex multi-color charts.

### Never rely on color alone

Always pair color with text labels, icons, patterns/shapes, or position/order.

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

### Axis and grid lines

| Context     | 1px informative line (4.5:1) | 3px informative line (3:1) |
|-------------|------------------------------|----------------------------|
| On white    | GM-500                       | GM-400                     |
| On GM-50    | GM-600                       | GM-500                     |

Decorative lines (not needed to read the data) are exempt from contrast requirements.

---

## 12. Project-specific Defaults (this workspace)

- **Borders OFF by default**. Only add a border when it serves a purpose (separation, contrast requirement). When used, **`border-radius: 10px`**.
- Use the **Corporate palette** (Ultraviolet) for all WTW-branded reports unless explicit CRM/sales-operations context warrants the Indigo palette.
- No emojis in code, comments, or measure expressions. (Emojis in HTML card OUTPUT are allowed.)
- All HTML cards use `font-family: 'Segoe UI', sans-serif;` — Graphik (print brand font) is not available in Power BI.
- **No gradients** in data visualization fills — solid colors only (limited pattern fills for accessibility where needed).
- **No graphic/image fills** in charts.

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
VAR _uvDark = "#48086F"  // named brand dark

-- Gray Matter
VAR _gmLight = "#E6E6E6"
VAR _gmMid   = "#BFBFBF"
VAR _gmDark  = "#808080"
VAR _gm400   = "#8F9194"
VAR _gm700   = "#414244"
VAR _gm900   = "#171718"

-- Combination 1 partners (UV + Fireworks + Coral Reef)
VAR _fw500 = "#D124B8"
VAR _fw650 = "#940D81"
VAR _fw700 = "#7B086B"
VAR _fw800 = "#530247"
VAR _cr400 = "#F75784"
VAR _cr500 = "#DB3363"
VAR _cr550 = "#CA2254"
VAR _cr650 = "#A0113D"
VAR _cr800 = "#5A031F"

-- Combination 2 partners (UV + Stratosphere + Infinity)
VAR _st500 = "#1A71EF"
VAR _st650 = "#074CAD"
VAR _st700 = "#043E8E"
VAR _st800 = "#01285D"
VAR _in400 = "#24A19B"
VAR _in500 = "#208382"
VAR _in550 = "#1D7575"
VAR _in800 = "#0F2F31"

-- Combination 3 partners (UV + Submarine + Mandarin)
VAR _su400 = "#CA8100"
VAR _su500 = "#A76900"
VAR _su550 = "#965D00"
VAR _su650 = "#744700"
VAR _su800 = "#3E2400"
VAR _ma500 = "#C25700"
VAR _ma650 = "#8B3700"
VAR _ma700 = "#742C00"
VAR _ma800 = "#3E2400"
```
