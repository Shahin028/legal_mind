import requests

KEY = "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"
models = [
    "google/gemma-3-27b-it:free",
    "meta-llama/llama-3.2-3b-instruct:free",
    "deepseek/deepseek-r1-0528:free",
    "qwen/qwen3-30b-a3b:free",
    "mistralai/mistral-small-3.1-24b-instruct:free",
]

for m in models:
    try:
        r = requests.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers={"Authorization": f"Bearer {KEY}", "Content-Type": "application/json"},
            json={"model": m, "messages": [{"role": "user", "content": "say hi"}], "max_tokens": 10},
            timeout=15,
        )
        body = r.json()
        err  = body.get("error", {}).get("message", "")
        ok   = "choices" in body
        print(f"{'OK' if ok else 'FAIL'} {r.status_code}  {m}  {err[:60]}")
    except Exception as e:
        print(f"ERR  {m}  {e}")
