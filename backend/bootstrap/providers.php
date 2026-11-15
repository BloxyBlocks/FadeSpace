<?php

declare(strict_types=1);

use App\Infrastructure\Observability\ObservabilityServiceProvider;
use App\Infrastructure\Persistence\Eloquent\EloquentServiceProvider;
use App\Providers\AppServiceProvider;

return [
    AppServiceProvider::class,
    ObservabilityServiceProvider::class,
    EloquentServiceProvider::class,
];
