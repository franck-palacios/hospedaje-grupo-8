# Documento de Requisitos del MVP

## 1. Información general

### 1.1 Propósito

Desarrollar una aplicación web para publicar hospedajes, gestionar reservas, procesar pagos y recibir retroalimentación de los arrendantes.

### 1.2 Objetivo de negocio

Facilitar el ofrecimiento y la reserva de hospedajes mediante un proceso digital que incluya disponibilidad, pagos, cancelaciones, reembolsos y retroalimentación.

### 1.3 Actores del sistema

- **Publicador:** ofrece hospedajes y administra sus reservas.
- **Arrendante:** busca hospedajes, realiza reservas y deja retroalimentación.
- **Administrador:** supervisa publicaciones, usuarios, comentarios y disputas.

## 2. Alcance del MVP

### 2.1 Incluido

- Registro de publicadores y arrendantes.
- Inicio de sesión y recuperación de contraseña.
- Publicación y aprobación de hospedajes.
- Gestión de disponibilidad.
- Búsqueda y reserva de hospedajes.
- Pago mediante PayPal.
- Cancelación y reembolso.
- Retroalimentación pública o anónima.
- Respuesta del publicador a calificaciones.
- Moderación automática de comentarios.
- Administración de usuarios y publicaciones.
- Notificaciones internas y por correo electrónico.
- Resolución básica de disputas.

### 2.2 Excluido del MVP

- Aplicaciones móviles nativas.
- Gestión avanzada de comisiones.
- Integraciones externas adicionales a PayPal.
- Conversaciones privadas entre usuarios.
- Mensajería en tiempo real.
- Sistema avanzado de reputación.
- Gestión automatizada de impuestos.

## 3. Supuestos

- Un publicador representa a una persona o entidad que ofrece hospedajes.
- Un arrendante representa a una persona que reserva hospedajes.
- Dos días de anticipación corresponden a dos días naturales antes del inicio de la reserva.
- Las cancelaciones realizadas con menos de dos días no tienen reembolso.
- Las cancelaciones realizadas con al menos dos días tienen un reembolso del 70 %.
- El reembolso debe procesarse dentro de quince días hábiles.
- Los comentarios detectados como inapropiados quedan ocultos hasta revisión administrativa.
- Las notificaciones se enviarán dentro del sistema y por correo electrónico.
- Las cuentas administrativas no se crean mediante el registro público.
- Los usuarios pueden registrarse como publicador o arrendante.

## 4. Requerimientos funcionales

### 4.1 Autenticación y cuentas

#### RF-001 — Registro de usuario

**Actor:** Publicador y Arrendante  
**Descripción:** El usuario podrá registrarse seleccionando el rol de publicador o arrendante.  
**Criterios de aceptación:**

- El registro solicitará los datos obligatorios definidos por el sistema.
- El usuario deberá indicar el rol solicitado.
- El sistema no permitirá registros públicos con rol de administrador.
- El usuario recibirá confirmación de la creación exitosa de la cuenta.

**Prioridad:** Alta

#### RF-002 — Inicio de sesión

**Actor:** Publicador, Arrendante y Administrador  
**Descripción:** El usuario podrá acceder al sistema con sus credenciales.  
**Criterios de aceptación:**

- Las credenciales válidas permitirán el acceso.
- Las credenciales inválidas mostrarán un mensaje de error.
- Una cuenta suspendida no podrá iniciar sesión.
- El sistema llevará al usuario a la pantalla correspondiente a su rol.

**Prioridad:** Alta

#### RF-003 — Recuperación de contraseña

**Actor:** Publicador y Arrendante  
**Descripción:** El usuario podrá recuperar su contraseña mediante correo electrónico.  
**Criterios de aceptación:**

- El usuario podrá solicitar la recuperación indicando su correo registrado.
- El sistema enviará un enlace o código válido por tiempo limitado.
- El enlace o código sólo podrá utilizarse una vez.
- Al cambiar la contraseña, la anterior quedará invalidada.

