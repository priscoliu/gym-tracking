"""
gym_dashboard.py
Parses all cache files, embeds parsed data as JSON, writes gym_dashboard.html.
"""

import json
import re
import os
from datetime import datetime, date, timedelta
from collections import defaultdict

# ── Same translation / parser as gym_analysis.py ──────────────────────────────
TRANSLATIONS = {
    "深蹲": "Squat",
    "腿举": "Leg Press",
    "腿弯举": "Leg Curl",
    "杠铃臀冲": "Barbell Hip Thrust",
    "臀冲架臀冲": "Barbell Hip Thrust",
    "站姿绳索卷腹": "Cable Crunch",
    "负重悬挂抬腿": "Weighted Hanging Leg Raise",
    "杠铃卧推": "Barbell Bench Press",
    "上斜哑铃卧推": "Incline DB Press",
    "双杠臂屈伸": "Weighted Dips",
    "器械坐姿推举": "Shoulder Press",
    "哑铃推肩": "Shoulder Press",
    "侧平举": "Lateral Raise",
    "平板上斜侧平举": "Lateral Raise",
    "直杆绳索下压": "Cable Tricep Pushdown",
    "悬挂抬腿": "Hanging Leg Raise",
    "引体向上": "Pull-up",
    "坐姿划船": "Seated Row",
    "窄距下拉": "Close-grip Lat Pulldown",
    "杠铃罗马尼亚硬拉": "Romanian Deadlift",
    "面拉": "Face Pull",
    "EZ杆二头弯举": "EZ Bar Curl",
    "上斜哑铃弯举": "Incline DB Curl",
}

CACHE_DIR      = os.path.join(os.path.dirname(os.path.abspath(__file__)), "cache")
OUT_PATH       = os.path.join(os.path.dirname(os.path.abspath(__file__)), "gym_dashboard.html")
NUTRITION_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "nutrition_data.json")


def translate(name):
    return TRANSLATIONS.get(name.strip(), name.strip())


def parse_exercises(raw):
    ex_start = re.search(r",1\.", raw)
    if not ex_start:
        return []
    exercise_part = raw[ex_start.start() + 1:]
    blocks = re.split(r",(?=\d+\.)", exercise_part)
    exercises = []
    for block in blocks:
        block = block.strip().strip(",")
        if not block:
            continue
        m = re.match(r"(\d+)\.(.+?)(?:,|$)", block)
        if not m:
            continue
        en_name = translate(m.group(2).strip())
        rest = block[m.end():]
        tokens = [t.strip() for t in rest.split(",") if t.strip()]
        sets = []
        i = 0
        while i < len(tokens):
            sm = re.match(r"(\d+)组$", tokens[i])
            if sm:
                weight = reps = None
                i += 1
                if i < len(tokens) and re.match(r"[\d.]+kg$", tokens[i]):
                    weight = float(tokens[i].replace("kg", ""))
                    i += 1
                if i < len(tokens) and re.match(r"(\d+)次$", tokens[i]):
                    reps = int(re.match(r"(\d+)次$", tokens[i]).group(1))
                    i += 1
                if i < len(tokens) and tokens[i].startswith("time:"):
                    i += 1
                if weight is not None and reps is not None:
                    sets.append({"weight": weight, "reps": reps})
            else:
                i += 1
        exercises.append({"name": en_name, "sets": sets})
    return exercises


def parse_session(raw):
    parts = raw.split(",")
    if len(parts) < 4:
        return None
    try:
        d = datetime.strptime(parts[0].strip(), "%y%m%d").date()
    except ValueError:
        return None

    wtype = parts[2].strip()

    tt = re.search(r"train_time:(\d+)-(\d+)", raw)
    duration_min = None
    if tt:
        diff = (int(tt.group(2)) - int(tt.group(1))) / 60000
        if diff < 180:
            duration_min = round(diff, 1)

    cal_m = re.search(r"calorie:(\d+)", raw)
    cal = int(cal_m.group(1)) if cal_m else None
    if cal and cal > 1000:
        cal = None

    exercises = parse_exercises(raw)
    total_vol = sum(s["weight"] * s["reps"] for ex in exercises for s in ex["sets"])

    return {
        "date": d.isoformat(),
        "type": wtype,
        "duration_min": duration_min,
        "calories": cal,
        "exercises": exercises,
        "total_volume": round(total_vol, 1),
    }


