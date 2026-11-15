# ADR-001 — Estrategia multi-tenant con esquema compartido y `TenantScope` global

- **Estado:** Aceptado
- **Fecha:** 2026-11-14
- **Decisores:** autor del proyecto (G2 pendiente de ratificación formal)
- **Requisitos:** RN-01, RN-02, C-03, RNF-18, D-02 (`02-plan.md` §3)
- **Tareas:** T-006 (pruebas de arquitectura), T-105…T-111 (F1), T-346 (G4)

## Contexto

FadeSpace atiende varias barberías (tenants) desde una sola aplicación Laravel. El modelo de datos de la
especificación (§7) ya define `tenant_id CHAR(36)` como clave foránea en **todas** las tablas de negocio, y
RN-01 establece que *ninguna consulta se ejecuta sin el scope de tenant*. La fuga de datos entre tenants es el
riesgo crítico del proyecto (`02-plan.md` §12) y el criterio de salida de F1 exige una suite de aislamiento en
verde.

Se evaluaron tres estrategias: base de datos por tenant, esquema por tenant y esquema compartido con columna
discriminante.

## Decisión

1. **Esquema compartido**: una sola base MySQL 8 con `tenant_id` (`CHAR(36)`, UUID v4) en todas las tablas de
   negocio, con clave foránea a `tenants.id`.
2. **Modelo Eloquent con `BelongsToTenant` + `TenantScope` global** (`Infrastructure/Persistence/Eloquent/Concerns`):
   el trait asigna `tenant_id` al crear y el scope global añade `where tenant_id = ?` a toda consulta.
3. **`TenantScope` es *fail-closed***: si no hay tenant resuelto en `TenantContext`, la consulta lanza
   `TenantNotResolved` en lugar de devolver filas de todos los tenants. El contexto solo se propaga desde
   `ResolveTenant` (middleware HTTP), jobs `TenantAwareJob` y comandos que lo reciben por parámetro explícito.
4. **Resolución del tenant** por el dominio de la petición (`tenants.domain`, RN-02) en HTTP y por claim del token
   en canales y jobs; nunca por un parámetro de *payload* que el cliente pueda cambiar.
5. **`withoutGlobalScope(TenantScope::class)` queda prohibido** salvo en *seeders*, comandos de mantenimiento y
   pruebas de aislamiento; cada uso debe justificarse en el código y en la revisión.
6. El `tenant_id` viaja también en logs (`RequestContext`), eventos de dominio y *broadcasts*; el canal de Reverb se
   prefija con el tenant (`tenant.{id}.*`).
7. La identidad (`Domain/Shared/TenantId`) es un *value object*; el dominio no conoce Eloquent ni el scope.

## Alternativas descartadas

| Alternativa | Por qué no |
|---|---|
| Base de datos por tenant | Costo operativo y de migraciones desproporcionado para barberías pequeñas; complica reportes y backups en F1. |
| Esquema por tenant | Multiplica migraciones y conexiones; `search_path` dinámico es frágil y difícil de probar con concurrencia. |
| Filtrado manual en cada repositorio | Un `where` olvidado es una fuga silenciosa; no es verificable de forma sistemática. |

## Consecuencias

**Positivas**

- Costo operativo mínimo, un solo *pipeline* de migraciones y respaldos simples (RNF-17).
- Aislamiento verificable de forma centralizada y automatizable.
- Escalado horizontal directo: la aplicación sigue *stateless* (RNF-18).

**Negativas y mitigaciones**

- *Ruido de vecino*: una consulta sin índice degrada a todos → índices compuestos obligatorios (RNF-14) y
  revisión de `EXPLAIN` en tareas de consulta pesada.
- Riesgo de fuga si alguien desactiva el scope → prueba de aislamiento dedicada en CI
  (`tests/Feature/Tenancy/IsolationTest`, F1) y prueba de arquitectura que impide que `Domain`/`Application`
  toquen Eloquent (T-006, ya en verde).
- Borrado de un tenant es una operación masiva → borrado lógico + anonimización, nunca `DELETE` en cascada desde
  la UI.

## Verificación

- `backend/tests/Architecture/LayersTest.php`: Eloquent solo en `Infrastructure`; `Domain` sin `Illuminate`.
- F1: suite `tests/Feature/Tenancy/` con dos tenants sembrados y aserciones cruzadas (lectura, escritura, jobs y
  canales de broadcast).
- F1: prueba negativa que exige `TenantNotResolved` cuando el contexto está vacío.

## Referencias

- `docs/01-spec.md` §6 (RN-01…RN-03), §7 modelo de datos.
- `docs/02-plan.md` §3 (D-02), §12 riesgos.
- `docs/00-constitucion.md` C-03, C-12.
