CREATE TABLE [dbo].[vRPRL]
(
[Location] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[Path] [varchar] (512) COLLATE Latin1_General_BIN NOT NULL,
[LocType] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[ServerName] [varchar] (50) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [IX_vRPRL_Loc] ON [dbo].[vRPRL] ([Location]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[vtRPRLd] on [dbo].[vRPRL] for DELETE as 
/*-------------------------------------------------------------- 
 * Created: TL 6/13/05
 * Modified: GG 10/25/06 - check RPRTShared, add auditing 
 *  
 * Prevents deletions of Report Locations referenced by Report Titles
 * Audit deletions in bHQMA
 *--------------------------------------------------------------*/
declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15), 
         @errno tinyint, @audit bYN, @validcnt int, @validcnt2 int
 
select @numrows = @@rowcount 
if @numrows = 0 return
set nocount on
 
-- check if Location is in use on any standard or custom report
if exists(select top 1 1 from deleted d join RPRTShared o with (nolock) ON d.Location = o.Location)
    begin
    select @errmsg = 'Report Titles exist that use this Location'
    goto error
    end

-- audit
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vRPRL','Location: ' + Location, null, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted
   
return
 
error:
    select @errmsg = isnull(@errmsg,'') + ' - cannot delete Report Location.'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
 
 
 







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
CREATE trigger [dbo].[vtRPRLi] on [dbo].[vRPRL] for INSERT as
/**************************************************
 * Created: GG 10/25/06
 * Modified:
 *
 * Audits inserted Report Locations
 *
 *************************************************/
   
declare @numrows int, @errmsg  varchar(255)
   
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
   
-- audit   
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vRPRL','Location: ' + Location, null, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted 
   
return
   
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert Report Location'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[vtRPRLu] on [dbo].[vRPRL] for UPDATE as
/**********************************************************
 * Created: TL 6/13/05
 * Modified: GG 10/25/06 - check for primary key change, add auditing 
 *
 * Validates updated Report Location info
 * Audits changed values to bHQMA
 *
 ******************************************************/ 

 declare @numrows int, @errmsg varchar(255)
 
select @numrows = @@rowcount
if @numrows=0 return
set nocount on
 
-- check for primary key change
if update(Location)
	begin
	select @errmsg = 'You are not allowed to change Location'
    goto error
	end

-- audit
if update(Path)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRL', 'Location: ' + i.Location, null, 'C', 'Path', d.Path, i.Path, getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on i.Location = d.Location 
   	where i.Path <> d.Path
if update(LocType)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRL', 'Location: ' + i.Location, null, 'C', 'LocType',
		d.LocType, i.LocType, getdate(), SUSER_SNAME() 
   	from inserted i
	join deleted d on i.Location = d.Location 
   	where i.LocType <> d.LocType

return

error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update Report Location'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction

 
 
 
 







GO
