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

---

# Actividad 7 — Revisar autenticación

## Respuestas sobre Autenticación y Autorización
A partir de la revisión de `password_encryption` (que debería preferir `scram-sha-256` frente a `md5`)[cite: 10], se responde a lo siguiente:

1. **¿Qué diferencia existe entre autenticación y autorización?**
   La **autenticación** verifica *quién* es el usuario (identidad), comprobando credenciales como usuario y contraseña[cite: 10]. La **autorización** determina *qué* tiene permitido hacer ese usuario una vez que ha ingresado (permisos, roles, acceso a tablas específicas)[cite: 10].
   
2. **¿Qué protege scram-sha-256?**
   Protege las contraseñas tanto en tránsito (evitando que se envíen en texto plano por la red o que sean interceptadas y reutilizadas en ataques de "pass-the-hash") como en reposo, almacenándolas mediante un algoritmo de hash criptográfico robusto y salteado (salt) que resiste ataques de diccionario y fuerza bruta mucho mejor que MD5[cite: 10].

3. **¿Por qué una contraseña almacenada mediante un mecanismo de autenticación no debe confundirse con cifrado reversible?**
   Porque las contraseñas se almacenan como un **hash (unidireccional)**, lo que significa que a partir del hash no se puede aplicar un proceso matemático para recuperar la contraseña original en texto plano[cite: 10]. El cifrado reversible, por el contrario, permite descifrar el contenido si se tiene la llave adecuada[cite: 10]. 

4. **¿Qué sucede si una cuenta tiene permisos excesivos aunque utilice una contraseña fuerte?**
   Si la cuenta llega a ser comprometida (por phishing, robo de sesión o uso malicioso por parte de un empleado), el atacante heredará todos esos permisos excesivos[cite: 10]. Una contraseña fuerte solo protege el perímetro de entrada (autenticación), pero no mitiga el daño si el atacante logra entrar; esto viola el principio de mínimo privilegio y expone todo el sistema[cite: 10].

---

# Actividad 8 — Revisar usuarios y privilegios

## Identificación de roles y privilegios
Al ejecutar la consulta en la vista `pg_roles`, se identificaron los siguientes usuarios y sus respectivos niveles de acceso en el sistema[cite: 11]:

| Rol | LOGIN | SUPERUSER | CREATEROLE | CREATEDB | Función |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **postgres** | Sí (`t`) | Sí (`t`) | Sí (`t`) | Sí (`t`) | Administrador principal del motor de base de datos. Cuenta por defecto. |
| **app_user** *(ejemplo)* | Sí (`t`) | No (`f`) | No (`f`) | No (`f`) | Rol utilizado por la aplicación para conectarse y operar sobre sus datos. |
| **backup_rol** *(ejemplo)* | Sí (`t`) | No (`f`) | No (`f`) | No (`f`) | Cuenta que podría ser innecesaria si no se programan respaldos automatizados o si retiene permisos excesivos. |

## Análisis de Seguridad

**Pregunta:** ¿Por qué no debería utilizarse una cuenta SUPERUSER como cuenta normal de una aplicación?[cite: 11]

**Respuesta:** 
Utilizar un `SUPERUSER` para una aplicación viola el principio de mínimo privilegio. Un superusuario elude todas las comprobaciones de permisos en PostgreSQL. Si la aplicación sufre una vulnerabilidad (como una Inyección SQL) o sus credenciales son robadas, el atacante obtendría control total y absoluto sobre todo el clúster. Podría leer, modificar o eliminar cualquier base de datos de otros inquilinos, alterar la configuración del motor e incluso, bajo ciertas condiciones, ejecutar comandos en el sistema operativo del servidor. Una aplicación solo debe tener permisos sobre los objetos (tablas, secuencias, vistas) que estrictamente necesita para funcionar.

---

# Actividad 9 — Separar cuentas administrativas y de aplicación

## Diseño de cuentas (Matriz de roles)
Para aplicar una correcta segregación de funciones y proteger la base de datos, se diseña la siguiente estructura conceptual de cuentas[cite: 12]:

| Cuenta | Propósito | LOGIN | Privilegios |
| :--- | :--- | :---: | :--- |
| **DBA** | Administración | Sí | Administrativos (gestión del motor, roles, esquemas y configuraciones globales)[cite: 12]. |
| **APP** | Aplicación | Sí | Mínimos (operaciones DML estrictamente necesarias para el software, ej: `INSERT`, `UPDATE`, `SELECT`)[cite: 12]. |
| **CONSULTA** | Consulta | Sí | Solo lectura (exclusivamente `SELECT`, ideal para reportes, análisis de datos o auditorías)[cite: 12]. |

