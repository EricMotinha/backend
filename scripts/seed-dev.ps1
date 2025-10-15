$env:DATABASE_URL = 'postgres://postgres:Bonja123@localhost:5432/Casamenteiro?sslmode=disable'
& 'C:\Program Files\PostgreSQL\18\bin\psql.exe' $env:DATABASE_URL -v ON_ERROR_STOP=1 -f .\db\seeds\dev_seed.sql
