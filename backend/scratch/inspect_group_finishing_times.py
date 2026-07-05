from app.database import SessionLocal
from app.matches.models import MatchResult
from uuid import UUID

db = SessionLocal()
group_match_ids = [
    UUID('f0e7e16e-97b4-4570-8250-b6333a7ecbaf'),
    UUID('07cbb9ab-6315-45c5-974c-13b3d4e63e0d'),
    UUID('5ffd4fcc-ea11-464a-989d-b3ff45ad9a62'),
    UUID('3ebf5326-d36b-480e-b78f-5101c95286d2'),
    UUID('a7ee4deb-9d28-4ac2-878a-627155824e2b'),
    UUID('77e93d1f-fb63-466d-bffd-19dcbb2ff80c'),
    UUID('8414a233-d932-4c74-9aec-6809296fb3ff'),
    UUID('25ecfd79-e535-4087-8ba0-51d79eaf7747'),
    UUID('53d92058-bc7e-4389-9cf5-2d0890283d25'),
    UUID('5e8e355b-4618-44ca-8f44-af9cd7f31626'),
    UUID('a147aeca-36a3-4d98-b0f7-bb994951f0a4'),
    UUID('d0668674-8a5b-4777-b2aa-efdf61a618d8')
]

for m_id in group_match_ids:
    r = db.query(MatchResult).filter(MatchResult.match_id == m_id).first()
    print(f"MatchResult {m_id}: created_at={r.created_at if r else 'None'} status={r.status if r else 'None'}")
db.close()
