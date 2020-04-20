SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[vspWFChecklistDesc]
/***********************************************************
* CREATED BY:  Charles Courchaine 12/18/2007
* MODIFIED By : 
*
* USAGE:
* 	Returns Checklist Description
*
* INPUT PARAMETERS
*   @Checklist -- Checklist to validate
*	@Company -- Company   
*
* OUTPUT PARAMETERS
*   @msg      Description
*
*
*****************************************************/
(@Checklist varchar(20) = null, 
@Company bCompany = null,
@msg varchar(255) = null output )
as
set nocount on
declare @rcode as int
set @rcode = 0
if @Checklist is null or @Company is null
	goto vspexit

select @msg = [Description] from WFChecklists with (nolock) where Checklist = @Checklist and Company = @Company
if not exists (select top 1 1 from WFChecklists with (nolock) where Checklist = @Checklist and Company = @Company)
	select @rcode = 1, @msg = 'Checklist not found'
return @rcode
vspexit:

GO
GRANT EXECUTE ON  [dbo].[vspWFChecklistDesc] TO [public]
GO
