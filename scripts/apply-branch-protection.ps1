#Requires -Version 7.0
<#
.SYNOPSIS
    Aplica la protección de rama `main` en GitHub a partir de infra/github/branch-protection.json.

.DESCRIPTION
    Requiere GitHub CLI (`gh`) autenticado con permiso de administración del repositorio.
    Idempotente: PUT reemplaza la configuración previa y después se verifica con GET.

.PARAMETER Repository
    Repositorio en formato "<owner>/<repo>". Si se omite, se usa el remoto del directorio actual.

.PARAMETER Branch
    Rama a proteger. Por defecto: main.

.EXAMPLE
    pwsh ./scripts/apply-branch-protection.ps1 -Repository "bloxysoft/fadespace"
#>
[CmdletBinding()]
param(
    [string] $Repository,
    [string] $Branch = 'main'
)

$ErrorActionPreference = 'Stop'

function Assert-Command {
    param([string] $Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "No se encontró '$Name' en el PATH. Instala GitHub CLI: https://cli.github.com/"
    }
}

Assert-Command -Name 'gh'

$repoRoot = Split-Path -Parent $PSScriptRoot
$policyPath = Join-Path $repoRoot 'infra/github/branch-protection.json'

if (-not (Test-Path $policyPath)) {
    throw "No existe el archivo de política: $policyPath"
}

if ([string]::IsNullOrWhiteSpace($Repository)) {
    $Repository = (gh repo view --json nameWithOwner --jq '.nameWithOwner').Trim()
    if ([string]::IsNullOrWhiteSpace($Repository)) {
        throw 'No se pudo determinar el repositorio. Usa -Repository "<owner>/<repo>".'
    }
}

Write-Host "Repositorio:     $Repository"
Write-Host "Rama protegida:  $Branch"
Write-Host "Política:        $policyPath"

# Validación local del JSON antes de tocar la API.
$policy = Get-Content $policyPath -Raw | ConvertFrom-Json
$expectedChecks = $policy.required_status_checks.contexts
Write-Host "Status checks exigidos ($($expectedChecks.Count)):"
$expectedChecks | ForEach-Object { Write-Host "  - $_" }

Write-Host "`nAplicando protección..." -ForegroundColor Cyan
gh api --method PUT "repos/$Repository/branches/$Branch/protection" --input $policyPath | Out-Null

Write-Host "Verificando..." -ForegroundColor Cyan
$applied = gh api "repos/$Repository/branches/$Branch/protection" | ConvertFrom-Json

$appliedChecks = $applied.required_status_checks.contexts
$missing = $expectedChecks | Where-Object { $_ -notin $appliedChecks }

if ($missing) {
    Write-Warning "Checks no aplicados: $($missing -join ', ')"
    Write-Warning 'Revisa que los nombres coincidan con los jobs de .github/workflows/ci.yml.'
    exit 1
}

Write-Host "`nProtección aplicada correctamente:" -ForegroundColor Green
Write-Host ("  strict:                  {0}" -f $applied.required_status_checks.strict)
Write-Host ("  approvals requeridas:    {0}" -f $applied.required_pull_request_reviews.required_approving_review_count)
Write-Host ("  enforce admins:          {0}" -f $applied.enforce_admins.enabled)
Write-Host ("  force push permitido:    {0}" -f $applied.allow_force_pushes.enabled)
Write-Host ("  borrado permitido:       {0}" -f $applied.allow_deletions.enabled)
Write-Host ("  historial lineal:        {0}" -f $applied.required_linear_history.enabled)
Write-Host ("  conversaciones resueltas:{0}" -f $applied.required_conversation_resolution.enabled)
