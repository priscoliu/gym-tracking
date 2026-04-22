# Interactions & Animation Patterns

Motion and hover patterns for WTW HTML cards and standalone web components.

## Table of Contents
1. [Principles](#principles)
2. [CSS Transitions](#css-transitions)
3. [Hover States](#hover-states)
4. [Progress Bar Animation](#progress-bar-animation)
5. [Loading States & Skeletons](#loading-states--skeletons)
6. [Micro-interactions](#micro-interactions)
7. [DAX-Safe Animation Notes](#dax-safe-animation-notes)

---

## Principles

- **One well-timed animation beats many scattered ones.** A single progress bar fill on load creates more impact than five simultaneous effects.
- **Motion has purpose.** Animate to communicate state change, not to decorate.
- **Keep it fast.** Max 300ms for UI interactions, 600ms for data reveals.
- **Power BI HTML cards have limited CSS support** — test all transitions in the actual visual before committing.

---

## CSS Transitions

### Standard Transition Stack

```css
/* Default smooth transition for most elements */
transition: all 200ms ease-out;

/* Color/background changes */
transition: background-color 150ms ease, color 150ms ease, border-color 150ms ease;

/* Transform + opacity (for reveal effects) */
transition: transform 250ms ease-out, opacity 250ms ease-out;

/* Shadow depth change */
transition: box-shadow 200ms ease;
```

### Timing Reference

| Duration | Use |
|----------|-----|
| 100ms | Instant feedback (button press, toggle) |
| 150ms | Color/border changes |
| 200ms | Hover lift, shadow |
| 250ms | Slide-in, fade-in |
| 400ms | Card entry animation |
| 600ms | Progress bar fill |
| 1200ms | Long progress bar (shows deliberate progress) |

---

## Hover States

### Card Lift (Container Hover)

```css
.wtw-card {
  transition: transform 200ms ease-out, box-shadow 200ms ease;
}
.wtw-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 14px 20px -4px rgba(0,0,0,0.12), 0 6px 8px -2px rgba(0,0,0,0.07);
}
```

### Metric Card Highlight

```css
.metric-card {
  transition: background-color 150ms ease, border-color 150ms ease;
  border: 1px solid #F3F4F6;
}
.metric-card:hover {
  background-color: #F9FAFB;
  border-color: #E5E7EB;
}
```

### WTW Purple Button

```css
.btn-primary {
  background-color: #7C3AED;
  transition: background-color 150ms ease, transform 100ms ease;
}
.btn-primary:hover  { background-color: #6D28D9; }
.btn-primary:active { background-color: #5B21B6; transform: scale(0.98); }
```

### Status Badge Hover

```css
.status-badge {
  transition: opacity 150ms ease;
}
.status-badge:hover {
  opacity: 0.85;
}
```

### DAX Hover Overlay Pattern

Power BI HTML cells don't support `:hover` in DAX-generated HTML. For hover-like effects, use JavaScript within the HTML cell:

```dax
-- Wrap the card in a div with onmouseenter/onmouseleave
VAR _hoverScript =
"<div onmouseenter=""this.style.transform='translateY(-2px)';this.style.boxShadow='0 14px 20px rgba(0,0,0,0.12)'"
& " onmouseleave=""this.style.transform='';this.style.boxShadow='0 10px 15px -3px rgba(0,0,0,0.1)'"
& " style='transition: transform 200ms ease, box-shadow 200ms ease;'>"
```

---

## Progress Bar Animation

### CSS Keyframe Fill (standalone HTML)

```css
@keyframes fillProgress {
  from { width: 0%; }
  to   { width: var(--progress-width); }
}

.progress-fill {
  animation: fillProgress 600ms ease-out forwards;
  animation-delay: 200ms;  /* slight delay after card appears */
  width: 0%;               /* start at 0 */
}
```

**Usage**:
```html
<div class="progress-fill" style="--progress-width: 78%"></div>
```

### DAX Progress Bar with Inline Transition

Since DAX HTML doesn't support `@keyframes`, use inline `transition` with JavaScript trigger:

```dax
VAR _progressBarHTML =
"<div style='width: 100%; height: 10px; background: #F1F5F9; border-radius: 5px; overflow: hidden;'>" &
"<div id='pb_" & [Card ID] & "' style='width: 0%; height: 100%; background: " & _gradientFill & "; border-radius: 5px; transition: width 800ms ease-out;'></div>" &
"</div>" &
"<script>setTimeout(function(){document.getElementById('pb_" & [Card ID] & "').style.width='" & _progressWidthCSS & "'},100);</script>"
```

> Note: Script-based animation may not work in all Power BI rendering environments. Test in the target workspace.

### Simple Static Bar (Most Compatible)

When animation isn't critical, skip the complexity:

```dax
VAR _progressBarHTML =
"<div style='width: 100%; height: 10px; background: #F1F5F9; border-radius: 5px; overflow: hidden;'>" &
"<div style='width: " & _progressWidthCSS & "; height: 100%; background: " & _gradientFill & "; border-radius: 5px;'></div>" &
"</div>"
```

---

## Loading States & Skeletons

### Shimmer Skeleton (standalone HTML)

Use while data is loading in web components:

```css
@keyframes shimmer {
  0%   { background-position: -200% 0; }
  100% { background-position: 200% 0; }
}

.skeleton {
  background: linear-gradient(90deg, #F3F4F6 25%, #E5E7EB 50%, #F3F4F6 75%);
  background-size: 200% 100%;
  animation: shimmer 1.4s infinite ease-in-out;
  border-radius: 4px;
}
```

**Skeleton card structure**:
```html
<div style="padding: 20px; background: #fff; border-radius: 12px; border: 1px solid #E5E7EB;">
  <div class="skeleton" style="height: 14px; width: 60%; margin-bottom: 16px;"></div>
  <div class="skeleton" style="height: 36px; width: 45%; margin-bottom: 12px;"></div>
  <div class="skeleton" style="height: 10px; width: 100%; margin-bottom: 8px;"></div>
  <div class="skeleton" style="height: 10px; width: 80%;"></div>
</div>
```

### DAX "No Data" State

When measures return BLANK(), show a styled placeholder:

```dax
RETURN
IF(
    ISBLANK([Sales Total]),
    "<div style='padding: 20px; text-align: center; color: #9CA3AF; font-size: 14px;'>
        <div style='font-size: 24px; margin-bottom: 8px;'>—</div>
        <div>No data for selected period</div>
    </div>",
    -- normal card HTML
    _cardHTML
)
```

---

## Micro-interactions

### Badge Pulse (draw attention to critical status)

```css
@keyframes pulse {
  0%, 100% { opacity: 1; }
  50%       { opacity: 0.7; }
}

.badge-critical {
  animation: pulse 2s ease-in-out infinite;
}
```

### Number Count-Up (web components, not DAX)

```javascript
function countUp(element, target, duration = 800) {
  const start = 0;
  const step = (timestamp) => {
    const progress = Math.min((timestamp - startTime) / duration, 1);
    const eased = 1 - Math.pow(1 - progress, 3);  // cubic ease-out
    element.textContent = Math.floor(eased * target).toLocaleString();
    if (progress < 1) requestAnimationFrame(step);
  };
  const startTime = performance.now();
  requestAnimationFrame(step);
}
```

### Tooltip Reveal

```css
.tooltip-trigger { position: relative; }

.tooltip {
  position: absolute;
  bottom: calc(100% + 8px);
  left: 50%;
  transform: translateX(-50%);
  background: #1E293B;
  color: #fff;
  padding: 6px 10px;
  border-radius: 6px;
  font-size: 12px;
  white-space: nowrap;
  opacity: 0;
  pointer-events: none;
  transition: opacity 150ms ease;
}

.tooltip-trigger:hover .tooltip { opacity: 1; }
```

---

## DAX-Safe Animation Notes

Power BI HTML visuals run in a sandboxed iframe. Compatibility varies:

| Feature | Status | Notes |
|---------|--------|-------|
| `transition` (inline CSS) | ✅ Works | Most reliable approach |
| CSS `@keyframes` | ⚠️ Partial | Works in some environments, not all |
| `<script>` tags | ⚠️ Often blocked | Depends on tenant security settings |
| `:hover` pseudo-class | ❌ No | Use `onmouseenter` JS inline instead |
| CSS variables (`var()`) | ⚠️ Partial | Prefer inline values in DAX measures |

**Safe rule**: In DAX measures, use only inline `style=""` attributes with `transition` property. Never rely on `@keyframes` or external `<style>` blocks for critical functionality.