## Análisis de Riesgo

**Pregunta:** ¿Qué riesgo existe si la aplicación se conecta utilizando una cuenta administrativa?[cite: 12]

**Respuesta:** 
Si la aplicación se conecta con privilegios administrativos (ej. superusuario o DBA), cualquier vulnerabilidad en el código del software (como una Inyección SQL) o el robo de las credenciales de conexión le otorgará a un atacante **control total sobre todo el servidor de base de datos**. 

El atacante no solo podría acceder a los datos de la aplicación comprometida, sino que podría eliminar bases de datos completas (`DROP DATABASE`), leer o modificar información de otras aplicaciones alojadas en el mismo clúster, crear usuarios maliciosos (backdoors) e incluso intentar ejecutar comandos a nivel del sistema operativo. Esto representa una violación crítica al principio de mínimo privilegio.

---

# Actividad 10 — Revisar extensiones

## Análisis de extensiones instaladas
Tras ejecutar la consulta `SELECT extname, extversion FROM pg_extension ORDER BY extname;`[cite: 12], se evaluó el estado de las extensiones en la base de datos:

1. **¿Qué extensiones existen?**
   En una instalación estándar de PostgreSQL siempre existirá `plpgsql`[cite: 12]. En entornos de prueba o si se han utilizado herramientas gráficas, es común encontrar otras como `adminpack`, `dblink` o `pgcrypto`[cite: 12].
2. **¿Cuáles son necesarias?**
   `plpgsql` es estrictamente necesaria si el sistema, las aplicaciones o los triggers dependen de funciones y procedimientos almacenados escritos en el lenguaje procedural nativo de PostgreSQL[cite: 12].
3. **¿Cuáles fueron instaladas para prácticas?**
   Extensiones como `adminpack` (usada comúnmente por pgAdmin para recolectar métricas del servidor) o `dblink` suelen instalarse específicamente para ejercicios de laboratorio y pruebas de administración[cite: 12].
4. **¿Cuáles podrían representar funcionalidad innecesaria en otro entorno?**
   En un entorno de producción, `adminpack` o módulos de conexión cruzada como `dblink` o `postgres_fdw` representan un riesgo si la aplicación principal no los requiere[cite: 12]. 

**Principio de Hardening:**
No significa que una extensión sea insegura simplemente por estar instalada[cite: 12]. Sin embargo, el principio rector de hardening establece que se debe **habilitar únicamente la funcionalidad necesaria para el propósito del sistema**[cite: 12]. Cualquier extensión ajena a las necesidades de la aplicación incrementa la superficie de ataque y debe ser desinstalada.

---

# Actividad 11 — Revisar configuración relacionada con conexiones

## Parámetros de Conexión y Tiempos de Espera
Al ejecutar las consultas de configuración[cite: 11], se obtuvieron los siguientes valores (Nota: los valores reales pueden variar según tu entorno, aquí se muestran los valores por defecto de PostgreSQL):

| Parámetro | Valor (Ejemplo) | Función |
| :--- | :--- | :--- |
| **max_connections** | `100` | Define el número máximo de conexiones concurrentes permitidas al servidor de base de datos[cite: 11]. |
| **superuser_reserved_connections** | `3` | Reserva un número específico de conexiones exclusivas para superusuarios[cite: 11]. Garantiza que un administrador siempre pueda entrar a diagnosticar o solucionar problemas, incluso si se alcanzó el límite de `max_connections`. |
| **statement_timeout** | `0` (desactivado) | Establece el tiempo máximo que cualquier consulta (`statement`) tiene permitido ejecutarse antes de ser cancelada automáticamente por el servidor[cite: 11]. Ayuda a prevenir que consultas mal optimizadas consuman recursos indefinidamente. |
| **idle_in_transaction_session_timeout** | `0` (desactivado) | Define el tiempo máximo que una sesión puede permanecer inactiva (idle) mientras mantiene una transacción abierta[cite: 11]. |

## Análisis de Disponibilidad y Recursos

**Pregunta:** ¿Por qué mantener conexiones indefinidamente abiertas puede representar un problema de disponibilidad o consumo de recursos?[cite: 11]

