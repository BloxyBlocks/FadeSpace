<?php

declare(strict_types=1);

it('responde con el estado de las dependencias vitales', function (): void {
    $response = $this->getJson('/api/v1/health');

    $response->assertOk()
        ->assertJson([
            'status' => 'ok',
            'checks' => [
                'database' => 'up',
                'cache' => 'up',
            ],
        ])
        ->assertJsonStructure([
            'status',
            'version',
            'checks' => ['database', 'cache'],
            'checked_at',
        ]);

    expect($response->headers->get('X-Request-Id'))->toBeString()->not->toBeEmpty()
        ->and($response->headers->get('Cache-Control'))->toContain('no-store');
});
