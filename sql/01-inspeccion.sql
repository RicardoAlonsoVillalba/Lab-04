-- =======================================================
-- Actividad 1: Inspección de la superficie de ataque
-- =======================================================

-- 1. Versión del servidor PostgreSQL
SELECT version();

-- 2. Parámetros de red y cifrado
SHOW port;
SHOW listen_addresses;
SHOW ssl;
SHOW password_encryption;

-- 3. Inspección de conexiones activas
SELECT 
    pid, 
    usename, 
    datname, 
    client_addr, 
    client_port, 
    application_name 
FROM pg_stat_activity;
