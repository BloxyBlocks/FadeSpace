<?php

declare(strict_types=1);

namespace App\Domain\Shared;

use RuntimeException;

/**
 * Excepción base del dominio.
 *
 * El código es estable y forma parte del contrato de la API (por ejemplo
 * `SLOT_TAKEN`); el mensaje está en español y es apto para el usuario final.
 */
final class DomainException extends RuntimeException
{
    public function __construct(
        private readonly string $errorCode,
        string $message,
    ) {
        parent::__construct($message);
    }

    public function errorCode(): string
    {
        return $this->errorCode;
    }
}
