using Genzai.EfCore.Repository;
using Gims.API.Domain.Data.Search.{{_lua:vim.g.entityname_}}s;
using Gims.API.Domain.Repositories.{{_lua:vim.g.entityname_}}s;
using Gims.Infraestructure.Persistence;
using LinqKit;

namespace Gims.API.Infrastructure.Data.Repositories.{{_lua:vim.g.entityname_}}s;

/// <summary>
/// {{_lua:vim.g.entityname_}} repository
/// </summary>
public class {{_lua:vim.g.entityname_}}Repository : PartialSearchRepository<GimsContext, {{_lua:vim.g.entityname_}}, long, {{_lua:vim.g.entityname_}}Search, {{_lua:vim.g.entityname_}}SearchResult>,  I{{_lua:vim.g.entityname_}}Repository
{
    /// <summary>
    /// Base Constructor
    /// </summary>
    /// <param name="context"> Gims context</param>
    public {{_lua:vim.g.entityname_}}Repository(GimsContext context)
        : base(context) { }

    protected override void AppendConditions(ref ExpressionStarter<{{_lua:vim.g.entityname_}}SearchResult> queryExpression, {{_lua:vim.g.entityname_}}Search search)
    {
        throw new NotImplementedException();
    }

    protected override IQueryable<{{_lua:vim.g.entityname_}}SearchResult> InitQuery({{_lua:vim.g.entityname_}}Search search)
    {
        var totalCentersCount = context.Center.Count();
        return from entity in GetEntityDbSet()
            select new {{_lua:vim.g.entityname_}}SearchResult
            {
            };
    }
}
