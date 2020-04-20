SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[vspWFChecklistTaskDesc]
/***********************************************************
* CREATED BY:  Charles Courchaine 12/18/2007
* MODIFIED By : 
*
* USAGE:
* 	Returns Checklist Task Summary
*
* INPUT PARAMETERS
*	@Company -- Company to identify task
*	@Checklist -- Checklist to indentify task
*   @task -- Task to validate
*   
* OUTPUT PARAMETERS
*   @msg      Summary
*
*****************************************************/
(@Company bCompany = null, @Checklist varchar(20) = null, @task int = null, @msg varchar(255) output)
as
set nocount on
if @Checklist is null or @Company is null
	goto vspexit

if @task is null
	goto vspexit

select @msg = Summary from WFChecklistTasks with (nolock) where Checklist = @Checklist and Task = @task and Company = @Company

vspexit:

GO
GRANT EXECUTE ON  [dbo].[vspWFChecklistTaskDesc] TO [public]
GO
