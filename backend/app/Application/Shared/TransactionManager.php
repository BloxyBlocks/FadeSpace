<?php

declare(strict_types=1);

namespace App\Application\Shared;

use Closure;

/**
 * Puerto de transacción para los casos de uso.
 *
 * La implementación vive en infraestructura (Laravel/MySQL). La capa de
 * aplicación solo conoce este contrato, nunca `DB` ni Eloquent.
 */
interface TransactionManager
{
    /**
     * Ejecuta la operación dentro de una transacción atómica.
     *
     * @template T
     *
     * @param  Closure(): T  $operation
     * @return T
     */
    public function transactional(Closure $operation): mixed;
}
