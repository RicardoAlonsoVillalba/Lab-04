# LAB-04 — Hardening y configuración segura de PostgreSQL

## Objetivo
Auditar, identificar vulnerabilidades y aplicar controles de hardening a nivel de motor de base de datos PostgreSQL, red y sistema operativo, garantizando el cumplimiento de los principios de mínimo privilegio, segregación de funciones, cifrado en tránsito y defensa en profundidad.

## Entorno
* **Motor de Base de Datos:** PostgreSQL 14+ / PostgreSQL 16
* **Sistema Operativo:** Ubuntu Linux / Debian / WSL
* **Herramientas de Administración:** Terminal `psql`, Git Bash, DBeaver / pgAdmin
* **Capa de Red:** Firewall local (ufw/iptables), cliente SSH

## Superficie de ataque inicial
Antes de la aplicación del hardening, la instancia presentaba una superficie de exposición elevada caracterizada por:
* Escucha en todas las interfaces de red (`listen_addresses = '*'`).
* Reglas en `pg_hba.conf` laxas permitiendo conexiones desde `0.0.0.0/0`.
* Uso potencial de algoritmos de autenticación obsoletos o contraseñas en texto plano.
* Uso de cuentas superusuario (`postgres`) para tareas de aplicación web.
* Cuentas de aplicación con acceso irrestricto al esquema `public`.
* Inexistencia de timeouts de sesión inactiva y límites de conexiones por rol.
* Permisos laxos a nivel de archivos del Sistema Operativo (`644` / `755`).

## Hallazgos
1. **Red sin segmentar:** Exposición innecesaria del puerto 5432 hacia subredes no autorizadas.
2. **Elevación de Privilegios:** Aplicaciones autenticadas con roles con capacidad de `SUPERUSER`, permitiendo la lectura de archivos locales del SO a través del motor.
3. **Falta de Trazabilidad:** Ausencia de registros (logs) detallados para auditar aperturas y cierres de sesión.
4. **Ausencia de Restricciones en Transacciones Inactivas:** Sesiones `idle in transaction` abiertas de forma indefinida, bloqueando recursos y tablas.
5. **Permisos de Archivo Inseguros:** Archivos de configuración como `postgresql.conf` y `pg_hba.conf` legibles por usuarios no administradores del SO.

## Cambios realizados
* **Aislamiento de Red:** Cambio de `listen_addresses` a `localhost` / IP privada específica y restricción de `pg_hba.conf` a IPs individuales con directivas `hostssl`.
* **Cifrado Obligatorio:** Activación de TLS con `ssl_min_protocol_version = 'TLSv1.2'` y uso exclusivo de cifrado de contraseñas con `scram-sha-256`.
* **Segregación de Roles:** Creación de roles independientes `app_user` (solo DML) y `consulta_user` (solo lectura), revocando accesos del rol `PUBLIC`.
* **Control de Tiempos de Espera:** Configuración de `statement_timeout = '30s'` e `idle_in_transaction_session_timeout = '10s'`.
* **Hardening a Nivel de OS:** Ajuste de permisos a `0700` en `$PGDATA` y `0600` en archivos `.conf` restringidos al usuario `postgres`.
* **Auditoría:** Habilitación de `log_connections = on` y `log_disconnections = on`.

## Justificación de los cambios
* **Protección contra Intercepción (MITM):** La migración a `scram-sha-256` y `TLSv1.2+` impide el sniffing de contraseñas y datos sensibles en tránsito.
* **Mitigación de SQL Injection:** Restringir a la aplicación web a un rol no-superusuario con permisos DML minima el impacto de un ataque de inyección SQL, evitando la destrucción o exfiltración total de la BD.
* **Prevención de DoS:** El ajuste de timeouts y límites de conexión previene que sesiones huérfanas agoten la memoria RAM del servidor o consuman el pool `max_connections`.
* **Defensa en Profundidad:** El hardening a nivel de SO previene que un atacante local sin privilegios pueda leer físicamente los archivos contables de la base de datos.

## Verificación
La validación de la efectividad de los controles se realizó mediante:
1. Consultas SQL de inspección (`SHOW`, `pg_roles`, `pg_stat_ssl`).
2. Comprobaciones desde la terminal del SO (`ss -lnt`, `ls -ld`, `ls -l`).
3. Auditorías ejecutadas desde los scripts acumulativos almacenados en la carpeta `sql/`.
4. Capturas de evidencia guardadas en la carpeta `evidencias/`.

## Checklist of hardening
Se definió e implementó un checklist de 15 controles esenciales (Red, Autenticación, Autorización, SO, Cifrado, Configuración y Mantenimiento), registrando la verificación completa de cada punto en el archivo `informe.md`.

## Conclusiones
El hardening de un motor de base de datos como PostgreSQL no depende exclusivamente de contar con contraseñas complejas. Requiere una arquitectura resiliente donde la seguridad en red (firewall y pg_hba), el principio de mínimo privilegio en los roles, el cifrado estricto y los permisos adecuados a nivel de sistema operativo trabajen en conjunto para neutralizar vectores de ataque antes de que comprometan la disponibilidad o la confidencialidad de la información.
