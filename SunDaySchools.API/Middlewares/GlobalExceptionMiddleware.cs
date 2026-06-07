using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using SunDaySchools.API.Json;
using SunDaySchools.BLL.Exceptions;
using System;
using System.Net;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace SunDaySchools.API.Middlewares
{
    public class GlobalExceptionMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<GlobalExceptionMiddleware> _logger;

        private static readonly JsonSerializerOptions _jsonOptions = ApiJsonSerializerOptions.Create();

        public GlobalExceptionMiddleware(
            RequestDelegate next,
            ILogger<GlobalExceptionMiddleware> logger)
        {
            _next = next;
            _logger = logger;
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

            var (statusCode, errorCode, message) = MapException(exception);

            context.Response.StatusCode = statusCode;

            if (exception is PhoneNotVerifiedException phoneEx)
            {
                context.Response.ContentType = "application/json; charset=utf-8";
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
                context.Response.ContentType = "application/json; charset=utf-8";
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

            context.Response.ContentType = "application/problem+json; charset=utf-8";

            var detail = GetSafeDetail(exception, message);

            if (exception is ValidationException validationException)
            {
                if (validationException.Errors.Count > 0)
                {
                    var first = validationException.Errors.First();
                    detail = $"{first.Key}: {string.Join("; ", first.Value)}";
                    if (validationException.Errors.Count > 1)
                        detail += $" (+{validationException.Errors.Count - 1} more)";
                }
            }

            var problem = new ProblemDetails
            {
                Type = errorCode,
                Title = message,
                Status = statusCode,
                Detail = detail
            };

            if (exception is ValidationException validationEx && validationEx.Errors.Count > 0)
            {
                problem.Extensions["errors"] = validationEx.Errors;
            }

            var json = JsonSerializer.Serialize(problem, _jsonOptions);
            await context.Response.WriteAsync(json);
        }

        private static string GetSafeDetail(Exception exception, string mappedMessage)
        {
            if (exception is InvalidCredentialsException credEx)
                return credEx.Message;

            return mappedMessage;
        }

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

                DbUpdateException => (
                    (int)HttpStatusCode.InternalServerError,
                    "DATABASE_ERROR",
                    FriendlyDatabaseMessage),

                AutoMapper.AutoMapperMappingException => (
                    (int)HttpStatusCode.InternalServerError,
                    "MAPPING_ERROR",
                    "A server error occurred while processing your request."),

                _ when IsDatabaseException(exception) => (
                    (int)HttpStatusCode.InternalServerError,
                    "DATABASE_ERROR",
                    FriendlyDatabaseMessage),

                _ => ((int)HttpStatusCode.InternalServerError, "SERVER_ERROR", FriendlyServerMessage)
            };
        }

        private const string FriendlyDatabaseMessage =
            "A database error occurred. Please try again later or contact support.";

        private const string FriendlyServerMessage =
            "An unexpected error occurred. Please try again later.";

        private static bool IsDatabaseException(Exception exception)
        {
            for (var ex = exception; ex != null; ex = ex.InnerException)
            {
                if (ex is SqlException or DbUpdateException)
                    return true;
            }

            return false;
        }

    }
}
