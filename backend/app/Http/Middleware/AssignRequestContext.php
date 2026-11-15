<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use App\Infrastructure\Observability\RequestContext;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\Response;

/**
 * Inicializa el contexto de observabilidad y propaga `X-Request-Id`.
 *
 * El `tenant_id` solo se toma de un atributo resuelto por el servidor
 * (p. ej. `ResolveTenant` en F1); nunca de una cabecera del cliente (C-03).
 */
final readonly class AssignRequestContext
{
    private const REQUEST_ID_PATTERN = '/^[A-Za-z0-9][A-Za-z0-9._:-]{7,63}$/';

    public function __construct(private RequestContext $context)
    {
    }

    public function handle(Request $request, Closure $next): Response
    {
        $requestId = $this->resolveRequestId($request);
        $tenantId = $request->attributes->get('tenant_id');

        $this->context->initialize(
            $requestId,
            is_string($tenantId) ? $tenantId : null,
        );

        $request->attributes->set('request_id', $requestId);

        $response = $next($request);
        $response->headers->set('X-Request-Id', $requestId);

        return $response;
    }

    private function resolveRequestId(Request $request): string
    {
        $candidate = $request->header('X-Request-Id');

        if (is_string($candidate) && preg_match(self::REQUEST_ID_PATTERN, $candidate) === 1) {
            return $candidate;
        }

        return (string) Str::ulid();
    }
}
