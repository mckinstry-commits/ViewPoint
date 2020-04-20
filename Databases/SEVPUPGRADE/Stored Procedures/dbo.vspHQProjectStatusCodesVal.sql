SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspHQProjectStatusCodesVal]
/***********************************************************
* Created By:	GP	2/2/2010 - Issue 129020
* Modified By: 
*
* USAGE:
* Validates Project Status Codes

* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
    *****************************************************/
(@StatusCode varchar(10) = null, @msg varchar(255) output)

   as
   set nocount on

	declare @rcode int

	set @rcode = 0
	
	
	if isnull(@StatusCode,'') = ''
	begin
		select @msg = 'Missing Status Code!', @rcode = 1
		goto vspexit
	end	
	
	select @msg = Description from dbo.HQProjectStatusCodes with (nolock) where ProjectStatusCode=@StatusCode
	if @@rowcount = 0
	begin
		select @msg = 'Project status code not on file!', @rcode = 1
		goto vspexit
	end	
		
			
	vspexit:
		return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspHQProjectStatusCodesVal] TO [public]
GO
