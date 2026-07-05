with open('/root/sport-ecosystem/backend/app/matches/services.py', 'r') as f:
    lines = f.readlines()
for i in range(130, 160):
    print(f"{i+1}: {lines[i]}", end="")
