using Microsoft.AspNetCore.Authentication.JwtBearer;
using Brokerage.Api.Data;
using Brokerage.Api.Models;
using Brokerage.Api.Services;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using System.Security.Claims;
using System.Text;


var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
var jwtKey = builder.Configuration["Jwt:Key"]
    ?? throw new InvalidOperationException("Cheia JWT nu este configurată.");

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidateAudience = true,
            ValidAudience = builder.Configuration["Jwt:Audience"],
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromMinutes(1)
        };
        options.Events = new JwtBearerEvents
        {
            OnTokenValidated = async context =>
            {
                var userId = context.Principal?.FindFirstValue(ClaimTypes.NameIdentifier);
                var version = context.Principal?.FindFirstValue("sessionVersion");
                if (!Guid.TryParse(userId, out var id) || !int.TryParse(version, out var tokenVersion))
                {
                    context.Fail("Sesiune nevalidă.");
                    return;
                }
                var db = context.HttpContext.RequestServices.GetRequiredService<BrokerageDbContext>();
                var user = await db.ApiUsers.AsNoTracking().SingleOrDefaultAsync(item => item.ApiUserId == id);
                if (user is null || !user.IsActive || user.SessionVersion != tokenVersion)
                    context.Fail("Sesiunea a fost deconectată.");
            }
        };
    });

builder.Services.AddAuthorization();
builder.Services.AddCors(options =>
{
    options.AddPolicy("AngularDevelopment", policy => policy
        .WithOrigins("http://localhost:4200", "https://localhost:4200")
        .AllowAnyHeader()
        .AllowAnyMethod());
});

builder.Services.AddControllers();
builder.Services.AddOpenApi();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Brokerage API",
        Version = "v1",
        Description = "API pentru conturi de tranzacționare, ordine, execuții și conversia valorilor în EUR."
    });

    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Introdu tokenul JWT obținut prin /api/auth/login."
    });

    options.AddSecurityRequirement(document => new OpenApiSecurityRequirement
    {
        [new OpenApiSecuritySchemeReference("Bearer", document)] = []
    });
});

builder.Services.AddDbContext<BrokerageDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("BrokerageDb")));

builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IPasswordHasher<ApiUser>, PasswordHasher<ApiUser>>();
builder.Services.AddScoped<DevelopmentUserSeeder>();
builder.Services.AddScoped<CustomerNotificationService>();
builder.Services.AddScoped<BrokerNotificationService>();
builder.Services.AddScoped<OrderAuditService>();
builder.Services.AddHostedService<StopOrderActivationService>();
builder.Services.AddHttpClient<AdminAiService>();
builder.Services.AddScoped<AdminAiService>();
builder.Services.AddHttpClient<CustomerAiService>();
builder.Services.AddScoped<CustomerAiService>();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseSwagger();
    app.UseSwaggerUI();

    using var scope = app.Services.CreateScope();
    await scope.ServiceProvider
        .GetRequiredService<DevelopmentUserSeeder>()
        .SeedAsync();
}

if (builder.Configuration.GetValue("UseHttpsRedirection", true))
    app.UseHttpsRedirection();

app.UseCors("AngularDevelopment");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();

public partial class Program { }
