import os
import json
import gzip
import urllib.request
import urllib.error
from datetime import datetime

class XunjiClient:
    def __init__(self, api_key="xjllm_5acea9452dc995e6df3334fc9a60f33a8a43e08dbda02428", cache_dir="xunji_cache"):
        self.api_key = api_key
        self.base_url = "https://trains.xunjiapp.cn/api_trains_for_llm"
        self.cache_dir = cache_dir
        
        # Ensure cache directory exists
        if not os.path.exists(self.cache_dir):
            os.makedirs(self.cache_dir)

    def get_training_data(self, datestr):
        """
        Fetch training data for a specific date (YYYY-MM-DD).
        Uses local cache if available to avoid duplicate requests.
        """
        try:
            datetime.strptime(datestr, "%Y-%m-%d")
        except ValueError:
            raise ValueError("datestr must be in YYYY-MM-DD format")

        cache_path = os.path.join(self.cache_dir, f"trains_{datestr}.json")

        # 1. Check if we already have it in the cache
        if os.path.exists(cache_path):
            print(f"[CACHE] Loading data for {datestr} from {cache_path}")
            with open(cache_path, 'r', encoding='utf-8') as f:
                return json.load(f)

        print(f"[API] Fetching data for {datestr} from {self.base_url}")
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
            "Accept-Encoding": "gzip"
        }
        
        payload = json.dumps({"datestr": datestr}).encode('utf-8')
        req = urllib.request.Request(self.base_url, data=payload, headers=headers, method='POST')
        
        try:
            # 2. Make the API request
            with urllib.request.urlopen(req) as response:
                content_encoding = response.headers.get('Content-Encoding', '')
                raw_data = response.read()
                
                # Handle gzip if returned
                if 'gzip' in content_encoding:
                    content = gzip.decompress(raw_data).decode('utf-8')
                else:
                    content = raw_data.decode('utf-8')
                
                try:
                    result = json.loads(content)
                except json.JSONDecodeError:
                    print(f"[ERROR] Invalid JSON response: {content}")
                    return None
                
                if not isinstance(result, dict):
                    print(f"[ERROR] Expected dict response, got {type(result)}: {result}")
                    return None

                if result.get("success") is False:
                    print(f"[ERROR] API request failed: {result}")
                    return None
                    
                res_array = result.get("res", [])
                if not isinstance(res_array, list):
                    print(f"[ERROR] Expected 'res' to be a list, got {type(res_array)}: {res_array}")
                    return None
                
                # 3. Save to local cache (preserving everything including id and train_time)
                with open(cache_path, 'w', encoding='utf-8') as f:
                    json.dump(res_array, f, ensure_ascii=False, indent=2)
                    
                print(f"[SUCCESS] Saved {len(res_array)} records to cache.")
                return res_array
                
        except urllib.error.HTTPError as e:
            error_body = e.read().decode('utf-8') if e.read() else ""
            print(f"[HTTP ERROR] {e.code}: {error_body}")
            return None
        except Exception as e:
            print(f"[ERROR] {str(e)}")
            return None

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Fetch Xunji training data and cache it locally.")
    parser.add_argument("--date", default="2026-04-02", help="Date in YYYY-MM-DD format (default: 2026-04-02)")
    args = parser.parse_args()
    
    client = XunjiClient()
    data = client.get_training_data(args.date)
    
    if data is not None:
        print(f"\n--- Data for {args.date} ---")
        for item in data:
            print(item)