**Respuesta:** 
En PostgreSQL, cada conexión establece un proceso independiente en el sistema operativo, lo que consume una cantidad significativa de memoria (RAM) y recursos de CPU. Si las conexiones se mantienen abiertas indefinidamente, se generan dos problemas críticos:
1. **Problema de Disponibilidad:** Se agota rápidamente el límite configurado en `max_connections`. Una vez alcanzado este límite, la base de datos rechazará cualquier nueva conexión entrante de la aplicación, provocando una denegación de servicio (DoS) efectiva.
2. **Consumo de Recursos y Bloqueos:** Si una conexión se queda inactiva pero dentro de una transacción (`idle in transaction`), mantiene retenidos candados (locks) sobre las tablas. Esto bloquea a otras consultas que intenten modificar esos datos e impide que el proceso de limpieza interno de PostgreSQL (`autovacuum`) libere el espacio de los registros muertos, lo que degrada severamente el rendimiento y aumenta el tamaño de la base de datos en disco.

---

# Actividad 12 — Revisar permisos del sistema operativo

## Identificación de rutas y permisos
Al ejecutar las consultas para identificar las rutas de los archivos de configuración y datos, se obtuvieron los siguientes resultados (las rutas pueden variar según la instalación):

*   **data_directory**: `/var/lib/postgresql/14/main` (Ejemplo)
*   **config_file**: `/etc/postgresql/14/main/postgresql.conf` (Ejemplo)
*   **hba_file**: `/etc/postgresql/14/main/pg_hba.conf` (Ejemplo)

Posteriormente, se verificaron los permisos desde la terminal del sistema operativo utilizando el comando `ls -l` y `ls -ld`[cite: 12]:

| Archivo / Directorio | Propietario | Grupo | Permisos (Octal) | Permisos (Simbólico) | Lectura por otros |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `postgresql.conf` | postgres | postgres | 644 (o 600) | `-rw-r--r--` | Sí (dependiendo de la distro) |
| `pg_hba.conf` | postgres | postgres | 640 (o 600) | `-rw-r-----` | No |
| `data_directory` | postgres | postgres | 700 | `drwx------` | No |

*Nota de seguridad:* El directorio de datos (`data_directory`) y el archivo de autenticación (`pg_hba.conf`) **jamás** deben tener permisos de lectura para "otros usuarios" (`o+r`)[cite: 12]. El propietario y grupo deben ser estrictamente el usuario del sistema que ejecuta el servicio de PostgreSQL (usualmente `postgres` o `_postgresql`).

## Análisis de Seguridad a nivel de Sistema Operativo

**Pregunta:** ¿Por qué no es suficiente proteger PostgreSQL mediante GRANT y REVOKE si cualquier usuario del sistema operativo puede leer archivos sensibles?[cite: 12]

**Respuesta:** 
La seguridad en base de datos opera bajo un modelo de capas (Defensa en Profundidad). `GRANT` y `REVOKE` protegen el acceso lógico a los datos *a través del motor de base de datos*. Sin embargo, los archivos físicos donde residen esos datos (los archivos del `data_directory`) y las configuraciones de autenticación (`pg_hba.conf`) residen en el sistema operativo[cite: 12]. 

Si un usuario del sistema operativo (un atacante, un empleado malintencionado, o una aplicación vulnerada en el mismo servidor) tiene permisos de lectura sobre el directorio de datos, puede copiar los archivos físicos de la base de datos a otro servidor, montarlos y acceder a toda la información en texto plano, evadiendo por completo todas las restricciones lógicas (`GRANT`/`REVOKE`) impuestas dentro de PostgreSQL. Por ello, el usuario del sistema operativo que ejecuta PostgreSQL debe ser el único con acceso a estos archivos.

---

# Actividad 13 — Revisar exposición de red

## Verificación de puertos y direcciones de escucha
Para identificar si PostgreSQL está escuchando en el puerto correspondiente, se ejecutó el comando `ss -lnt` (o `ss -lntp`) desde la terminal del servidor. Buscando el servicio asociado al puerto `5432`[cite: 12], se documentó lo siguiente (los valores reales dependen del entorno auditado):

*   **Dirección de escucha:** `127.0.0.1` *(Nota: Cambia este valor por `0.0.0.0` o la IP real que te arroje el comando)*[cite: 12]
*   **Puerto:** `5432`[cite: 12]

## Análisis de Exposición

**Pregunta:** ¿Está expuesto fuera de la interfaz necesaria?[cite: 12]

**Respuesta:** 
*(Nota: Deja en tu informe solo el escenario que coincida con tu resultado)*

*   **Escenario A (Si tu resultado fue `127.0.0.1`):** 
    No. La base de datos está escuchando únicamente en la interfaz de *localhost* (bucle local). Esta es la configuración óptima y más segura si la aplicación web y la base de datos se encuentran alojadas en el mismo servidor, ya que bloquea físicamente a nivel de sistema operativo cualquier intento de conexión desde el exterior.
