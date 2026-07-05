import subprocess

try:
    output = subprocess.check_output(
        "journalctl -u orleon-backend.service --since 'today' --no-pager",
        shell=True,
        stderr=subprocess.STDOUT,
        text=True
    )
    print("Logs from today:")
    # Print the last 150 lines of today's logs
    lines = output.split('\n')
    print(f"Total lines: {len(lines)}")
    for line in lines[-150:]:
        print(line)
except Exception as e:
    print(f"Error: {e}")
