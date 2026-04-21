using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using SunDaySchools.BLL.Exceptions;
using System;
using System.Net;
using System.Text.Json;
using System.Threading.Tasks;

public class GlobalExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionMiddleware> _logger;
    private readonly IWebHostEnvironment _env;

    private static readonly JsonSerializerOptions _jsonOptions = new(JsonSerializerDefaults.Web);

    public GlobalExceptionMiddleware(
        RequestDelegate next,
        ILogger<GlobalExceptionMiddleware> logger,
        IWebHostEnvironment env)
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
        // Logs full exception + stack trace to server logs only.
        _logger.LogError(
            exception,
            "Unhandled exception. method={Method} path={Path} query={QueryString} traceId={TraceId}",
            context.Request.Method,
            context.Request.Path.Value,
            context.Request.QueryString.Value,
            context.TraceIdentifier);

        var response = context.Response;
        if (response.HasStarted)
        {
            _logger.LogWarning("Response already started; cannot write error response. traceId={TraceId}", context.TraceIdentifier);
            return;
        }

        response.ContentType = "application/json; charset=utf-8";

        var (statusCode, errorCode, publicMessage) = MapException(exception);

        response.StatusCode = statusCode;

        var payload = new ApiErrorResponse
        {
            Success = false,
            Message = publicMessage,
            ErrorCode = errorCode
        };

        var json = JsonSerializer.Serialize(payload, _jsonOptions);
        await response.WriteAsync(json);
    }

    private (int StatusCode, string ErrorCode, string Message) MapException(Exception exception)
    {
        return exception switch
        {
            NotFoundException => ((int)HttpStatusCode.NotFound, "NOT_FOUND", "Not found"),
            ValidationException => ((int)HttpStatusCode.BadRequest, "VALIDATION_ERROR", "Validation error"),
            InvalidCredentialsException => ((int)HttpStatusCode.Unauthorized, "AUTH_FAILED", "Authentication failed"),
            UnauthorizedAccessException => ((int)HttpStatusCode.Unauthorized, "UNAUTHORIZED", "Unauthorized"),
            ServantProfileMissingException => ((int)HttpStatusCode.Forbidden, "FORBIDDEN", "Forbidden"),
            AccountNotApprovedException => ((int)HttpStatusCode.Forbidden, "FORBIDDEN", "Forbidden"),
            ProfileNotCompletedException => ((int)HttpStatusCode.Forbidden, "FORBIDDEN", "Forbidden"),
            UserAlreadyExistsException => ((int)HttpStatusCode.Conflict, "CONFLICT", "Conflict"),
            ServantAlreayAssigned => ((int)HttpStatusCode.Conflict, "CONFLICT", "Conflict"),
            ChurchAlreadyExistsException => ((int)HttpStatusCode.Conflict, "CONFLICT", "Conflict"),
            MeetingAlreadyExistsException => ((int)HttpStatusCode.Conflict, "CONFLICT", "Conflict"),
            PassordsMissMatchException => ((int)HttpStatusCode.Conflict, "CONFLICT", "Conflict"),
            _ => ((int)HttpStatusCode.InternalServerError, "SERVER_ERROR", "Server error")
        };
    }

    private sealed class ApiErrorResponse
    {
        public bool Success { get; init; }
        public string Message { get; init; } = "";
        public string ErrorCode { get; init; } = "";
    }
}
