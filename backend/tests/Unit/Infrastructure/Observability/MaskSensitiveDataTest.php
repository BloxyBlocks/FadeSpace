<?php

declare(strict_types=1);

use App\Infrastructure\Observability\Logging\MaskSensitiveData;
use Monolog\Level;
use Monolog\LogRecord;

/**
 * @param  array<mixed>  $context
 * @param  array<mixed>  $extra
 */
function recordWith(array $context, array $extra = [], string $message = 'Mensaje'): LogRecord
{
    return new LogRecord(
        datetime: new DateTimeImmutable('2026-01-01T00:00:00Z'),
        channel: 'testing',
        level: Level::Info,
        message: $message,
        context: $context,
        extra: $extra,
    );
}

it('enmascara claves sensibles y teléfonos en el mensaje', function (): void {
    $processor = new MaskSensitiveData();

    $record = recordWith(
        context: [
            'phone' => '+573001234567',
            'otp' => '123456',
            'password' => 'secreto',
            'customer' => ['phone_number' => '3001234567', 'name' => 'Ana'],
            'service' => 'Corte',
        ],
        extra: ['authorization' => 'Bearer token'],
        message: 'Cliente +573001234567 y 3001234567 agendaron',
    );

    $masked = $processor($record);

    expect($masked->message)->not->toContain('+573001234567')
        ->and($masked->message)->not->toContain('3001234567')
        ->and($masked->context['phone'])->toBe('[REDACTED]')
        ->and($masked->context['otp'])->toBe('[REDACTED]')
        ->and($masked->context['password'])->toBe('[REDACTED]')
        ->and($masked->context['customer'])->toBe([
            'phone_number' => '[REDACTED]',
            'name' => 'Ana',
        ])
        ->and($masked->context['service'])->toBe('Corte')
        ->and($masked->extra['authorization'])->toBe('[REDACTED]');
});

it('conserva los datos que no son personales', function (): void {
    $processor = new MaskSensitiveData();

    $masked = $processor(recordWith(
        context: ['amount' => '25000.00', 'scheduled_at' => '2026-01-01T10:00:00Z'],
        message: 'Cita confirmada',
    ));

    expect($masked->context)->toBe([
        'amount' => '25000.00',
        'scheduled_at' => '2026-01-01T10:00:00Z',
    ])->and($masked->message)->toBe('Cita confirmada');
});
