import json

file_path = r"c:\Users\LiuPr\OneDrive - Willis Towers Watson\Documents\WTW-Data-Solutions\SME-PowerBI\Gantt 2.1 Spec (WTW).json"

try:
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
except FileNotFoundError:
    print(f"File not found: {file_path}")
    exit(1)

# 1. Signals
signals = data.get("signals", [])
for s in signals:
    if s.get("name") == "yRowHeight":
        s["value"] = 44  # From HTML layout.rowHeight = 44
    elif s.get("name") == "textColour":
        s["value"] = "#374151"  # colors.textBody

# 2. Update phasePath for modern 3px thin line (centered in 44px row)
# Row is 44, line is 3px. 
for ds in data.get("data", []):
    if ds.get("name") == "phasePaths":
        for transform in ds.get("transform", []):
            if transform.get("as") == "phasePath" and "expr" in transform:
                # 44/2 = 22, -1.5 = 20.5 offset approximately. 
                # (scale('y', datum.id)+yPaddingInner+5) was used earlier. Let's use +10.
                transform["expr"] = "'M ' + scale('x', datum.start)+' ' + (scale('y', datum.id)+yPaddingInner+5) + ' H ' + scale('x', datum.end) + ' v 3 H ' + scale('x', datum.start) + ' z'"

# 3. Add pill-shape styling to task bars
def update_task_bar_styles(obj):
    if isinstance(obj, dict):
        if obj.get("type") == "rect":
            name = obj.get("name", "")
            if name not in ["weekendShading", "todayHighlight", "xDomainBackground", "phaseBackgrounds", "columnHolder"]:
                if "encode" in obj and "update" in obj["encode"]:
                    # Fully rounded ends for 18px tall bar is 9px radius
                    obj["encode"]["update"]["cornerRadius"] = {"value": 9}
        for k, v in obj.items():
            update_task_bar_styles(v)
    elif isinstance(obj, list):
        for item in obj:
            update_task_bar_styles(item)

for mark in data.get("marks", []):
    if mark.get("name") == "ganttContainer":
        update_task_bar_styles(mark.get("marks", []))

# 4. Remove heavy weekend shading & update today line
for mark in data.get("marks", []):
    if mark.get("name") == "weekendContainer":
        for inner_mark in mark.get("marks", []):
            if inner_mark.get("name") == "weekendShading":
                # Clear shading to match HTML #ffffff background
                if "encode" in inner_mark and "update" in inner_mark["encode"]:
                    inner_mark["encode"]["update"]["fill"] = {"value": "transparent"}
                    inner_mark["encode"]["update"]["stroke"] = {"value": "transparent"}
            elif inner_mark.get("name") == "todayHighlight":
                # Striking thin #1877f2 blue line logic from HTML
                if "encode" in inner_mark and "update" in inner_mark["encode"]:
                    inner_mark["encode"]["update"]["fill"] = {"value": "#1877f2"}
                    inner_mark["encode"]["update"]["width"] = {"value": 1.5}
                    inner_mark["encode"]["update"]["opacity"] = {"value": 1.0}

with open(file_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2)

print("Applied HTML design to JSON Spec successfully.")
