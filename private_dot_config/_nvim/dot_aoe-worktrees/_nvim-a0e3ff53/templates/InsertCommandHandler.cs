using AutoMapper;
using Genzai.Core.Errors;
using Genzai.WebCore.Audit;
using Genzai.WebCore.Commands.Insert;
using Gims.API.Application.Requests.{{_lua:vim.g.entityname_}}s;
using Gims.API.Application.Responses.{{_lua:vim.g.entityname_}}s;
using Gims.API.Application.{{_lua:vim.g.entityname_}}s.Commands.Insert;
using Gims.API.Domain.Repositories.{{_lua:vim.g.entityname_}}s;
using Gims.Domain.Persistence.Model;
using Microsoft.Extensions.Logging;

namespace Gims.API.Application.Outputs.Commands.Insert;

public class Insert{{_lua:vim.g.entityname_}}CommandHandler : BaseInsertCommandHandler<{{_lua:vim.g.entityname_}}, I{{_lua:vim.g.entityname_}}Repository, Insert{{_lua:vim.g.entityname_}}Command, {{_lua:vim.g.entityname_}}InsertRequest, {{_lua:vim.g.entityname_}}Response, {{_lua:vim.g.entityname_}}Response, {{_lua:vim.g.entityname_}}Response>
{
    /// <summary>
    /// Command handler
    /// </summary>
    /// <param name="repository">{{_lua:vim.g.entityname_}} repository</param>
    /// <param name="validator">Validator</param>
    /// <param name="mapper">Mapper</param>
    /// <param name="auditService">Audit service</param>
    public Insert{{_lua:vim.g.entityname_}}CommandHandler(I{{_lua:vim.g.entityname_}}Repository repository, ILogger<Insert{{_lua:vim.g.entityname_}}Command> logger, Insert{{_lua:vim.g.entityname_}}CommandValidator validator, IMapper mapper, IAuditService<{{_lua:vim.g.entityname_}}Response, {{_lua:vim.g.entityname_}}Response> auditService) : base(repository, logger, validator, mapper, auditService)
    {
    }

    protected override IList<ApplicationError> PreSaveValidation({{_lua:vim.g.entityname_}} entity)
    {
        return new List<ApplicationError>();
    }
}

