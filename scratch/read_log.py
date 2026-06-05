import json

log_path = r"C:\Users\Asus\.gemini\antigravity\brain\d1d5fe80-4dd6-4088-94a4-cdef79622e6c\.system_generated\logs\transcript.jsonl"

with open(log_path, 'r', encoding='utf-8') as f:
    for line in f:
        try:
            data = json.loads(line)
            content = data.get("content", "")
            # check tool calls too
            tool_calls = data.get("tool_calls", [])
            for tc in tool_calls:
                args = tc.get("args", {})
                cmd = args.get("CommandLine", "")
                if "ssh" in cmd.lower():
                    print(f"Step {data.get('step_index')}: COMMAND={cmd}")
        except Exception as e:
            pass
