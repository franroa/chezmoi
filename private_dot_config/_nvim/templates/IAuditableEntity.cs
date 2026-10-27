using Genzai.EfCore.Repository
using Gims.Domain.Persistence.Model;

namespace Gims.API.Domain.Repositories.{{_lua:vim.g.entityname_}}
{
    /// <summary>
    /// This interface controls operations over repository with {{_lua:vim.g.entityname_}}
    /// </summary>
    public interface I{{_lua:vim.g.entityname_}}Repository : IAuditableRepository<{{_lua:vim.g.entityname_}}, long>
    {
    }
}

