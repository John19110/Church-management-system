using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using SunDaySchools.API.Json;
using SunDaySchools.BLL.Exceptions;
using System;
using System.Net;
using System.Text.Json;
using System.Threading.Tasks;

namespace SunDaySchools.API.Middlewares
{
    public class GlobalExceptionMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<GlobalExceptionMiddleware> _logger;
        private readonly IHostEnvironment _env;

        private static readonly JsonSerializerOptions _jsonOptions = ApiJsonSerializerOptions.Create();

        public GlobalExceptionMiddleware(
            RequestDelegate next,
            ILogger<GlobalExceptionMiddleware> logger,
            IHostEnvironment env)
        {
            _next = next;
            _logger = logger;
            _env = env;
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
            _logger.LogError(
                exception,
                "Unhandled exception occurred. Method={Method}, Path={Path}, TraceId={TraceId}",
                context.Request.Method,
                context.Request.Path,
                context.TraceIdentifier);

            if (context.Response.HasStarted)
            {
                _logger.LogWarning("Response already started, cannot write error response.");
                return;
            }

            context.Response.ContentType = "application/json; charset=utf-8";

            var (statusCode, errorCode, message) = MapException(exception);

            context.Response.StatusCode = statusCode;

            var response = new ApiErrorResponse
            {
                Success = false,
                ErrorCode = errorCode,
                Message = _env.IsDevelopment() && exception is not ValidationException
                    ? exception.ToString()
                    : message
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

            var json = JsonSerializer.Serialize(response, _jsonOptions);
            await context.Response.WriteAsync(json);
        }

        private static (int StatusCode, string ErrorCode, string Message) MapException(Exception exception)
        {
            return exception switch
            {
                ArgumentException => ((int)HttpStatusCode.BadRequest, "BAD_REQUEST", "Invalid argument"),
                ValidationException => ((int)HttpStatusCode.BadRequest, "VALIDATION_ERROR", "Validation error"),

                UnauthorizedAccessException => ((int)HttpStatusCode.Unauthorized, "UNAUTHORIZED", "Unauthorized"),
                InvalidCredentialsException => ((int)HttpStatusCode.Unauthorized, "AUTH_FAILED", "Authentication failed"),

                ServantProfileMissingException => ((int)HttpStatusCode.Forbidden, "FORBIDDEN", "Forbidden"),
                AccountNotApprovedException => ((int)HttpStatusCode.Forbidden, "FORBIDDEN", "Forbidden"),
                ProfileNotCompletedException => ((int)HttpStatusCode.Forbidden, "FORBIDDEN", "Forbidden"),

                NotFoundException => ((int)HttpStatusCode.NotFound, "NOT_FOUND", "Not found"),

                UserAlreadyExistsException => ((int)HttpStatusCode.Conflict, "CONFLICT", "Conflict"),
                ServantAlreayAssigned => ((int)HttpStatusCode.Conflict, "CONFLICT", "Conflict"),
                ChurchAlreadyExistsException => ((int)HttpStatusCode.Conflict, "CONFLICT", "Conflict"),
                MeetingAlreadyExistsException => ((int)HttpStatusCode.Conflict, "CONFLICT", "Conflict"),
                PassordsMissMatchException => ((int)HttpStatusCode.Conflict, "CONFLICT", "Conflict"),

                _ => ((int)HttpStatusCode.InternalServerError, "SERVER_ERROR", "An unexpected error occurred")
            };
        }

        private sealed class ApiErrorResponse
        {
            public bool Success { get; set; }
            public string Message { get; set; } = "";
            public string ErrorCode { get; set; } = "";
            public IDictionary<string, string[]>? Errors { get; set; }
        }
    }
}
