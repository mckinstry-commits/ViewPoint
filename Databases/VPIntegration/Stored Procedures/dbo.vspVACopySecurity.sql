SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[vspVACopySecurity]
/**************************************************************
* Created: LM 07/03/96
* Modified: 04/30/99 JRE - make sure Forms & Reports exist
*			06/15/99 LM - modified to use username instead of user id for SQL 7.0 change
*			01/11/00 LM - changed for report security by company enhancement
*			02/20/00 JRE - don't copy if company is not in HQCO
*			08/17/2000 DANF - remove system user idk
*			12/8/00 DANF added copy of security groups
*			06/11/01 RICKM Added copy for Payroll Group Security
*			06/17/02 SR - added new input parameter, Overwrite, and put deletes in Condition block if Overwrite 
*   			is Yes (Issue 16400)
*			7/10/2 kb - issue #17858 - added to restrict DDFT to be for t.DetailTabYN = 'N' only
*			10/08/02 danf - 16400 Added check for existance of security detail. 
*			11/14/02 danf - 16400 Do not insert form security if the user does not have acces to the module.
*			03/19/04 danf - 20980 Expand Security Group
*			??/??/?? ?? - Converted this stored proc for VP6.
*			09/29/06 JRK - Changed "vHQCO" and "vPRGS" back to "bHQCO" and "bPRGS". Handle cases where Co=-1 in the 'from" row.
*			11/19/06 AL - Added AllowAttachments to DDFS insert section
*			3/19/08  AL - Changed report copying to use RPRTShared rather than vRPRT
*			06/10/08 JonathanP - See issue #128467. Attachment type security will now be copied.
*			7/21/08  AL - DDFS and DDTS Sections now use DDFHShared and DDFTShared issue #128987
*			7/24/08  AL - #128543 - Replaced pseudo-cursor in DDSU section. Removed transaction. Replaced cursor in PRGS section issue 
*			7/25/08  GG - additional cleanup for #128543
*			7/30/08 - GG - added 'distinct' to the insert quueries to avoid duplicates
*			7/30/08 - GG - #129266 - fix tab security copy
*			2/2/09	-	AL - #131035 - Added template security.
*	    	02/25/09 - JonathanP - #132390 - Updated to handle attachment security level column in DDFS
*
* Purpose:	
*	Copies Form, Tab, Report, Attachments, and Data Security from one user to another
*
* Inputs:
*	@tousername				'Copy To' User Name
*	@fromusername			'Copy From' User Name
*	@OverWrite				Y = remove all existing security before copy, N = leave existing security entries
*
* Output:
*	@msg					Error message
*
* Return code:
*	@rcode					0 = success, 1 = error
* 
**************************************************************/
   
   (@tousername bVPUserName = null, @fromusername bVPUserName = null, @OverWrite bYN, @msg varchar(60) output)
		 
as
set nocount on
   
declare @rcode int, @validcnt int, @securitygroup smallint,@prco bCompany, @prgroup bGroup
select @rcode = 0

-- validate input parameters   
if @tousername is null
	begin
	select @msg = 'Missing Copy To Username!', @rcode = 1
	goto vspexit
	end
if @fromusername is null
	begin
	select @msg = 'Missing Copy From Username!', @rcode = 1
	goto vspexit
	end
if not exists(select top 1 1 from dbo.vDDUP (nolock) where VPUserName = @tousername)
	begin
	select @msg = 'User ' + @tousername + ' not on file!', @rcode = 1
	goto vspexit
	end
if not exists(select top 1 1 from dbo.vDDUP (nolock) where VPUserName = @fromusername)
	begin
	select @msg = 'User ' + @fromusername + ' not on file!', @rcode = 1
	goto vspexit
	end
   
