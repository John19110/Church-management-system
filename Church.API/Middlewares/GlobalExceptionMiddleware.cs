using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Church.API.Json;
using Church.BLL.Exceptions;
using System;
using System.Linq;
using System.Net;
using System.Text.Json;
using System.Threading.Tasks;

namespace Church.API.Middlewares
{
    public class GlobalExceptionMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<GlobalExceptionMiddleware> _logger;

        private static readonly JsonSerializerOptions _jsonOptions =
            ApiJsonSerializerOptions.Create();

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


        private async Task HandleExceptionAsync(
            HttpContext context,
            Exception exception)
        {
            LogExceptionChain(exception, context);


            if (context.Response.HasStarted)
            {
                _logger.LogWarning(
                    "Response already started, cannot write error response.");

                return;
            }


            var (statusCode, errorCode, message) =
                MapException(exception);


            context.Response.StatusCode = statusCode;


            if (exception is PhoneNotVerifiedException phoneEx)
            {
                context.Response.ContentType =
                    "application/json; charset=utf-8";

                var payload = new
                {
                    success = false,
                    errorCode = "PHONE_NOT_VERIFIED",
                    message = phoneEx.Message,
                    requiresPhoneVerification = true,
                    phoneNumber = phoneEx.PhoneNumber
                };

                await WriteJsonAsync(context, payload);
                return;
            }


            if (exception is OtpRateLimitException rateEx)
            {
                context.Response.ContentType =
                    "application/json; charset=utf-8";

                var payload = new
                {
                    success = false,
                    errorCode = "OTP_RATE_LIMIT",
                    message = rateEx.Message,
                    retryAfterSeconds = rateEx.RetryAfterSeconds
                };

                await WriteJsonAsync(context, payload);
                return;
            }


            context.Response.ContentType =
                "application/problem+json; charset=utf-8";


            var detail = GetSafeDetail(exception, message);


            if (exception is ValidationException validationException)
            {
                if (validationException.Errors.Any())
                {
                    detail = string.Join(
                        Environment.NewLine,
                        validationException.Errors
                            .SelectMany(x => x.Value));
                }
            }


            var problem = new ProblemDetails
            {
                Type = errorCode,
                Title = message,
                Status = statusCode,
                Detail = detail
            };


            if (exception is ValidationException validationEx &&
                validationEx.Errors.Any())
            {
                problem.Extensions["errors"] =
                    validationEx.Errors;
            }


            await WriteJsonAsync(context, problem);
        }


        private async Task WriteJsonAsync(
            HttpContext context,
            object data)
        {
            var json = JsonSerializer.Serialize(
                data,
                _jsonOptions);

            await context.Response.WriteAsync(json);
        }



        private static string GetSafeDetail(
            Exception exception,
            string mappedMessage)
        {
            if (exception is InvalidCredentialsException credEx)
                return credEx.Message;


            if (exception is AccountNotApprovedException ||
                exception is AccountRejectedException)
            {
                return exception.Message;
            }


            return mappedMessage;
        }



        private void LogExceptionChain(
            Exception exception,
            HttpContext context)
        {
            var depth = 0;


            for (var ex = exception;
                 ex != null;
                 ex = ex.InnerException, depth++)
            {

                var message = ex.Message;


                if (ex is ValidationException validationEx &&
                    validationEx.Errors.Any())
                {
                    message += Environment.NewLine +
                               string.Join(
                                   Environment.NewLine,
                                   validationEx.Errors
                                       .SelectMany(x => x.Value));
                }


                _logger.LogError(
                    ex,
                    "Unhandled exception depth={Depth}. " +
                    "Type={ExceptionType}. " +
                    "Message={Message}. " +
                    "Method={Method}. " +
                    "Path={Path}. " +
                    "TraceId={TraceId}",
                    depth,
                    ex.GetType().FullName,
                    message,
                    context.Request.Method,
                    context.Request.Path,
                    context.TraceIdentifier
                );
            }
        }



        private static (int StatusCode,
                        string ErrorCode,
                        string Message)
            MapException(Exception exception)
        {

            return exception switch
            {

                ValidationException =>
                (
                    (int)HttpStatusCode.BadRequest,
                    "VALIDATION_ERROR",
                    "Validation error"
                ),


                ArgumentException argEx =>
                (
                    (int)HttpStatusCode.BadRequest,
                    "BAD_REQUEST",
                    argEx.Message
                ),


                InvalidOperationException opEx =>
                (
                    (int)HttpStatusCode.BadRequest,
                    "INVALID_OPERATION",
                    opEx.Message
                ),



                UnauthorizedAccessException =>
                (
                    (int)HttpStatusCode.Unauthorized,
                    "UNAUTHORIZED",
                    "Unauthorized"
                ),


                InvalidCredentialsException =>
                (
                    (int)HttpStatusCode.Unauthorized,
                    "AUTH_FAILED",
                    "Authentication failed"
                ),



                ServantProfileMissingException =>
                (
                    (int)HttpStatusCode.Forbidden,
                    "FORBIDDEN",
                    "Forbidden"
                ),


                AccountNotApprovedException ex =>
                (
                    (int)HttpStatusCode.Forbidden,
                    "ACCOUNT_PENDING",
                    ex.Message
                ),


                AccountRejectedException ex =>
                (
                    (int)HttpStatusCode.Forbidden,
                    "ACCOUNT_REJECTED",
                    ex.Message
                ),



                InvalidOtpException ex =>
                (
                    (int)HttpStatusCode.BadRequest,
                    "INVALID_OTP",
                    ex.Message
                ),



                OtpRateLimitException ex =>
                (
                    (int)HttpStatusCode.TooManyRequests,
                    "OTP_RATE_LIMIT",
                    ex.Message
                ),



                NotFoundException ex =>
                (
                    (int)HttpStatusCode.NotFound,
                    "NOT_FOUND",
                    ex.Message
                ),

                UserAlreadyExistsException ex =>
                (
                    (int)HttpStatusCode.BadRequest,
                    "VALIDATION_ERROR",
                    ex.Message
                ),



                DbUpdateException =>
                (
                    (int)HttpStatusCode.InternalServerError,
                    "DATABASE_ERROR",
                    FriendlyDatabaseMessage
                ),



                _ when IsDatabaseException(exception) =>
                (
                    (int)HttpStatusCode.InternalServerError,
                    "DATABASE_ERROR",
                    FriendlyDatabaseMessage
                ),



                _ =>
                (
                    (int)HttpStatusCode.InternalServerError,
                    "SERVER_ERROR",
                    FriendlyServerMessage
                )
            };
        }



        private const string FriendlyDatabaseMessage =
            "A database error occurred. Please try again later or contact support.";


        private const string FriendlyServerMessage =
            "An unexpected error occurred. Please try again later.";



        private static bool IsDatabaseException(Exception exception)
        {
            for (var ex = exception;
                 ex != null;
                 ex = ex.InnerException)
            {
                if (ex is SqlException ||
                    ex is DbUpdateException)
                {
                    return true;
                }
            }

            return false;
        }
    }
}