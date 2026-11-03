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
