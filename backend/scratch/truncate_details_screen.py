filepath = r"c:\Users\Asus\Desktop\test\mobile\lib\features\matches\presentation\screens\match_details_screen.dart"

with open(filepath, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Truncate after line 901 (index 900)
truncated_lines = lines[:901]

with open(filepath, 'w', encoding='utf-8') as f:
    f.writelines(truncated_lines)

print("Truncation complete!")
