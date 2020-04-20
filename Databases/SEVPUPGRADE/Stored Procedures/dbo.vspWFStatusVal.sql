SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[vspWFStatusVal]
/***********************************************************
* CREATED BY: Charles Courchaine 05/01/2008
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
*   @msg      		Returns status description
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
	set @msg = ''

bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspWFStatusVal] TO [public]
GO