-- overwritting user's current security settings, remove existing entries   
if @OverWrite = 'Y'		
	begin
	-- delete user's tab security
	if exists(select top 1 1 from dbo.vDDTS (nolock) where VPUserName = @tousername)
   		delete dbo.vDDTS where VPUserName=@tousername
   		
    -- delete user's form security
	if exists(select top 1 1 from dbo.vDDFS (nolock) where VPUserName = @tousername)
   		delete dbo.vDDFS where VPUserName=@tousername
   		
    -- delete user's report security
    if exists(select top 1 1 from dbo.vRPRS (nolock) where VPUserName = @tousername)
   		delete dbo.vRPRS where VPUserName = @tousername
   		
	-- delete user's attachment type security - #128467
	if exists(select top 1 1 from dbo.vVAAttachmentTypeSecurity (nolock) where VPUserName = @tousername)
   		delete dbo.vVAAttachmentTypeSecurity where VPUserName = @tousername
   		
   	-- delete user's Payroll Group assignments
   	if exists(select top 1 1 from dbo.bPRGS where VPUserName = @tousername)
   		delete dbo.bPRGS where VPUserName = @tousername

	-- delete user's security group assignments 
	if exists(select top 1 1 from dbo.vDDSU with (nolock) where VPUserName = @tousername)
   		delete dbo.vDDSU where VPUserName = @tousername
   		
   	-- delete user's data security (removed by delete trigger on vDDSU, but OK to delete here as well)
	if exists(select top 1 1 from dbo.vDDDU with (nolock) where VPUserName=@tousername)
   		delete dbo.vDDDU where VPUserName = @tousername

	end
   
------------- Form Security  -----------------
-- add User level Form Security - (Security Group = -1)
insert dbo.vDDFS(Co, Form, VPUserName, SecurityGroup, Access, RecAdd, RecUpdate, RecDelete, AttachmentSecurityLevel)
select distinct s.Co, s.Form, @tousername, -1, s.Access, s.RecAdd, s.RecUpdate, s.RecDelete, s.AttachmentSecurityLevel
from dbo.vDDFS s 
join dbo.DDFHShared f (nolock) on f.Form = s.Form	-- must be a valid Form
join dbo.bHQCO c (nolock) on c.HQCo = case s.Co when -1 then c.HQCo else s.Co end	-- must be a valid HQ Co# or -1 (all companies)
where s.VPUserName = @fromusername 
	-- avoid duplicates
	and not exists(select top 1 1 from dbo.vDDFS d 
					where s.Co = d.Co and s.Form = d.Form and d.VPUserName = @tousername and d.SecurityGroup = -1)

------------- Tab Security ------------------
-- add User level Tab Security - (Security Group = -1)
insert dbo.vDDTS(Co, Form, Tab, VPUserName, SecurityGroup, Access)
select distinct s.Co, s.Form, s.Tab, @tousername, -1, s.Access
from dbo.vDDTS s  
join dbo.DDFTShared t (nolock) on t.Form = s.Form and t.Tab = s.Tab	-- must be a valid Form Tab
join dbo.bHQCO c (nolock) on c.HQCo = case s.Co when -1 then c.HQCo else s.Co end	-- must be a valid HQ Co# or -1 (all companies)
where s.VPUserName = @fromusername 
	-- avoid duplicates
	and not exists(select top 1 1 from dbo.vDDTS d 
					where s.Co = d.Co and s.Form = d.Form and s.Tab = d.Tab and d.VPUserName = @tousername and d.SecurityGroup = -1) 
	-- don't add unless user's form level access is 'by tab' - (Access = 1)
	and exists (select top 1 1 from dbo.vDDFS f 
					where f.Co = s.Co and f.Form = s.Form and f.VPUserName = @tousername and f.SecurityGroup = -1 and f.Access = 1)

