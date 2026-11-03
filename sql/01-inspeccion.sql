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

-- =======================================================
-- Actividad 7: Revisar autenticación
-- =======================================================

SHOW password_encryption;

-- =======================================================
-- Actividad 8: Revisar usuarios y privilegios
-- =======================================================

SELECT rolname, rolsuper, rolinherit, rolcreaterole, rolcreatedb, rolcanlogin 
FROM pg_roles 
ORDER BY rolname;

-- =======================================================
-- Actividad 10: Revisar extensiones
-- =======================================================

SELECT extname, extversion FROM pg_extension ORDER BY extname;

-- =======================================================
-- Actividad 11: Revisar configuración de conexiones
-- =======================================================

SHOW max_connections;
SHOW superuser_reserved_connections;
SHOW statement_timeout;
SHOW idle_in_transaction_session_timeout;

-- =======================================================
-- Actividad 12: Revisar permisos del sistema operativo
-- =======================================================

SHOW data_directory;
SHOW config_file;
SHOW hba_file;

-- =======================================================
-- Actividad 15: Revisar TLS
-- =======================================================

SHOW ssl;
SHOW ssl_min_protocol_version;

SELECT 
    pid, 
    usename, 
    client_addr, 
    ssl, 
    version, 
    cipher 
FROM pg_stat_ssl 
WHERE pid = pg_backend_pid();
