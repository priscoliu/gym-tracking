"""
gym_analysis.py
Parses all cache/trains_YYYY-MM-DD.json files and prints a text summary
suitable for pasting into a Claude conversation.
"""

import json
import re
import os
from datetime import datetime
from collections import defaultdict

# ── Translation map ────────────────────────────────────────────────────────────
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

KEY_LIFTS = ["Squat", "Barbell Bench Press", "Romanian Deadlift", "Pull-up", "Seated Row"]

CACHE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "cache")


# ── Parser ─────────────────────────────────────────────────────────────────────

def translate(name: str) -> str:
    return TRANSLATIONS.get(name.strip(), name.strip())


def parse_exercises(raw: str) -> list:
    """Extract exercises and their sets from a session string."""
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
        num_name_match = re.match(r"(\d+)\.(.+?)(?:,|$)", block)
        if not num_name_match:
            continue
        num = int(num_name_match.group(1))
        cn_name = num_name_match.group(2).strip()
        en_name = translate(cn_name)

        rest = block[num_name_match.end():]
        tokens = [t.strip() for t in rest.split(",") if t.strip()]

        sets = []
        i = 0
        while i < len(tokens):
            t = tokens[i]
            set_match = re.match(r"(\d+)组$", t)
            if set_match:
                weight = None
                reps = None
                i += 1
                if i < len(tokens) and re.match(r"[\d.]+kg$", tokens[i]):
                    w_str = tokens[i].replace("kg", "")
                    weight = float(w_str) if w_str else 0.0
                    i += 1
                if i < len(tokens) and re.match(r"(\d+)次$", tokens[i]):
                    reps = int(re.match(r"(\d+)次$", tokens[i]).group(1))
                    i += 1
                if i < len(tokens) and tokens[i].startswith("time:"):
                    i += 1
                if weight is not None and reps is not None:
                    sets.append({"set": int(set_match.group(1)), "weight": weight, "reps": reps})
            else:
                i += 1

        exercises.append({"num": num, "name_cn": cn_name, "name_en": en_name, "sets": sets})

    return exercises


def parse_session(raw: str) -> dict | None:
    parts = raw.split(",")
    if len(parts) < 4:
        return None

    date_str = parts[0].strip()
    try:
        date = datetime.strptime(date_str, "%y%m%d").date()
    except ValueError:
        return None

    session = {"date": date, "raw": raw}

    id_match = re.search(r"id:(\d+)", raw)
    session["id"] = id_match.group(1) if id_match else None
    session["type"] = parts[2].strip() if len(parts) > 2 else "Unknown"

    tt_match = re.search(r"train_time:(\d+)-(\d+)", raw)
    if tt_match:
        start_ms, end_ms = int(tt_match.group(1)), int(tt_match.group(2))
        duration_min = (end_ms - start_ms) / 60000
        session["duration_min"] = round(duration_min, 1) if duration_min < 180 else None
    else:
        session["duration_min"] = None

    cal_match = re.search(r"calorie:(\d+)", raw)
    cal = int(cal_match.group(1)) if cal_match else None
    session["calories"] = cal if cal and cal <= 1000 else None

    exercises = parse_exercises(raw)
    session["exercises"] = exercises

    total_vol = sum(st["weight"] * st["reps"] for ex in exercises for st in ex["sets"])
    session["total_volume"] = round(total_vol, 1)

    return session


def load_all_sessions() -> list:
    sessions = []
    for fname in sorted(os.listdir(CACHE_DIR)):
        if not fname.endswith(".json"):
            continue
        fpath = os.path.join(CACHE_DIR, fname)
        try:
            with open(fpath, "r", encoding="utf-8") as f:
                data = json.load(f)
        except Exception:
            continue
        if not data:
            continue
        for entry in data:
            if isinstance(entry, str) and entry.strip():
                s = parse_session(entry)
                if s:
                    sessions.append(s)
    sessions.sort(key=lambda x: x["date"])
    return sessions


# ── Analysis helpers ───────────────────────────────────────────────────────────

def best_set(sessions: list, lift_name: str) -> dict | None:
    best = None
    for s in sessions:
        for ex in s["exercises"]:
            if ex["name_en"] == lift_name:
                for st in ex["sets"]:
                    score = st["weight"] * st["reps"]
                    if best is None or score > best["score"]:
                        best = {"score": score, "weight": st["weight"], "reps": st["reps"], "date": s["date"]}
    return best


def lift_trend(sessions: list, lift_name: str) -> list:
    """Return (date, value, unit) tuples. For BW lifts (0 kg), tracks max reps."""
    points = []
    for s in sessions:
        for ex in s["exercises"]:
            if ex["name_en"] == lift_name and ex["sets"]:
                weights = [st["weight"] for st in ex["sets"] if st["weight"] > 0]
                if weights:
                    points.append((s["date"], max(weights), "kg"))
                else:
                    reps = [st["reps"] for st in ex["sets"]]
                    if reps:
                        points.append((s["date"], max(reps), "reps"))
                break
    return points


# ── Main summary ───────────────────────────────────────────────────────────────

