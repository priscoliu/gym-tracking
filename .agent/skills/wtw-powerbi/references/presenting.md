# Dashboard Presentation Framework

How to present a WTW Power BI dashboard to stakeholders. Never give a "tour of the charts" — use a data storytelling framework that leads with the answer and forces the audience to care before you show them the data.

## The Three-Framework Stack

Combine these three methods in every stakeholder presentation:

| Framework | Role |
|---|---|
| **McKinsey Pyramid Principle** | Answer first, evidence second — leads with the business conclusion |
| **ABT (And-But-Therefore)** | Narrative structure — Setup → Conflict → Resolution |
| **"So What?" test** | Forces you to translate data into business impact before moving on |

---

## Structure

### Opening — The Answer First (Pyramid Principle)

State the business conclusion before showing any data. Executives should know the point of the meeting in the first 30 seconds.

> *"This dashboard will show us how moving clients from 1 product to multi-product will materially increase revenue — and it will tell us exactly which clients to call."*

Do not open with: "Let me walk you through the dashboard..."

---

### Act 1 — The Setup *(And… this is where we are)*

Anchor the audience in current reality using your KPI strip. State facts without editorialising.

> *"We manage X active clients. Average revenue per client is $Y. Average product density is Z classes per client."*

Briefly acknowledge what the old reporting showed — and why it wasn't enough.

> *"Until recently, we tracked this by geography and time. Useful for health checks. Not useful for knowing what to do on Monday morning."*

---

### Act 2 — The Conflict *(But… here is the problem)*

Name the structural issue your dashboard was designed to surface. Use your highest-impact KPI as the hook.

> *"But mapping the book by product depth reveals a concentration problem. X% of our clients hold exactly one product class — that is N clients. Two thirds of our portfolio is single-line."*

**Deliver the "So What?"** — translate the problem into dollars before moving on.

> *"So what does that cost us? Single-class clients generate $X on average. Four-plus class clients generate $Y. That is a Zx revenue multiplier. We have N clients sitting at the bottom of that curve."*

Do not move to the resolution until the audience has felt the size of the opportunity.

---

### Act 3 — The Resolution *(Therefore… here is what we do)*

Introduce the dashboard as the engine, not the report. Walk through each key visual in terms of the action it enables — not what it shows.

**Frame each visual as a decision tool:**
- Not: *"This heatmap shows penetration rates by segment."*
- But: *"This heatmap tells a sales manager which product to lead with in a client meeting before they walk in the door."*

End with a concrete next action:
> *"The ask is not a system change. It's a behaviour change: use product density as the primary lens for account planning, not revenue rank or geography."*

---

## "So What?" Test (apply to every data point before presenting it)

Ask yourself three questions before stating any number:

1. **So what does this mean for the business?** (translate data → impact)
2. **So what should we do about it?** (translate impact → action)
3. **So what happens if we do nothing?** (translate inaction → cost)

If you can't answer all three, don't present the number yet.

---

## Presentation Tips

**Start with the headline**: State the conclusion before opening the report. The first sentence should be the "therefore", not the "and".

**Pause after the multiplier**: The revenue step-function chart (class depth vs average revenue) is where the audience reacts. Let the number land before continuing.

**Distinguish reporting from action**: Make clear this is a decision tool, not a status update. The question it answers is "what should we do next?" — not "what happened?"

**One visual, one point**: When walking through the heatmap or matrix, pick one specific cell or insight to highlight. Never describe the whole visual — describe the most important thing it reveals.

---

## Loom Dashboard Script Template

Adapt this script to any cross-sell / whitespace dashboard:

```
OPENING
"This dashboard exists to answer one question: which clients should we call 
this quarter, and what should we sell them?"

ACT 1 — SETUP
"We manage [N] active CRB clients. Average revenue per client is [$X].
Average product density is [Y] classes per client.
Until recently, reporting tracked this by [geography/time] — useful for 
health checks, not useful for knowing what to do on Monday."

ACT 2 — CONFLICT
"But mapping the book by product depth reveals a concentration problem.
[X]% of our clients hold exactly one product class. That is [N] clients.

So what does that cost us?
Single-class clients generate [$X] on average.
Four-plus class clients generate [$Y] — a [Z]x revenue multiplier.
We have [N] clients sitting at the bottom of that curve."

ACT 3 — RESOLUTION
"Therefore, we rebuilt this dashboard as a cross-sell engine.

[Visual 1] — KPI strip: the 1-LOB concentration figure is the target.
Every quarter we want to watch it fall.

[Visual 2] — Revenue step-function: every broker sees the ROI of one 
cross-sell conversation before they look at a single client name.

[Visual 3] — Penetration heatmap: maps product gap by segment.
[Segment] clients are [X]% missing [Product]. 

[Visual 4] — Client page: select a client. The card shows revenue,
product lines held, and whitespace pills — the conversation starter
before any meeting."

CLOSE
"The ask is not a system change. It's a behaviour change:
use product density as the primary lens for account planning.
The data shows the opportunity. This dashboard makes it actionable.
The only variable is execution."
```