**Prioridad:** Alta

### 4.2 Administración de usuarios

#### RF-004 — Gestión de usuarios y roles

**Actor:** Administrador  
**Descripción:** El administrador podrá consultar usuarios y gestionar sus roles o permisos.  
**Criterios de aceptación:**

- El administrador podrá visualizar la información disponible de cada usuario.
- Los cambios de rol serán registrados.
- El administrador no podrá modificar su propia cuenta de forma que quede bloqueado el acceso administrativo.

**Prioridad:** Alta

#### RF-005 — Suspensión de cuentas

**Actor:** Administrador  
**Descripción:** El administrador podrá suspender o reactivar cuentas.  
**Criterios de aceptación:**

- Una cuenta suspendida no podrá iniciar sesión ni realizar operaciones.
- La suspensión incluirá el motivo y la fecha.
- El administrador podrá reactivar la cuenta.
- La cuenta reactivada podrá volver a operar normalmente.

**Prioridad:** Alta

### 4.3 Publicación de hospedajes

#### RF-006 — Creación de publicación

**Actor:** Publicador  
**Descripción:** El publicador podrá crear una publicación de hospedaje con información básica, imágenes, ubicación, precio y reglas.  
**Criterios de aceptación:**

- El sistema exigirá completar los campos obligatorios.
- La publicación quedará inicialmente pendiente de aprobación.
- El publicador podrá visualizar el estado de la publicación.
- El publicador recibirá una notificación cuando la publicación sea aprobada o rechazada.

**Prioridad:** Alta

#### RF-007 — Edición y gestión de publicaciones

**Actor:** Publicador  
**Descripción:** El publicador podrá modificar, pausar o eliminar sus publicaciones.  
**Criterios de aceptación:**

- El publicador sólo podrá gestionar publicaciones propias.
- Los cambios pendientes no afectarán reservas ya confirmadas.
- Un anuncio pausado no podrá aparecer en nuevas búsquedas.
- Un anuncio eliminado no podrá recibir nuevas reservas.

**Prioridad:** Alta

#### RF-008 — Aprobación de publicaciones

**Actor:** Administrador  
**Descripción:** El administrador podrá aprobar o rechazar publicaciones pendientes.  
**Criterios de aceptación:**

- Las publicaciones nuevas permanecerán pendientes hasta una decisión.
- El rechazo requerirá registrar un motivo.
- La aprobación hará visible el anuncio en las búsquedas.
- El publicador recibirá una notificación sobre la decisión.

**Prioridad:** Alta

#### RF-009 — Gestión de disponibilidad

**Actor:** Publicador  
**Descripción:** El publicador podrá definir fechas disponibles y bloquear fechas manualmente.  
**Criterios de aceptación:**

- Las fechas bloqueadas no podrán ser reservadas.
- Las fechas reservadas no podrán volver a quedar disponibles.
- El sistema mostrará fechas disponibles, reservadas y bloqueadas.
- Las reservas existentes se mostrarán en el calendario del hospedaje.

**Prioridad:** Alta

### 4.4 Búsqueda y reservas

#### RF-010 — Búsqueda de hospedajes

**Actor:** Arrendante  
**Descripción:** El arrendante podrá buscar hospedajes por destino, fechas, cantidad de huéspedes y rango de precio.  
**Criterios de aceptación:**

- Sólo se mostrarán publicaciones aprobadas.
- Sólo se mostrarán hospedajes disponibles para las fechas solicitadas.
- Los resultados podrán combinar varios filtros.
- Cada resultado mostrará precio e información principal.

**Prioridad:** Alta

#### RF-011 — Solicitud de reserva

**Actor:** Arrendante  
**Descripción:** El arrendante podrá solicitar una reserva para un hospedaje disponible.  
**Criterios de aceptación:**

