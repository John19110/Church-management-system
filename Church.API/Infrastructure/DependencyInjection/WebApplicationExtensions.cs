using Church.API.Infrastructure.Tenant;
using Church.API.Middlewares;
using Church.DAL.DBcontext;
using Church.DAL.Models;
using Microsoft.AspNetCore.Identity;

namespace Church.API.Infrastructure.DependencyInjection
{
    public static class WebApplicationExtensions
    {
        public static async Task<WebApplication> InitializeDatabaseAsync(this WebApplication app)
        {
            await DatabaseBootstrap.ApplyMigrationsAndRepairSchemaAsync(app.Services, app.Logger);
            return app;
        }

        /// <summary>
        /// Seeds roles/users when possible. Continues startup on failure so a shared hosting
        /// seed glitch does not take the whole API offline after migrations already applied.
        /// </summary>
        public static async Task<WebApplication> SeedIdentityAsync(this WebApplication app)
        {
            try
            {
                using var scope = app.Services.CreateScope();
                var services = scope.ServiceProvider;

                var roleManager = services.GetRequiredService<RoleManager<IdentityRole>>();
                var userManager = services.GetRequiredService<UserManager<ApplicationUser>>();

                await IdentitySeeder.SeedIdentityAsync(roleManager, userManager);
            }
            catch (Exception ex)
            {
                app.Logger.LogError(ex, "Identity seeding failed; continuing startup.");
            }

            return app;
        }

        public static WebApplication UseApplicationMiddleware(this WebApplication app)
        {
            // Must be first so it catches exceptions from all middleware/controllers.
            app.UseMiddleware<GlobalExceptionMiddleware>();

            // CSP is intentionally omitted here: the API also serves static privacy/deletion
            // pages, and a wrong policy would break them. CSP belongs on the Flutter Web host.
            app.Use(async (context, next) =>
            {
                var headers = context.Response.Headers;
                headers["X-Content-Type-Options"] = "nosniff";
                headers["X-Frame-Options"] = "DENY";
                headers["Referrer-Policy"] = "no-referrer";
                headers["Cross-Origin-Resource-Policy"] = "cross-origin";
                await next();
            });

            if (!app.Environment.IsProduction())
            {
                app.UseHsts();
            }

            // Swagger publishes the full API surface; keep it off in Production unless opted in.
            if (app.IsSwaggerEnabled())
            {
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            app.UseHttpsRedirection();

            app.UseStaticFiles(new StaticFileOptions
            {
                OnPrepareResponse = ctx =>
                {
                    // UseStaticFiles short-circuits before UseCors. Flutter Web loads member/
                    // servant images cross-origin from this API host, so public asset paths need
                    // an ACAO header here. These paths are intentionally public read-only files.
                    var path = ctx.Context.Request.Path.Value ?? string.Empty;
                    if (path.StartsWith("/uploads", StringComparison.OrdinalIgnoreCase) ||
                        path.StartsWith("/images", StringComparison.OrdinalIgnoreCase))
                    {
                        ctx.Context.Response.Headers["Access-Control-Allow-Origin"] = "*";
                        ctx.Context.Response.Headers["Access-Control-Allow-Headers"] = "*";
                        ctx.Context.Response.Headers["Access-Control-Allow-Methods"] = "GET, HEAD, OPTIONS";
                    }
                }
            });

            // Before authentication so OPTIONS preflight succeeds without a JWT.
            app.UseCors(CorsServiceCollectionExtensions.FlutterWebPolicyName);

            app.UseRateLimiter();
            app.UseAuthentication();
            app.UseAuthorization();

            // After auth so JWT claims are available when populating tenant scope.
            app.UseMiddleware<TenantContextPopulationMiddleware>();

            return app;
        }

        public static WebApplication MapApplicationEndpoints(this WebApplication app)
        {
            app.MapControllers();

            app.MapGet(
                    "/account-deletion",
                    (IWebHostEnvironment environment) => Results.File(
                        Path.Combine(environment.WebRootPath, "account-deletion", "index.html"),
                        "text/html; charset=utf-8"))
                .AllowAnonymous();

            app.MapGet(
                    "/privacy-policy",
                    (IWebHostEnvironment environment) => Results.File(
                        Path.Combine(environment.WebRootPath, "privacy-policy", "index.html"),
                        "text/html; charset=utf-8"))
                .AllowAnonymous();

            var swaggerEnabled = app.IsSwaggerEnabled();
            app.MapGet(
                    "/",
                    () => swaggerEnabled ? Results.Redirect("/swagger") : Results.NoContent())
                .AllowAnonymous();

            return app;
        }
    }
}
