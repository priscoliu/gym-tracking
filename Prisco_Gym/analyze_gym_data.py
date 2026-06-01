import os
import json
import time
from datetime import datetime, timedelta
from xunji_api_client import XunjiClient

def fetch_recent_data(days=30):
    client = XunjiClient()
    today = datetime.now()
    
    all_data = []
    
    # Loop from today backwards
    for i in range(days):
        date = today - timedelta(days=i)
        datestr = date.strftime("%Y-%m-%d")
        
        print(f"Fetching {datestr}...")
        data = client.get_training_data(datestr)
        
        if data:
            all_data.extend(data)
            
        # Add a tiny sleep to avoid triggering any global rate limits just in case
        time.sleep(0.5)
        
    return all_data

def analyze_data(all_data):
    if not all_data:
        print("No training data found.")
        return
        
    print("\n" + "="*50)
    print(f"TOTAL EXERCISE ENTRIES FOUND: {len(all_data)}")
    print("="*50)
    
    # We skipped printing to console to avoid UnicodeEncodeError on Windows
    print("Writing data to recent_gym_data_summary.json...")
        
    # We will write the aggregated data to a file for the LLM to read easily
    with open("recent_gym_data_summary.json", "w", encoding="utf-8") as f:
        json.dump(all_data, f, ensure_ascii=False, indent=2)

if __name__ == "__main__":
    data = fetch_recent_data(30)
    analyze_data(data)
