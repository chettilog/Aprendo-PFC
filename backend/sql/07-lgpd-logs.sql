\encoding UTF8
-- Entrega 16/11 (LGPD): tira os e-mails que estavam escritos por extenso nos logs antigos.
-- "Novo usuário: joao@email.com" vira "Novo usuário: j***@email.com".
-- Os logs novos já são gravados assim pelo sistema (backend/src/servicos/logs.js).
-- Pode rodar mais de uma vez.
-- Como rodar (na pasta backend):
--   psql $env:DB_URL -f sql/07-lgpd-logs.sql

UPDATE logs
SET detalhes = regexp_replace(
  detalhes,
  '([A-Za-z0-9._%+-])[A-Za-z0-9._%+-]*@',
  '\1***@',
  'g'
)
WHERE detalhes ~ '[A-Za-z0-9._%+-]@';
