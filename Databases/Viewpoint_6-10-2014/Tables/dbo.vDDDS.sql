CREATE TABLE [dbo].[vDDDS]
(
[Datatype] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Qualifier] [tinyint] NOT NULL,
[Instance] [char] (30) COLLATE Latin1_General_BIN NOT NULL,
[SecurityGroup] [int] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[vtDDDSd] on [dbo].[vDDDS] for DELETE 
/*-----------------------------------------------------------------
* Created: GG 02/15/07
* Modified: 
*
* Delete trigger on vDDDS (DD Datatype Security).
*
* Removes user level data security entries (vDDDU) 
* Adds HQ Master Audit entry
* 
*/----------------------------------------------------------------
as

if @@rowcount = 0 return
set nocount on

-- remove User Data Security entries (vDDDU) for all users in the Security Group unless
-- they have access through another Security Group
delete dbo.vDDDU
from deleted t
join dbo.vDDSU s (nolock) on s.SecurityGroup = t.SecurityGroup
join dbo.vDDDU u (nolock) on u.Datatype = t.Datatype and u.Qualifier = t.Qualifier
   	and u.Instance = t.Instance
where s.VPUserName = u.VPUserName
	and not exists(select top 1 1 from dbo.vDDDS d (nolock)
					join dbo.vDDSU s2 (nolock) on d.SecurityGroup = s2.SecurityGroup 
   					where d.Datatype = t.Datatype and d.Qualifier = t.Qualifier and d.Instance = t.Instance
						and d.SecurityGroup <> t.SecurityGroup and s.VPUserName = s2.VPUserName)  

-- Master Audit 
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vDDDS', 'Datatype: ' + rtrim(Datatype) + ' Qualifier: ' + Convert(char(3),Qualifier) 
	+ ' Instance: ' + rtrim(Instance) + ' SecurityGroup: ' + Convert(char(5),SecurityGroup),
	Qualifier, 'D', null, null, null, getdate(), SUSER_SNAME() from deleted
   	
return
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE trigger [dbo].[vtDDDSi] on [dbo].[vDDDS] for INSERT
/*****************************
* Created: GG 02/15/07
* Modified: 
*
* Insert trigger on vDDDS (DD Datatype Security).  Rejects
* entries if any of the following error conditions exist:
*		Invalid Datatype
*		Invalid Security Group
*
* Adds user level data security entries (vDDDU) 
* Adds HQ Master Audit entry
*
*************************************/

as

declare @errmsg varchar(255), @numrows int, @validcnt int
  
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- validate Datatype
select @validcnt = count(*) 
from dbo.vDDDT t with (nolock)
join inserted i on t.Datatype = i.Datatype
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Datatype'
	goto error
	end
   
--validate Security Group
select @validcnt = count(*) 
from dbo.vDDSG g with (nolock)
join inserted i on g.SecurityGroup = i.SecurityGroup
where g.GroupType = 0	-- group type 0 used for data security
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Security Group'
	goto error
	end

-- add DD Data Security entries for all users in the Security Group
insert dbo.vDDDU (Datatype, Qualifier, Instance, VPUserName)
select i.Datatype, i.Qualifier, i.Instance, s.VPUserName
from inserted i
join dbo.vDDSU s with (nolock) on i.SecurityGroup = s.SecurityGroup
	and not exists (select top 1 1 from dbo.vDDDU u with (nolock)
    		where u.Datatype = i.Datatype and u.Qualifier = i.Qualifier
    		and u.Instance = i.Instance	and u.VPUserName = s.VPUserName)
   
-- Master Audit
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vDDDS', 'Datatype: ' + rtrim(Datatype) + ' Qualifier: ' + Convert(char(3),Qualifier) + ' Instance: ' + rtrim(Instance)
	+ ' SecurityGroup: ' + Convert(char(5),SecurityGroup), Qualifier,
	'A', null, null, null, getdate(), SUSER_SNAME()
from inserted
   
return
   
error:
    select @errmsg = isnull(@errmsg,'') + ' - cannot insert Data Security entries!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  trigger [dbo].[vtDDDSu] on [dbo].[vDDDS] for UPDATE
/************************************
* Created: GG 02/15/07
* Modified: 
*
* Update trigger on vDDDS (DD Group Level Data Security)
*
* All columns are key fields, no changes allowed
*
************************************/

as

declare @errmsg varchar(255), @numrows int, @validcnt int 
  
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
  
-- check for key changes 
select @validcnt = count(*) from inserted i
join deleted d	on i.Datatype = d.Datatype and i.Qualifier = d.Qualifier and i.Instance = d.Instance
	and i.SecurityGroup = d.SecurityGroup
if @validcnt <> @numrows
	begin
  	select @errmsg = 'Cannot change key fields Datatype, Qualifier, Instance, or Security Group'
  	goto error
  	end


return
  
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update Datatype Security!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
  
  
  
  
 










GO
CREATE UNIQUE CLUSTERED INDEX [viDDDS] ON [dbo].[vDDDS] ([Datatype], [Qualifier], [Instance], [SecurityGroup]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
