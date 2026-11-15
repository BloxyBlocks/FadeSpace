<?php

declare(strict_types=1);

arch('el dominio es PHP puro y no conoce frameworks')
    ->expect('App\Domain')
    ->not->toUse([
        'Illuminate',
        'Laravel',
        'Carbon',
        'App\Application',
        'App\Infrastructure',
        'App\Http',
    ]);

arch('la capa de aplicación no conoce HTTP ni Eloquent')
    ->expect('App\Application')
    ->not->toUse([
        'App\Http',
        'App\Livewire',
        'Illuminate\Http',
        'Illuminate\Routing',
        'Illuminate\Database\Eloquent',
        'Illuminate\Support\Facades',
    ]);

arch('Eloquent solo vive en infraestructura')
    ->expect([
        'App\Domain',
        'App\Application',
        'App\Http',
        'App\Providers',
    ])
    ->not->toUse('Illuminate\Database\Eloquent');

arch('las dependencias apuntan hacia adentro')
    ->expect('App\Domain')
    ->not->toUse('App\Infrastructure');
