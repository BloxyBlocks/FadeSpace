<?php

declare(strict_types=1);

namespace App\Infrastructure\Realtime;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * Evento sintético del *spike* T-008.
 *
 * `emitted_at` se captura justo antes de entregar el evento al broadcaster;
 * el cliente calcula `cliente_recibido - emitted_at` para estimar la latencia
 * de commit/emisión a cliente sin depender del reloj del servidor.
 */
final class RealtimeProbe implements ShouldBroadcastNow
{
    use Dispatchable;
    use InteractsWithSockets;

    public function __construct(
        public readonly string $probeId,
        public readonly int $sequence,
        public readonly string $emittedAt,
    ) {
    }

    /**
     * @return array<int, Channel>
     */
    public function broadcastOn(): array
    {
        return [new Channel('fadespace.probe')];
    }

    public function broadcastAs(): string
    {
        return 'realtime.probe';
    }

    /**
     * @return array{probe_id: string, sequence: int, emitted_at: string}
     */
    public function broadcastWith(): array
    {
        return [
            'probe_id' => $this->probeId,
            'sequence' => $this->sequence,
            'emitted_at' => $this->emittedAt,
        ];
    }
}