- El sistema verificará disponibilidad y cantidad máxima de huéspedes.
- La solicitud incluirá fechas y monto total.
- La reserva quedará en estado pendiente de confirmación.
- El publicador recibirá una notificación de la solicitud.

**Prioridad:** Alta

#### RF-012 — Confirmación de reserva

**Actor:** Publicador  
**Descripción:** El publicador podrá aceptar o rechazar una solicitud de reserva.  
**Criterios de aceptación:**

- Una reserva rechazada no podrá continuar al pago.
- Una reserva aceptada pasará al estado pendiente de pago.
- El arrendante recibirá una notificación con la decisión.
- Las fechas permanecerán disponibles si el pago no se completa dentro del plazo definido.

**Prioridad:** Alta

#### RF-013 — Pago de reserva

**Actor:** Arrendante  
**Descripción:** El arrendante podrá pagar una reserva aceptada mediante PayPal.  
**Criterios de aceptación:**

- El pago sólo estará disponible para reservas aceptadas.
- Un pago aprobado cambiará la reserva a confirmada.
- Un pago fallido no confirmará la reserva.
- El sistema conservará la referencia y el estado proporcionados por PayPal.
- El arrendante y el publicador recibirán una notificación del resultado.

**Prioridad:** Alta

#### RF-014 — Consulta de reservas

**Actor:** Publicador y Arrendante  
**Descripción:** Los usuarios podrán consultar sus reservas y sus estados.  
**Criterios de aceptación:**

- Cada usuario verá únicamente reservas asociadas a su cuenta.
- Se mostrará el estado actual de cada reserva.
- Se mostrará el historial básico de cambios de estado.
- Los estados incluirán solicitada, aceptada, rechazada, pendiente de pago, confirmada, cancelada y finalizada.

**Prioridad:** Alta

#### RF-015 — Cancelación de reserva

**Actor:** Publicador y Arrendante  
**Descripción:** Los dos roles podrán cancelar una reserva confirmada.  
**Criterios de aceptación:**

- La cancelación con al menos dos días de anticipación generará un reembolso del 70 %.
- La cancelación con menos de dos días no generará reembolso.
- Las fechas canceladas volverán a quedar disponibles.
- El arrendante y el publicador recibirán una notificación.
- La cancelación registrará actor, fecha y motivo.

**Prioridad:** Alta

#### RF-016 — Reembolso

**Actor:** Sistema  
**Descripción:** El sistema registrará y gestionará el reembolso correspondiente a una cancelación anticipada.  
**Criterios de aceptación:**

- El reembolso corresponde al 70 % del monto pagado.
- El estado del reembolso será visible para arrendante y publicador.
- El reembolso deberá procesarse dentro de un máximo de quince días hábiles.
- El arrendante recibirá una notificación cuando el reembolso sea aprobado y completado.

**Prioridad:** Alta

#### RF-017 — Finalización de reserva

**Actor:** Sistema o Administrador  
**Descripción:** La reserva pasará al estado finalizada después del periodo reservado.  
**Criterios de aceptación:**

- La reserva finalizada permitirá la creación de retroalimentación.
- El arrendante recibirá una notificación de finalización.
- El publicador recibirá una notificación de finalización.

**Prioridad:** Media

### 4.5 Retroalimentación

#### RF-018 — Registro de calificación

**Actor:** Arrendante  
**Descripción:** El arrendante podrá calificar y comentar un hospedaje después de finalizar la reserva.  
**Criterios de aceptación:**

- Sólo podrá calificar reservas propias.
- Sólo podrá calificar una reserva una vez.
- La retroalimentación podrá enviarse de manera identificada o anónima.
- La calificación deberá incluir puntuación y comentario.
- El publicador recibirá una notificación.

**Prioridad:** Media

#### RF-019 — Retroalimentación anónima

**Actor:** Sistema  
**Descripción:** La aplicación ocultará la identidad del arrendante cuando la retroalimentación sea anónima.  
**Criterios de aceptación:**

