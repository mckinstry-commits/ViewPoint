SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE              PROCEDURE [dbo].[vspVPMenuAddCompanyFolderRecord]
/**************************************************
* Created:  JK 12/10/03
* Modified:
*
* Used by VPMenu to ensure that a row exists with zero in the SubFolder field for the
* company-specific folder that is being shown on the menu.
*
* The key of vDDSF is  company + username + mod + subfolder (smallint).  
* We use the passed-in Company and set SubFolde = 0,
* "  " for Mod, and the user's name = "".  We'll set the Title (company name)
* to a dummy text since it is redundant data and not needed.
*
* There is no output.
* 
* Inputs
*       @co		
*
* Output
*	@errmsg
*
****************************************************/
	(@co bCompany = null, @errmsg varchar(512) output)
as

set nocount on 
declare @rcode int
select @rcode = 0

-- Check for required fields
if (@co is null) 
	begin
	select @errmsg = 'Missing required field:  co.', @rcode = 1
	goto vspexit
	end

if (@co = 0) 
	begin
	select @errmsg = 'co cannot be zero.', @rcode = 1
	goto vspexit
	end

-- Count the number of rows for this user, with Mod = "  " and SubFolder = 0.  Will return 0 or 1.

if exists(SELECT SubFolder FROM vDDSF WHERE Co = @co AND SubFolder = 0)
	begin
	select @rcode = @@rowcount
	goto vspexit
	end

-- We need to insert a row.

insert into vDDSF (Co, VPUserName, Mod, SubFolder, Title) VALUES (@co, '', '', 0, 'Company Name')


vspexit:
	return @rcode










GO
GRANT EXECUTE ON  [dbo].[vspVPMenuAddCompanyFolderRecord] TO [public]
GO
