using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace SunDaySchools.API.Filters
{
    /// <summary>
    /// Logs and surfaces real exception details for dynamic form endpoints when diagnostics are enabled.
    /// </summary>
    public sealed class FormDataExceptionFilter : IAsyncExceptionFilter
    {
        private readonly ILogger<FormDataExceptionFilter> _logger;
        private readonly IHostEnvironment _env;
        private readonly IConfiguration _configuration;

        public FormDataExceptionFilter(
            ILogger<FormDataExceptionFilter> logger,
            IHostEnvironment env,
            IConfiguration configuration)
        {
            _logger = logger;
            _env = env;
            _configuration = configuration;
        }

        public Task OnExceptionAsync(ExceptionContext context)
        {
            var ex = context.Exception;
            var path = context.HttpContext.Request.Path.Value ?? string.Empty;

            if (!IsFormDataPath(path))
                return Task.CompletedTask;

            LogExceptionChain(ex, path);

            if (!ShouldExposeDetails())
                return Task.CompletedTask;

            context.Result = new ObjectResult(new
            {
                success = false,
                message = ex.Message,
                errorCode = "SERVER_ERROR",
                exceptionType = ex.GetType().FullName,
                stackTrace = ex.StackTrace,
                innerException = ex.InnerException?.Message,
                errors = (object?)null
            })
            {
                StatusCode = StatusCodes.Status500InternalServerError
            };

            context.ExceptionHandled = true;
            return Task.CompletedTask;
        }

        private bool ShouldExposeDetails() =>
            _env.IsDevelopment()
            || _configuration.GetValue<bool>("DetailedErrors")
            || string.Equals(
                Environment.GetEnvironmentVariable("SUN_DAYSCHOOLS_DETAILED_ERRORS"),
                "true",
                StringComparison.OrdinalIgnoreCase);

        private static bool IsFormDataPath(string path) =>
            path.Contains("/form-data", StringComparison.OrdinalIgnoreCase)
            || path.Contains("/form-schema", StringComparison.OrdinalIgnoreCase)
            || path.Contains("/api/CustomField/definitions", StringComparison.OrdinalIgnoreCase)
            || path.Contains("/api/customfield/definitions", StringComparison.OrdinalIgnoreCase);

        private void LogExceptionChain(Exception exception, string path)
        {
            var depth = 0;
            for (var ex = exception; ex != null; ex = ex.InnerException, depth++)
            {
                _logger.LogError(
                    ex,
                    "Form-data endpoint failed (depth={Depth}) Path={Path} Type={Type} Message={Message}",
                    depth,
                    path,
                    ex.GetType().FullName,
                    ex.Message);

                if (!string.IsNullOrWhiteSpace(ex.StackTrace))
                {
                    _logger.LogError("StackTrace depth={Depth}: {StackTrace}", depth, ex.StackTrace);
                }
            }
        }
    }
}
