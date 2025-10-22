using Genzai.WebCore.Constants;
using Genzai.WebCore.Controllers;
using Gims.API.Application.Requests.{{_lua:vim.g.entityname_}}s;
using Gims.API.Application.Responses.{{_lua:vim.g.entityname_}}s;
using Gims.API.Application.{{_lua:vim.g.entityname_}}s.Commands.Insert;
using Gims.API.Constants;
using Gims.API.Operations;
using MediatR;
using Microsoft.AspNetCore.Mvc;

namespace Gims.API.Controllers.{{_lua:vim.g.entityname_}}s;

/// <summary>
/// Controller for centrals
/// </summary>
[ApiController]
[Route($"{GimsConstants.PathBase}rule_exceptios")]
[ApiVersion("1.0")]
[Produces(CommonsConstants.AplicationJson)]
[Tags(OperationId.{{_lua:vim.g.entityname_}}.One)]
public class {{_lua:vim.g.entityname_}}CommandController : BaseCommandController
{
    /// <summary>
    /// Constructor
    /// </summary>
    /// <param name="mediator">Mediator injection</param>
    public {{_lua:vim.g.entityname_}}CommandController(IMediator mediator) : base(mediator, GimsConstants.Controller{{_lua:vim.g.entityname_}}s)
    {
    }

    /// <summary>
    /// Creates a rule exceptio in a central
    /// </summary>
    /// <param name="request"></param>
    /// <returns>void</returns>
    [HttpPost(
        "",
        Name = OperationId.Post.Create + OperationId.{{_lua:vim.g.entityname_}}.One
        )]
    [ProducesResponseType(StatusCodes.Status201Created, Type = typeof({{_lua:vim.g.entityname_}}Response))]
    // TODO:
    // [HasPermission(PermissionTypes.ManageCentrals, "centralId", GimsEntitiesConstants.CentralEntity)]
    public async Task<IActionResult> InsertEntity([FromBody] {{_lua:vim.g.entityname_}}InsertRequest request)
    {
        return await BaseInsertEntity<{{_lua:vim.g.entityname_}}InsertRequest, {{_lua:vim.g.entityname_}}Response, Insert{{_lua:vim.g.entityname_}}Command>(
            new Insert{{_lua:vim.g.entityname_}}Command(request)
        );
    }

    /// /// <summary>
    /// /// Deletes rule exceptios in a central
    /// /// </summary>
    /// /// <param name="id"></param>
    /// /// <returns>void</returns>
    /// [HttpDelete(
    ///     "{id}",
    ///     Name = OperationId.Delete.Remove + OperationId.{{_lua:vim.g.entityname_}}.Many
    ///     )]
    /// [ProducesResponseType(StatusCodes.Status204NoContent)]
    /// // TODO:
    /// // [HasPermission(PermissionTypes.ManageCentrals, "centralId", GimsEntitiesConstants.CentralEntity)]
    /// public async Task<IActionResult> DeleteEntity(long id)
    /// {
    ///     return await CommandNoContentAsync(new Delete{{_lua:vim.g.entityname_}}Command(id));
    /// }
    ///
    ///  /// <summary>
    ///  /// Updates a rule exceptio in a central
    ///  /// </summary>
    ///  /// <param name="id"></param>
    ///  /// <param name="request"></param>
    ///  /// <returns>void</returns>
    ///  [HttpPut(
    ///      "{id}",
    ///      Name = OperationId.Put.Update + OperationId.{{_lua:vim.g.entityname_}}.Many
    ///      )]
    ///  [ProducesResponseType(StatusCodes.Status204NoContent)]
    /// // TODO:
    ///  // [HasPermission(PermissionTypes.ManageCentrals, "centralId", GimsEntitiesConstants.CentralEntity)]
    ///  public async Task<IActionResult> UpdateEntity(long id, [FromBody] {{_lua:vim.g.entityname_}}UpdateRequest request)
    ///  {
    ///      return await CommandNoContentAsync(new Update{{_lua:vim.g.entityname_}}Command(id, request));
    ///  }
}

