---
name: csharp
description: C# and .NET patterns — ASP.NET Core, Entity Framework, async/await, LINQ, REST APIs. Use when writing C# backend code.
---

You are a C# / .NET expert. Apply these patterns.

## ASP.NET Core API Patterns
```csharp
// Minimal API (modern, .NET 6+)
app.MapGet("/api/items/{id}", async (int id, IItemService service) =>
{
    var item = await service.GetByIdAsync(id);
    return item is null ? Results.NotFound() : Results.Ok(item);
})
.WithName("GetItem")
.RequireAuthorization();

// Controller pattern (legacy / complex APIs)
[ApiController]
[Route("api/[controller]")]
public class ItemsController : ControllerBase
{
    private readonly IItemService _service;
    public ItemsController(IItemService service) => _service = service;

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ItemDto>> Get(int id)
    {
        var item = await _service.GetByIdAsync(id);
        return item is null ? NotFound() : Ok(item);
    }
}
```

## Async Best Practices
```csharp
// Always use CancellationToken in service methods
public async Task<Item> GetAsync(int id, CancellationToken ct = default)
{
    return await _context.Items.FindAsync(new object[] { id }, ct)
        ?? throw new NotFoundException($"Item {id} not found");
}

// Never use .Result or .Wait() — causes deadlocks
// Use ConfigureAwait(false) in library code, not app code
```

## Entity Framework
```csharp
// Repository pattern with EF
public async Task<List<Item>> GetAllAsync(int orgId, CancellationToken ct)
    => await _context.Items
        .Where(i => i.OrganizationId == orgId && !i.IsDeleted)
        .OrderByDescending(i => i.CreatedAt)
        .Select(i => new ItemDto(i.Id, i.Name, i.CreatedAt))  // project early
        .ToListAsync(ct);

// Migrations
// dotnet ef migrations add InitialCreate
// dotnet ef database update
```

## Dependency Injection
```csharp
// Registration (Program.cs)
builder.Services.AddScoped<IItemService, ItemService>();
builder.Services.AddSingleton<ICacheService, RedisCacheService>();
// Scoped = per request, Transient = per injection, Singleton = app lifetime
```

## LINQ Patterns
```csharp
// Prefer LINQ to SQL (EF translates) over in-memory operations on large sets
var result = items
    .Where(i => i.Status == Status.Active)
    .GroupBy(i => i.Category)
    .Select(g => new { Category = g.Key, Count = g.Count(), Total = g.Sum(i => i.Price) })
    .OrderByDescending(g => g.Total)
    .ToList();
```

## Error Handling
```csharp
// Global exception middleware
app.UseExceptionHandler(exceptionHandlerApp =>
    exceptionHandlerApp.Run(async context =>
    {
        var ex = context.Features.Get<IExceptionHandlerFeature>()?.Error;
        var (status, message) = ex switch
        {
            NotFoundException => (404, ex.Message),
            ValidationException => (400, ex.Message),
            _ => (500, "An error occurred")
        };
        context.Response.StatusCode = status;
        await context.Response.WriteAsJsonAsync(new { error = message });
    }));
```

## Razor / CSHTML Tips
```csharp
// Partial views for reusable markup
@await Html.PartialAsync("_ItemCard", model)

// Tag helpers over HTML helpers (cleaner)
<a asp-controller="Items" asp-action="Edit" asp-route-id="@item.Id">Edit</a>

// Display templates in Views/Shared/DisplayTemplates/
@Html.DisplayFor(m => m.Property)
```
