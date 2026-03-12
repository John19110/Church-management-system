using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
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

    public GlobalExceptionMiddleware(RequestDelegate next, ILogger<GlobalExceptionMiddleware> logger, IWebHostEnvironment env)
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
        _logger.LogError(exception, "An unhandled exception occurred.");

        // Default to 500 if unexpected
        var response = context.Response;
        response.ContentType = "application/problem+json";

        var problemDetails = new ProblemDetails
        {
            Title = "An error occurred while processing your request.",
            Status = (int)HttpStatusCode.InternalServerError,
            Instance = context.Request.Path,
            Type = "https://tools.ietf.org/html/rfc7231#section-6.6.1" // generic server error
        };

        // Customize based on exception type
        switch (exception)
        {
            case NotFoundException notFound:
                problemDetails.Title = "The requested resource was not found.";
                problemDetails.Status = (int)HttpStatusCode.NotFound;
                problemDetails.Type = "https://tools.ietf.org/html/rfc7231#section-6.5.4";
                problemDetails.Detail = notFound.Message;
                break;

            case ValidationException validation:
                problemDetails.Title = "One or more validation errors occurred.";
                problemDetails.Status = (int)HttpStatusCode.BadRequest;
                problemDetails.Type = "https://tools.ietf.org/html/rfc7231#section-6.5.1";
                problemDetails.Detail = validation.Message;
                // Add validation errors as an extension
                problemDetails.Extensions["errors"] = validation.Errors;
                break;
            case InvalidCredentialsException:
                problemDetails.Title = "Authentication failed";
                problemDetails.Status = (int)HttpStatusCode.Unauthorized;
                problemDetails.Detail = exception.Message;
                break;
            case UserAlreadyExistsException:
                problemDetails.Title = "User already exists";
                problemDetails.Status = (int)HttpStatusCode.Conflict; // 409
                problemDetails.Detail = exception.Message;
                break;
            case ServantAlreayAssigned:
                problemDetails.Title = "Servant already Assigned to the class";
                problemDetails.Status = (int)HttpStatusCode.Conflict; // 409
                problemDetails.Detail = exception.Message;
                break;




            // You can add more cases for other custom exceptions

            default:
                // For security, don't leak exception details in production
                if (_env.IsDevelopment())
                {
                    problemDetails.Detail = exception.ToString();
                }
                else
                {
                    problemDetails.Detail = "An internal server error occurred. Please try again later.";
                }
                break;
        }

        response.StatusCode = problemDetails.Status.Value;
        var json = JsonSerializer.Serialize(problemDetails);
        await response.WriteAsync(json);
    }
}