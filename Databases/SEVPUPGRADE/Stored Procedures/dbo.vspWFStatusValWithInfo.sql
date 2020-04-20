SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[vspWFStatusValWithInfo]
/***********************************************************
* CREATED BY: Charles Courchaine 12/6/2007
*			
*
* USAGE:
* 	Validates Status # 
*	Returns KeyID for given Status #
*
* INPUT PARAMETERS
*   @Status		Status # to Validate
*
* OUTPUT PARAMETERS
*   @msg      		error message if error occurs, or vWFStatusCodes.TemplateName
*
* RETURN VALUE
*   0	Success
*   1	Failure
*****************************************************/
(@Status int,
 @msg varchar(60) = null output)
     
as
set nocount on

declare @rcode int
set @rcode = 0 

if @Status is null
	begin
	select @msg = 'Missing Status Number!', @rcode = 1
	goto bspexit
	end

select @msg = [Description] from WFStatusCodes where StatusID = @Status and IsChecklistStatus = 'N'
if @msg is null
	begin
		set @rcode = 1
		set @msg = 'Invalid status '
	end

bspexit:
if @rcode<>0 select @msg=@msg
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspWFStatusValWithInfo] TO [public]
GO