-------------- Report Security -----------------
-- add User level Report Security - (Security Group = -1)
insert dbo.vRPRS ( Co, VPUserName, ReportID, SecurityGroup, Access)
select distinct s.Co, @tousername, s.ReportID, -1, s.Access
from dbo.vRPRS s 
join dbo.RPRTShared t (nolock) on t.ReportID = s.ReportID	-- must be a valid Report
join dbo.bHQCO c (nolock) on c.HQCo = case s.Co when -1 then c.HQCo else s.Co end	-- must be a valid HQ Co# or -1 (all companies)
where s.VPUserName = @fromusername
	-- avoid duplicates
	and not exists(select top 1 1 from dbo.vRPRS d 
					where s.Co = d.Co and s.ReportID = d.ReportID and d.VPUserName=@tousername and d.SecurityGroup = -1)
   
------------ Attachment Type Security #128467 -------------------
-- add User level Attachment Security - (Security Group = -1)
insert dbo.vVAAttachmentTypeSecurity (Co, VPUserName, AttachmentTypeID, SecurityGroup, Access)
select distinct s.Co, @tousername, s.AttachmentTypeID, -1, s.Access
from dbo.vVAAttachmentTypeSecurity s 
join dbo.DMAttachmentTypesShared t (nolock) on t.AttachmentTypeID = s.AttachmentTypeID	-- must be a valid Attachment Type
join dbo.bHQCO c (nolock) on c.HQCo = case s.Co when -1 then c.HQCo else s.Co end	-- must be a valid HQ Co# or -1 (all companies)
where s.VPUserName = @fromusername
	-- avoid duplicates
	and not exists(select top 1 1 from dbo.vVAAttachmentTypeSecurity d
					where s.Co = d.Co and s.AttachmentTypeID = d.AttachmentTypeID and d.VPUserName = @tousername and d.SecurityGroup = -1)

	
----------- Payroll Group assignments ------------
insert dbo.bPRGS(PRCo, PRGroup, VPUserName)   
select s.PRCo, s.PRGroup, @tousername
from dbo.bPRGS s
where s.VPUserName = @fromusername
	-- avoid duplicates
	and not exists(select top 1 1 from dbo.bPRGS g where s.PRCo = g.PRCo and s.PRGroup = g.PRGroup and g.VPUserName = @tousername)
					
	
------------ Security Group assignments ------------
insert dbo.vDDSU (SecurityGroup, VPUserName)
select s.SecurityGroup, @tousername
from dbo.vDDSU s
where s.VPUserName = @fromusername 
	-- avoid duplicates
	and not exists(select top 1 1 from dbo.vDDSU u where s.SecurityGroup = u.SecurityGroup and u.VPUserName = @tousername)
 
-------------- Query Security -----------------
insert dbo.VPQuerySecurity (Co, QueryName, SecurityGroup, VPUserName, Access)
select distinct s.Co, s.QueryName, -1, @tousername, s.Access
from dbo.VPQuerySecurity s 
join dbo.bHQCO c (nolock) on c.HQCo = case s.Co when -1 then c.HQCo else s.Co end	-- must be a valid HQ Co# or -1 (all companies)
where s.VPUserName = @fromusername
	-- avoid duplicates
	and not exists(select top 1 1 from dbo.VPQuerySecurity d 
					where s.Co = d.Co and s.QueryName = d.QueryName and d.VPUserName=@tousername and d.SecurityGroup = -1)
 
 
---------------Template Security ---------------
insert dbo.VPCanvasTemplateSecurity (Co, TemplateName, SecurityGroup, VPUserName, Access)
select distinct s.Co, s.TemplateName, -1, @tousername, s.Access
from dbo.VPCanvasTemplateSecurity s 
join dbo.bHQCO c (nolock) on c.HQCo = case s.Co when -1 then c.HQCo else s.Co end	-- must be a valid HQ Co# or -1 (all companies)
where s.VPUserName = @fromusername
	-- avoid duplicates
	and not exists(select top 1 1 from dbo.VPCanvasTemplateSecurity d 
					where s.Co = d.Co and s.TemplateName = d.TemplateName and d.VPUserName=@tousername and d.SecurityGroup = -1)
 
vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspVACopySecurity] TO [public]
GO
