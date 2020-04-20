SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE       PROCEDURE [dbo].[vspVPMenuGetVCSSecurity]
/**************************************************
* Created: JRK 09/08/03
* Modified: JRK 09/26/03:
* - LicenseLevel and AppRolePassword are now encrypted, so fields are bigger.
* - Dropped field UserTimeout.
* Modified: JRK 06/13/05: Use the view, DDVS, instead of the table, vDDVS.
* JRK 01/07/2007 #27068 Retrieve new fields for login message.
*			RM 03/02/08 - Retrieve Date Format for system level.
*
* Used by VPMenu to count/itemize users for a license check or to list logged in users.
* Each user + workstation are counted as 1 license, so a user can be logged in from
* multiple workstations and each will be counted.
*
* Inputs:
*	none
*
* Output:
*	resultset containing one row from vDDVS.
*	@errmsg		Error message
*
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	(@errmsg varchar(512) output)
as

set nocount on 

declare @rcode int
select @rcode = 0

return_results:		
	select LicenseLevel, UseAppRole, AppRolePassword, MaxLookupRows, MaxFilterRows, LoginMessage, LoginMessageActive from DDVS

   
vspexit:

	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspVPMenuGetVCSSecurity]'
	return @rcode




GO
GRANT EXECUTE ON  [dbo].[vspVPMenuGetVCSSecurity] TO [public]
GO
