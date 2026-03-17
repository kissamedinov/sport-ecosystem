
import os
with open("test_error.txt", "rb") as f:
    content = f.read()
    # Try different encodings
    for encoding in ['utf-16le', 'utf-16', 'utf-8']:
        try:
            print(f"--- {encoding} ---")
            print(content.decode(encoding))
            break
        except:
            pass
