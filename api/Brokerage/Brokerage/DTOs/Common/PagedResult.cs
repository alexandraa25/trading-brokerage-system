using Microsoft.EntityFrameworkCore;

namespace Brokerage.Api.DTOs.Common;

/// <summary>Parametrii standard pentru listările mari din API.</summary>
public sealed record PageRequest(int Page = 1, int PageSize = 50)
{
    public int ValidPage => Math.Max(Page, 1);
    public int ValidPageSize => Math.Clamp(PageSize, 1, 100);
}

/// <summary>Rezultatul paginat, cu suficiente metadate pentru paginarea din interfață.</summary>
public sealed record PagedResult<T>(IReadOnlyList<T> Items, int Page, int PageSize, int TotalCount)
{
    public int TotalPages => Math.Max(1, (int)Math.Ceiling(TotalCount / (double)PageSize));
}

public static class PaginationExtensions
{
    public static async Task<PagedResult<T>> ToPagedResultAsync<T>(
        this IQueryable<T> query,
        PageRequest request,
        CancellationToken cancellationToken = default)
    {
        var page = request.ValidPage;
        var pageSize = request.ValidPageSize;
        var totalCount = await query.CountAsync(cancellationToken);
        var items = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken);
        return new PagedResult<T>(items, page, pageSize, totalCount);
    }
}
