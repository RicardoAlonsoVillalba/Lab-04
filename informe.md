# Actividad 1 — Identificar la superficie de ataque

## Registro de superficie de ataque

| Elemento | Estado actual | ¿Es necesario? | Riesgo |
| :--- | :--- | :--- | :--- |
| **Puerto PostgreSQL** | `5432` | Sí (para servicio), pero puede cambiar o aislarse. | Bajo por sí solo, pero expuesto a escaneos automatizados si la red está abierta[cite: 11, 13]. |
| **Interfaces de escucha** | `*` (Escucha en todas las IPs) | No (sólo debería escuchar en la interfaz requerida). | **Alto**: Expone el puerto a redes no autorizadas o públicas[cite: 11, 13]. |
| **Conexiones remotas** | Activas desde múltiples orígenes IP | Solo para nodos autorizados. | **Alto**: Movimiento lateral de atacantes e intentos de fuerza bruta[cite: 11, 13]. |
| **Usuarios administrativos** | `postgres` (Superuser genérico) | Solo para administración controlada. | **Crítico**: Si la contraseña es débil o se usa en apps, compromete la base completa[cite: 11, 13]. |
| **SSL/TLS** | `off` / deshabilitado | Sí, para proteger datos en tránsito. | **Alto**: Intercepción de credenciales y datos en texto plano (Man-in-the-Middle)[cite: 11, 13]. |
| **Métodos de autenticación** | `md5` o `trust` | No (debe usarse `scram-sha-256`). | **Medio-Alto**: Susceptible a cracking de hashes o acceso sin contraseña[cite: 11, 13]. |

## Pregunta Analítica
**¿Por qué conocer la superficie de ataque debe preceder al hardening?**[cite: 13]

Porque no se puede proteger lo que no se conoce. Conocer la superficie de ataque permite establecer una línea base de seguridad identificando todos los puntos expuestos (puertos, interfaces, servicios, permisos y usuarios)[cite: 11]. Esto asegura que las medidas de *hardening* se apliquen sobre riesgos reales identificados y evita deshabilitar configuraciones o servicios legítimos que la organización realmente necesita para su operación[cite: 11].
# Actividad 1 — Identificar la superficie de ataque

## Registro de superficie de ataque

| Elemento | Estado actual | ¿Es necesario? | Riesgo |
| :--- | :--- | :--- | :--- |
| **Puerto PostgreSQL** | `5432` | Sí (para servicio), pero puede cambiar o aislarse. | Bajo por sí solo, pero expuesto a escaneos automatizados si la red está abierta[cite: 11, 13]. |
| **Interfaces de escucha** | `*` (Escucha en todas las IPs) | No (sólo debería escuchar en la interfaz requerida). | **Alto**: Expone el puerto a redes no autorizadas o públicas[cite: 11, 13]. |
| **Conexiones remotas** | Activas desde múltiples orígenes IP | Solo para nodos autorizados. | **Alto**: Movimiento lateral de atacantes e intentos de fuerza bruta[cite: 11, 13]. |
| **Usuarios administrativos** | `postgres` (Superuser genérico) | Solo para administración controlada. | **Crítico**: Si la contraseña es débil o se usa en apps, compromete la base completa[cite: 11, 13]. |
| **SSL/TLS** | `off` / deshabilitado | Sí, para proteger datos en tránsito. | **Alto**: Intercepción de credenciales y datos en texto plano (Man-in-the-Middle)[cite: 11, 13]. |
| **Métodos de autenticación** | `md5` o `trust` | No (debe usarse `scram-sha-256`). | **Medio-Alto**: Susceptible a cracking de hashes o acceso sin contraseña[cite: 11, 13]. |

## Pregunta Analítica
**¿Por qué conocer la superficie de ataque debe preceder al hardening?**[cite: 13]

Porque no se puede proteger lo que no se conoce. Conocer la superficie de ataque permite establecer una línea base de seguridad identificando todos los puntos expuestos (puertos, interfaces, servicios, permisos y usuarios)[cite: 11]. Esto asegura que las medidas de *hardening* se apliquen sobre riesgos reales identificados y evita deshabilitar configuraciones o servicios legítimos que la organización realmente necesita para su operación[cite: 11].

---

# Actividad 2 — Identificar los archivos de configuración

## Clasificación de parámetros
Al ejecutar las consultas, distinguimos cuatro categorías principales de almacenamiento en el motor[cite: 9]:
* **Configuración:** `config_file` (generalmente `postgresql.conf`).
* **Autenticación:** `hba_file` (`pg_hba.conf`) y `ident_file` (`pg_ident.conf`).
* **Datos:** `data_directory` (donde residen las bases de datos físicas).
* **Logs:** `log_directory`, `log_connections`, y `log_disconnections` (para auditoría y monitoreo).

## Pregunta Analítica
**¿Por qué es importante conocer la ubicación física de estos archivos?**[cite: 9]

Es fundamental porque la seguridad de PostgreSQL no depende únicamente de los permisos internos de la base de datos (roles y grants), sino también de la seguridad del sistema operativo. Si un atacante o usuario no autorizado logra acceso de lectura/escritura a archivos críticos como `pg_hba.conf` o `postgresql.conf` a nivel del sistema de archivos, podría modificar las reglas de autenticación, habilitar el acceso sin contraseña (trust) o exponer toda la base de datos, evadiendo completamente los controles internos del motor. Conocer su ubicación permite auditar y restringir los permisos de lectura y escritura (ej. mediante `chmod` y `chown`) para que solo el usuario de sistema `postgres` pueda acceder a ellos.

---

# Actividad 3 — Revisar listen_addresses

## Documentación de la configuración
* **Configuración encontrada:** `*` (Escucha en todas las interfaces).
* **Interfaces necesarias:** `localhost` y la IP de la red privada interna.
* **Interfaces innecesarias:** Interfaces públicas o comodines como `0.0.0.0`.

## Análisis de Arquitectura
La segunda arquitectura (Internet -> X -> Firewall -> Red privada -> Servidor PostgreSQL) reduce mejor la exposición[cite: 8]. Al ubicar el motor de base de datos dentro de una red privada protegida por un firewall que bloquea el tráfico de Internet, el puerto 5432 queda completamente aislado del exterior[cite: 8]. Esto garantiza que solo los servicios internos (como una aplicación en la misma red) puedan comunicarse con la base de datos, eliminando la posibilidad de ataques directos o escaneos desde redes públicas[cite: 8].
