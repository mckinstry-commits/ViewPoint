CREATE TABLE [dbo].[vRPRS]
(
[Co] [smallint] NOT NULL,
[ReportID] [int] NOT NULL,
[SecurityGroup] [int] NOT NULL,
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[Access] [tinyint] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE trigger [dbo].[vtRPRSd] on [dbo].[vRPRS] for DELETE as

/*-----------------------------------------------------------------
*	Created:  SEANE 3/18/2004 - 23822  Added auditing to bHQMA
*	Modified: GG 01/20/06 - convert Co for bCompany datatype
*		
*/----------------------------------------------------------------
 
if @@rowcount = 0 return
set nocount on
 
 /* Audit deletions to bHQMA*/
insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vRPRS', 'Co # ' + isnull(convert(varchar,Co),'') + ' VPUsername: ' + isnull(VPUserName,'') + ' ReportID: ' + isnull(convert(varchar,ReportID),'') + ' Security Group:  ' + isnull(convert(varchar,SecurityGroup),''),
 	case Co when -1 then null else Co end,	-- convert for bCompany datatype 
	'D', null, null, null, getdate(), SUSER_SNAME()
from deleted
 	
 return


 
 
 
 







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE trigger [dbo].[vtRPRSi] on [dbo].[vRPRS] for Insert as
/*-----------------------------------------------------------------
* Created:  SEANE 3/18/2004 - 23822  Added auditing to bHQMA
* Modified: GG 06/19/07 - added validation, cleanup auditing
*		
* Insert trigger on RP Report Security table (vRPRT) 		
*
*/----------------------------------------------------------------

declare @errmsg varchar(255), @numrows int, @validcnt int, @usercnt int 

select @numrows = @@rowcount
if @numrows = 0 return 
 
set nocount on

/* check for valid Companies */
select @usercnt = count(*) from inserted where Co = -1		-- all company entries
select @validcnt = count(*)
from dbo.bHQCO c (nolock)
join inserted i on c.HQCo = i.Co
if @validcnt + @usercnt <> @numrows
	begin
 	select @errmsg = 'Invalid Company'
 	goto error
 	end
/* check for valid ReportIDs */
select @validcnt = count(*)
from RPRTShared r (nolock)
join inserted i on r.ReportID = i.ReportID
if @validcnt <> @numrows
 	begin
 	select @errmsg = 'Invalid ReportID#'
 	goto error
 	end
-- check for mixed Group and User entries
if exists(select top 1 1 from inserted where SecurityGroup = -1 and VPUserName = '')
	or exists(select top 1 1 from inserted where SecurityGroup <> -1 and VPUserName <> '')
	begin
	select @errmsg = 'Security Group and User information cannot be mixed on the the same record'
	goto error
	end

-- validate Security Group
select @usercnt = count(*) from inserted where SecurityGroup = -1	-- user override entries
select @validcnt = count(*)
from inserted i
join dbo.vDDSG g (nolock) on i.SecurityGroup = g.SecurityGroup
where g.GroupType = 2	-- report groups
if @usercnt + @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Security Group'
	goto error
	end
 
-- validate User
select @usercnt = count(*) from inserted where VPUserName = ''
select @validcnt = count(*)
from inserted  i
join dbo.vDDUP u (nolock) on u.VPUserName = i.VPUserName
if @validcnt + @usercnt <> @numrows
 	begin
 	select @errmsg = 'Invalid user'
 	goto error
 	end

-- validate Report Access
if exists(select top 1 1 from inserted where Access not in (0,2))
	begin
	select @errmsg = 'Invalid Report Access level, must be ''0=allowed'' or ''2=denied'''
	goto error
	end
if exists(select top 1 1 from inserted where VPUserName = '' and Access = 2)
	begin
	select @errmsg = 'Invalid Access level, cannot be ''2=denied'' for Security Groups'
	goto error
	end

-- /* Audit adds to bHQMA*/
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vRPRS', 'Co: ' + convert(varchar,Co)+' ReportID: ' + convert(varchar,ReportID) + ' Security Group:  ' + convert(varchar,SecurityGroup) + ' VPUsername: ' + VPUserName,
 	null, 'A', null, null, null, getdate(), SUSER_SNAME() from inserted 

return
 
error:
	select @errmsg = @errmsg + ' - cannot insert Report Security!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
 
 
 	

 
 
 
 






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE trigger [dbo].[vtRPRSu] on [dbo].[vRPRS] for UPDATE as
/*-----------------------------------------------------------------
* Created: ??
* Modified: GG 07/27/07 - added Access validation, auditing, cleanup
*
* This trigger rejects update in vRPRS (Report Security) if any
*	of the following error conditions exist:
*
*		Cannot change primary key
*		Invalid Access level
*
*/----------------------------------------------------------------
 
declare @errmsg varchar(255), @numrows int, @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
 
/* check for changes to Report Title or User */
select @validcnt = count(*)
from inserted i
join deleted d on i.Co = d.Co and i.ReportID = d.ReportID and i.SecurityGroup = d.SecurityGroup
	and i.VPUserName = d.VPUserName
if @validcnt <> @numrows
	begin
	select @errmsg = 'Cannot change Company#, Report ID#, Security Group, or User'
	goto error
	end

-- validate Access level
if exists(select top 1 1 from inserted where SecurityGroup = -1 and Access not in (0,2))
	begin
	select @errmsg = 'Invalid Access level.  Must be ''0=allowed'' or ''2=denied'' for User entries.'
	goto error
	end
if exists(select top 1 1 from inserted where SecurityGroup <> -1 and Access <> 0)
	begin
	select @errmsg = 'Invalid Access level.  Must be ''0=allowed'' for Security Group entries.'
	goto error
	end

/* Audit updates */
if update(Access)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRS', 'Co: ' + convert(varchar,i.Co)+' ReportID: ' + convert(varchar,i.ReportID) + ' Security Group:  ' 
		+ convert(varchar,i.SecurityGroup) + ' VPUsername: ' + i.VPUserName,
		null, 'C', 'Access', convert(varchar,d.Access), convert(varchar,i.Access), getdate(),
 		case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
 	from inserted i
	join deleted d on i.Co = d.Co and i.ReportID = d.ReportID and i.SecurityGroup = d.SecurityGroup	and i.VPUserName = d.VPUserName
 	where i.Access <> d.Access
 
return
 
 
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update Report Security!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
 
 
 
 
 





GO
CREATE UNIQUE CLUSTERED INDEX [viRPRS] ON [dbo].[vRPRS] ([Co], [ReportID], [SecurityGroup], [VPUserName]) ON [PRIMARY]
GO
