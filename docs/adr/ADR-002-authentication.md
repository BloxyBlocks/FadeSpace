# ADR-002 — Autenticación con Sanctum: personal, cliente Zero-Login y Pantalla de TV

- **Estado:** Aceptado
- **Fecha:** 2026-11-14
- **Requisitos:** C-11, C-12, RN-22…RN-25, RN-29, RF-10, RF-13, RF-27, RNF-19
- **Tareas:** T-120…T-122 (staff), T-137…T-138 (OTP), T-143 (mi cita), T-204 (canales), T-346 (G4)

## Contexto

Conviven cuatro identidades distintas:

1. **Administrador** (dashboard Livewire, navegador de escritorio).
2. **Barbero** (app Flutter móvil, sesión persistente en un dispositivo compartido de la barbería).
3. **Cliente** (PWA, *Zero-Login*: solo nombre y celular, verificado con OTP).
4. **Pantalla de TV** (kiosco de solo lectura, sin teclado ni capacidad de iniciar sesión).

La especificación prohíbe contraseñas para el cliente (C-11), exige tokens revocables para la TV (RN-29) y liga el
token al tenant (`02-plan.md` §8). Además el cliente recurrente debe poder reservar sin OTP durante 30 días
(RN-24).

## Decisión

| Identidad | Mecanismo | Almacenamiento del token | Vigencia |
|---|---|---|---|
| Administrador / personal web | Sesión de Laravel + guard `web`, contraseña con `bcrypt` y `RateLimiter` | Cookie de sesión `HttpOnly`, `Secure`, `SameSite=Lax` | Sesión con expiración deslizante |
| Barbero (app Flutter) | Sanctum *personal access token* con *ability* `staff` | Almacenamiento seguro del dispositivo (`flutter_secure_storage`), nunca preferencias en claro | 90 días, revocable por dispositivo |
| Cliente (PWA) | Sanctum *token* con *ability* `customer:booking`, creado solo tras verificar OTP | Cookie `HttpOnly` de primera parte en web; almacenamiento seguro en la app móvil | 30 días (RN-24) |
| Pantalla de TV | *display token* aleatorio de 40+ caracteres, guardado como **hash** en `display_devices` | Configuración del kiosco | Sin expiración; revocable por el administrador |

Reglas transversales:

1. **Tenant en el token**: cada token se emite con el `tenant_id` resuelto por dominio. Si el dominio de la petición
   no coincide con el del token → `403 TENANT_MISMATCH`, sin filtrar datos.
2. **Habilidad mínima**: `customer:booking` solo permite leer y mutar las citas del `customer_id` del token
   (RN-24). No hay endpoints públicos con capacidad de administración.
3. **Revocación**: `DELETE /auth/devices/{id}` invalida el token del dispositivo; el *display token* se revoca en
   `display_devices.revoked_at`. Toda revocación se audita.
4. **OTP**: 6 dígitos, hash en Redis con TTL 300 s, máximo 5 intentos por código y límites de envío de RN-22/RN-23
   aplicados con `RateLimiter` por teléfono, IP y tenant.
5. **CSRF**: las rutas de personal y cliente en navegador usan el flujo SPA de Sanctum con cookie de sesión y
   `XSRF-TOKEN`; las rutas autenticadas por token de dispositivo quedan exentas de CSRF y dependen de `Authorization`.
6. **Contraseñas**: mínimo 12 caracteres, `bcrypt` con coste 12, sin preguntas de seguridad ni recuperación por
   correo en F1 (el administrador restablece desde el dashboard).
7. **Secretos y rotación**: `APP_KEY` y credenciales en variables de entorno; la rotación se documenta en el
   *runbook* (T-345).

## Alternativas descartadas

| Alternativa | Por qué no |
|---|---|
| JWT propios | Revocación inmediata difícil; se necesitaría lista negra en Redis, que es exactamente lo que Sanctum evita. |
| Sesiones para la app móvil | Requiere cookies en un cliente nativo y complica el flujo *offline*/reintentos idempotentes. |
| Contraseña + OTP para el cliente | Contradice C-11 (*Zero-Login*) y añade fricción medida en RNF-06. |
| *Display token* en `localStorage` del navegador | La TV no debe tener sesión navegable ni token expuesto a XSS; el token se inyecta como encabezado desde la configuración del kiosco. |
| OAuth social (Google/Apple) | No resuelve el caso de barberías con personal sin cuentas corporativas y agrega dependencia externa. |

## Consecuencias

**Positivas**

- Un solo mecanismo (Sanctum) para móvil, web y TV, con habilidades y revocación por dispositivo.
- El cliente nunca crea cuenta ni contraseña: menos fricción y menos datos personales almacenados (C-12).
- Los canales de Reverb reutilizan el mismo token (T-204), sin un segundo sistema de identidad.

**Negativas y mitigaciones**

- Cookies `HttpOnly` en la PWA obligan a que el frontend comparta dominio con la API → `ResolveTenant` por dominio
  y sin llamadas cross-site en producción (mitiga CSRF y CORS a la vez).
- Tokens de 30/90 días son un riesgo si el dispositivo se pierde → revocación por dispositivo, rotación al
  iniciar sesión y auditoría de accesos.
- El *display token* es un secreto de larga vida → hash en base de datos, solo lectura, revocación inmediata y
  rotación periódica recomendada en el *runbook*.

## Verificación

- F1 `tests/Feature/Auth/`: login de personal, token ligado a tenant, `403` por dominio distinto, expiración y
  revocación de dispositivo.
- F1 `tests/Feature/Auth/OtpTest.php`: límites de RN-22/RN-23, hash en Redis, un solo uso, `OTP_RATE_LIMITED`.
- F2 `tests/Feature/Realtime/ChannelAuthorizationTest.php`: TV de solo lectura, cliente limitado a sus citas.
- Prueba de arquitectura: `Http` no contiene reglas de negocio de autorización; la decisión vive en `Application`.

## Referencias

- `docs/01-spec.md` §6 (RN-22…RN-25, RN-29), RF-10, RF-11, RF-13.
- `docs/02-plan.md` §8 (seguridad), §7 rutas.
- `docs/00-constitucion.md` C-11, C-12.
