SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[vspWFTemplateTaskDesc]
/***********************************************************
* CREATED BY:  Charles Courchaine 12/18/2007
* MODIFIED By : 
*
* USAGE:
* 	Returns Template Task Summary
*
* INPUT PARAMETERS
*	@template -- template to indentify task
*   @task -- Task to validate
*   
* OUTPUT PARAMETERS
*   @msg      Summary
*
* RETURN VALUE
*   0         success
*   1         failure
*****************************************************/
(@template varchar(20) = null, @task int = null, @msg varchar(255) output)
as
set nocount on
if @template is null
	goto vspexit

if @task is null
	goto vspexit

select @msg = Summary from WFTemplateTasks with (nolock) where Template = @template and Task = @task

vspexit:

GO
GRANT EXECUTE ON  [dbo].[vspWFTemplateTaskDesc] TO [public]
GO