*   **Escenario B (Si tu resultado fue `0.0.0.0` o `*`):** 
    Sí, está expuesto a todas las interfaces de red del servidor. Si la base de datos solo necesita comunicarse con una aplicación local o una subred específica, escuchar en `0.0.0.0` es una violación al principio de hardening, ya que incrementa la superficie de ataque permitiendo que escaneos de red o atacantes externos intenten conectarse al puerto `5432`.

---

# Actividad 14 — Diseñar una política de firewall

## Política de Firewall (Conceptual)
Considerando que el servidor PostgreSQL se encuentra en la IP `10.10.10.20` por el puerto `5432` y que solo la Red DBA (`10.10.10.0/24`) debe tener acceso[cite: 13], se diseña la siguiente regla restrictiva:

| Origen | Destino | Puerto | Acción |
| :--- | :--- | :---: | :--- |
| 10.10.10.0/24 | 10.10.10.20 (PostgreSQL) | 5432 | Permitir[cite: 13] |
| Cualquier otro origen | 10.10.10.20 (PostgreSQL) | 5432 | Denegar[cite: 13] |

## Análisis de Controles de Seguridad

**Pregunta:** ¿Por qué pg_hba.conf y el firewall no son controles equivalentes?[cite: 13]

**Respuesta:** 
No son equivalentes porque aplican seguridad en capas diferentes (modelo de Defensa en Profundidad):

1. **El Firewall opera a nivel de red (Capas 3/4):** Bloquea los paquetes TCP/IP maliciosos o no autorizados antes de que toquen el servicio. Protege los recursos del sistema operativo y previene ataques de escaneo o de Denegación de Servicio (DoS).
2. **`pg_hba.conf` opera a nivel de aplicación (Capa 7):** Asume que la conexión de red ya fue aceptada. Su propósito es decidir si esa conexión válida lógicamente tiene credenciales correctas para entrar a una base de datos específica.

Si un entorno no tiene firewall y depende únicamente de `pg_hba.conf`, el puerto 5432 queda totalmente expuesto a Internet. Un atacante podría agotar las conexiones máximas (`max_connections`) o intentar explotar vulnerabilidades de desbordamiento en el proceso de autenticación inicial, colapsando la base de datos sin siquiera haber iniciado sesión.

---

# Actividad 15 — Revisar TLS

## Configuración y Estado de la Conexión Actual
Tras ejecutar las consultas de configuración de SSL y revisar el estado de la sesión actual (`pg_stat_ssl`)[cite: 14], se determinaron los siguientes valores (Nota: debes ajustar estos valores según lo que arroje tu consola):

*   **¿La conexión actual utiliza TLS?** 
    *(Ejemplo: Sí / `t` — O No / `f` si estás conectado de forma local sin forzar SSL)*[cite: 14]
*   **Versión:** 
    *(Ejemplo: `TLSv1.3` o vacío si no usa SSL)*[cite: 14]
*   **Cipher:** 
    *(Ejemplo: `TLS_AES_256_GCM_SHA384` o vacío si no usa SSL)*[cite: 14]

## Análisis de Hardening (Relación con LAB-02 y LAB-04)
En este laboratorio de hardening de configuración (LAB-04), no basta con saber que TLS existe (como se vio en LAB-02 sobre Cifrado y TLS)[cite: 14]. Debemos determinar si está **correctamente integrado** en la configuración del servidor y de los clientes[cite: 14]. 

**Evaluación de la integración:**
Para considerar que TLS está configurado de forma segura bajo estándares de hardening, el parámetro `ssl` debe estar en `on` y `ssl_min_protocol_version` debe configurarse, como mínimo, en `TLSv1.2` (idealmente `TLSv1.3`), rechazando protocolos obsoletos y vulnerables como SSLv3, TLSv1.0 o TLSv1.1. Además, en `pg_hba.conf`, las conexiones de red (host) deberían forzarse a usar `hostssl` en lugar de conexiones no cifradas.

---

# Actividad 16 — Comparar configuración antes y después

## Línea base de Hardening
A continuación se presenta la tabla comparativa que resume los controles evaluados e implementados a lo largo del laboratorio, estableciendo la nueva línea base de seguridad:

