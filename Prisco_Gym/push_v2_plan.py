import os
import sys
import time

# Ensure we can import xunji_api_client from current directory
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from xunji_api_client import XunjiClient

client = XunjiClient()

# Plan v2 (PBB hybrid) - Week 1 = intro/deload week, return from break.
# Loads at ~65-70% of pre-break working weights. RPE 5-6, no intensity techniques.
# Schedule: Push Tue 8/18, Pull Wed 8/19, Legs Fri 8/21, Arms+WP Sun 8/23.

push_plan = [
    "2026-08-18,Push (v2周1),"
    "1.器械平板卧推,1组,40kg,10次,time:180s,2组,40kg,10次,time:180s,3组,40kg,10次,time:180s,"
    "2.下半程低上斜哑铃卧推,1组,17.5kg,12次,time:150s,2组,17.5kg,12次,time:150s,3组,17.5kg,12次,time:150s,"
    "3.哑铃推肩,1组,10kg,12次,time:150s,2组,10kg,12次,time:150s,3组,10kg,12次,time:150s,"
    "4.上斜哑铃侧平举,1组,5kg,12次,time:90s,2组,5kg,12次,time:90s,3组,5kg,12次,time:90s,"
    "5.绳索过头臂屈伸,1组,10kg,15次,time:90s,2组,10kg,15次,time:90s,3组,10kg,15次,time:90s,"
    "6.绳索俯身臂屈伸,1组,5kg,18次,time:60s,2组,5kg,18次,time:60s"
]

pull_plan = [
    "2026-08-19,Pull (v2周1),"
    "1.宽距引体向上,1组,0kg,8次,time:150s,2组,0kg,8次,time:150s,3组,0kg,8次,time:150s,"
    "2.胸靠器械划船,1组,35kg,10次,time:150s,2组,35kg,10次,time:150s,3组,35kg,10次,time:150s,"
    "3.单臂跪姿下拉,1组,20kg,13次,time:90s,2组,20kg,13次,time:90s,"
    "4.单臂面拉,1组,7kg,12次,time:90s,2组,7kg,12次,time:90s,"
    "5.高位绳索弯举,1组,10kg,13次,time:90s,2组,10kg,13次,time:90s,3组,10kg,13次,time:90s,"
    "6.站姿绳索卷腹,1组,21kg,12次,time:90s,2组,21kg,12次,time:90s"
]

legs_plan = [
    "2026-08-21,Legs (v2周1),"
    "1.深蹲,1组,55kg,8次,time:210s,2组,55kg,8次,time:210s,3组,55kg,8次,time:210s,"
    "2.杠铃罗马尼亚硬拉,1组,40kg,10次,time:180s,2组,40kg,10次,time:180s,"
    "3.坐姿腿弯举,1组,25kg,10次,time:90s,2组,25kg,10次,time:90s,3组,25kg,10次,time:90s,"
    "4.腿屈伸,1组,25kg,12次,time:90s,2组,25kg,12次,time:90s,"
    "5.站姿提踵,1组,40kg,18次,time:60s,2组,40kg,18次,time:60s,"
    "6.罗马椅举腿,1组,0kg,15次,time:60s,2组,0kg,15次,time:60s"
]

arms_plan = [
    "2026-08-23,Arms (v2周1),"
    "1.器械侧平举,1组,15kg,10次,time:90s,2组,15kg,10次,time:90s,3组,15kg,10次,time:90s,"
    "2.哑铃仰卧上拉,1组,15kg,10次,time:90s,2组,15kg,10次,time:90s,"
    "3.EZ杆绳索弯举,1组,12.5kg,12次,time:90s,2组,12.5kg,12次,time:90s,"
    "4.上斜哑铃弯举(下半程),1组,5kg,13次,time:90s,2组,5kg,13次,time:90s,"
    "5.EZ杆仰卧臂屈伸,1组,12.5kg,12次,time:90s,2组,12.5kg,12次,time:90s,"
    "6.直杆绳索下压,1组,12.5kg,13次,time:90s,2组,12.5kg,13次,time:90s"
]

def safe_upsert(plan_name, plan_data, max_retries=5):
    print(f"Pushing {plan_name}...")
    for attempt in range(max_retries):
        res = client.upsert_training_data(plan_data)
        if res is not None:
            print(f"Result for {plan_name}: SUCCESS")
            return res
        print(f"Failed (attempt {attempt+1}/{max_retries}), waiting 15 seconds...")
        time.sleep(15)
    print(f"Result for {plan_name}: FAILED after {max_retries} attempts")
    return None

if __name__ == "__main__":
    safe_upsert("Day 1 Push (Tue 8/18)", push_plan)
    time.sleep(5)
    safe_upsert("Day 2 Pull (Wed 8/19)", pull_plan)
    time.sleep(5)
    safe_upsert("Day 3 Legs (Fri 8/21)", legs_plan)
    time.sleep(5)
    safe_upsert("Day 4 Arms+WP (Sun 8/23)", arms_plan)
    print("Done! Check your Xunji app calendar for the week of Aug 18.")
