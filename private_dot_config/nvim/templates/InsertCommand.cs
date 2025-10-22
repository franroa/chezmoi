using Genzai.WebCore.Commands.Insert;
using Gims.API.Application.Requests.{{_lua:vim.g.entityname_}}s;
using Gims.API.Application.Responses.{{_lua:vim.g.entityname_}}s;

namespace Gims.API.Application.{{_lua:vim.g.entityname_}}s.Commands.Insert
{
    public class {{_file_name_}}: BaseInsertCommand<{{_lua:vim.g.entityname_}}InsertRequest, {{_lua:vim.g.entityname_}}Response>
    {
        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="request">Insert request</param>
        public Insert{{_lua:vim.g.entityname_}}Command({{_lua:vim.g.entityname_}}InsertRequest request) : base(request)
        {
        }
    }
}


