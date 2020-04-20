SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspVADDFSList]
-- =============================================
-- Created:	GG 10/30/07	
-- Modified:  
--
-- Used by VA Form Security to retrieve form access info for one or more Security Groups, Modules, and Companiess
--
-- Inputs:
--	@type			Return entries for Security Groups ('G'), Users ('U'), or Forms ('F')
--	@NameArray		comma separated list of Security Group Titles, User Names, or Forms depending on Type (should be changed to use Group #s)
--	@ModArray		comma separated list of Modules (e.g. 'AP,AR,CM')
--	@CoArray		comma separated list of Companies (-1 used for 'all' companies)
--
-- =============================================

(@type char(1), @NameArray varchar(8000),@ModArray varchar(8000), @CoArray varchar(8000)) 

as

set nocount on

-- table variables
declare @allcos table (Co smallint)
declare @groupsandusers table (Name varchar(128), SecGroup smallint)
declare @names table (Name varchar(60))
declare @mods table (Mod varchar(2))
declare @cos table (Co smallint)

declare @i int, @workstring varchar(8000)

-- load a table variable with all existing Co#s and -1 ('all' company)
insert @allcos(Co)
select HQCo from dbo.bHQCO (nolock)
union
select -1

-- load a table variable with all Form Security Groups and VPUserNames
insert @groupsandusers (Name, SecGroup)
select VPUserName, -1	-- Security Group is -1 for all User entries
from dbo.vDDUP (nolock)
union
select Name, SecurityGroup
from dbo.vDDSG (nolock)
where GroupType = 1	-- Form Security 
 
-- convert Names Array to table variable for perfomance (Security Group Titles, VPUserNames, or Forms)
set @i = 1
while @i <> 0
	begin
	select @i = charindex(',',@NameArray)
	if @i > 0
		select @workstring = left(@NameArray,@i-1)
	else
		select @workstring = @NameArray
	insert @names(Name) values(@workstring)
	select @NameArray = right(@NameArray,len(@NameArray)-@i)
	if len(@NameArray) = 0 break
	end
	
-- convert Modules Array to table variable for performance
set @i = 1
while @i <> 0
	begin
	select @i = charindex(',',@ModArray)
	if @i > 0
		select @workstring = left(@ModArray,@i-1)
	else
		select @workstring = @ModArray
	insert @mods(Mod) values(@workstring)
	select @ModArray = right(@ModArray,len(@ModArray)-@i)
	if len(@ModArray) = 0 break
	end
	
-- convert Company Array to table variable for performance
set @i = 1
while @i <> 0
	begin
	select @i = charindex(',',@CoArray)
	if @i > 0
		select @workstring = left(@CoArray,@i-1)
	else
		select @workstring = @CoArray
	insert @cos(Co) values(@workstring)
	select @CoArray = right(@CoArray,len(@CoArray)-@i)
	if len(@CoArray) = 0 break
	end
	
if @type = 'G'	-- Form Security by Group (replaces vspVADDFSGroupRefresh)
	begin
	select distinct m.Mod, c.Co AS Co, g.Name, f.Title, f.Form, isnull(s.Access, 3) AS Access, -- 3 = no access
		isnull(s.RecAdd, 'N') AS RecAdd, isnull(s.RecUpdate, 'N') AS RecUpdate,
		isnull(s.RecDelete, 'N') AS RecDelete , s.AttachmentSecurityLevel, --isnull(s.AllowAttachments, 'N') AS AllowAttachments,
		g.SecurityGroup, f.FormType
	from dbo.DDFHShared f (nolock)			-- vDDFHSecureable is no longer needed
	join dbo.DDMFShared m (nolock) on f.Form = m.Form
	join dbo.vDDMO o (nolock) on o.Mod = m.Mod and o.Active = 'Y' and o.Mod in (select Mod from @mods)
	join dbo.vDDSG g (nolock) on g.Name in (select Name from @names) and g.GroupType = 1   -- Form Security 
	cross join @cos c 
	left join dbo.vDDFS s (nolock) on s.Co = c.Co and f.Form = s.Form and s.SecurityGroup = g.SecurityGroup
	where (f.Form = f.SecurityForm or f.DetailFormSecurity = 'Y')
	order by g.SecurityGroup, c.Co, f.Title
	end
	
if @type = 'U'	-- Form Security by User	(replaces vspVADDFSUserRefresh2)
	begin
	select distinct m.Mod, c.Co AS Co, u.VPUserName, f.Title, f.Form, isnull(s.Access, 3) AS Access, -- 3 = no access
		isnull(s.RecAdd, 'N') AS RecAdd, isnull(s.RecUpdate, 'N') AS RecUpdate,
		isnull(s.RecDelete, 'N') AS RecDelete , s.AttachmentSecurityLevel, --isnull(s.AllowAttachments, 'N') AS AllowAttachments,
		-1 as SecurityGroup, f.FormType
	from dbo.DDFHShared f (nolock) 
	join dbo.DDMFShared m (nolock) on f.Form = m.Form
	join dbo.vDDMO o (nolock) on o.Mod = m.Mod and o.Active = 'Y' and o.Mod in (select Mod from @mods)
	join dbo.vDDUP u (nolock) on u.VPUserName in (select Name from @names)
	cross join @cos c 
	left join dbo.vDDFS s (nolock) on s.Co = c.Co and f.Form = s.Form and s.VPUserName = u.VPUserName
	where (f.Form = f.SecurityForm or f.DetailFormSecurity = 'Y')
	order by u.VPUserName, c.Co, f.Title
	end
	
if @type = 'F'	-- Form Secuity by Form	(replaces vspVSDDFSFormRefresh)
	begin
	select distinct f.Mod, c.Co AS Co, g.Name, f.Title, f.Form, isnull(s.Access, 3) AS Access,
		isnull(s.RecAdd, 'N') AS RecAdd, isnull(s.RecUpdate, 'N') AS RecUpdate, 
		isnull(s.RecDelete, 'N') AS RecDelete , s.AttachmentSecurityLevel, --isnull(s.AllowAttachments, 'N') AS AllowAttachments,
		g.SecGroup, f.FormType
	from dbo.DDFHShared f (nolock) 
	join dbo.DDMFShared m (nolock) on f.Form = m.Form
	join dbo.vDDMO o (nolock) on o.Mod = m.Mod and o.Active = 'Y' and o.Mod in (select Mod from @mods)
	cross join @cos c 
	cross join @groupsandusers g
	left join dbo.vDDFS s (nolock) on s.Co = c.Co and f.Form = s.Form and (s.VPUserName = g.Name or s.SecurityGroup = g.SecGroup)
	where (f.Form = f.SecurityForm or f.DetailFormSecurity = 'Y')
		and f.Form in (select Name from @names)
	order by g.SecGroup, c.Co
	end
	
vspexit:
	return 
	
	
	
	

	
	
	
	





















GO
GRANT EXECUTE ON  [dbo].[vspVADDFSList] TO [public]
GO
