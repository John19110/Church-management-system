using Church.API.Filters;
using Church.API.Json;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Server.Kestrel.Core;
using System.Text.Json.Serialization;

namespace Church.API.Infrastructure.DependencyInjection
{
    public static class ApiServiceCollectionExtensions
    {
        public static IServiceCollection AddApiServices(this IServiceCollection services)
        {
            services.AddProblemDetails();
            services.AddHttpContextAccessor();

            services.AddControllers(options =>
                {
                    options.Filters.Add<FormDataExceptionFilter>();
                })
                .AddJsonOptions(o =>
                {
                    ApiJsonSerializerOptions.Configure(o.JsonSerializerOptions);
                    o.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
                    o.JsonSerializerOptions.Converters.Add(new TimeOnlyJsonConverter());
                });

            services.Configure<ApiBehaviorOptions>(options =>
            {
                options.InvalidModelStateResponseFactory = context =>
                {
                    var errors = context.ModelState
                        .Where(e => e.Value?.Errors.Count > 0)
                        .ToDictionary(
                            e => e.Key,
                            e => e.Value!.Errors.Select(x => x.ErrorMessage).ToArray());

                    return new BadRequestObjectResult(new
                    {
                        success = false,
                        errorCode = "MODEL_BINDING_ERROR",
                        message = "Validation failed",
                        errors
                    });
                };
            });

            // Anonymous registration accepts multipart uploads; keep the body small so an
            // unauthenticated caller cannot exhaust disk/bandwidth with huge files.
            services.Configure<FormOptions>(options =>
            {
                options.MultipartBodyLengthLimit = 8 * 1024 * 1024;
                options.ValueLengthLimit = 1024 * 1024;
                options.MultipartHeadersLengthLimit = 32 * 1024;
            });

            services.Configure<KestrelServerOptions>(options =>
            {
                options.Limits.MaxRequestBodySize = 8 * 1024 * 1024;
            });

            return services;
        }
    }
}
