using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using SunDaySchools.API.Json;
using SunDaySchools.BLL.Exceptions;
using System;
using System.Net;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;

namespace SunDaySchools.API.Middlewares
{
    public class GlobalExceptionMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<GlobalExceptionMiddleware> _logger;
        private readonly IHostEnvironment _env;
        private readonly IConfiguration _configuration;

        private static readonly JsonSerializerOptions _jsonOptions = ApiJsonSerializerOptions.Create();

        public GlobalExceptionMiddleware(
            RequestDelegate next,
            ILogger<GlobalExceptionMiddleware> logger,
            IHostEnvironment env,
            IConfiguration configuration)
        {
            _next = next;
            _logger = logger;
            _env = env;
            _configuration = configuration;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            try
            {
                await _next(context);
            }
            catch (Exception ex)
            {
                await HandleExceptionAsync(context, ex);
            }
        }

        private async Task HandleExceptionAsync(HttpContext context, Exception exception)
        {
            LogExceptionChain(exception, context);

            if (context.Response.HasStarted)
            {
                _logger.LogWarning("Response already started, cannot write error response.");
                return;
            }

            context.Response.ContentType = "application/json; charset=utf-8";

            var (statusCode, errorCode, message) = MapException(exception);

            context.Response.StatusCode = statusCode;

            var showDevelopmentDetails = ShouldExposeDetails();

            var response = new ApiErrorResponse
            {
                Success = false,
                ErrorCode = errorCode,
                Message = showDevelopmentDetails && exception is not ValidationException
                    ? BuildDevelopmentErrorMessage(exception)
                    : message,
                ExceptionType = showDevelopmentDetails ? exception.GetType().FullName : null,
                StackTrace = showDevelopmentDetails ? exception.StackTrace : null,
                InnerException = showDevelopmentDetails ? exception.InnerException?.Message : null
            };

            if (exception is ValidationException validationException)
            {
                response.Errors = validationException.Errors;
                if (validationException.Errors.Count > 0)
                {
                    var first = validationException.Errors.First();
                    response.Message = $"{first.Key}: {string.Join("; ", first.Value)}";
                    if (validationException.Errors.Count > 1)
                        response.Message += $" (+{validationException.Errors.Count - 1} more)";
                }
            }

            if (exception is PhoneNotVerifiedException phoneEx)
            {
                var payload = new
                {
                    success = false,
                    errorCode = "PHONE_NOT_VERIFIED",
                    message = phoneEx.Message,
                    requiresPhoneVerification = true,
                    phoneNumber = phoneEx.PhoneNumber
                };
                var jsonPhone = JsonSerializer.Serialize(payload, _jsonOptions);
                await context.Response.WriteAsync(jsonPhone);
                return;
            }

            if (exception is OtpRateLimitException rateEx)
            {
                var payload = new
                {
                    success = false,
                    errorCode = "OTP_RATE_LIMIT",
                    message = rateEx.Message,
                    retryAfterSeconds = rateEx.RetryAfterSeconds
                };
                var jsonRate = JsonSerializer.Serialize(payload, _jsonOptions);
                await context.Response.WriteAsync(jsonRate);
                return;
            }

            var json = JsonSerializer.Serialize(response, _jsonOptions);
            await context.Response.WriteAsync(json);
        }

        private bool ShouldExposeDetails() =>
            _env.IsDevelopment()
            || _configuration.GetValue<bool>("DetailedErrors")
            || string.Equals(
                Environment.GetEnvironmentVariable("SUN_DAYSCHOOLS_DETAILED_ERRORS"),
                "true",
                StringComparison.OrdinalIgnoreCase);

        private void LogExceptionChain(Exception exception, HttpContext context)
        {
            var depth = 0;
            for (var ex = exception; ex != null; ex = ex.InnerException, depth++)
            {
                _logger.LogError(
                    ex,
                    "Unhandled exception (depth={Depth}). Type={ExceptionType}, Message={Message}, Method={Method}, Path={Path}, TraceId={TraceId}",
                    depth,
                    ex.GetType().FullName,
                    ex.Message,
                    context.Request.Method,
                    context.Request.Path,
                    context.TraceIdentifier);

                if (!string.IsNullOrWhiteSpace(ex.StackTrace))
                {
                    _logger.LogError(
                        "StackTrace depth={Depth}: {StackTrace}",
                        depth,
                        ex.StackTrace);
                }
            }
        }

