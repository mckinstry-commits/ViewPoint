SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspARDescRecType    Script Date:  ******/
CREATE PROC [dbo].[vspHQDescStatusCode]
/***********************************************************
* CREATED BY:  TJL 10/16/06 - Issue #26203:  6x Rewrite
* MODIFIED By : 
*
* USAGE:
* 	Returns Status Code Description
*
* INPUT PARAMETERS
*   Status Code
*
* OUTPUT PARAMETERS
*   @msg      Description
*
* RETURN VALUE
*   0         success
*   1         failure
*****************************************************/
(@statcode bStatus, @msg varchar(255) output)
as
set nocount on

if @statcode is null
	begin
	goto vspexit
	end
Else
   	begin
 	select @msg = Description from HQDS with (nolock) where Status = @statcode
   	end

vspexit:

GO
GRANT EXECUTE ON  [dbo].[vspHQDescStatusCode] TO [public]
GO
