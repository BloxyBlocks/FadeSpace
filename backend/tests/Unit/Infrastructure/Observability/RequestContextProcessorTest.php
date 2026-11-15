<?php

declare(strict_types=1);

use App\Infrastructure\Observability\Logging\RequestContextProcessor;
use App\Infrastructure\Observability\RequestContext;
use Monolog\Level;
use Monolog\LogRecord;

it('añade request_id y tenant_id a cada registro', function (): void {
    $context = new RequestContext();
    $context->initialize('01JTESTREQUEST00000000000', '8a5b56e4-0e9d-4a1e-9f37-8f9f4f6b6a11');

    $record = new LogRecord(
        datetime: new DateTimeImmutable('2026-01-01T00:00:00Z'),
        channel: 'testing',
        level: Level::Info,
        message: 'Cita confirmada',
        extra: ['existing' => 'value'],
    );

    $processed = (new RequestContextProcessor($context))($record);

    expect($processed->extra)->toMatchArray([
        'existing' => 'value',
        'request_id' => '01JTESTREQUEST00000000000',
        'tenant_id' => '8a5b56e4-0e9d-4a1e-9f37-8f9f4f6b6a11',
    ]);
});

it('no inventa un tenant cuando la petición es pública', function (): void {
    $context = new RequestContext();
    $context->initialize('01JTESTREQUEST00000000000');

    $record = new LogRecord(
        datetime: new DateTimeImmutable('2026-01-01T00:00:00Z'),
        channel: 'testing',
        level: Level::Info,
        message: 'Health check',
    );

    $processed = (new RequestContextProcessor($context))($record);

    expect($processed->extra)->toHaveKey('request_id')
        ->not->toHaveKey('tenant_id');
});
