<?php

declare(strict_types=1);

use App\Domain\Shared\DomainException;

it('expone un código estable y un mensaje en español', function (): void {
    $exception = new DomainException('SLOT_TAKEN', 'La franja ya fue tomada.');

    expect($exception->errorCode())->toBe('SLOT_TAKEN')
        ->and($exception->getMessage())->toBe('La franja ya fue tomada.');
});
