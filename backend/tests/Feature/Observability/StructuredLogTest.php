<?php

declare(strict_types=1);

use App\Infrastructure\Observability\Logging\ConfigureStructuredLogging;
use App\Infrastructure\Observability\RequestContext;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Monolog\Formatter\JsonFormatter;

it('escribe logs JSON con request_id, tenant_id y teléfonos enmascarados', function (): void {
    $path = storage_path('logs/test-'.Str::random(8).'.log');

    config([
        'logging.channels.test_json' => [
            'driver' => 'single',
            'path' => $path,
            'level' => 'debug',
            'formatter' => JsonFormatter::class,
            'formatter_with' => ['appendNewline' => true],
            'tap' => [ConfigureStructuredLogging::class],
        ],
    ]);

    app(RequestContext::class)->initialize(
        'req-test-12345678',
        'tenant-12345678',
    );

    Log::channel('test_json')->info('Cliente +573001234567', [
        'phone' => '+573001234567',
    ]);

    $line = json_decode(trim((string) file_get_contents($path)), true, 512, JSON_THROW_ON_ERROR);
    $raw = (string) file_get_contents($path);

    expect($line['message'])->not->toContain('+573001234567')
        ->and($line['extra']['request_id'])->toBe('req-test-12345678')
        ->and($line['extra']['tenant_id'])->toBe('tenant-12345678')
        ->and($raw)->not->toContain('+573001234567');

    @unlink($path);
});
