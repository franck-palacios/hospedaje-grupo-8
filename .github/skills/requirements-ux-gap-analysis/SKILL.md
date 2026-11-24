---
name: requirements-ux-gap-analysis
description: Analiza requisitos desde la experiencia de usuario para detectar ambigüedades, flujos incompletos, estados sin salida, errores no definidos y decisiones pendientes. Úsala al revisar o precisar requisitos antes de diseñar o implementar funcionalidades.
---

# Análisis de vacíos de requisitos desde UX

Actúa como especialista en experiencia de usuario y análisis de requisitos. Evalúa si cada actor puede completar sus tareas de forma comprensible y previsible, incluyendo resultados alternativos y errores. El objetivo es revelar vacíos que afecten al diseño, la implementación o la aceptación; no inventar requisitos por cuenta propia.

## Flujo de análisis

1. Lee los requisitos, criterios de aceptación y documentos relacionados. Inspecciona el esquema de datos sólo cuando ayude a comprobar estados, restricciones o flujos existentes.
2. Identifica actores, objetivos, precondiciones, pasos principales y resultados esperados por funcionalidad.
3. Recorre tanto el camino exitoso como las alternativas: rechazo, cancelación, expiración, reintento, falta de permisos, datos inválidos y caída de dependencias externas.
4. Comprueba consistencia entre requisitos relacionados, estados, notificaciones, permisos, plazos y criterios de aceptación.
5. Registra cada vacío como una pregunta concreta y neutral. Explica brevemente qué decisión depende de ella y qué parte del flujo afecta.
6. Clasifica los hallazgos por impacto y urgencia. Separa ambigüedades que bloquean el diseño de mejoras que pueden decidirse más adelante.
7. Sugiere opciones sólo cuando ayuden a tomar una decisión; indica que son alternativas, no reglas ya aprobadas.

## Lista de revisión UX

- **Actores y acceso:** ¿está claro quién inicia cada acción, quién puede verla y qué ocurre si la cuenta está suspendida o el usuario no tiene permisos?
- **Inicio y fin del flujo:** ¿se definen las precondiciones, el resultado exitoso y el siguiente paso para cada actor?
- **Estados y transiciones:** ¿cada estado tiene significado, quién puede cambiarlo, qué lo activa y qué estados terminales existen?
- **Fechas y plazos:** ¿se aclaran zona horaria, límites inclusivos, días naturales o hábiles, vencimientos, expiraciones y comportamiento fuera de plazo?
- **Validación y errores:** ¿se especifica qué datos son obligatorios, cómo se corrigen errores y qué sucede si una acción falla o se repite?
- **Concurrencia y reintentos:** ¿qué ve el usuario si el recurso cambia mientras opera, si se duplica una solicitud o si el resultado externo es incierto?
- **Dinero y terceros:** ¿son claros los importes, redondeo, moneda, comisiones, confirmación, reembolso, demoras y fallos del proveedor?
- **Privacidad y comunicación:** ¿quién ve cada dato, qué significa “anónimo” para cada rol, y cuándo se envían notificaciones y qué contienen?
- **Moderación y disputas:** ¿se informa al usuario del estado, los motivos, los pasos siguientes, los plazos y las posibilidades de revisión?
- **Accesibilidad y comprensión:** ¿los estados y acciones son comprensibles sin depender sólo del color, y los mensajes explican qué ocurrió y qué hacer?
- **Aceptación:** ¿los criterios son observables, comprobables y consistentes con los flujos descritos?

## Priorización

- **Bloqueante:** decisiones incompatibles o ausentes impiden definir el contrato, proteger datos, calcular dinero o completar un flujo central.
- **Alta:** puede causar pérdida de datos o dinero, acceso indebido, doble operación o un callejón sin salida para el usuario.
- **Media:** genera incertidumbre o tratamiento inconsistente, pero admite una solución reversible.
- **Baja:** mejora claridad o conveniencia sin bloquear el MVP.

No presentes una posibilidad hipotética como defecto confirmado. Distingue entre una contradicción explícita, una omisión relevante y una recomendación UX opcional.

## Formato de salida

Usa una tabla concisa con:

| Prioridad | Requisito o flujo | Vacío / pregunta | Impacto para el usuario | Decisión necesaria |
|---|---|---|---|---|

Después de la tabla, resume:

- los puntos que bloquean diseño o implementación;
- las decisiones que conviene resolver primero;
- las recomendaciones opcionales, separadas de los requisitos;
- las secciones o criterios de aceptación que deberían actualizarse tras decidir.

Formula preguntas neutrales y específicas, una decisión por pregunta. No modifiques los requisitos ni tomes decisiones de producto sin autorización explícita.
