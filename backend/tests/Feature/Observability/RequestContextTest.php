<?php

declare(strict_types=1);

it('propaga un X-Request-Id válido enviado por el cliente', function (): void {
    $response = $this->withHeader('X-Request-Id', 'req-abc12345')
        ->getJson('/api/v1/health');

    $response->assertOk()
        ->assertHeader('X-Request-Id', 'req-abc12345');
});

it('genera un identificador cuando la cabecera es inválida', function (): void {
    $response = $this->withHeader('X-Request-Id', 'con espacios y <script>')
        ->getJson('/api/v1/health');

    $requestId = (string) $response->headers->get('X-Request-Id');

    $response->assertOk();
    expect($requestId)->not->toBe('con espacios y <script>')
        ->and($requestId)->toMatch('/^[A-Z0-9]{26}$/');
});

it('nunca toma el tenant_id de una cabecera del cliente', function (): void {
    $this->withHeader('X-Tenant-Id', 'tenant-atacante')
        ->getJson('/api/v1/health')
        ->assertOk();

    expect(app(App\Infrastructure\Observability\RequestContext::class)->tenantId())->toBeNull();
});
