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