def summarise() -> str:
    sessions = load_all_sessions()
    if not sessions:
        return "No session data found."

    first_date = sessions[0]["date"]
    last_date = sessions[-1]["date"]
    total_sessions = len(sessions)
    weeks = ((last_date - first_date).days + 1) / 7
    freq = round(total_sessions / weeks, 2) if weeks > 0 else 0

    type_counts = defaultdict(int)
    type_volume = defaultdict(float)
    for s in sessions:
        type_counts[s["type"]] += 1
        type_volume[s["type"]] += s["total_volume"]

    valid_durations = [s["duration_min"] for s in sessions if s["duration_min"]]
    avg_dur = round(sum(valid_durations) / len(valid_durations), 1) if valid_durations else 0
    total_dur = round(sum(valid_durations), 0)
    valid_cal = [s["calories"] for s in sessions if s["calories"]]
    avg_cal = round(sum(valid_cal) / len(valid_cal), 0) if valid_cal else 0
    total_s = sum(type_counts.values())

    lines = []
    lines.append("=" * 60)
    lines.append("PRISCO GYM TRAINING ANALYSIS")
    lines.append("=" * 60)
    lines.append("")
    lines.append("OVERVIEW")
    lines.append(f"  Date range       : {first_date} to {last_date}")
    lines.append(f"  Total sessions   : {total_sessions}")
    lines.append(f"  Weeks covered    : {weeks:.1f}")
    lines.append(f"  Sessions / week  : {freq}")
    lines.append(f"  Avg session time : {avg_dur} min")
    lines.append(f"  Total gym time   : {int(total_dur)} min ({total_dur/60:.1f} hrs)")
    if avg_cal:
        lines.append(f"  Avg calories     : {int(avg_cal)} kcal/session")
    lines.append("")

    lines.append("TRAINING SPLIT")
    for wtype in ["Push", "Pull", "Legs"]:
        cnt = type_counts.get(wtype, 0)
        pct = round(100 * cnt / total_s, 1) if total_s else 0
        lines.append(f"  {wtype:<6}: {cnt} sessions ({pct}%)")
    lines.append("")

    lines.append("VOLUME BY TYPE (total kg lifted)")
    for wtype in ["Push", "Pull", "Legs"]:
        vol = type_volume.get(wtype, 0)
        cnt = type_counts.get(wtype, 0)
        avg = round(vol / cnt, 0) if cnt else 0
        lines.append(f"  {wtype:<6}: {vol:,.0f} kg total | {avg:,.0f} kg avg/session")
    lines.append("")

    lines.append("KEY LIFTS — BEST SET")
    for lift in KEY_LIFTS:
        b = best_set(sessions, lift)
        if b:
            w_str = "BW" if b["weight"] == 0 else f"{b['weight']} kg"
            lines.append(f"  {lift:<28}: {w_str} x {b['reps']} reps  ({b['date']})")
        else:
            lines.append(f"  {lift:<28}: no data")
    lines.append("")

    lines.append("KEY LIFTS — PROGRESSION (working weight over time)")
    for lift in KEY_LIFTS:
        trend = lift_trend(sessions, lift)
        if not trend:
            lines.append(f"  {lift}: no data")
            continue
        def fmt_val(val, unit): return f"{val} {unit}"
        first_w = fmt_val(trend[0][1], trend[0][2])
        last_w  = fmt_val(trend[-1][1], trend[-1][2])
        recent = trend[-4:]
        recent_str = "  ->  ".join(f"{d} {fmt_val(v, u)}" for d, v, u in recent)
        lines.append(f"  {lift}")
        lines.append(f"    First : {trend[0][0]} {first_w}  ->  Latest : {trend[-1][0]} {last_w}")
        lines.append(f"    Recent: {recent_str}")
    lines.append("")

    lines.append("TRAINING LOG (all sessions)")
    lines.append(f"  {'Date':<12} {'Type':<8} {'Duration':>9} {'Volume':>10} {'Cal':>7}")
    lines.append("  " + "-" * 52)
    for s in sessions:
        dur_str = f"{s['duration_min']} min" if s["duration_min"] else "    --"
        cal_str = str(s["calories"]) if s["calories"] else "--"
        lines.append(
            f"  {str(s['date']):<12} {s['type']:<8} {dur_str:>9} {s['total_volume']:>10,.0f} {cal_str:>7}"
        )
    lines.append("")

    lines.append("=" * 60)
    lines.append("CLAUDE CHAT PASTE BLOCK")
    lines.append("Copy from here into a new Claude conversation")
    lines.append("=" * 60)
    lines.append("")
    lines.append("Here is my gym training data for analysis:")
    lines.append("")
    lines.append(f"Period: {first_date} to {last_date} ({total_sessions} sessions, {freq} sessions/week average)")
    lines.append("")
    lines.append("Training split:")
    for wtype in ["Push", "Pull", "Legs"]:
        cnt = type_counts.get(wtype, 0)
        pct = round(100 * cnt / total_s, 1) if total_s else 0
        lines.append(f"  {wtype}: {cnt} sessions ({pct}%)")
    lines.append("")
    lines.append("Best sets achieved:")
    for lift in KEY_LIFTS:
        b = best_set(sessions, lift)
        if b:
            w_str = "BW" if b["weight"] == 0 else f"{b['weight']} kg"
            lines.append(f"  {lift}: {w_str} x {b['reps']} reps  (on {b['date']})")
    lines.append("")
    lines.append("Full session log:")
    for s in sessions:
        ex_names = [ex["name_en"] for ex in s["exercises"]]
        dur_str = f"{s['duration_min']}min" if s["duration_min"] else ""
        lines.append(f"  {s['date']} [{s['type']}] {dur_str}  | {', '.join(ex_names)}")
    lines.append("")

    return "\n".join(lines)


if __name__ == "__main__":
    print(summarise())