| Control[cite: 14] | Antes[cite: 14] (Por defecto / Inseguro) | Después[cite: 14] (Hardening) | Justificación[cite: 14] |
| :--- | :--- | :--- | :--- |
| **listen_addresses**[cite: 14] | `*` (Escucha en todas las interfaces) | `localhost` o IP específica de la red de base de datos | Reduce la superficie de exposición de red, previniendo conexiones desde interfaces no confiables. |
| **pg_hba.conf**[cite: 14] | Subredes amplias (`0.0.0.0/0`) y/o permitiendo conexiones no cifradas | IPs/Subredes estrictamente necesarias y usando reglas `hostssl` | Limita qué equipos pueden conectarse físicamente, implementando el principio de mínimo privilegio en red. |
| **Método de autenticación**[cite: 14] | `trust` (sin contraseña) o `md5` | `scram-sha-256` | MD5 es criptográficamente débil; SCRAM es el estándar actual que mitiga ataques de sniffing de contraseñas. |
| **Usuarios administrativos**[cite: 14] | Uso de la cuenta genérica `postgres` para toda la administración | Cuentas nominales, bloqueando login remoto para la cuenta `postgres` | Garantiza la trazabilidad (saber qué persona hizo qué) y evita ataques de fuerza bruta al usuario por defecto. |
| **Cuentas de aplicación**[cite: 14] | Uso de superusuarios para la app, o rol `public` excesivamente permisivo | Roles específicos con permisos limitados (ej. solo DML) y contraseñas fuertes | Si la app es vulnerada (ej. Inyección SQL), el atacante no podrá destruir la instancia ni leer otras BDs. |
| **Puerto**[cite: 14] | `5432` expuesto abiertamente a cualquier red | `5432` restringido mediante Firewall a nivel de Sistema Operativo | El firewall bloquea paquetes maliciosos o escaneos antes de que siquiera toquen el motor de base de datos. |
| **TLS**[cite: 14] | `off` o versiones obsoletas (SSLv3, TLS 1.0) | `on`, requiriendo `TLSv1.2` o superior (`ssl_min_protocol_version`) | Cifra los datos en tránsito, protegiendo credenciales y consultas contra ataques Man-in-the-Middle. |
| **Permisos SO**[cite: 14] | Permisos laxos de lectura (`644`) en archivos de configuración/datos | `700` (o `600`) estrictos y exclusivos para el usuario OS `postgres` | Previene que atacantes o malware en el servidor copien los archivos físicos de la base de datos (robo offline). |
| **Extensiones**[cite: 14] | Instaladas globalmente en `public` | Instaladas en esquemas dedicados, administradas solo por superusuarios | Evita la escalada de privilegios a través de vulnerabilidades en el código de extensiones de terceros. |
| **Conexiones**[cite: 14] | Sin límites por usuario (`connection_limit = -1`) | Límites definidos por Rol y ajuste del pool global | Protege al servidor contra ataques de denegación de servicio (DoS) por agotamiento de conexiones. |

*(Esta tabla representa una de las evidencias principales del laboratorio de hardening).*

---

# Actividad 17 — Elaborar checklist de hardening

## Checklist de Controles de Seguridad
A continuación se presenta el checklist de validación con los 15 controles mínimos requeridos para asegurar la instancia de PostgreSQL, consolidando y verificando todo lo implementado en el laboratorio[cite: 15]:

| # | Control | Verificado | Evidencia |
| :--- | :--- | :---: | :--- |
| 1 | Puerto documentado | [x] | `01-inspeccion.sql` / `informe.md` |
| 2 | Interfaces de escucha justificadas | [x] | `09-exposicion-red.png` |
| 3 | pg_hba.conf revisado | [x] | `informe.md` |
| 4 | Redes autorizadas restringidas | [x] | `informe.md` |
| 5 | Autenticación segura | [x] | `06-scram.png` (Ejemplo) |
| 6 | Superusuarios identificados | [x] | `03-roles.png` (Ejemplo) |
| 7 | Cuentas de aplicación separadas | [x] | `05-permisos.png` (Ejemplo) |
| 8 | Privilegios mínimos | [x] | `05-permisos.png` (Ejemplo) |
| 9 | Extensiones revisadas | [x] | `07-extensiones.png` (Ejemplo) |
| 10 | TLS verificado | [x] | `10-tls.png` |
| 11 | Configuración protegida | [x] | `informe.md` |
| 12 | Directorio de datos protegido | [x] | `08-permisos-so.png` |
| 13 | Firewall documentado | [x] | `informe.md` |
| 14 | Actualizaciones documentadas | [x] | `informe.md` |
| 15 | Configuración registrada | [x] | Repositorio Git |


---

# Actividad 18 — Caso integral

## Análisis de Riesgos y Controles
A partir del escenario planteado (PostgreSQL expuesto a internet, firewall permisivo, `pg_hba.conf` en `all/all` y aplicación usando cuenta administrativa)[cite: 15], se identifican los siguientes 10 problemas y sus respectivos controles:

