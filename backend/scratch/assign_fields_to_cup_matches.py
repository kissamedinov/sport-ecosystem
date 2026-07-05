from app.database import SessionLocal
from app.matches.models import Match
from app.tournaments.models import Tournament
from sqlalchemy import text
import json
from uuid import UUID, uuid4

db = SessionLocal()
T_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')
OWNER_ID = UUID('00bf28d3-feb0-42e4-b5ea-1549aba2a0bd')

try:
    # 1. Get or create fields "Поле 1" and "Поле 2"
    f1_row = db.execute(text("SELECT id FROM fields WHERE name = 'Поле 1'")).first()
    if f1_row:
        f1_id = f1_row[0]
    else:
        f1_id = uuid4()
        db.execute(
            text("INSERT INTO fields (id, name, location, owner_id) VALUES (:fid, 'Поле 1', 'Astana', :oid)"),
            {"fid": f1_id, "oid": OWNER_ID}
        )
        print(f"Created field 'Поле 1' with ID: {f1_id}")
        
    f2_row = db.execute(text("SELECT id FROM fields WHERE name = 'Поле 2'")).first()
    if f2_row:
        f2_id = f2_row[0]
    else:
        f2_id = uuid4()
        db.execute(
            text("INSERT INTO fields (id, name, location, owner_id) VALUES (:fid, 'Поле 2', 'Astana', :oid)"),
            {"fid": f2_id, "oid": OWNER_ID}
        )
        print(f"Created field 'Поле 2' with ID: {f2_id}")
        
    # 2. Update field_ids of the tournament
    t = db.query(Tournament).filter(Tournament.id == T_ID).first()
    if t:
        t.field_ids = json.dumps([str(f1_id), str(f2_id)])
        t.num_fields = 2
        print(f"Updated tournament fields configuration: {t.field_ids}")
        
    # 3. Assign matches to Поле 1
    pole1_matches = [
        UUID('07cbb9ab-6315-45c5-974c-13b3d4e63e0d'),  # Elsana vs FC ASU 1
        UUID('a7ee4deb-9d28-4ac2-878a-627155824e2b'),  # Fc Arda vs Legacy
        UUID('77e93d1f-fb63-466d-bffd-19dcbb2ff80c'),  # Legacy vs Elsana
        UUID('5e8e355b-4618-44ca-8f44-af9cd7f31626'),  # Fc Arda vs FC ASU 1
        UUID('d0668674-8a5b-4777-b2aa-efdf61a618d8'),  # Elsana vs Fc Arda
        UUID('8414a233-d932-4c74-9aec-6809296fb3ff'),  # Legacy vs FC ASU 1
        UUID('dc247b0e-0397-443f-a755-9c220f072124'),  # 1/2: B1 vs A2
        UUID('63cc68ed-5576-4f3e-936e-2e0a816f48de'),  # За 5-6 место: A3 vs B3
        UUID('34f770c7-8cf4-42d2-8ab2-d6e50892e529'),  # Финал 🏆
    ]
    
    # 4. Assign matches to Поле 2
    pole2_matches = [
        UUID('53d92058-bc7e-4389-9cf5-2d0890283d25'),  # Commandos vs Kultegin
        UUID('a147aeca-36a3-4d98-b0f7-bb994951f0a4'),  # Sairan vs IM
        UUID('f0e7e16e-97b4-4570-8250-b6333a7ecbaf'),  # IM vs Commandos
        UUID('5ffd4fcc-ea11-464a-989d-b3ff45ad9a62'),  # Sairan vs Kultegin
        UUID('25ecfd79-e535-4087-8ba0-51d79eaf7747'),  # Commandos vs Sairan
        UUID('3ebf5326-d36b-480e-b78f-5101c95286d2'),  # IM vs Kultegin
        UUID('377b52c8-ee15-497b-98c0-3ba9535407c4'),  # 1/2: A1 vs B2
        UUID('f544bfdd-4c6c-4d5c-beff-536a3ca877c4'),  # За 7-8 место: A4 vs B4
        UUID('6cf1685a-305d-4c9e-8e80-850f16795d17'),  # За 3 место 🥉
    ]
    
    for m_id in pole1_matches:
        m = db.query(Match).filter(Match.id == m_id).first()
        if m:
            m.field_id = f1_id
            
    for m_id in pole2_matches:
        m = db.query(Match).filter(Match.id == m_id).first()
        if m:
            m.field_id = f2_id
            
    db.commit()
    print("Successfully assigned all matches of Juldyz Ball Cup to 'Поле 1' and 'Поле 2' in DB!")
except Exception as e:
    db.rollback()
    print(f"Error during assignment: {e}")
finally:
    db.close()
