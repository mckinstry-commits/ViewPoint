SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspEMRevCodeDesc    Script Date:  ******/
CREATE PROC [dbo].[vspEMRevCodeDesc]
/***********************************************************
* CREATED BY:  TJL 12/07/07 - Issue #124113:  Return Description to VCSLabelDesc on record save
* MODIFIED By : 
*
* USAGE:
* 	Returns Revenue Code Description
*
* INPUT PARAMETERS
*   EM Group
*   Revenue Code to validate
*
* OUTPUT PARAMETERS
*   @msg      Description
*
* RETURN VALUE
*   0         success
*   1         failure
*****************************************************/
(@emgroup bGroup = null, @revcode bRevCode = null, @msg varchar(255) output)
as
set nocount on

if @emgroup is null
	begin
	goto vspexit
	end
if @revcode is null
	begin
	goto vspexit
	end
Else
   	begin
 	select @msg = Description from EMRC with (nolock) where EMGroup = @emgroup and RevCode = @revcode
   	end

vspexit:

GO
GRANT EXECUTE ON  [dbo].[vspEMRevCodeDesc] TO [public]
GO
