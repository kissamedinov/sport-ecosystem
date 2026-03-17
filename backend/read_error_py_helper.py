
import os
def read_with_guessing(filepath):
    with open(filepath, "rb") as f:
        content = f.read()
    for encoding in ['utf-16le', 'utf-16', 'utf-8', 'cp1252']:
        try:
            print(f"--- {encoding} ---")
            print(content.decode(encoding))
            return
        except:
            pass
read_with_guessing("server_debug.txt")
