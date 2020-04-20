SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO












CREATE              PROCEDURE [dbo].[vspVPMenuRenameCompanySubfolder]
/**************************************************
* Created:  JK 12/09/03
* Modified:
*
* Used by VPMenu to rename a company-specific subfoler in the tree.
*
* The key of DDSF is  co + username + mod + subfolder (smallint), but
* for company-specific folders we only specify co + subfolder.
* We will change the Title field only.
*
* The output depends on the username being viewpointcs or other.
* 
* Inputs
*       @co			company nbr.
*	@subfolder		smallint
*	@title			New title for the subfolder. Up to 30 chars.
*
* Output
*	@errmsg
*
****************************************************/
	(@co bCompany = null, @subfolder smallint, @title varchar(30) = null, 
	 @errmsg varchar(512) output)
as

set nocount on 
declare @rcode int
select @rcode = 0

-- Check for required fields
if (@co is null or @subfolder is null or @title is null) 
	begin
	select @errmsg = 'Missing required field:  co, subfolder or title.', @rcode = 1
	goto vspexit
	end

if (@co = 0)
	begin
	select @errmsg = 'Company cannot be zero.', @rcode=2
	goto vspexit
	end

-- Subfolder has to be a value > 0.  (0 means a root-level folder, which isn't
-- a subfolder.)

if (@subfolder < 1)
	begin
	select @errmsg = 'Subfolder is less than 1.', @rcode=3
	goto vspexit
	end


-- Insert a row with the supplied data.
UPDATE DDSF SET Title = @title
WHERE Co = @co AND SubFolder = @subfolder
   
vspexit:
	return @rcode












GO
GRANT EXECUTE ON  [dbo].[vspVPMenuRenameCompanySubfolder] TO [public]
GO