def load_sessions():
    sessions = []
    for fname in sorted(os.listdir(CACHE_DIR)):
        if not fname.endswith(".json"):
            continue
        fpath = os.path.join(CACHE_DIR, fname)
        try:
            data = json.loads(open(fpath, encoding="utf-8").read())
        except Exception:
            continue
        for entry in data:
            if isinstance(entry, str) and entry.strip():
                s = parse_session(entry)
                if s:
                    sessions.append(s)
    return sorted(sessions, key=lambda x: x["date"])


def build_dashboard_data(sessions):
    type_counts = defaultdict(int)
    type_volume = defaultdict(float)
    for s in sessions:
        type_counts[s["type"]] += 1
        type_volume[s["type"]] += s["total_volume"]

    first = sessions[0]["date"]
    last  = sessions[-1]["date"]
    weeks = ((date.fromisoformat(last) - date.fromisoformat(first)).days + 1) / 7
    valid_dur = [s["duration_min"] for s in sessions if s["duration_min"]]
    total_dur = round(sum(valid_dur), 0)

    # Key lift progressions
    LIFTS = ["Squat", "Barbell Bench Press", "Romanian Deadlift"]
    lift_series = {}
    for lift in LIFTS:
        pts = []
        for s in sessions:
            for ex in s["exercises"]:
                if ex["name"] == lift and ex["sets"]:
                    w = [st["weight"] for st in ex["sets"] if st["weight"] > 0]
                    if w:
                        pts.append({"date": s["date"], "weight": max(w)})
                        break
        lift_series[lift] = pts

    # Training days set for heatmap
    training_days = {s["date"]: s["type"] for s in sessions}

    return {
        "summary": {
            "total_sessions": len(sessions),
            "first_date": first,
            "last_date": last,
            "weeks": round(weeks, 1),
            "sessions_per_week": round(len(sessions) / weeks, 1) if weeks else 0,
            "total_duration_min": int(total_dur),
            "avg_duration_min": round(total_dur / len(valid_dur), 1) if valid_dur else 0,
        },
        "split": {
            "Push": type_counts.get("Push", 0),
            "Pull": type_counts.get("Pull", 0),
            "Legs": type_counts.get("Legs", 0),
        },
        "lift_series": lift_series,
        "training_days": training_days,
        "sessions": sessions,
    }


# ── HTML template ──────────────────────────────────────────────────────────────

HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Prisco's Fitness Dashboard</title>
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet" />
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      font-family: 'Inter', system-ui, sans-serif;
      background: #f5f4f1;
      color: #1a1a1a;
      min-height: 100vh;
      padding: 32px 24px 64px;
    }

    .page-header {
      text-align: center;
      margin-bottom: 40px;
    }
    .page-header h1 {
      font-size: 28px;
      font-weight: 700;
      letter-spacing: -0.5px;
      color: #1a1a1a;
    }
    .page-header p {
      font-size: 14px;
      color: #6b6b6b;
      margin-top: 6px;
      font-weight: 400;
    }

    .container {
      max-width: 1080px;
      margin: 0 auto;
    }

    /* Cards */
    .card {
      background: #ffffff;
      border-radius: 12px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.04);
      border-top: 3px solid #d4700a;
      padding: 24px;
      position: relative;
    }
    .card-title {
      font-size: 11px;
      font-weight: 600;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      color: #6b6b6b;
      margin-bottom: 16px;
    }

    /* Summary row */
    .summary-row {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 16px;
      margin-bottom: 24px;
    }
    .stat-card {
      background: #ffffff;
      border-radius: 12px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.08);
      border-top: 3px solid #d4700a;
      padding: 20px 22px;
    }
    .stat-label {
      font-size: 11px;
      font-weight: 600;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      color: #6b6b6b;
      margin-bottom: 8px;
    }
    .stat-value {
      font-size: 32px;
      font-weight: 700;
      color: #1a1a1a;
      line-height: 1;
      letter-spacing: -1px;
    }
    .stat-sub {
      font-size: 13px;
      color: #6b6b6b;
      margin-top: 6px;
    }

    /* Two-col layout */
    .two-col {
      display: grid;
      grid-template-columns: 1fr 1.6fr;
      gap: 16px;
      margin-bottom: 24px;
    }

    /* Split chart */
    .split-bars { margin-top: 4px; }
    .split-row {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-bottom: 14px;
    }
    .split-label {
      font-size: 13px;
      font-weight: 500;
      color: #1a1a1a;
      width: 40px;
      flex-shrink: 0;
    }
    .split-bar-track {
      flex: 1;
      height: 10px;
      background: #f0ece6;
      border-radius: 5px;
      overflow: hidden;
    }
    .split-bar-fill {
      height: 100%;
      border-radius: 5px;
    }
    .split-count {
      font-size: 12px;
      color: #6b6b6b;
      width: 60px;
      text-align: right;
      flex-shrink: 0;
    }

    /* Lift charts */
    .lifts-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 16px;
    }
    .lift-chart-wrap {
      background: #ffffff;
      border-radius: 12px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.08);
      border-top: 3px solid #d4700a;
      padding: 20px;
    }
    .lift-title {
      font-size: 11px;
      font-weight: 600;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      color: #6b6b6b;
      margin-bottom: 4px;
    }
    .lift-current {
      font-size: 22px;
      font-weight: 700;
      color: #1a1a1a;
      margin-bottom: 12px;
      letter-spacing: -0.5px;
    }
    .lift-current span {
      font-size: 13px;
      font-weight: 400;
      color: #6b6b6b;
    }
    .sparkline-svg {
      width: 100%;
      height: 60px;
      overflow: visible;
    }

    /* Heatmap */
    .heatmap-wrap {
      margin-top: 4px;
    }
    .heatmap-months {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }
    .heatmap-month {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .heatmap-month-label {
      font-size: 12px;
      font-weight: 500;
      color: #6b6b6b;
      width: 32px;
      flex-shrink: 0;
    }
    .heatmap-dots {
      display: flex;
      flex-wrap: wrap;
      gap: 5px;
    }
    .heatmap-day {
      width: 18px;
      height: 18px;
      border-radius: 4px;
      flex-shrink: 0;
      position: relative;
      cursor: default;
    }
    .heatmap-day[title]:hover::after {
      content: attr(title);
      position: absolute;
      bottom: 24px;
      left: 50%;
      transform: translateX(-50%);
      background: #1a1a1a;
      color: #fff;
      font-size: 11px;
      padding: 4px 8px;
      border-radius: 6px;
      white-space: nowrap;
      z-index: 10;
      pointer-events: none;
    }

    /* Heatmap legend */
    .heatmap-legend {
      display: flex;
      align-items: center;
      gap: 10px;
      margin-top: 16px;
      font-size: 11px;
      color: #6b6b6b;
    }
    .legend-dot {
      width: 14px;
      height: 14px;
      border-radius: 3px;
      flex-shrink: 0;
    }

    /* Nutrition section */
    .nutrition-card {
      background: #ffffff;
      border-radius: 12px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.08);
      border-top: 3px solid #d4700a;
      padding: 24px;
      margin-bottom: 24px;
    }
    .nutrition-card.placeholder {
      border: 2px dashed #e8e2d9;
      border-top: none;
    }
    .nutrition-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 20px;
    }
    .nutrition-header-left {
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .nutrition-header h2 {
      font-size: 11px;
      font-weight: 600;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      color: #6b6b6b;
    }
    .nutrition-badge {
      font-size: 10px;
      font-weight: 600;
      background: #fff5ec;
      color: #d4700a;
      border: 1px solid #f5d9b8;
      border-radius: 20px;
      padding: 2px 10px;
      letter-spacing: 0.05em;
    }
    .nutrition-date-range {
      font-size: 12px;
      color: #6b6b6b;
    }
    .nutrition-slots {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 14px;
      margin-bottom: 16px;
    }
    .nutrition-slot {
      background: #faf9f7;
      border-radius: 8px;
      border: 1px solid #ede9e0;
      padding: 14px 16px;
    }
    .nutrition-slot-label {
      font-size: 11px;
      font-weight: 600;
      letter-spacing: 0.06em;
      text-transform: uppercase;
      color: #6b6b6b;
      margin-bottom: 6px;
    }
    .nutrition-slot-value {
      font-size: 24px;
      font-weight: 700;
      color: #1a1a1a;
      letter-spacing: -0.5px;
    }
    .nutrition-slot-value.placeholder-val {
      color: #ccc0b0;
    }
    .nutrition-slot-unit {
      font-size: 12px;
      font-weight: 400;
      color: #6b6b6b;
      margin-left: 2px;
    }
    /* Target bars */
    .nutrition-target-bar-wrap {
      margin-top: 8px;
    }
    .nutrition-target-track {
      width: 100%;
      height: 5px;
      background: #ede9e0;
      border-radius: 3px;
      overflow: hidden;
    }
    .nutrition-target-fill {
      height: 100%;
      border-radius: 3px;
      background: #d4700a;
      transition: width 0.4s ease;
    }
    .nutrition-target-label {
      font-size: 10px;
      color: #9b8b7b;
      margin-top: 4px;
    }
    /* Last 7 days mini table */
    .nutrition-table-wrap {
      margin-top: 4px;
      overflow-x: auto;
    }
    .nutrition-table {
      width: 100%;
      border-collapse: collapse;
      font-size: 12px;
    }
    .nutrition-table th {
      font-size: 10px;
      font-weight: 600;
      letter-spacing: 0.06em;
      text-transform: uppercase;
      color: #6b6b6b;
      padding: 6px 10px 8px;
      text-align: left;
      border-bottom: 1px solid #ede9e0;
    }
    .nutrition-table td {
      padding: 7px 10px;
      color: #1a1a1a;
      border-bottom: 1px solid #f5f2ed;
    }
    .nutrition-table tr:last-child td { border-bottom: none; }
    .nutrition-table tr:hover td { background: #faf9f7; }
    .status-dot {
      display: inline-block;
      width: 7px;
      height: 7px;
      border-radius: 50%;
      margin-right: 5px;
      vertical-align: middle;
    }
    .nutrition-notes {
      margin-top: 14px;
      background: #faf9f7;
      border-radius: 8px;
      border: 1px solid #ede9e0;
      padding: 12px 16px;
      font-size: 13px;
      color: #b0a090;
      font-style: italic;
    }

    /* Section spacing */
    .section { margin-bottom: 24px; }
    .section-title {
      font-size: 11px;
      font-weight: 600;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      color: #6b6b6b;
      margin-bottom: 12px;
    }

    @media (max-width: 768px) {
      .summary-row { grid-template-columns: repeat(2, 1fr); }
      .two-col { grid-template-columns: 1fr; }
      .lifts-grid { grid-template-columns: 1fr 1fr; }
      .nutrition-slots { grid-template-columns: repeat(2, 1fr); }
    }
  </style>
</head>
<body>
  <div class="container">

    <div class="page-header">
      <h1>Prisco's Fitness Dashboard</h1>
      <p>Training Analysis &middot; Apr &ndash; Jun 2026</p>
    </div>

    <!-- Summary row -->
    <div class="summary-row" id="summary-row"></div>

    <!-- Split + Heatmap -->
    <div class="two-col">
      <div class="card" id="split-card">
        <div class="card-title">Training Split</div>
        <div class="split-bars" id="split-bars"></div>
      </div>
      <div class="card" id="heatmap-card">
        <div class="card-title">Training Days</div>
        <div class="heatmap-wrap" id="heatmap-wrap"></div>
      </div>
    </div>

    <!-- Key lifts -->
    <div class="section">
      <div class="section-title">Key Lifts Progression</div>
      <div class="lifts-grid" id="lifts-grid"></div>
    </div>

    <!-- Nutrition section -->
    <div class="nutrition-card" id="nutrition-card"></div>

  </div>

  <script>
    const DATA = __DATA_PLACEHOLDER__;

    // ── Colors ────────────────────────────────────────────────────────────────
    const TYPE_COLOR = {
      Push: "#d4700a",
      Pull: "#2563eb",
      Legs: "#16a34a",
    };

    // ── Summary cards ─────────────────────────────────────────────────────────
    const s = DATA.summary;
    const summaryItems = [
      { label: "Total Sessions", value: s.total_sessions, sub: `${s.first_date} &ndash; ${s.last_date}` },
      { label: "Weeks Active",   value: s.weeks,          sub: "weeks tracked" },
      { label: "Sessions / Week", value: s.sessions_per_week, sub: "avg frequency" },
      { label: "Total Duration", value: `${Math.round(s.total_duration_min / 60)}h ${s.total_duration_min % 60}m`, sub: `avg ${s.avg_duration_min} min/session` },
    ];
    const row = document.getElementById("summary-row");
    summaryItems.forEach(item => {
      row.innerHTML += `
        <div class="stat-card">
          <div class="stat-label">${item.label}</div>
          <div class="stat-value">${item.value}</div>
          <div class="stat-sub">${item.sub}</div>
        </div>`;
    });

    // ── Split bars ────────────────────────────────────────────────────────────
    const split = DATA.split;
    const total = split.Push + split.Pull + split.Legs;
    const splitBars = document.getElementById("split-bars");
    ["Push", "Pull", "Legs"].forEach(t => {
      const pct = total ? Math.round(split[t] / total * 100) : 0;
      splitBars.innerHTML += `
        <div class="split-row">
          <div class="split-label">${t}</div>
          <div class="split-bar-track">
            <div class="split-bar-fill" style="width:${pct}%;background:${TYPE_COLOR[t]}"></div>
          </div>
          <div class="split-count">${split[t]} &nbsp;<span style="color:#aaa">(${pct}%)</span></div>
        </div>`;
    });

    // ── Heatmap ───────────────────────────────────────────────────────────────
    function buildHeatmap() {
      const td = DATA.training_days;
      const dates = Object.keys(td).sort();
      if (!dates.length) return;

      // Build month buckets from first to last date
      const firstD = new Date(dates[0]);
      const lastD  = new Date(dates[dates.length - 1]);
      const trainingSet = new Set(dates);

      // Collect all months
      const months = {};
      let cur = new Date(firstD.getFullYear(), firstD.getMonth(), 1);
      while (cur <= lastD) {
        const key = `${cur.getFullYear()}-${String(cur.getMonth()+1).padStart(2,'0')}`;
        months[key] = [];
        // Get days in month
        const daysInMonth = new Date(cur.getFullYear(), cur.getMonth()+1, 0).getDate();
        for (let d = 1; d <= daysInMonth; d++) {
          const ds = `${cur.getFullYear()}-${String(cur.getMonth()+1).padStart(2,'0')}-${String(d).padStart(2,'0')}`;
          months[key].push(ds);
        }
        cur = new Date(cur.getFullYear(), cur.getMonth()+1, 1);
      }

      const wrap = document.getElementById("heatmap-wrap");
      const monthNames = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];

      let html = '<div class="heatmap-months">';
      for (const [mkey, days] of Object.entries(months)) {
        const mIdx = parseInt(mkey.split("-")[1]) - 1;
        html += `<div class="heatmap-month">
          <div class="heatmap-month-label">${monthNames[mIdx]}</div>
          <div class="heatmap-dots">`;
        days.forEach(ds => {
          const trained = trainingSet.has(ds);
          const wtype = td[ds] || "";
          const color = trained ? TYPE_COLOR[wtype] || "#d4700a" : "#ede9e0";
          const tip = trained ? `${ds}: ${wtype}` : ds;
          // Fade out-of-range days slightly
          const opacity = ds < dates[0] || ds > dates[dates.length-1] ? "0.3" : "1";
          html += `<div class="heatmap-day" style="background:${color};opacity:${opacity}" title="${tip}"></div>`;
        });
        html += `</div></div>`;
      }
      html += '</div>';
      // Legend
      html += `<div class="heatmap-legend">
        <div class="legend-dot" style="background:#ede9e0"></div> Rest
        <div class="legend-dot" style="background:${TYPE_COLOR.Push}"></div> Push
        <div class="legend-dot" style="background:${TYPE_COLOR.Pull}"></div> Pull
        <div class="legend-dot" style="background:${TYPE_COLOR.Legs}"></div> Legs
      </div>`;

      wrap.innerHTML = html;
    }
    buildHeatmap();

    // ── Lift sparklines ────────────────────────────────────────────────────────
    function drawSparkline(svgEl, points, color) {
      if (!points || points.length < 2) {
        svgEl.innerHTML = '<text x="0" y="30" font-size="11" fill="#aaa">Insufficient data</text>';
        return;
      }
      const W = svgEl.clientWidth || 200;
      const H = 60;
      const weights = points.map(p => p.weight);
      const minW = Math.min(...weights);
      const maxW = Math.max(...weights);
      const range = maxW - minW || 1;
      const pad = 4;

      const xs = points.map((_, i) => pad + (i / (points.length - 1)) * (W - pad * 2));
      const ys = points.map(p => H - pad - ((p.weight - minW) / range) * (H - pad * 2));

      let d = `M ${xs[0]} ${ys[0]}`;
      for (let i = 1; i < xs.length; i++) {
        const cx = (xs[i-1] + xs[i]) / 2;
        d += ` C ${cx} ${ys[i-1]}, ${cx} ${ys[i]}, ${xs[i]} ${ys[i]}`;
      }

      // Area fill
      const areaD = d + ` L ${xs[xs.length-1]} ${H} L ${xs[0]} ${H} Z`;

      svgEl.innerHTML = `
        <defs>
          <linearGradient id="grad${color.replace('#','')}" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stop-color="${color}" stop-opacity="0.18"/>
            <stop offset="100%" stop-color="${color}" stop-opacity="0.01"/>
          </linearGradient>
        </defs>
        <path d="${areaD}" fill="url(#grad${color.replace('#','')})" />
        <path d="${d}" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        <circle cx="${xs[xs.length-1]}" cy="${ys[ys.length-1]}" r="3.5" fill="${color}"/>
      `;
    }

    const liftColors = {
      "Squat": "#d4700a",
      "Barbell Bench Press": "#2563eb",
      "Romanian Deadlift": "#16a34a",
    };

    const grid = document.getElementById("lifts-grid");
    Object.entries(DATA.lift_series).forEach(([lift, pts]) => {
      const color = liftColors[lift] || "#d4700a";
      const lastWeight = pts.length ? pts[pts.length-1].weight : "--";
      const firstWeight = pts.length ? pts[0].weight : "--";
      const trend = pts.length >= 2 ? lastWeight - firstWeight : 0;
      const trendStr = trend > 0 ? `+${trend.toFixed(1)} kg` : trend < 0 ? `${trend.toFixed(1)} kg` : "stable";
      const trendColor = trend > 0 ? "#16a34a" : trend < 0 ? "#dc2626" : "#6b6b6b";

      const div = document.createElement("div");
      div.className = "lift-chart-wrap";
      div.innerHTML = `
        <div class="lift-title">${lift}</div>
        <div class="lift-current">${lastWeight}<span> kg &nbsp;
          <span style="color:${trendColor};font-weight:600">${trendStr}</span>
        </span></div>
        <svg class="sparkline-svg" id="svg-${lift.replace(/\s+/g,'-')}"></svg>
        <div style="font-size:11px;color:#aaa;margin-top:6px">${pts.length} sessions tracked</div>
      `;
      grid.appendChild(div);

      // Draw after DOM insertion (need width)
      requestAnimationFrame(() => {
        const svg = document.getElementById(`svg-${lift.replace(/\s+/g,'-')}`);
        drawSparkline(svg, pts, color);
      });
    });

    // ── Nutrition section ─────────────────────────────────────────────────────
    const NUTRITION = __NUTRITION_PLACEHOLDER__;
    const nutCard = document.getElementById("nutrition-card");

    function fmtDate(ds) {
      const d = new Date(ds + "T00:00:00");
      return d.toLocaleDateString("en-AU", { day: "numeric", month: "short" });
    }

    if (!NUTRITION) {
      nutCard.classList.add("placeholder");
      nutCard.innerHTML = `
        <div class="nutrition-header"><div class="nutrition-header-left">
          <h2>Nutrition Tracking</h2>
          <span class="nutrition-badge">NO DATA</span>
        </div></div>
        <div class="nutrition-notes">nutrition_data.json not found &mdash; run the nutrition sync task to populate this section.</div>`;
    } else {
      const n = NUTRITION;
      const targets = n.targets;

      function targetBar(val, target) {
        const pct = Math.min(Math.round((val / target) * 100), 100);
        const color = pct >= 90 ? "#16a34a" : pct >= 70 ? "#d4700a" : "#ef4444";
        return `<div class="nutrition-target-bar-wrap">
          <div class="nutrition-target-track">
            <div class="nutrition-target-fill" style="width:${pct}%;background:${color}"></div>
          </div>
          <div class="nutrition-target-label">${val} / ${target} (${pct}%)</div>
        </div>`;
      }

      const macros = [
        { label: "Avg Calories", val: n.avg_calories, unit: "kcal", target: targets.calories },
        { label: "Avg Protein",  val: n.avg_protein,  unit: "g",    target: targets.protein  },
        { label: "Avg Carbs",    val: n.avg_carbs,    unit: "g",    target: targets.carbs    },
        { label: "Avg Fat",      val: n.avg_fat,      unit: "g",    target: targets.fat      },
      ];

      let slotsHtml = '<div class="nutrition-slots">';
      macros.forEach(m => {
        slotsHtml += `<div class="nutrition-slot">
          <div class="nutrition-slot-label">${m.label}</div>
          <div class="nutrition-slot-value">${m.val}<span class="nutrition-slot-unit">${m.unit}</span></div>
          ${targetBar(m.val, m.target)}
        </div>`;
      });
      slotsHtml += '</div>';

      // Last 7 days table
      const last7 = n.last7;
      let tableHtml = `<div style="font-size:11px;font-weight:600;letter-spacing:0.06em;text-transform:uppercase;color:#6b6b6b;margin-bottom:8px">Last 7 Days</div>
        <div class="nutrition-table-wrap"><table class="nutrition-table">
          <thead><tr>
            <th>Date</th><th>Type</th><th>Kcal</th><th>P (g)</th><th>C (g)</th><th>F (g)</th><th>Status</th>
          </tr></thead><tbody>`;
      last7.forEach(e => {
        const dotColor = e.log_status === "Complete" ? "#16a34a" : "#f59e0b";
        const typeShort = e.day_type === "Training Day" ? "Train" : "Rest";
        tableHtml += `<tr>
          <td>${fmtDate(e.date)}</td>
          <td><span style="color:${e.day_type === 'Training Day' ? '#d4700a' : '#6b6b6b'};font-weight:500">${typeShort}</span></td>
          <td>${e.calories ?? "—"}</td>
          <td>${e.protein ?? "—"}</td>
          <td>${e.carbs ?? "—"}</td>
          <td>${e.fat ?? "—"}</td>
          <td><span class="status-dot" style="background:${dotColor}"></span>${e.log_status}</td>
        </tr>`;
      });
      tableHtml += '</tbody></table></div>';

      const startLabel = fmtDate(n.date_range_start);
      const endLabel   = fmtDate(n.date_range_end);

      nutCard.innerHTML = `
        <div class="nutrition-header">
          <div class="nutrition-header-left">
            <h2>Nutrition Tracking</h2>
            <span class="nutrition-badge">${n.n_complete} COMPLETE DAYS</span>
          </div>
          <div class="nutrition-date-range">${startLabel} &ndash; ${endLabel}</div>
        </div>
        ${slotsHtml}
        ${tableHtml}`;
    }

  </script>
</body>
</html>
"""


def load_nutrition():
    if not os.path.exists(NUTRITION_PATH):
        return None
    try:
        with open(NUTRITION_PATH, encoding="utf-8") as f:
            entries = json.load(f)
        complete = [e for e in entries if e.get("log_status") == "Complete"]
        if not complete:
            return None
        dates = sorted(e["date"] for e in entries)
        def avg(field):
            vals = [e[field] for e in complete if e.get(field) is not None]
            return round(sum(vals) / len(vals), 1) if vals else None
        last7 = sorted(entries, key=lambda e: e["date"])[-7:]
        return {
            "date_range_start": dates[0],
            "date_range_end": dates[-1],
            "n_complete": len(complete),
            "n_total": len(entries),
            "avg_calories": avg("calories"),
            "avg_protein": avg("protein"),
            "avg_carbs": avg("carbs"),
            "avg_fat": avg("fat"),
            "targets": {"calories": 1850, "protein": 130, "carbs": 195, "fat": 60},
            "last7": last7,
        }
    except Exception as e:
        print(f"  Warning: could not load nutrition data: {e}")
        return None


def generate_html(data: dict, nutrition=None) -> str:
    data_json = json.dumps(data, ensure_ascii=False, default=str)
    nutrition_json = json.dumps(nutrition, ensure_ascii=False, default=str)
    html = HTML_TEMPLATE.replace("__DATA_PLACEHOLDER__", data_json)
    html = html.replace("__NUTRITION_PLACEHOLDER__", nutrition_json)
    return html


def main():
    print("Parsing cache files...")
    sessions = load_sessions()
    print(f"  Found {len(sessions)} sessions.")
    data = build_dashboard_data(sessions)
    nutrition = load_nutrition()
    if nutrition:
        print(f"  Loaded nutrition data: {nutrition['n_complete']} complete entries ({nutrition['date_range_start']} to {nutrition['date_range_end']})")
        print(f"  Avg (complete): {nutrition['avg_calories']} kcal | {nutrition['avg_protein']}g P | {nutrition['avg_carbs']}g C | {nutrition['avg_fat']}g F")
    html = generate_html(data, nutrition)
    with open(OUT_PATH, "w", encoding="utf-8") as f:
        f.write(html)
    print(f"  Dashboard written to: {OUT_PATH}")


if __name__ == "__main__":
    main()
