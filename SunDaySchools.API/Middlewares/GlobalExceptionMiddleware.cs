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
        _logger.LogError(exception, "An unhandled exception occurred.");

        var response = context.Response;
        response.ContentType = "application/problem+json";

        var problemDetails = new ProblemDetails
        {
            Title = "An error occurred while processing your request.",
            Status = (int)HttpStatusCode.InternalServerError,
            Instance = context.Request.Path,
            Type = "https://tools.ietf.org/html/rfc7231#section-6.6.1"
        };

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
                problemDetails.Extensions["errors"] = validation.Errors;
                break;

            case InvalidCredentialsException invalidCredentials:
                problemDetails.Title = "Authentication failed.";
                problemDetails.Status = (int)HttpStatusCode.Unauthorized;
                problemDetails.Type = "https://tools.ietf.org/html/rfc7235#section-3.1";
                problemDetails.Detail = invalidCredentials.Message;
                break;

            case UnauthorizedAccessException unauthorized:
                problemDetails.Title = "Unauthorized.";
                problemDetails.Status = (int)HttpStatusCode.Unauthorized;
                problemDetails.Type = "https://tools.ietf.org/html/rfc7235#section-3.1";
                problemDetails.Detail = unauthorized.Message;
                break;

            case ServantProfileMissingException servantProfileMissing:
                problemDetails.Title = "Servant profile required.";
                problemDetails.Status = (int)HttpStatusCode.Forbidden;
                problemDetails.Type = "https://tools.ietf.org/html/rfc7231#section-6.5.3";
                problemDetails.Detail = servantProfileMissing.Message;
                break;

            case AccountNotApprovedException accountNotApproved:
                problemDetails.Title = "Account not approved.";
                problemDetails.Status = (int)HttpStatusCode.Forbidden;
                problemDetails.Type = "https://tools.ietf.org/html/rfc7231#section-6.5.3";
                problemDetails.Detail = accountNotApproved.Message;
                break;

            case UserAlreadyExistsException userAlreadyExists:
                problemDetails.Title = "User already exists.";
                problemDetails.Status = (int)HttpStatusCode.Conflict;
                problemDetails.Type = "https://tools.ietf.org/html/rfc7231#section-6.5.8";
                problemDetails.Detail = userAlreadyExists.Message;
                break;

            case ServantAlreayAssigned servantAlreadyAssigned:
                problemDetails.Title = "Servant already assigned to the class.";
                problemDetails.Status = (int)HttpStatusCode.Conflict;
                problemDetails.Type = "https://tools.ietf.org/html/rfc7231#section-6.5.8";
                problemDetails.Detail = servantAlreadyAssigned.Message;
                break;

            case ChurchAlreadyExistsException churchAlreadyExists:
                problemDetails.Title = "Church already exists.";
                problemDetails.Status = (int)HttpStatusCode.Conflict;
                problemDetails.Type = "https://tools.ietf.org/html/rfc7231#section-6.5.8";
                problemDetails.Detail = churchAlreadyExists.Message;
                break;

            case MeetingAlreadyExistsException meetingAlreadyExists:
                problemDetails.Title = "Meeting already exists.";
                problemDetails.Status = (int)HttpStatusCode.Conflict;
                problemDetails.Type = "https://tools.ietf.org/html/rfc7231#section-6.5.8";
                problemDetails.Detail = meetingAlreadyExists.Message;
                break;

            case PassordsMissMatchException passordsMissMatchException:
                problemDetails.Title =" Passwords Miss match.";
                problemDetails.Status = (int)HttpStatusCode.Conflict;
                problemDetails.Type = "https://tools.ietf.org/html/rfc7231#section-6.5.8";
                problemDetails.Detail = passordsMissMatchException.Message;
                break;


            default:
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

        response.StatusCode = problemDetails.Status ?? (int)HttpStatusCode.InternalServerError;

        var json = JsonSerializer.Serialize(problemDetails);

        await response.WriteAsync(json);
    }
}