- El público no verá la identidad del arrendante.
- El publicador no verá la identidad del arrendante.
- El administrador podrá conservar acceso interno a la identidad.

**Prioridad:** Alta

#### RF-020 — Consulta de retroalimentación

**Actor:** Publicador y Arrendante  
**Descripción:** Los usuarios podrán consultar las calificaciones de un hospedaje.  
**Criterios de aceptación:**

- Se mostrará la puntuación agregada.
- Se mostrarán los comentarios aprobados.
- Los comentarios anónimos no mostrarán identidad.
- Los comentarios ocultos no serán visibles públicamente.

**Prioridad:** Media

#### RF-021 — Respuesta a calificaciones

**Actor:** Publicador  
**Descripción:** El publicador podrá responder varias veces a una calificación de su hospedaje.  
**Criterios de aceptación:**

- Sólo el publicador propietario podrá responder.
- Las respuestas aparecerán asociadas a la calificación original.
- Las respuestas podrán ser moderadas automáticamente.
- Las respuestas registrarán fecha y publicador.

**Prioridad:** Media

### 4.6 Moderación de comentarios

#### RF-022 — Moderación automática

**Actor:** Sistema  
**Descripción:** El sistema analizará automáticamente los comentarios para identificar contenido posiblemente inapropiado.  
**Criterios de aceptación:**

- El comentario detectado permanecerá oculto.
- El administrador podrá aprobarlo o rechazarlo.
- La ocultación generará una notificación interna y por correo electrónico.
- La decisión generará una notificación a las partes autorizadas.
- La moderación automática no constituye una decisión definitiva.

**Prioridad:** Alta

#### RF-023 — Revisión de comentarios

**Actor:** Administrador  
**Descripción:** El administrador podrá revisar comentarios ocultos y aprobarlos o rechazarlos.  
**Criterios de aceptación:**

- Un comentario aprobado será visible públicamente.
- Un comentario rechazado no será publicado.
- La decisión registrará administrador, fecha y resultado.
- Las partes relacionadas recibirán una notificación de la decisión.

**Prioridad:** Alta

### 4.7 Administración y disputas

#### RF-024 — Consulta de reservas y pagos

**Actor:** Administrador  
**Descripción:** El administrador podrá consultar reservas, pagos y reembolsos.  
**Criterios de aceptación:**

- El administrador podrá consultar registros de todos los usuarios y hospedajes.
- La consulta mostrará estado, fecha y referencias disponibles.
- La información administrativa tendrá acceso restringido.

**Prioridad:** Media

#### RF-025 — Resolución de disputas

**Actor:** Administrador  
**Descripción:** El administrador podrá registrar y resolver disputas relacionadas con reservas, pagos o retroalimentación.  
**Criterios de aceptación:**

- Cada disputa tendrá estado y responsable.
- El administrador podrá registrar la resolución y las notas.
- Las partes involucradas podrán consultar el resultado final.
- Los cambios serán registrados con fecha y responsable.

**Prioridad:** Alta

### 4.8 Notificaciones

#### RF-026 — Notificaciones internas y por correo

**Actor:** Sistema  
**Descripción:** El sistema enviará notificaciones internas y por correo electrónico ante cambios relevantes.  
**Criterios de aceptación:**

- Las notificaciones internas estarán disponibles dentro de la aplicación.
- Los eventos seleccionados también enviarán correo electrónico.
- El usuario podrá consultar sus notificaciones.
- Una notificación indicará evento, fecha y estado relevante.

**Prioridad:** Alta

Los eventos incluidos son:

- Solicitud de reserva.
- Aceptación o rechazo de reserva.
- Pago aprobado o fallido.
- Reserva cancelada.
- Reembolso aprobado o completado.
- Reserva finalizada.
- Nueva retroalimentación.
- Comentario oculto por moderación.
- Decisión de moderación.

