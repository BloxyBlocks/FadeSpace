<?php

declare(strict_types=1);

namespace App\Infrastructure\Observability;

use Illuminate\Support\ServiceProvider;

final class ObservabilityServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->scoped(RequestContext::class);
    }
}
