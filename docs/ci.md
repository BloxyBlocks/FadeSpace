# Integración continua y protección de ramas

**Estado:** pipeline **ejecutado en verde** en `BloxyBlocks/FadeSpace` (run `44215818457`, 2026-11-17) y protección de
`main` **aplicada y verificada** por API. Ver `docs/status/E-01-report.md` §10.

## 1. Pipeline

Archivo: [`.github/workflows/ci.yml`](../.github/workflows/ci.yml). Se dispara en `push` y `pull_request` contra
`main`, con `concurrency` por referencia y `permissions: contents: read`.

| Job | Comando efectivo | Qué garantiza |
|---|---|---|
| `backend` | `composer lint` → `composer analyse` → `composer audit` → `composer test` | PSR-12 (Pint), Larastan nivel 8, dependencias sin vulnerabilidades conocidas, suite Pest (incluye pruebas de arquitectura). |
| `mobile` | `dart format --output=none --set-exit-if-changed .` → `flutter analyze` → `dart run melos exec --dir-exists=test -- flutter test` | Formato, `very_good_analysis` y pruebas de los 6 paquetes. |
| `infra` | `docker compose config --quiet` | El `compose.yaml` es válido y no tiene referencias rotas. |

Versiones fijadas: PHP **8.4** (extensiones `bcmath, intl, pdo_mysql, pdo_sqlite, sodium, sqlite3, zip`), Flutter
**3.50.0** (`stable`), Melos **8.10.1**, Composer 2.

Decisiones del pipeline:

- **Un solo job por tecnología**: el feedback llega en ~2-3 min por job en lugar de encadenar etapas.
- **`composer audit` antes de las pruebas**: una dependencia vulnerable invalida el *merge* aunque los tests pasen.
- **`--dir-exists=test`**: los paquetes sin carpeta `test/` no rompen `melos exec`.
- **Caché de Composer** por `composer.lock` y caché de Flutter gestionada por `subosito/flutter-action`.
- **Sin secretos**: ningún job necesita credenciales; las pruebas usan SQLite y `array` (ver `phpunit.xml`).

## 2. Equivalentes locales

```bash
# Backend
cd backend && composer quality

# Móvil (melos está en dev_dependencies del workspace)
cd mobile && dart format --output=none --set-exit-if-changed . \
  && flutter analyze \
  && dart run melos exec --dir-exists=test -- flutter test

# Infra
docker compose config --quiet
```

`composer quality` = `pint --test` + `phpstan analyse --level 8` + `composer security` (que ejecuta
`composer audit --locked`) + `php artisan test`.

## 3. Protección de ramas (`main`)

El *merge* a `main` debe exigir:

1. *Pull request* con descarte de aprobaciones obsoletas. **Aprobaciones requeridas: 0** mientras el repositorio tenga
   un solo *maintainer*: GitHub no permite aprobar el propio PR y `enforce_admins` impide saltarse la regla, así que
   exigir 1 aprobación bloquearía todos los *merges*. Se elevará a **1** (`required_approving_review_count`) al
   incorporar un segundo colaborador.
2. Todos los *status checks* del pipeline en verde, con la rama actualizada respecto a `main` (*strict*).
3. Conversaciones resueltas.
4. Prohibido el *force push* y el borrado de la rama.
5. Reglas aplicadas también a administradores.
6. Historial lineal (*squash* o *rebase*), sin *merge commits*.

### Aplicación

Con `gh` autenticado y el repositorio ya creado:

```powershell
pwsh ./scripts/apply-branch-protection.ps1 -Repository "<owner>/<repo>"
```

El script envía [`infra/github/branch-protection.json`](../infra/github/branch-protection.json) a
`PUT /repos/{owner}/{repo}/branches/main/protection` y luego verifica el resultado con
`GET .../branches/main/protection`. Requiere permisos de administrador del repositorio.

### Requisito previo

Los nombres de los *status checks* deben coincidir **exactamente** con los del workflow. Si se renombra un job,
hay que actualizar el JSON y volver a aplicar la protección; de lo contrario el *merge* queda bloqueado esperando
un check que nunca aparecerá.

## 4. Criterio de cierre de T-011

- [x] Workflow escrito con Pint, Larastan, Pest, `composer audit`, `flutter analyze` y `flutter test`.
- [x] Política de protección de ramas versionada (JSON + script).
- [x] Documentación de los checks y de su mantenimiento.
- [x] **T-100:** pipeline ejecutado en GitHub (verde) y protección real aplicada y verificada:
      3 checks obligatorios, *strict*, `enforce_admins`, sin *force push* ni borrado, historial lineal y
      conversaciones resueltas.
- [ ] Verificar el primer *pull request* real bajo la política (se hará en la primera tarea de F1).

## 5. Riesgos y mantenimiento

| Riesgo | Mitigación |
|---|---|
| Divergencia local↔CI (extensiones PHP, versión de Flutter) | Versiones fijadas; `composer.lock` y `pubspec.lock` versionados. |
| *Status checks* renombrados y *merge* bloqueado | El JSON es la fuente de verdad; el script reaplica y verifica. |
| CI lento por `flutter pub get` | Caché de `flutter-action`; Melos evita resolver por paquete. |
| Falso verde en móvil si un paquete no tiene `test/` | `melos exec` informa cuántos paquetes ejecutó; se revisa la salida. |
| Dependencias vulnerables | `composer audit` en cada *push*; alertas de Dependabot recomendadas al crear el repositorio. |
| Repositorio con un solo *maintainer* | Aprobaciones en 0 y `enforce_admins`; al añadir un segundo colaborador se sube a 1 y se reaplica el JSON. |
