# Project Management Page — Gantt Chart Design

**Date:** 2026-03-30
**Status:** Approved
**Visual:** Full Vega spec in Deneb custom visual

---

## Stakeholder Requirements

- Delivery timeline with upcoming release dates
- 30 / 60 / 90 day milestones
- Risks

---

## Data Source

**Table:** `fact_project_tasks`

| Field | Column | Notes |
|---|---|---|
| Task Name | `TaskName` | text |
| Start | `Start` | date |
| End | `EffectiveFinish` | ActualFinish ?? Finish |
| Duration | `Duration` | days (number) |
| Progress | `PctComplete` | percentage |
| Grouping | `MilestoneHorizon` | Overdue / Next 30/60/90 Days / Beyond 90 Days |
| Risk flag | `IsCritical` | boolean |
| Delay flag | `IsDelayed` | boolean |

---

## Visual Design

### Engine
Full Vega spec inside Deneb custom visual. Fields dragged in from the data pane; spec references them by name.

### Layout
Split panel matching reference:
- **Left panel** — text table: Task Name · Duration · % Complete
- **Right panel** — Gantt timeline bars

### Grouping
Rows grouped by `MilestoneHorizon` in urgency order:
1. Overdue
2. Next 30 Days
3. Next 60 Days
4. Next 90 Days
5. Beyond 90 Days

Group header rows rendered as bold section labels.

### Bar Encoding
Each task = two layered bar marks:
- **Background bar** — full planned duration, lighter opacity
- **Foreground bar** — `PctComplete` fill, solid color

### Color (inline risk encoding — no separate risk section)
| Condition | Color |
|---|---|
| `IsCritical = true` | `#DC2626` Red |
| `IsDelayed = true` | `#F59E0B` Amber |
| On-track | `#7C3AED` WTW Purple |
| Completed (100%) | `#22C55E` Green |

### Progress Rings
Circular arc mark per row in the left panel showing `PctComplete`. Matches reference style.

### Today Marker
Vertical `rule` mark at today's date across the full chart height.

### Timeline Header
Week / date labels above the Gantt bars.

---

## Workflow

1. Add Deneb custom visual to Power BI canvas
2. Drag fields: `TaskName`, `Start`, `EffectiveFinish`, `Duration`, `PctComplete`, `MilestoneHorizon`, `IsCritical`, `IsDelayed`
3. Open Deneb editor → paste Full Vega JSON spec
4. Iterate: Claude updates JSON → user repastes

---

## Out of Scope
- Collapsible group rows (static grouping only)
- Assignee avatars (no image URLs in data)
- Baseline vs actual variance bars
