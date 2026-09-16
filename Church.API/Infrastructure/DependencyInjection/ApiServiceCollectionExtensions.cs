using Church.API.Filters;
using Church.API.Json;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Server.Kestrel.Core;
using System.Reflection.Metadata;
using System.Security.Cryptography.Xml;
using System.Text.Json.Serialization;
using static System.Net.WebRequestMethods;

namespace Church.API.Infrastructure.DependencyInjection
{
    public static class ApiServiceCollectionExtensions
    {
        public static IServiceCollection AddApiServices(this IServiceCollection services)
        {
            services.AddProblemDetails();
            // Problem Details is a standardized structure for HTTP errors.

            services.AddHttpContextAccessor();
            // This allows services that aren't controllers to access the current HTTP request.
            //you can inject:
            // IHttpContextAccessor
            //and access:
            //_httpContextAccessor.HttpContext


            //This application uses MVC/Web API controllers.
            services.AddControllers(options =>
                {
                            //HTTP Request
                            //     ↓
                            //Controller
                            //     ↓
                            //Action
                            //     ↓
                            //Exception ?
                            //     ↓
                            //FormDataExceptionFilter
                            //     ↓
                            //Handle / transform exception

                    options.Filters.Add<FormDataExceptionFilter>();
                })
                .AddJsonOptions(o =>
                {
                    //This controls how your C# objects are converted to/from JSON.
                    ApiJsonSerializerOptions.Configure(o.JsonSerializerOptions);

                    //This is important for Entity Framework applications.
                    //If you encounter a circular reference, don't keep following it forever.
                    o.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;


                    o.JsonSerializerOptions.Converters.Add(new TimeOnlyJsonConverter());

                });

            // ASP.NET Core automatically performs model validation when using [ApiController].
            services.Configure<ApiBehaviorOptions>(options =>
            {
                options.InvalidModelStateResponseFactory = context =>
                {
                    var errors = context.ModelState
                        .Where(e => e.Value?.Errors.Count > 0)
                        //Give me only the fields that contain errors.
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
