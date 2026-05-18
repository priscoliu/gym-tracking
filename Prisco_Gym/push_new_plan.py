import os
import sys
import time

# Ensure we can import xunji_api_client from current directory
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from xunji_api_client import XunjiClient

client = XunjiClient()

push_plan = [
    "2026-05-18,Push (新计划),1.杠铃卧推,1组,61.25kg,10次,time:90s,2组,61.25kg,10次,time:90s,3组,61.25kg,10次,time:90s,2.上斜哑铃卧推,1组,25kg,8次,time:90s,2组,25kg,8次,time:90s,3组,25kg,8次,time:90s,3.双杠臂屈伸(负重),1组,5kg,12次,time:90s,2组,5kg,12次,time:90s,3组,5kg,12次,time:90s,4.器械推肩,1组,25kg,10次,time:90s,2组,25kg,10次,time:90s,3组,25kg,10次,time:90s,5.平板上斜侧平举,1组,6kg,12次,time:60s,2组,6kg,12次,time:60s,3组,6kg,12次,time:60s,6.直杆绳索下压,1组,21kg,12次,time:60s,2组,21kg,12次,time:60s,3组,21kg,12次,time:60s,7.悬垂举腿,1组,0kg,12次,time:60s,2组,0kg,12次,time:60s,3组,0kg,12次,time:60s"
]

pull_plan = [
    "2026-05-19,Pull (新计划),1.引体向上,1组,0kg,12次,time:90s,2组,0kg,12次,time:90s,3组,0kg,12次,time:90s,4组,0kg,12次,time:90s,2.坐姿划船,1组,50kg,10次,time:90s,2组,50kg,10次,time:90s,3组,50kg,10次,time:90s,3.窄距下拉,1组,48kg,10次,time:90s,2组,48kg,10次,time:90s,3组,48kg,10次,time:90s,4.杠铃罗马尼亚硬拉,1组,40kg,10次,time:90s,2组,40kg,10次,time:90s,3组,40kg,10次,time:90s,5.面拉,1组,12.5kg,12次,time:60s,2组,12.5kg,12次,time:60s,3组,12.5kg,12次,time:60s,6.EZ杆二头弯举,1组,20kg,12次,time:60s,2组,20kg,12次,time:60s,3组,20kg,12次,time:60s,7.上斜哑铃弯举,1组,7kg,12次,time:60s,2组,7kg,12次,time:60s,3组,7kg,12次,time:60s"
]

legs_plan = [
    "2026-05-20,Legs (新计划),1.深蹲(底部停顿1秒),1组,77.5kg,8次,time:90s,2组,77.5kg,8次,time:90s,3组,77.5kg,8次,time:90s,2.腿举,1组,165kg,10次,time:90s,2组,165kg,10次,time:90s,3组,165kg,10次,time:90s,3.腿弯举,1组,35kg,10次,time:60s,2组,35kg,10次,time:60s,3组,35kg,10次,time:60s,4.杠铃臀冲,1组,40kg,12次,time:90s,2组,40kg,12次,time:90s,3组,40kg,12次,time:90s,5.站姿绳索卷腹,1组,30.5kg,12次,time:60s,2组,30.5kg,12次,time:60s,3组,30.5kg,12次,time:60s,6.悬垂举腿,1组,0kg,12次,time:60s,2组,0kg,12次,time:60s,3组,0kg,12次,time:60s"
]

def safe_upsert(plan_name, plan_data):
    print(f"Pushing {plan_name}...")
    while True:
        res = client.upsert_training_data(plan_data)
        if res is not None:
            print(f"Result for {plan_name}: SUCCESS")
            return res
        print("Rate limited or failed, waiting 15 seconds...")
        time.sleep(15)

safe_upsert("Day 1 (Push)", push_plan)
time.sleep(5)
safe_upsert("Day 2 (Pull)", pull_plan)
time.sleep(5)
safe_upsert("Day 3 (Legs)", legs_plan)

print("Done! Check your Xunji app.")
