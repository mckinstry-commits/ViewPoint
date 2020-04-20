SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE view [dbo].[VASecurityByForm]
/**************************************************
* Created: ??
* Modified: GG 06/11/07 - #124784 - Modified for new V6 DD tables and views 
* Modified Charles Wirtz 11/28/2007 #126219
* Modified:  DH 11/2/2010 - Issue # 140848 - Added new column AttachmentSecurityLevel.
*			GF 02/19/2013 TFS-39904 show forms where license level <= module license level
*
* added join criteria "and s.VPUserName = ts.VPUserName" 
* and "su.SecurityGroup = ts.SecurityGroup" to vDDTS 
* to ensure duplicate records were not being selected
*
*
* Used in VA Security reports.
*
***************************************************/
as
select m.Mod
	, m.Title as 'ModTitle'
	, f.Form, f.Title as 'FormTitle'
	, s.VPUserName as 'UserName'
	--case s.SecurityGroup when -1 then '' else convert(varchar,s.SecurityGroup) end as 'SecurityGroup',
	, s.SecurityGroup as 'SecurityGroup'
	, g.[Name] as 'SecurityGroupName'
	, g.GroupType as 'GroupType'
	--case s.Co when -1 then 'All' else convert(varchar,s.Co) end as 'Company'
	, s.Co as 'Company', c.Name as 'CompanyName'
	, case s.Access when 0 then 'Full' when 1 then 'ByTab' when 2 then 'Denied' else 'None' end as 'FormAccess'
	, s.RecAdd, s.RecUpdate, s.RecDelete --, s.AllowAttachments
	, case  when s.AttachmentSecurityLevel = 0 then 'Add'
			when s.AttachmentSecurityLevel = 1 then 'Add, Edit'
			when s.AttachmentSecurityLevel = 2 then 'Add, Edit, Delete'
			else 'View Only'
	  end as AttachmentSecurityLevel
	, su.VPUserName as DDSUVPUserName
	, t.Tab, t.Title as 'TabTitle'
	, case ts.Access when 0 then 'Full' when 1 then 'ReadOnly' when 2 then 'Denied' else 'None' end as 'TabAccess' 
	, ts.VPUserName as DDTSVPUserName
from dbo.DDFHShared f (nolock)
----TFS-39904
left join dbo.vDDMO m (nolock) on m.Mod = f.Mod AND m.LicLevel <= f.LicLevel
left join dbo.vDDFS s (nolock) on f.Form = s.Form
left join dbo.bHQCO c (nolock) on c.HQCo = s.Co
left join dbo.vDDSG g (nolock) on s.SecurityGroup = g.SecurityGroup
left join dbo.vDDSU su (nolock) on su.SecurityGroup = g.SecurityGroup
left join dbo.DDFTShared t (nolock) on f.Form = t.Form and (f.FormType = 3 or t.Tab > 0)	-- exclude Grid tab on non-processing forms
left join dbo.vDDTS ts (nolock) on s.Co = ts.Co and t.Form = ts.Form and t.Tab = ts.Tab 	
and (s.VPUserName = ts.VPUserName or su.VPUserName = ts.VPUserName )
	and s.SecurityGroup = ts.SecurityGroup





GO
GRANT SELECT ON  [dbo].[VASecurityByForm] TO [public]
GRANT INSERT ON  [dbo].[VASecurityByForm] TO [public]
GRANT DELETE ON  [dbo].[VASecurityByForm] TO [public]
GRANT UPDATE ON  [dbo].[VASecurityByForm] TO [public]
GRANT SELECT ON  [dbo].[VASecurityByForm] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VASecurityByForm] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VASecurityByForm] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VASecurityByForm] TO [Viewpoint]
GO
