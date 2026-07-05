import subprocess

try:
    output = subprocess.check_output(
        "journalctl -u orleon-backend.service -n 500 --no-pager",
        shell=True,
        stderr=subprocess.STDOUT,
        text=True
    )
    # Search for traceback
    lines = output.split('\n')
    tb_indices = [i for i, line in enumerate(lines) if 'Traceback' in line]
    print(f"Found {len(tb_indices)} tracebacks in recent logs:")
    for idx in tb_indices:
        print("\n--- TRACEBACK ---")
        # Print 20 lines from the traceback index
        for j in range(idx, min(idx + 25, len(lines))):
            print(lines[j])
except Exception as e:
    print(f"Error reading journalctl: {e}")
