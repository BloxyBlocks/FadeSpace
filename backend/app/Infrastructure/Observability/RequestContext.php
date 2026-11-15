<?php

declare(strict_types=1);

namespace App\Infrastructure\Observability;

/**
 * Contexto de observabilidad de la petición o job actual.
 *
 * `request_id` acompaña todas las líneas de log y la cabecera `X-Request-Id`.
 * `tenant_id` solo se asigna cuando el resolver de tenancy lo determina; nunca
 * se toma de datos enviados por el cliente (C-03).
 */
final class RequestContext
{
    private ?string $requestId = null;

    private ?string $tenantId = null;

    public function initialize(string $requestId, ?string $tenantId = null): void
    {
        $this->requestId = $requestId;
        $this->tenantId = $tenantId;
    }

    public function requestId(): ?string
    {
        return $this->requestId;
    }

    public function tenantId(): ?string
    {
        return $this->tenantId;
    }

    public function assignTenant(?string $tenantId): void
    {
        $this->tenantId = $tenantId;
    }

    public function isInitialized(): bool
    {
        return $this->requestId !== null;
    }

    /**
     * @return array{request_id: string|null, tenant_id: string|null}
     */
    public function toArray(): array
    {
        return [
            'request_id' => $this->requestId,
            'tenant_id' => $this->tenantId,
        ];
    }

    public function reset(): void
    {
        $this->requestId = null;
        $this->tenantId = null;
    }
}