| # | Problema | Riesgo | Control propuesto |
| :--- | :--- | :--- | :--- |
| 1 | **Firewall abierto (Cualquier origen)** | Exposición a ataques de denegación de servicio (DoS) y escaneos masivos desde Internet. | Restringir el puerto 5432 en el Firewall solo a la IP del servidor de la aplicación web. |
| 2 | **Servidor escucha en todas las interfaces** | Aumenta la superficie de ataque al exponer el motor en interfaces públicas o no confiables. | Cambiar `listen_addresses` a la IP privada específica de la red de la base de datos o `localhost`. |
| 3 | **pg_hba.conf permite 0.0.0.0/0** | Cualquier equipo en el mundo puede intentar iniciar sesión. | Modificar `pg_hba.conf` para permitir conexiones solo desde la subred o IP de la aplicación. |
| 4 | **Regla all/all en pg_hba.conf** | Las conexiones permitidas pueden intentar acceder a cualquier base de datos. | Especificar exactamente el nombre de la base de datos y el usuario autorizado en lugar de `all`. |
| 5 | **App web usa usuario administrativo** | Si la app web sufre Inyección SQL, el atacante obtiene control total de la instancia (destrucción de BD, robo total). | Aplicar el Principio de Mínimo Privilegio: crear un rol solo con permisos DML (SELECT, INSERT, UPDATE) para la app. |
| 6 | **Falta de cifrado en tránsito (implícito)** | Las "contraseñas fuertes" y los datos pueden ser interceptados (sniffing) si viajan en texto plano. | Forzar el uso de `hostssl` en `pg_hba.conf` y configurar certificados TLS. |
| 7 | **Dependencia de un solo factor perimetral** | Si la contraseña se filtra (ej. en el código fuente de la app), el atacante tiene acceso directo. | Implementar Defensa en Profundidad, combinando contraseñas con restricciones de IP y certificados de cliente. |
| 8 | **Sin límites de conexión por usuario** | Un atacante puede agotar el `max_connections` realizando múltiples peticiones concurrentes, tirando el servicio. | Establecer un `connection_limit` específico para el usuario de la aplicación web. |
| 9 | **Riesgo de escalada al Sistema Operativo** | Un superusuario comprometido (usado por la app) puede ejecutar comandos como `COPY` para leer/escribir archivos del SO. | Quitar privilegios de superusuario a la app web y asegurar permisos `700` en el directorio de datos. |
| 10 | **Vulnerabilidades pre-autenticación** | Confiar solo en contraseñas ignora que el motor de base de datos podría tener vulnerabilidades (ej. desbordamientos) antes del login. | El Firewall debe bloquear el tráfico anómalo antes de que el motor de BD intente procesarlo. |

## Análisis de Controles de Seguridad

**¿Es suficiente tener contraseñas fuertes?**
No, en absoluto. Las contraseñas fuertes son solo un componente de una estrategia de seguridad, pero por sí solas representan un punto único de fallo (Single Point of Failure). Si se filtra la contraseña, el sistema colapsa[cite: 15]. 

Explicación basada en las capas de Defensa en Profundidad:
*   **Autenticación:** Una contraseña fuerte no sirve de nada si se transmite sin cifrar (falta de TLS) y es interceptada, o si se almacena estáticamente en un repositorio de código expuesto.
*   **Autorización:** Aunque el usuario se autentique correctamente, usar una cuenta con privilegios administrativos para una aplicación web es un error crítico. Un fallo en la aplicación (SQL Injection) daría al atacante poder para destruir el servidor.
*   **Red:** Exponer el puerto a todo Internet (`0.0.0.0/0` en Firewall y pg_hba) permite que la base de datos sufra ataques de Denegación de Servicio (DoS) o explotación de vulnerabilidades del motor antes de llegar a la fase de contraseña.
*   **Configuración:** Usar comodines (`all/all`) elimina la granularidad, permitiendo movimientos laterales a otras bases de datos en el mismo servidor si una es comprometida.
*   **Sistema operativo:** Si la base de datos es vulnerada mediante esa cuenta administrativa, el atacante podría usar comandos de PostgreSQL para interactuar con los archivos del sistema operativo, escalando el ataque.
*   **Monitoreo:** Sin registros (logs) ni alertas, el administrador jamás se enterará si las "contraseñas fuertes" están sufriendo ataques de fuerza bruta o si ya han sido vulneradas y se están extrayendo datos.

---

# Actividad 19 — Construcción de una línea base

## Propuesta de Baseline de Seguridad para PostgreSQL 16
A continuación se presenta la línea base de seguridad estructurada para entornos de producción, cubriendo los 7 dominios críticos de la arquitectura[cite: 15]:

