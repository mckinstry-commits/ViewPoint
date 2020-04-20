SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[vspWFTemplateDesc]
/***********************************************************
* CREATED BY:  Charles Courchaine 12/18/2007
* MODIFIED By : 
*
* USAGE:
* 	Returns Template Description
*
* INPUT PARAMETERS
*   @template -- template to validate
*   
* OUTPUT PARAMETERS
*   @msg      Description
*
* RETURN VALUE
*   0         success
*   1         failure
*****************************************************/
(@template varchar(20) = null, @msg varchar(255) output)
as
set nocount on

if @template is null
	goto vspexit
Else
 	select @msg = left([Description], 255) from WFTemplates with (nolock) where Template = @template

vspexit:

GO
GRANT EXECUTE ON  [dbo].[vspWFTemplateDesc] TO [public]
GO