        private static string BuildDevelopmentErrorMessage(Exception exception)
        {
            var sb = new StringBuilder();
            var depth = 0;
            for (var ex = exception; ex != null; ex = ex.InnerException, depth++)
            {
                if (depth > 0)
                    sb.AppendLine($"--- Inner exception #{depth} ---");

                sb.AppendLine($"[{ex.GetType().Name}] {ex.Message}");
                if (!string.IsNullOrWhiteSpace(ex.StackTrace))
                    sb.AppendLine(ex.StackTrace);
            }

            return sb.ToString();
        }

        private static (int StatusCode, string ErrorCode, string Message) MapException(Exception exception)
        {
            var root = exception;
            while (root.InnerException != null)
                root = root.InnerException;

            return exception switch
            {
                ValidationException => ((int)HttpStatusCode.BadRequest, "VALIDATION_ERROR", "Validation error"),
                ArgumentException argEx => ((int)HttpStatusCode.BadRequest, "BAD_REQUEST", argEx.Message),
                InvalidOperationException opEx => ((int)HttpStatusCode.BadRequest, "INVALID_OPERATION", opEx.Message),

                UnauthorizedAccessException => ((int)HttpStatusCode.Unauthorized, "UNAUTHORIZED", "Unauthorized"),
                InvalidCredentialsException => ((int)HttpStatusCode.Unauthorized, "AUTH_FAILED", "Authentication failed"),

                ServantProfileMissingException => ((int)HttpStatusCode.Forbidden, "FORBIDDEN", "Forbidden"),
                AccountNotApprovedException => ((int)HttpStatusCode.Forbidden, "FORBIDDEN", "Forbidden"),
                ProfileNotCompletedException => ((int)HttpStatusCode.Forbidden, "FORBIDDEN", "Forbidden"),
                PhoneNotVerifiedException phoneEx => (
                    (int)HttpStatusCode.Forbidden,
                    "PHONE_NOT_VERIFIED",
                    phoneEx.Message),

                InvalidOtpException otpEx => ((int)HttpStatusCode.BadRequest, "INVALID_OTP", otpEx.Message),
                OtpRateLimitException rateEx => ((int)HttpStatusCode.TooManyRequests, "OTP_RATE_LIMIT", rateEx.Message),

                NotFoundException notFound => ((int)HttpStatusCode.NotFound, "NOT_FOUND", notFound.Message),

                UserAlreadyExistsException => ((int)HttpStatusCode.Conflict, "CONFLICT", "Conflict"),
                ServantAlreayAssigned => ((int)HttpStatusCode.Conflict, "CONFLICT", "Conflict"),
                ChurchAlreadyExistsException => ((int)HttpStatusCode.Conflict, "CONFLICT", "Conflict"),
                MeetingAlreadyExistsException => ((int)HttpStatusCode.Conflict, "CONFLICT", "Conflict"),
                PassordsMissMatchException => ((int)HttpStatusCode.Conflict, "CONFLICT", "Conflict"),

                DbUpdateException dbEx => (
                    (int)HttpStatusCode.InternalServerError,
                    "DATABASE_ERROR",
                    root.Message),

                AutoMapper.AutoMapperMappingException mapEx => (
                    (int)HttpStatusCode.InternalServerError,
                    "MAPPING_ERROR",
                    mapEx.Message),

                _ => ((int)HttpStatusCode.InternalServerError, "SERVER_ERROR", root.Message)
            };
        }

        private sealed class ApiErrorResponse
        {
            public bool Success { get; set; }
            public string Message { get; set; } = "";
            public string ErrorCode { get; set; } = "";
            public string? ExceptionType { get; set; }
            public string? StackTrace { get; set; }
            public string? InnerException { get; set; }
            public IDictionary<string, string[]>? Errors { get; set; }
        }
    }
}
