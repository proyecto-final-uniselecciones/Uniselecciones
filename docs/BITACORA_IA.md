# Bitácora de uso de IA

Registramos aquí los usos de IA que produjeron algo integrado al proyecto o que influyeron en una decisión, conforme a la carta de acuerdo que firmamos (`propuesta/Carta_Acuerdo_Uso_IA_UniSelecciones.docx`). Declarar el uso nunca resta puntos; ocultarlo sí es falta de integridad académica.

Los commits con código asistido o generado por IA lo indican al final del mensaje con "IA: asistido" o "IA: generado y revisado".

| Fecha e integrante | Herramienta | Propósito | Resultado | Verificación | Commit relacionado |
|---|---|---|---|---|---|
| 2026-11-09 · Luis Gustavo Martínez Muñoz | Claude (Anthropic) | Borrador del diseño de la base de datos distribuida: esquema relacional, fragmentación, asignación y replicación, procesamiento y transacciones | Nos sirvió de base para la propuesta. Lo adaptamos nosotros a baloncesto y a Aguascalientes | Lo contrastamos con el material de clase y con los Lineamientos | `fb797a8` |
| 2026-11-09 · Luis Gustavo Martínez Muñoz | Claude (Anthropic) | Borrador de la propuesta del equipo y de la carta de acuerdo de uso de IA | Los documentos que están en `propuesta/`, que revisamos y ajustamos | Revisión contra el apartado VI de los Lineamientos | `fb797a8` |
| 2026-11-21 · Pamila | Codex (OpenAI) | Base Flutter multiplataforma y pantalla inicial de acceso | Estructura de la app, UI adaptable y validaciones de acceso sin conexión real a la API | Ejecución manual reportada en Windows y navegador: formato de correo, mostrar/ocultar contraseña y aviso de API pendiente | `07f4a86` |
| 2026-11-21 · Pamila | Codex (OpenAI) | Implementación del issue #11: Compose para tres nodos PostgreSQL y MongoDB | Perfiles de nodos, credenciales por entorno, volúmenes persistentes y healthchecks | `docker compose config --quiet` correcto; `docker compose up -d` levantó los cuatro servicios y todos quedaron `healthy` | `32771ff` |
