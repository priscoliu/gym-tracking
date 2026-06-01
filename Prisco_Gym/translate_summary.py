import json

with open('recent_gym_data_summary.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# English translations mapping
translations = {
    '1.深蹲': 'Squat',
    '2.腿举': 'Leg Press',
    '3.腿弯举': 'Leg Curls',
    '4.杠铃臀冲': 'Barbell Hip Thrust',
    '4.臀冲架臀冲': 'Hip Thrust Machine',
    '5.站姿绳索卷腹': 'Standing Cable Crunch',
    '6.负重悬挂抬腿': 'Weighted Hanging Leg Raise',
    '7.悬挂抬腿': 'Hanging Leg Raise',
    '1.杠铃卧推': 'Barbell Bench Press',
    '2.上斜哑铃卧推': 'Incline DB Bench Press',
    '3.双杠臂屈伸（负重）': 'Dips (Weighted)',
    '4.器械坐姿推举': 'Machine Seated Press',
    '4.哑铃推肩': 'DB Shoulder Press',
    '5.侧平举': 'Lateral Raises',
    '5.平板上斜侧平举': 'Incline Lateral Raises',
    '6.直杆绳索下压': 'Straight Bar Cable Pushdown',
    '1.引体向上': 'Pull-ups',
    '2.坐姿划船': 'Seated Row',
    '3.窄距下拉': 'Close-grip Pulldown',
    '4.杠铃罗马尼亚硬拉': 'Barbell RDL',
    '5.面拉': 'Face Pull',
    '6.EZ杆二头弯举': 'EZ Bar Bicep Curl',
    '7.上斜哑铃弯举': 'Incline DB Bicep Curl',
    '组': 'Set',
    '次': 'reps'
}

def translate(text):
    for ch, en in translations.items():
        text = text.replace(ch, en)
    return text

lines = ['# 🏋️ Detailed Daily Training Log (May 3 - May 31)', '']

for entry in data:
    parts = entry.split(',')
    date_str = parts[0]
    date_formatted = f'20{date_str[:2]}-{date_str[2:4]}-{date_str[4:]}'
    
    # find workout type (Push, Pull, Legs)
    workout_type = 'Unknown'
    for p in parts:
        if p in ['Push', 'Pull', 'Legs']:
            workout_type = p
            break
            
    lines.append(f'## 📅 {date_formatted} - {workout_type}')
    
    current_exercise = ''
    sets = []
    
    for p in parts:
        if 'id:' in p or 'train_time:' in p or 'calorie:' in p or p in ['Push', 'Pull', 'Legs'] or p == date_str:
            continue
            
        # If it contains a dot, it is an exercise name (e.g. 1.深蹲)
        if '.' in p and not 'kg' in p and not 's' in p and not '次' in p:
            if current_exercise:
                sets_str = ", ".join(sets)
                lines.append(f'- **{translate(current_exercise)}**: {sets_str}')
            current_exercise = p
            sets = []
        elif '组' in p:
            pass # Skip set markers
        elif 'kg' in p or '次' in p or 's' in p:
            sets.append(translate(p))
            
    # Add the last exercise
    if current_exercise:
        sets_str = ", ".join(sets)
        lines.append(f'- **{translate(current_exercise)}**: {sets_str}')
        
    lines.append('')

with open('c:/Users/LiuPr/.gemini/antigravity/brain/ee86209d-90f7-42ca-b65d-5b3223351d13/training_details_en_may_2026.md', 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))