## 5. Requerimientos no funcionales del MVP

### RNF-001 — Seguridad de cuentas

Las contraseñas deberán almacenarse mediante mecanismos seguros y no deberán mostrarse ni almacenarse en texto legible.

### RNF-002 — Acceso basado en roles

Cada operación deberá estar restringida al rol autorizado.

### RNF-003 — Seguridad de pagos

El sistema no almacenará datos sensibles de tarjetas. PayPal será la fuente de validación del pago.

### RNF-004 — Integridad de reservas

El sistema deberá impedir que dos reservas confirmadas utilicen simultáneamente las mismas fechas.

### RNF-005 — Privacidad

Los comentarios anónimos no deberán mostrar la identidad del arrendante al público ni al publicador.

### RNF-006 — Auditoría

El sistema conservará registros de decisiones administrativas, cambios de reserva, pagos y reembolsos.

### RNF-007 — Trazabilidad

Las reservas tendrán un historial identificable de solicitudes, cambios de estado y cancelaciones.

### RNF-008 — Moderación automática

La detección automática tendrá carácter preventivo. El sistema no deberá garantizar una clasificación perfecta y deberá permitir revisión humana.

### RNF-009 — Consistencia de notificaciones

Las notificaciones internas y por correo deberán reflejar el mismo estado del proceso.

### RNF-010 — Disponibilidad de información

Las operaciones críticas deberán mostrar mensajes claros cuando un servicio externo, como PayPal o el correo electrónico, no esté disponible.

## 6. Dependencias

- RF-008 depende de RF-006.
- RF-011 depende de RF-010.
- RF-012 depende de RF-011.
- RF-013 depende de RF-012.
- RF-014 depende de RF-011.
- RF-015 depende de RF-013 y RF-014.
- RF-016 depende de RF-015.
- RF-017 depende de RF-014.
- RF-018 depende de RF-017.
- RF-020 depende de RF-018.
- RF-021 depende de RF-020.
- RF-022 depende de RF-018 o RF-021.
- RF-023 depende de RF-022.
- RF-024 depende de RF-013 y RF-016.
- RF-025 depende de RF-014 y RF-024.

## 7. Ambigüedades pendientes

- Confirmar si el registro público requiere verificación de correo electrónico.
- Definir los campos obligatorios de registro.
- Confirmar si las cancelaciones tardías pueden realizarse antes del inicio de la estancia.
- Definir si los días naturales deberán utilizarse en todos los cálculos.
- Confirmar si PayPal se utilizará también para reembolsos.
- Definir el plazo límite para pagar una reserva aceptada.
- Definir los criterios utilizados por la moderación automática.
- Definir el plazo máximo de revisión de comentarios ocultos.
- Confirmar si existirá apelación para comentarios rechazados.
- Definir si el usuario podrá cancelar una reserva después de iniciada la estancia.
- Confirmar si los cargos o comisiones de PayPal reducen el reembolso.
- Confirmar si una reserva será visible después de estar finalizada.

## 8. Criterios generales de aceptación del MVP

El MVP será considerado funcional cuando:

1. Un publicador pueda registrar, publicar y gestionar un hospedaje.
2. Una publicación pueda ser aprobada o rechazada por el administrador.
3. Un arrendante pueda buscar hospedajes disponibles y realizar una reserva.
4. La reserva pueda pagarse mediante PayPal.
5. El publicador pueda aceptar o rechazar solicitudes.
6. Las reservas puedan cancelarse conforme a la política definida.
7. El reembolso del 70 % pueda registrarse para cancelaciones anticipadas.
8. El arrendante pueda dejar una calificación pública o anónima.
9. El publicador pueda responder varias veces a una calificación.
10. Los comentarios sospechosos puedan ocultarse y revisarse.
11. El administrador pueda gestionar usuarios, publicaciones y disputas.
12. Los usuarios puedan recibir notificaciones internas y por correo electrónico.
