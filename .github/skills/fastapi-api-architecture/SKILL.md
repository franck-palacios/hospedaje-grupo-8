---
name: fastapi-api-architecture
description: Diseña o mejora la estructura de una API REST con FastAPI, desde módulos y rutas hasta contratos, dependencias y persistencia. Úsala al definir la arquitectura de una API o planear la estructura de endpoints y componentes.
---

# Diseño de estructura para APIs FastAPI

Ayuda a diseñar una estructura clara, extensible y adecuada al tamaño del proyecto para una API con FastAPI. Esta skill se centra en la arquitectura y organización de la API; implementa código sólo si el usuario lo solicita.

## Flujo de trabajo

1. Inspecciona la estructura existente, el punto de entrada de FastAPI, las dependencias, la configuración, los modelos, las migraciones y las pruebas.
2. Lee `requerimientos.md` y `schema_hospedajes.sql` cuando estén presentes. Identifica actores, recursos, reglas y relaciones que afecten el diseño.
3. Conserva las convenciones del proyecto. No propongas una reorganización completa si basta con extender la estructura actual.
4. Antes de proponer módulos o endpoints, delimita el alcance de la funcionalidad y las responsabilidades de cada componente.
5. Presenta la estructura recomendada con rutas de archivos, responsabilidades y flujo de una solicitud. Expón supuestos y decisiones pendientes.
6. Si se pide implementación, realiza cambios pequeños y coherentes, y valida con las herramientas de pruebas existentes.

## Guía de diseño

- Organiza por funcionalidad de negocio cuando eso ayude a localizar conjuntamente rutas, esquemas, servicios y persistencia; evita fragmentar en exceso un MVP.
- Mantén los handlers HTTP enfocados en traducir solicitudes y respuestas. Sitúa reglas de negocio en servicios o casos de uso según el patrón existente.
- Separa esquemas de entrada y salida de los modelos de persistencia. Define contratos tipados, validación y códigos de respuesta adecuados.
- Centraliza preocupaciones compartidas —sesión de base de datos, autenticación, configuración y manejo de errores— usando mecanismos explícitos y existentes, como `Depends`.
- Diseña límites claros entre API, lógica de negocio, persistencia e integraciones externas. No introduzcas capas ceremoniales sin una necesidad concreta.
- Considera transacciones, consistencia y errores al estructurar operaciones que cambian varios registros o llaman a servicios externos.
- Para PostgreSQL, respeta `schema_hospedajes.sql`: enums, restricciones, claves y relaciones son parte del contrato de persistencia. Configura `app.usuario_id` dentro de la misma transacción cuando la auditoría lo requiera.
- Protege recursos con autenticación, autorización por rol y propiedad, y validación del estado del usuario. No confíes en datos de autorización enviados por el cliente.
- Propón pruebas en el nivel apropiado: unidad para reglas de negocio e integración para rutas y persistencia crítica.
- No inventes rutas, estados o políticas ausentes de los requisitos. Documenta las preguntas que el diseño necesita resolver.

## Formato de respuesta recomendado

Cuando sea útil, organiza la respuesta en:

1. **Estructura propuesta** — árbol breve de directorios y archivos.
2. **Responsabilidades** — propósito de cada módulo y sus dependencias.
3. **Flujo de una operación** — desde la ruta hasta persistencia y respuesta.
4. **Contratos y controles** — recursos, autorización, transacciones y errores relevantes.
5. **Decisiones pendientes** — preguntas que bloquean o condicionan el diseño.
6. **Validación** — pruebas o chequeos recomendados o ejecutados.

Mantén la propuesta proporcional al proyecto: prioriza claridad, consistencia y facilidad de prueba sobre patrones arquitectónicos sofisticados.