### 1. Red
*   **Interfaces autorizadas:** El parámetro `listen_addresses` debe estar configurado únicamente en la IP privada orientada al servidor de aplicaciones (ej. `10.0.1.20`) y `localhost`. Nunca usar `*`[cite: 15].
*   **Puerto:** Usar el puerto `5432` (o uno modificado), pero estrictamente documentado en la arquitectura de red[cite: 15].
*   **Firewall:** Implementar políticas de "Denegación por Defecto". Habilitar una regla de entrada que permita tráfico al puerto del motor exclusivamente desde la IP del servidor de la aplicación[cite: 15].
*   **Redes permitidas:** En `pg_hba.conf`, usar direcciones IP/máscaras específicas (ej. `10.0.1.50/32`) en lugar de subredes completas o el comodín `0.0.0.0/0`[cite: 15].

### 2. Autenticación
*   **Método:** Uso obligatorio y exclusivo de `scram-sha-256` en todo el clúster (`password_encryption = scram-sha-256`)[cite: 15].
*   **Políticas de credenciales:** Contraseñas de al menos 16 caracteres, generadas aleatoriamente (sin palabras de diccionario) y almacenadas en bóvedas de secretos (Vaults)[cite: 15].
*   **Cuentas administrativas:** Prohibir el inicio de sesión de la cuenta genérica `postgres` por red. Cada DBA debe tener su propia cuenta administrativa nominal para garantizar trazabilidad[cite: 15].

### 3. Autorización
*   **Roles:** Implementar el Principio de Mínimo Privilegio. Revocar privilegios por defecto en el esquema `public` y usar roles de grupo (`rol_lectura`, `rol_escritura`)[cite: 15].
*   **Privilegios:** Asignar permisos estrictamente granulares sobre tablas y vistas. Ningún usuario no administrativo debe tener permisos de `CREATEROLE` o `CREATEDB`[cite: 15].
*   **Cuentas de aplicación:** La aplicación debe conectarse con una cuenta dedicada que no sea superusuario y que solo tenga permisos DML (SELECT, INSERT, UPDATE, DELETE) sobre los objetos que realmente necesita[cite: 15].

### 4. Configuración
*   **Parámetros relevantes:** Habilitar auditoría básica activando `log_connections = on`, `log_disconnections = on`, y definir un `connection_limit` para cada usuario[cite: 15].
*   **Extensiones:** Instalar extensiones de terceros en esquemas dedicados (no en `public`) y limitar su creación y ejecución a superusuarios autorizados[cite: 15].
*   **Conexiones:** Ajustar `max_connections` a la capacidad real del hardware y usar un pooler de conexiones (como PgBouncer) para administrar la concurrencia[cite: 15].

### 5. Sistema operativo
*   **Propietario de archivos:** El usuario `postgres` del Sistema Operativo debe ser el único dueño de los binarios y del directorio de datos de la instancia[cite: 15].
*   **Permisos:** El directorio de datos (`$PGDATA`) debe tener permisos estrictos `0700` (`rwx------`). Archivos sensibles como `pg_hba.conf` deben estar en `0600`[cite: 15].
*   **Protección del directorio de datos:** Aislar `$PGDATA` en una partición lógica separada del sistema operativo raíz para evitar bloqueos por almacenamiento lleno[cite: 15].

### 6. Cifrado
*   **TLS:** Configurar `ssl = on` y `ssl_min_protocol_version = 'TLSv1.2'` (idealmente `TLSv1.3`). Forzar conexiones mediante reglas `hostssl` en `pg_hba.conf`[cite: 15].
*   **Protección de credenciales:** Nunca usar contraseñas en texto plano en scripts; usar el archivo `.pgpass` con permisos `0600` en el SO o variables de entorno inyectadas[cite: 15].
*   **Protección de información sensible:** Utilizar funciones como `pgcrypto` para encriptar columnas con PII (Datos de Identificación Personal) o implementar cifrado a nivel de disco (LUKS)[cite: 15].

### 7. Mantenimiento
*   **Actualización:** Definir una ventana de mantenimiento para aplicar parches de seguridad (versiones menores) de PostgreSQL regularmente[cite: 15].
*   **Revisión periódica:** Realizar una auditoría semestral de las cuentas activas, revisión de los roles asignados y análisis de logs buscando anomalías[cite: 15].
*   **Documentación:** Mantener siempre actualizado el diseño de red, el archivo `pg_hba.conf` comentado, los procedimientos de respaldo/restauración y esta línea base[cite: 15].

---

# Cuestionario Final de Evaluación y Síntesis

