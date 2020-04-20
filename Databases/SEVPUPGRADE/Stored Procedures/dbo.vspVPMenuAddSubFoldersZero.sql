SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










CREATE                PROCEDURE [dbo].[vspVPMenuAddSubFoldersZero]
/**************************************************
* Created:  JRK 07/24/03
* Modified: JRK 12/12/03 - Inserts missing records instead of just test if one existed.
*
* Used by VPMenu to ensure that rows exist with zero in the SubFolder field.
*
* The key of vDDSF is  company + username + mod + subfolder (smallint).  We use 0 for Company and SubFolder,
* "  " for Mod, and the user's name for VPUserName.
*
* There is no output.
* 
* Inputs
*       @username		Needed since we use a system connection.
*
* Output
*	@errmsg
*
****************************************************/
	(@username varchar(128) = null, @errmsg varchar(512) output)
as

set nocount on 
declare @rcode int
select @rcode = 0

-- Check for required fields
if (@username is null) 
	begin
	select @errmsg = 'Missing required field:  username.', @rcode = 1
	goto vspexit
	end


-- Insert a row into vDDSF for each mod defined in vDDMO, if not already there.
-- This inserts only those records into vDDSF that do not already exist.
--   Company will be 0.
--   VPUserName comes from the argument @username.
--   SubFolder will be 0
--   Mod and Title come from vDDMO.
insert into vDDSF (Co, VPUserName, Mod, SubFolder, Title, ViewOptions) 
select 0, @username, mo.Mod, 0, mo.Title, null from vDDMO mo
where mo.Mod not in
(select Mod from vDDSF sf
where sf.VPUserName = @username and sf.SubFolder = 0)


-- Add one more record for My Viewpoint ("  "), if needed.
declare @mod char(2)
select @mod = Mod from vDDSF
where Mod = '  ' and Co = 0 and VPUserName = @username and SubFolder = 0

-- Does the record exist?
if @@rowcount = 0
	begin 
	-- Does not exist, so insert it.
	insert into vDDSF (Co, VPUserName, Mod, SubFolder, Title, ViewOptions) 
	VALUES (0, @username, '  ', 0, 'My Viewpoint', null)
	end

vspexit:
	return @rcode












GO
GRANT EXECUTE ON  [dbo].[vspVPMenuAddSubFoldersZero] TO [public]
GO
