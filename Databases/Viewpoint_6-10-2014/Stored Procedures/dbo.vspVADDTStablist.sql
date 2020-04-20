SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspVADDTStablist]
/************************************************************************
* Created: AL 8/1/07 
* Modified: GG 08/16/07 - cleanup
*		TJL 03/24/09 - Issue #132867 - ANSI Null evaluating FALSE instead of TRUE
*		CC	07/16/09 - #129922 - Added link for culture text
*		AL 09/27/12 - Changed group to Int	
* Usage:
*	Returns tab security information for a specific Company, Form, User and/or Security Group
*
* Inputs:
*	@Company		Company # (-1 used for 'all' company entries)
*	@Form			Form name
*	@uname			VP User Name
*	@secgroup		Security Group
*
* Outputs:
*	@msg			Error message 
*	resultset of tab security info
*
* Return code:
*	0 = success, 1 = error
*
* **************************************************************************/
 	(	@Company smallint = null, 
 		@Form varchar(30) = null, 
 		@uname bVPUserName = null,
		@secgroup int = null, 
		@culture INT = NULL,
		@msg varchar(256) output)
as
 
set nocount on
declare @validcnt int, @rcode int
select @rcode = 0
 

if not exists(select top 1 1 from dbo.DDFHShared (nolock) where  Form=@Form)
	begin
 	select @msg = 'Invalid Form', @rcode = 1
 	goto vspexit
 	end
if @Company is null
	begin
	select @msg = 'Missing Company #', @rcode = 1
	goto vspexit
	end
if @Company <> -1	-- -1 used for all company entries
	begin
	if not exists(select top 1 1 from dbo.bHQCO (nolock) where HQCo=@Company)
 		begin
 		select @msg = 'Company not in HQCO!', @rcode = 1
 		goto vspexit
 		end
	end
if @uname is null
	begin
	select @msg = 'Missing User Name!', @rcode = 1
	goto vspexit
	end
if @secgroup is null
	begin
	select @msg = 'Missing Security Group!', @rcode = 1
	goto vspexit
	end

if @uname = ''	-- user name is '' when security by group
	begin
	if not exists(select top 1 1 from dbo.vDDSG (nolock)
				where SecurityGroup = @secgroup and GroupType = 1)	-- form security group type
 		begin
 		select @msg = 'Invalid Security Group', @rcode = 1
 		goto vspexit
 		end
	end
else
	begin
	if not exists(select top 1 1 from dbo.vDDUP (nolock) where VPUserName = @uname)
	 	begin
 		select @msg = 'Invalud User Name!', @rcode = 1
 		goto vspexit
 		end
	end 

-- make sure Form Security is by Tab 
if not exists(select top 1 1 from dbo.vDDFS (nolock) 
				where Co = @Company and Form = @Form and SecurityGroup = @secgroup
					and VPUserName = @uname and Access = 1)	-- tab level access
 	begin
 	select @msg = 'Security is not by tab for this Company, Form, and Group/User combination!', @rcode = 1
 	goto vspexit
 	end
 
-- get Tab Security info, include all but the (0) Grid tab 
select	h.Tab, 
		ISNULL(CultureText.CultureText, h.Title) AS Title, 
		case when t.Access is null then 3 else t.Access end as [Access],
		h.Tab
from dbo.DDFTShared h (nolock)
left join dbo.vDDTS t (nolock) on t.Co = @Company and t.Form = h.Form and t.Tab = h.Tab
	and t.SecurityGroup = @secgroup and t.VPUserName = @uname
LEFT OUTER JOIN dbo.DDCTShared AS CultureText ON h.TitleID = CultureText.TextID AND CultureText.CultureID = @culture
where h.Form = @Form and h.GridForm is null and h.Tab <> 0		-- exclude related grid forms and Grid tab
 

vspexit:
 	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspVADDTStablist] TO [public]
GO
