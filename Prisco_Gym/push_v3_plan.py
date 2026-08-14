import os
import sys
import time

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from xunji_api_client import XunjiClient

client = XunjiClient()

# Plan v3 - Full PBB Phase 2, Block 1 Week 1 (intro week), 4 days/week.
# Week A = the "#1" sessions. Intro week: 2 working sets, RPE ~7, no intensity techniques.
# Loads ~65-70% of pre-break baselines; new machines are estimates - adjust to RPE 7 on the day.

pull_1 = [
    "2026-08-18,Pull #1 (B1W1),"
    "1.宽距引体向上,1组,0kg,9次,time:150s,2组,0kg,9次,time:150s,"
    "2.胸靠器械划船,1组,35kg,10次,time:150s,2组,35kg,10次,time:150s,"
    "3.单臂跪姿高位下拉,1组,20kg,13次,time:90s,2组,20kg,13次,time:90s,"
    "4.单臂绳索面拉,1组,7kg,11次,time:90s,2组,7kg,11次,time:90s,"
    "5.坐姿高位绳索弯举,1组,10kg,13次,time:90s,2组,10kg,13次,time:90s,"
    "6.站姿绳索卷腹,1组,21kg,11次,time:90s,2组,21kg,11次,time:90s"
]

push_1 = [
    "2026-08-19,Push #1 (B1W1),"
    "1.上斜哑铃侧平举,1组,5kg,11次,time:90s,2组,5kg,11次,time:90s,3组,5kg,11次,time:90s,"
    "2.器械平板卧推,1组,40kg,9次,time:240s,2组,40kg,9次,time:240s,"
    "3.坐姿绳索夹胸(下半程),1组,10kg,9次,time:150s,2组,10kg,9次,time:150s,"
    "4.哑铃推肩,1组,10kg,11次,time:150s,2组,10kg,11次,time:150s,"
    "5.绳索过头臂屈伸,1组,10kg,13次,time:90s,2组,10kg,13次,time:90s,"
    "6.绳索俯身臂屈伸,1组,5kg,18次,time:90s,2组,5kg,18次,time:90s"
]

legs_1 = [
    "2026-08-21,Legs #1 (B1W1),"
    "1.坐姿腿弯举(下半程),1组,25kg,9次,time:90s,2组,25kg,9次,time:90s,"
    "2.史密斯深蹲,1组,50kg,7次,time:240s,2组,50kg,7次,time:240s,"
    "3.臀腿举,1组,0kg,11次,time:150s,2组,0kg,11次,time:150s,"
    "4.腿屈伸,1组,25kg,11次,time:90s,2组,25kg,11次,time:90s,"
    "5.站姿提踵,1组,40kg,18次,time:90s,2组,40kg,18次,time:90s,"
    "6.器械髋外展,1组,25kg,13次,time:90s,2组,25kg,13次,time:90s"
]

arms_1 = [
    "2026-08-23,Arms & WP #1 (B1W1),"
    "1.器械侧平举,1组,15kg,10次,time:120s,2组,15kg,10次,time:120s,"
    "2.器械上拉,1组,20kg,10次,time:120s,2组,20kg,10次,time:120s,"
    "3.EZ杆绳索弯举,1组,12.5kg,11次,time:90s,2组,12.5kg,11次,time:90s,"
    "4.EZ杆仰卧臂屈伸,1组,12.5kg,11次,time:90s,2组,12.5kg,11次,time:90s,"
    "5.上斜哑铃弯举(下半程),1组,5kg,13次,time:90s,2组,5kg,13次,time:90s,"
    "6.直杆绳索下压,1组,12.5kg,13次,time:90s,2组,12.5kg,13次,time:90s,"
    "7.罗马椅举腿,1组,0kg,15次,time:90s,2组,0kg,15次,time:90s,3组,0kg,15次,time:90s"
]

SESSIONS = [
    ("Pull #1 (Tue 8/18)", pull_1),
    ("Push #1 (Wed 8/19)", push_1),
    ("Legs #1 (Fri 8/21)", legs_1),
    ("Arms & WP #1 (Sun 8/23)", arms_1),
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
    for name, data in SESSIONS:
        safe_upsert(name, data)
        time.sleep(5)
    print("Done! Week A (#1 sessions) pushed. Week B (#2 sessions) starts Aug 25.")
