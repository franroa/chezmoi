using Genzai.Core.Domain.Model;
using Genzai.WebCore.Responses;

namespace Gims.API.Application.Responses.{{_lua:vim.g.entityname_}}s
{
    /// <summary>
    /// {{_lua:vim.g.entityname_}} Response
    /// </summary>
    public class {{_lua:vim.g.entityname_}}Response : IEntityResponse, IEntity<long>
    {
        public long Id { get; set; }
    }
}

