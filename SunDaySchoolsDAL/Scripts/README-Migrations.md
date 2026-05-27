# Database migrations when `update-database` fails locally

## Why Package Manager `update-database` times out (error 10060)

Hosted SQL on **databaseasp.net** / MonsterASP often **does not accept connections from your home PC**.  
EF is trying to reach `db47820.public.databaseasp.net:1433` and the network blocks it. This is not an EF bug.

`EnableRetryOnFailure` only helps brief outages; it will not fix a blocked remote host.

## Option A — Run SQL in the hosting panel (recommended)

1. Log in to your host (MonsterASP / databaseasp.net).
2. Open **SQL Server** / **Query** for database `db47820`.
3. Run scripts in `SunDaySchoolsDAL/Scripts/` (newest first if unsure).
4. Confirm `__EFMigrationsHistory` contains the migration ids you applied.

## Option B — Deploy the API and migrate from the server

If your host allows outbound SQL from the web app only, publish the API and run migrations there (one-time startup or host console), using the same connection string as production.

## Option C — Local `dotnet ef` (only if your IP is allowed)

```powershell
$env:ASPNETCORE_ENVIRONMENT = "Development"
dotnet ef database update `
  --project SunDaySchoolsDAL\SunDaySchools.DAL.csproj `
  --startup-project SunDaySchools.API\SunDaySchools.API.csproj
```

Connection string is read from `SunDaySchools.API/appsettings.Development.json` (not committed to git).

## Package Manager Console

Set **Default project**: `SunDaySchools.DAL`  
Set **Startup project**: `SunDaySchools.API`

Before `Update-Database`:

```powershell
$env:ASPNETCORE_ENVIRONMENT = "Development"
```

If it still times out, use **Option A**.