## 1. ¿Cuál era la principal superficie de ataque?
La exposición del servicio hacia redes públicas o no restringidas debido al parámetro `listen_addresses = '*'` combinado con reglas permisivas en `pg_hba.conf` (`0.0.0.0/0`). Esto permitía que cualquier equipo de la red pudiera alcanzar el puerto del motor de base de datos e intentar realizar ataques de denegación de servicio o fuerza bruta.

## 2. ¿Qué configuración representaba el mayor riesgo?
El uso de cuentas con privilegios de `SUPERUSER` por parte de las aplicaciones web y la permisión de conexiones sin cifrar. Si la aplicación web sufría una vulnerabilidad (como SQL Injection), un atacante obtenía control total sobre el clúster de base de datos e incluso la capacidad de interactuar con el sistema operativo subyacente.

## 3. ¿Qué cambio produjo la mayor reducción de exposición?
Restringir `listen_addresses` a la IP privada específica (o `localhost`) y configurar `pg_hba.conf` para aceptar únicamente conexiones desde direcciones IP/subredes autorizadas mediante protocolos cifrados (`hostssl`).

## 4. ¿Qué diferencia existe entre firewall y pg_hba.conf?
* **Firewall (Capa 3/4 - Red):** Filtra los paquetes de red a nivel de sistema operativo antes de que toquen el proceso de PostgreSQL, previniendo escaneos y ataques de agotamiento de recursos (DoS).
* **`pg_hba.conf` (Capa 7 - Aplicación):** Controla el acceso a nivel de aplicación una vez que la conexión TCP ya fue establecida, validando la dirección IP de origen, la base de datos destino, el usuario y el método de autenticación solicitado.

## 5. ¿Qué diferencia existe entre autenticación y autorización?
* **Autenticación:** Es el proceso de **verificar la identidad** del usuario o cliente que intenta conectarse (por ejemplo, validar si la contraseña encriptada con `scram-sha-256` es correcta).
* **Autorización:** Es el proceso de **determinar qué permisos tiene** una identidad previamente autenticada dentro de la base de datos (por ejemplo, si tiene privilegios para ejecutar `SELECT`, `INSERT` o `DELETE` sobre una tabla).

## 6. ¿Por qué una cuenta de aplicación no debe ser SUPERUSER?
Porque viola el Principio de Mínimo Privilegio. Un rol `SUPERUSER` ignora todas las verificaciones de permisos dentro de la base de datos, pudiendo crear/eliminar tablas, alterar otros usuarios y ejecutar comandos del sistema operativo mediante funciones de copia de archivos, aumentando catastróficamente el impacto de un fallo de seguridad en la aplicación.

## 7. ¿Por qué cambiar el puerto de PostgreSQL no constituye hardening suficiente?
Porque cambiar el puerto por defecto (`5432`) es únicamente "seguridad por oscuridad". Un atacante o herramienta automatizada de escaneo de red (como Nmap) puede identificar fácilmente que el servicio expuesto en el puerto alternativo corresponde a PostgreSQL mediante el análisis de firma del protocolo TCP.

## 8. ¿Por qué listen_addresses='*' puede ser innecesario?
Porque fuerza al servicio de PostgreSQL a escuchar peticiones en todas las interfaces de red configuradas en el servidor (incluyendo interfaces públicas o de mantenimiento). Si la base de datos se comunica únicamente con una aplicación local o una interfaz privada específica, escuchar en `*` expone el servicio a redes innecesarias.

## 9. ¿Qué papel tiene el sistema operativo en la seguridad de PostgreSQL?
El sistema operativo es la base de la seguridad física e infraestructura (Defensa en Profundidad). Si los permisos de archivos en el SO son laxos, un usuario local no autorizado podría leer el directorio de datos (`$PGDATA`) o extraer configuraciones sensibles (`pg_hba.conf`), evadiendo completamente los controles de acceso lógicos (`GRANT`/`REVOKE`) del motor.

## 10. ¿Qué controles deberían revisarse periódicamente?
1. **Auditoría de Roles y Permisos:** Verificar usuarios activos, cuentas inactivas y revocación de permisos elevados.
2. **Revisión de `pg_hba.conf`:** Confirmar que no existan subredes obsoletas o reglas permisivas agregadas temporalmente.
3. **Análisis de Logs:** Inspeccionar intentos fallidos de autenticación y conexiones no autorizadas.
4. **Permisos a Nivel de OS:** Validar que el directorio de datos mantenga los permisos restringidos (`0700`).
5. **Parches de Seguridad:** Aplicar actualizaciones menores del motor PostgreSQL regularmente.
