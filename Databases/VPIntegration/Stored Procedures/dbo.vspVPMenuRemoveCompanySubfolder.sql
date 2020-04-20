SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO












CREATE              PROCEDURE [dbo].[vspVPMenuRemoveCompanySubfolder]
/**************************************************
* Created:  JK 12/09/03
* Modified:
*
* Used by VPMenu to remove a company-specific subfolder (from vDDSF) and all subfolder
* items (from vDDSI) that are associated with the specified subfolder.
*
* The key of vDDSF and vDDSI is  co + username + mod + subfolder.
* For company-specific subfolders, we only need to specify co and subfolder.
*
* Inputs
*       @co			Company number
*	@subfolder 		smallint id of the folder for the user+mod
*
* Output
*	@errmsg
*
****************************************************/
	(@co bCompany = null, @subfolder smallint = null, 
	 @errmsg varchar(512) output)
as

set nocount on 
declare @rcode int
select @rcode = 0

-- Check for required fields
if (@co is null or @subfolder is null) 
	begin
	select @errmsg = 'Missing required field:  co or subfolder.', @rcode = 1
	goto vspexit
	end

-- Check for non-zero company
if (@co = 0) 
	begin
	select @errmsg = 'Company cannot be zero.', @rcode = 1
	goto vspexit
	end

-- Delete any items in vDDSI associated with this subfolder.
DELETE FROM vDDSI WHERE Co = @co AND SubFolder = @subfolder


-- Delete a row with the supplied data.
DELETE FROM vDDSF WHERE Co = @co AND SubFolder = @subfolder

vspexit:
	return @rcode












GO
GRANT EXECUTE ON  [dbo].[vspVPMenuRemoveCompanySubfolder] TO [public]
GO
