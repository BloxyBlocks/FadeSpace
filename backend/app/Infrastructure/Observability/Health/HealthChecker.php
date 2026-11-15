<?php

declare(strict_types=1);

namespace App\Infrastructure\Observability\Health;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Throwable;

/**
 * Comprueba las dependencias vitales sin exponer detalles internos.
 */
final class HealthChecker
{
    /**
     * @return array{status: string, checks: array<string, string>, checked_at: string}
     */
    public function run(): array
    {
        $checks = [
            'database' => $this->checkDatabase(),
            'cache' => $this->checkCache(),
        ];

        $healthy = ! in_array('down', $checks, true);

        return [
            'status' => $healthy ? 'ok' : 'degraded',
            'checks' => $checks,
            'checked_at' => now()->toIso8601ZuluString(),
        ];
    }

    private function checkDatabase(): string
    {
        try {
            DB::connection()->getPdo();
            DB::select('select 1');

            return 'up';
        } catch (Throwable) {
            return 'down';
        }
    }

    private function checkCache(): string
    {
        try {
            $key = 'health:'.Str::random(12);
            $value = Str::random(8);

            Cache::put($key, $value, 5);
            $stored = Cache::get($key);
            Cache::forget($key);

            return $stored === $value ? 'up' : 'down';
        } catch (Throwable) {
            return 'down';
        }
    }
}
