import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database import Base

with open("debug_results.txt", "w") as f:
    f.write("Registered tables in Base.metadata:\n")
    for table in Base.metadata.tables.keys():
        f.write(f" - {table}\n")

    try:
        from app.users import models
        f.write("\nAttempted to import users.models...\n")
        from app.users.models import Permission, RolePermission
        f.write("Permission and RolePermission imported.\n")
    except Exception as e:
        f.write(f"\nImport failed: {e}\n")
