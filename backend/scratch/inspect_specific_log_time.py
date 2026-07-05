import subprocess

try:
    output = subprocess.check_output(
        "journalctl -u orleon-backend.service --since '2026-07-05 06:10:00' --until '2026-07-05 06:20:00' --no-pager",
        shell=True,
        stderr=subprocess.STDOUT,
        text=True
    )
    print("Logs from 06:10 to 06:20:")
    print(output)
except Exception as e:
    print(f"Error: {e}")
