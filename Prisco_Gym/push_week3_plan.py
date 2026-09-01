import os
import sys
import time

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from xunji_api_client import XunjiClient

client = XunjiClient()

# Week 3 = Block 1, first climb week (repeats the #1 sessions with 3 sets,
# RPE 8-9 early / 9-10 last, intensity techniques ON).
# Weights derived from actual logged working sets Aug 18-21 (warm-up sets
# excluded), progressed where reps were at/near top of target range.
# Exercise names kept identical to what's already in Xunji history.

pull_1 = [
    "2026-09-02,Pull #1 (B1W2),"
    "1.引体向上,1组,9次,time:90s,2组,9次,time:90s,3组,9次,time:90s,"
    "2.器械划船1,1组,40kg,8次,time:90s,2组,40kg,8次,time:90s,3组,40kg,8次,time:90s,"
    "3.弹力绳-单手下拉,1组,12.5kg,12次,time:60s,2组,12.5kg,12次,time:60s,3组,12.5kg,12次,time:60s,"
    "4.单臂绳索面拉,1组,8kg,10次,time:60s,2组,8kg,10次,time:60s,3组,8kg,10次,time:60s,"
    "5.坐姿高位绳索弯举,1组,6kg,12次,time:60s,2组,6kg,12次,time:60s,3组,6kg,12次,time:60s,"
    "6.站姿绳索卷腹,1组,22.5kg,10次,time:60s,2组,22.5kg,10次,time:60s,3组,22.5kg,10次,time:60s"
]

push_1 = [
    "2026-09-03,Push #1 (B1W2),"
    "1.平板上斜侧平举,1组,6kg,10次,time:60s,2组,6kg,10次,time:60s,3组,6kg,10次,time:60s,"
    "2.悍马机推胸,1组,17.5kg,8次,time:150s,2组,17.5kg,8次,time:150s,3组,17.5kg,8次,time:150s,"
    "3.把手式蝴蝶机飞鸟,1组,33kg,8次,time:90s,2组,33kg,8次,time:90s,"
    "4.哑铃推肩,1组,12kg,10次,time:90s,2组,12kg,10次,time:90s,3组,12kg,10次,time:90s,"
    "5.绳索过头臂屈伸,1组,11kg,12次,time:60s,2组,11kg,12次,time:60s,"
    "6.单手绳索臂屈伸,1组,5kg,13次,time:60s,2组,5kg,13次,time:60s"
]

legs_1 = [
    "2026-09-04,Legs #1 (B1W2),"
    "1.腿弯举,1组,27.5kg,8次,time:60s,2组,27.5kg,8次,time:60s,3组,27.5kg,8次,time:60s,"
    "2.史密斯机深蹲,1组,55kg,6次,time:180s,2组,55kg,6次,time:180s,3组,55kg,6次,time:180s,"
    "3.水平山羊挺身,1组,10次,time:90s,2组,10次,time:90s,3组,10次,time:90s,"
    "4.坐姿腿屈伸,1组,27.5kg,10次,time:60s,2组,27.5kg,10次,time:60s,3组,27.5kg,10次,time:60s,"
    "5.坐姿器械提踵,1组,12.5kg,15次,time:60s,2组,12.5kg,15次,time:60s,3组,12.5kg,15次,time:60s,"
    "6.绳索侧踢,1组,3kg,12次,time:60s,2组,3kg,12次,time:60s,3组,3kg,12次,time:60s"
]

arms_1 = [
    "2026-09-06,Arms & WP #1 (B1W2),"
    "1.器械坐姿反向飞鸟,1组,22.5kg,8次,time:90s,2组,22.5kg,8次,time:90s,3组,22.5kg,8次,time:90s,"
    "2.平躺哑铃过头拉,1组,13kg,8次,time:90s,2组,13kg,8次,time:90s,3组,13kg,8次,time:90s,"
    "3.直杆绳索弯举,1组,14kg,10次,time:60s,2组,14kg,10次,time:60s,3组,14kg,10次,time:60s,"
    "4.绳索过头臂屈伸,1组,12kg,10次,time:60s,2组,12kg,10次,time:60s,3组,12kg,10次,time:60s,"
    "5.上斜哑铃弯举,1组,7kg,12次,time:60s,2组,7kg,12次,time:60s,"
    "6.绳索三头下压_SZ杆,1组,17kg,12次,time:60s,2组,17kg,12次,time:60s,"
    "7.悬挂抬腿,1组,12次,time:60s,2组,12次,time:60s,3组,12次,time:60s"
]

SESSIONS = [
    ("Pull #1 (Wed 9/2)", pull_1),
    ("Push #1 (Thu 9/3)", push_1),
    ("Legs #1 (Fri 9/4)", legs_1),
    ("Arms & WP #1 (Sun 9/6)", arms_1),
]


def safe_upsert(plan_name, plan_data, max_retries=5):
    print(f"Pushing {plan_name}...")
    for attempt in range(max_retries):
        res = client.upsert_training_data(plan_data)
        if res is not None:
            print(f"Result for {plan_name}: SUCCESS")
            return res
        print(f"Failed (attempt {attempt+1}/{max_retries}), waiting 20 seconds...")
        time.sleep(20)
    print(f"Result for {plan_name}: FAILED after {max_retries} attempts")
    return None


if __name__ == "__main__":
    for name, data in SESSIONS:
        safe_upsert(name, data)
        time.sleep(8)
    print("Done! Week 3 (Block 1 climb week, #1 sessions) pushed to Xunji calendar.")
