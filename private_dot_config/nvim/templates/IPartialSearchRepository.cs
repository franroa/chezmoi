using Genzai.EfCore.Repository;
using Gims.API.Domain.Data.Search.{{_lua:vim.g.entityname_}}s;
using Genzai.EfCore.Repository;

namespace Gims.API.Domain.Repositories.{{_lua:vim.g.entityname_}}s
{
    /// <summary>
    /// This interface controls operations over repository with rules
    /// </summary>
    public interface I{{_lua:vim.g.entityname_}}Repository : IPartialSearchRepository<{{_lua:vim.g.entityname_}}, long, {{_lua:vim.g.entityname_}}Search, {{_lua:vim.g.entityname_}}SearchResult>
    {
    }
}

