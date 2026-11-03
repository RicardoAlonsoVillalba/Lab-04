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

-- =======================================================
-- Actividad 2: Archivos de configuración
-- =======================================================

-- 1. Rutas de configuración y autenticación
SHOW config_file;
SHOW hba_file;
SHOW ident_file;

-- 2. Directorios de datos y logs
SHOW data_directory;
SHOW log_directory;

-- 3. Parámetros de auditoría de conexiones
SHOW log_connections;
SHOW log_disconnections;

-- =======================================================
-- Actividad 3: Revisión de listen_addresses
-- =======================================================

SHOW listen_addresses;

-- =======================================================
-- Actividad 4: Revisar pg_hba.conf
-- =======================================================

SELECT type, database, user_name, address, auth_method 
FROM pg_hba_file_rules;
