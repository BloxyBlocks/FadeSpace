<?php

declare(strict_types=1);

namespace App\Infrastructure\Observability\Logging;

use App\Infrastructure\Observability\RequestContext;
use Illuminate\Log\Logger;

/**
 * Se aplica con `tap` en los canales de log para activar JSON estructurado,
 * contexto de petición y enmascarado de datos personales.
 */
final readonly class ConfigureStructuredLogging
{
    public function __construct(private RequestContext $context)
    {
    }

    public function __invoke(Logger $logger): void
    {
        $monolog = $logger->getLogger();

        if (! method_exists($monolog, 'pushProcessor')) {
            return;
        }

        $monolog->pushProcessor(new RequestContextProcessor($this->context));
        $monolog->pushProcessor(new MaskSensitiveData());
    }
}
