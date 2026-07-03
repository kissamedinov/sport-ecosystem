#!/bin/bash
export PGPASSWORD=sportpassword123
echo "Current matchstatus enum labels before alter:"
psql -h localhost -U sportuser -d sportseco -c "SELECT enumlabel FROM pg_enum JOIN pg_type ON pg_enum.enumtypid = pg_type.oid WHERE pg_type.typname = 'matchstatus';"

echo "Running: ALTER TYPE matchstatus ADD VALUE 'LIVE';"
psql -h localhost -U sportuser -d sportseco -c "ALTER TYPE matchstatus ADD VALUE 'LIVE';"

echo "Current matchstatus enum labels after alter:"
psql -h localhost -U sportuser -d sportseco -c "SELECT enumlabel FROM pg_enum JOIN pg_type ON pg_enum.enumtypid = pg_type.oid WHERE pg_type.typname = 'matchstatus';"
