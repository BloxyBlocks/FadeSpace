<?php

declare(strict_types=1);

namespace App\Infrastructure\Observability\Logging;

use App\Infrastructure\Observability\RequestContext;
use Monolog\LogRecord;

/**
 * Añade `request_id` y `tenant_id` a cada registro de log (RNF-12).
 */
final readonly class RequestContextProcessor
{
    public function __construct(private RequestContext $context)
    {
    }

    public function __invoke(LogRecord $record): LogRecord
    {
        $extra = $record->extra;
        $requestId = $this->context->requestId();
        $tenantId = $this->context->tenantId();

        if ($requestId !== null) {
            $extra['request_id'] = $requestId;
        }

        if ($tenantId !== null) {
            $extra['tenant_id'] = $tenantId;
        }

        if ($extra === $record->extra) {
            return $record;
        }

        return new LogRecord(
            datetime: $record->datetime,
            channel: $record->channel,
            level: $record->level,
            message: $record->message,
            context: $record->context,
            extra: $extra,
        );
    }
}
