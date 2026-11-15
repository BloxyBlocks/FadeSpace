<?php

declare(strict_types=1);

namespace App\Infrastructure\Observability\Logging;

use Monolog\LogRecord;
use Stringable;
use Throwable;

/**
 * Enmascara datos personales y secretos antes de escribir el log (C-14).
 */
final class MaskSensitiveData
{
    /**
     * Claves cuyo valor se reemplaza por completo.
     *
     * @var list<string>
     */
    private const SENSITIVE_KEYS = [
        'phone',
        'phone_number',
        'customer_phone',
        'telefono',
        'whatsapp',
        'otp',
        'otp_code',
        'password',
        'password_confirmation',
        'remember_token',
        'token',
        'access_token',
        'refresh_token',
        'authorization',
        'api_key',
        'secret',
        'display_token',
    ];

    private const PHONE_PATTERNS = [
        '/\+\d{1,3}[\s.\-]?(?:\d[\s.\-]?){5,12}\d/',
        '/\b3\d{9}\b/',
    ];

    public function __invoke(LogRecord $record): LogRecord
    {
        return new LogRecord(
            datetime: $record->datetime,
            channel: $record->channel,
            level: $record->level,
            message: $this->maskText($record->message),
            context: $this->maskArray($record->context),
            extra: $this->maskArray($record->extra),
        );
    }

    /**
     * @param  array<mixed>  $data
     * @return array<mixed>
     */
    private function maskArray(array $data, int $depth = 0): array
    {
        if ($depth > 8) {
            return ['[REDACTED]'];
        }

        $masked = [];

        foreach ($data as $key => $value) {
            if (is_string($key) && $this->isSensitiveKey($key)) {
                $masked[$key] = '[REDACTED]';

                continue;
            }

            $masked[$key] = $this->maskValue($value, $depth + 1);
        }

        return $masked;
    }

    private function maskValue(mixed $value, int $depth): mixed
    {
        if (is_string($value)) {
            return $this->maskText($value);
        }

        if (is_array($value)) {
            return $this->maskArray($value, $depth);
        }

        if ($value instanceof Throwable) {
            return [
                'class' => $value::class,
                'message' => $this->maskText($value->getMessage()),
                'code' => $value->getCode(),
                'file' => $value->getFile(),
                'line' => $value->getLine(),
                'trace' => $this->maskText($value->getTraceAsString()),
            ];
        }

        if ($value instanceof Stringable) {
            return $this->maskText((string) $value);
        }

        return $value;
    }

    private function maskText(string $text): string
    {
        foreach (self::PHONE_PATTERNS as $pattern) {
            $text = (string) preg_replace_callback(
                $pattern,
                static fn (array $matches): string => self::maskPhone($matches[0]),
                $text,
            );
        }

        return $text;
    }

    private function isSensitiveKey(string $key): bool
    {
        return in_array(strtolower($key), self::SENSITIVE_KEYS, true);
    }

    private static function maskPhone(string $phone): string
    {
        $length = strlen($phone);

        if ($length <= 5) {
            return str_repeat('*', $length);
        }

        return substr($phone, 0, 3).str_repeat('*', $length - 5).substr($phone, -2);
    }
}
