<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Infrastructure\Realtime\RealtimeProbe;
use Illuminate\Console\Command;
use Illuminate\Support\Str;
use Throwable;

/**
 * Emite eventos de prueba para medir la latencia Reverb → cliente (T-008).
 */
final class RealtimeProbeCommand extends Command
{
    protected $signature = 'realtime:probe
        {--count=20 : Número de eventos a emitir}
        {--interval=250 : Milisegundos entre eventos}';

    protected $description = 'Emite eventos sintéticos por Reverb para medir latencia extremo a extremo.';

    public function handle(): int
    {
        $count = max(1, (int) $this->option('count'));
        $interval = max(0, (int) $this->option('interval'));
        $probeId = (string) Str::ulid();

        $this->info("Probe {$probeId}: {$count} eventos cada {$interval} ms");

        for ($sequence = 1; $sequence <= $count; $sequence++) {
            $emittedAt = now()->utc()->format('Y-m-d\TH:i:s.u\Z');

            try {
                broadcast(new RealtimeProbe($probeId, $sequence, $emittedAt));
            } catch (Throwable $exception) {
                $this->error('No se pudo emitir: '.$exception->getMessage());

                return self::FAILURE;
            }

            $this->line(json_encode([
                'probe_id' => $probeId,
                'sequence' => $sequence,
                'emitted_at' => $emittedAt,
            ], JSON_THROW_ON_ERROR));

            if ($sequence < $count && $interval > 0) {
                usleep($interval * 1000);
            }
        }

        $this->info('Probe finalizado.');

        return self::SUCCESS;
    }
}
