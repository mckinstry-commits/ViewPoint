SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[VASecurityByForm]
/**************************************************
* Created: ??
* Modified: GG 06/11/07 - #124784 - Modified for new V6 DD tables and views 
* Modified Charles Wirtz 11/28/2007 #126219
* added join criteria "and s.VPUserName = ts.VPUserName" 
* and "su.SecurityGroup = ts.SecurityGroup" to vDDTS 
* to ensure duplicate records were not being selected
*
* Modified:  DH 11/2/2010 - Issue # 140848 - Added new column AttachmentSecurityLevel.
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
left join dbo.vDDMO m (nolock) on m.Mod = f.Mod
left join dbo.vDDFS s (nolock) on f.Form = s.Form
left join dbo.bHQCO c (nolock) on c.HQCo = s.Co
left join dbo.vDDSG g (nolock) on s.SecurityGroup = g.SecurityGroup
left join dbo.vDDSU su (nolock) on su.SecurityGroup = g.SecurityGroup
left join dbo.DDFTShared t (nolock) on f.Form = t.Form and (f.FormType = 3 or t.Tab > 0)	-- exclude Grid tab on non-processing forms
left join dbo.vDDTS ts (nolock) on s.Co = ts.Co and t.Form = ts.Form and t.Tab = ts.Tab 	
and (s.VPUserName = ts.VPUserName or su.VPUserName = ts.VPUserName )
	and s.SecurityGroup = ts.SecurityGroup


-- old 5.x version
--    SELECT
--        DDMS.Mod, DDFH.Form, 'FormTitle'=DDFH.Title, 'UserName'=name,
--        'Company'= DDMS.Co, 'CompanyName'=HQCO.Name, SecByForm,
--       'FormReadOnly'= Case DDFS.SecLvl when 1 then 'ReadOnly' else '' end,
--       DDFS.SecByTab, DDTS.Tab,'TabTitle'=DDFT.Title,
--       'TabReadOnly'=Case DDTS.SecLvl when 1 then 'ReadOnly' else '' end
--    
--    FROM
--        (dbo.DDFH DDFH
--        Join dbo.DDMS DDMS on DDMS.Mod=substring(DDFH.Form,1,2)
--        Join dbo.bHQCO HQCO on HQCO.HQCo=DDMS.Co
--        Join dbo.DDUP DDUP ON DDMS.VPUserName=DDUP.name
--        Left Join dbo.DDFS DDFS on DDFS.Form=DDFH.Form and DDFS.VPUserName=DDUP.name and DDFS.Co=DDMS.Co)
--        Left Join dbo.DDTS DDTS on DDTS.Form=DDFS.Form and DDTS.Co=DDFS.Co and DDTS.VPUserName=DDFS.VPUserName
--        Left Join dbo.DDFT DDFT on DDFT.Form = DDTS.Form and DDFT.Tab=DDTS.Tab
--    where DDFH.Form=case when DDMS.SecByForm=1 then DDFS.Form else DDFH.Form end




GO
GRANT SELECT ON  [dbo].[VASecurityByForm] TO [public]
GRANT INSERT ON  [dbo].[VASecurityByForm] TO [public]
GRANT DELETE ON  [dbo].[VASecurityByForm] TO [public]
GRANT UPDATE ON  [dbo].[VASecurityByForm] TO [public]
GO
