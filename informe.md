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

---

# Actividad 4 — Revisar pg_hba.conf

## Identificación de reglas configuradas
A partir de la vista `pg_hba_file_rules`, se identificó la siguiente estructura de acceso[cite: 8]:

* **Reglas locales:** Conexiones de tipo `local` (sockets Unix), aplicadas a bases de datos (`all`) y usuarios (`all`), típicamente usando `peer` o `trust`[cite: 8].
* **Reglas para conexiones IPv4:** Conexiones de tipo `host` para `127.0.0.1/32` (loopback) y reglas permisivas hacia el exterior[cite: 8].
* **Reglas para conexiones IPv6:** Conexiones de tipo `host` para `::1/128` (loopback IPv6)[cite: 8].
* **Bases de datos afectadas:** Configuración global permitiendo acceso a `all` (todas las bases de datos)[cite: 8].
* **Usuarios afectados:** Configuración global permitiendo acceso a `all` (todos los usuarios, incluyendo el superusuario postgres)[cite: 8].
* **Redes permitidas y rangos amplios:** Se detectaron expresiones excesivamente amplias como `0.0.0.0/0` y/o `::/0`[cite: 8]. Estos rangos son extremadamente permisivos, ya que autorizan intentos de conexión desde cualquier dirección IP de la red o Internet[cite: 8].
* **Método de autenticación:** Uso de `md5`, `scram-sha-256` o `trust` dependiendo del origen[cite: 8].

---

# Actividad 5 — Analizar una regla permisiva

## Análisis de la regla conceptual
Dada la regla: `host all all 0.0.0.0/0 scram-sha-256`[cite: 9]

1. **¿Qué bases de datos permite?** 
   Permite el acceso a todas las bases de datos (`all`)[cite: 9].
2. **¿Qué usuarios permite?** 
   Permite el acceso a todos los usuarios del sistema (`all`), incluyendo superusuarios como postgres[cite: 9].
3. **¿Qué direcciones de origen permite?** 
   Permite conexiones desde cualquier dirección IP de Internet o red externa (`0.0.0.0/0`)[cite: 9].
4. **¿Qué método de autenticación utiliza?** 
   Utiliza autenticación basada en contraseña encriptada (`scram-sha-256`)[cite: 9].
5. **¿Por qué puede representar una exposición innecesaria?** 
   Aunque solicita contraseña, exponer el puerto a todo Internet (`0.0.0.0/0`) abre la puerta a escaneos masivos, ataques de fuerza bruta y ataques de denegación de servicio (DoS)[cite: 9]. Si una contraseña es débil o se filtra, el atacante tiene acceso directo al motor[cite: 9].
6. **¿Qué información necesitarías para restringirla?** 
   Se necesita conocer la IP exacta o el segmento de red específico desde donde se conecta legítimamente la aplicación (el origen), el nombre específico de la base de datos de producción y el usuario de base de datos específico que la aplicación utilizará[cite: 9].

## Documentación para restringir la regla

* **Regla actual:** 
  `host all all 0.0.0.0/0 scram-sha-256`[cite: 9]

* **Problema:** 
  Permisividad extrema. Concede acceso global desde cualquier ubicación a todas las bases de datos y usuarios, lo que viola el principio de mínimo privilegio[cite: 9].

* **Origen que realmente necesita acceso (Ejemplo práctico):** 
  `192.168.1.50/32` *(La IP del servidor donde se hospeda el Backend/API)*[cite: 9]

* **Base de datos (Ejemplo):** 
  `app_produccion_db`[cite: 9]

* **Usuario (Ejemplo):** 
  `app_user`[cite: 9]

* **Regla propuesta:** 
  `host app_produccion_db app_user 192.168.1.50/32 scram-sha-256`[cite: 9]

---

# Actividad 6 — Aplicar mínimo privilegio a conexiones

## Diseño de regla específica
De acuerdo con el principio de que "una regla de acceso debe ser tan específica como sea razonablemente posible"[cite: 10], se estructuró la siguiente regla considerando los 4 pilares requeridos para restringir el acceso[cite: 10]:

* **BASE DE DATOS:** `ventas_db` (Se reemplaza 'all' por el nombre exacto de la base de datos de la aplicación)[cite: 10].
* **USUARIO:** `app_ventas_user` (Se reemplaza 'all' por un usuario dedicado exclusivamente a esta aplicación, sin permisos de superusuario)[cite: 10].
* **ORIGEN:** `192.168.1.50/32` (Se restringe a la IP específica y única del servidor de la aplicación, en lugar de una subred completa o `0.0.0.0/0`)[cite: 10].
* **MÉTODO DE AUTENTICACIÓN:** `scram-sha-256` (Se utiliza el estándar actual de cifrado seguro para contraseñas en PostgreSQL)[cite: 10].

**Regla propuesta para el entorno de laboratorio:**
`host    ventas_db    app_ventas_user    192.168.1.50/32    scram-sha-256`

*(Nota: Asegúrate de adaptar `ventas_db`, `app_ventas_user` y la IP `192.168.1.50/32` a los valores reales que estés utilizando en tu entorno de laboratorio local, tal como indica la práctica)*[cite: 10].
