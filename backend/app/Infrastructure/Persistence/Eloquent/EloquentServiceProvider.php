<?php

declare(strict_types=1);

namespace App\Infrastructure\Persistence\Eloquent;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\ServiceProvider;

final class EloquentServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        Model::preventLazyLoading(! $this->app->isProduction());
    }
}
