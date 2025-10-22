using FluentValidation;
using Genzai.WebCore.Validations;
using Gims.API.Application.Calendars.Common;

namespace Gims.API.Application.{{_lua:vim.g.entityname_}}s.Commands.Insert
{
    /// <summary>
    /// Insert output command validator
    /// </summary>
    public class Insert{{_lua:vim.g.entityname_}}CommandValidator : BaseAbstractValidator<Insert{{_lua:vim.g.entityname_}}Command>
    {
        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="{{_lua:vim.g.entityname_}}BaseValidator">IValidator</param>
        public Insert{{_lua:vim.g.entityname_}}CommandValidator() 
        {
        }
    }
}

