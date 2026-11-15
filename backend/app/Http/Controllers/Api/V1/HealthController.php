<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Infrastructure\Observability\Health\HealthChecker;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final readonly class HealthController
{
    public function __construct(private HealthChecker $healthChecker)
    {
    }

    public function __invoke(Request $request): JsonResponse
    {
        $report = $this->healthChecker->run();
        $status = $report['status'] === 'ok' ? 200 : 503;

        return response()
            ->json([
                'status' => $report['status'],
                'version' => (string) config('app.version'),
                'checks' => $report['checks'],
                'checked_at' => $report['checked_at'],
            ], $status)
            ->header('Cache-Control', 'no-store');
    }
}
