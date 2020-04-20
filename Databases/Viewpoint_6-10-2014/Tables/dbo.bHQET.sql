CREATE TABLE [dbo].[bHQET]
(
[EarnType] [dbo].[bEarnType] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[AnnualLimit] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bHQET_AnnualLimit] DEFAULT ((0))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE trigger [dbo].[btHQETd] on [dbo].[bHQET] for DELETE as
/*-----------------------------------------------------------------
* Created: DC 05/28/08
* Modified: 
*
* Validates and inserts HQ Master Audit entry.  Will rollback delete
* if entries exist in other tables
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount
set nocount on
if @numrows = 0 return

/* check EM Department */
if exists(select 1 from dbo.bEMDE a (nolock) join deleted d on a.EarnType = d.EarnType)
	begin
	select @errmsg = 'Entries exist in EM Department Earning Type for this HQ Earning Type'
	goto error
	end
/* check PR Earning Code */
if exists(select 1 from dbo.bPREC a (nolock) join deleted d on a.EarnType = d.EarnType)
	begin
	select @errmsg = 'Entries exist in PR Earning Code for this HQ Earning Type'
	goto error
	end
/* check PR Department Master */
if exists(select 1 from dbo.bPRDE a (nolock) join deleted d on a.EarnType = d.EarnType)
	begin
	select @errmsg = 'Entries exist in PR Department Master for this HQ Earning Type'
	goto error
	end
/* check JC Dept Master */
if exists(select 1 from dbo.bJCDE a (nolock) join deleted d on a.EarnType = d.EarnType)
	begin
	select @errmsg = 'Entries exist in JC Department Master for this HQ Earning Type'
	goto error
	end
/* check JB T&M Bill Line Sequences */
if exists(select 1 from dbo.bJBID a (nolock) join deleted d on a.EarnType = d.EarnType)
	begin
	select @errmsg = 'Entries exist in JB T&M Bill Line Sequences for this HQ Earning Type'
	goto error
	end
/* check JB T&M Template Labor Rates */
if exists(select 1 from dbo.bJBLR a (nolock) join deleted d on a.EarnType = d.EarnType)
	begin
	select @errmsg = 'Entries exist in JB T&M Template Labor Rates for this HQ Earning Type'
	goto error
	end
/* check JB T&M Template Labor Override */
if exists(select 1 from dbo.bJBLO a (nolock) join deleted d on a.EarnType = d.EarnType)
	begin
	select @errmsg = 'Entries exist in JB T&M Template Labor Override for this HQ Earning Type'
	goto error
	end
/* check JB T&M Template Setup */
if exists(select 1 from dbo.bJBTS a (nolock) join deleted d on a.EarnType = d.EarnType)
	begin
	select @errmsg = 'Entries exist in JB T&M Template Setup for this HQ Earning Type'
	goto error
	end

/* Audit HQ Earning Type deletions */
insert dbo.bHQMA(TableName, KeyString, Co, RecType,
	FieldName, OldValue, NewValue, DateTime, UserName)
select 'bHQET', 'EarnType: ' + convert(varchar(10),EarnType), null, 'D',
	null, null, null, getdate(), SUSER_SNAME()
from deleted

return

error:
	select @errmsg = @errmsg + ' - cannot delete HQ Earning Type!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btHQETu    Script Date: 8/28/99 9:37:33 AM ******/
   CREATE  trigger [dbo].[btHQETu] on [dbo].[bHQET] for UPDATE as
   

declare @errmsg varchar(255), @numrows int, @validcount int
   
   /*-----------------------------------------------------------------
    *	This trigger rejects update in bHQET (HQ Earnings Types)
   
    *	if the following error condition exists:
    *
    *		Cannot change HQ EarnType
    *
    */----------------------------------------------------------------
   
   /* initialize */
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* reject key changes */
   select @validcount = count(*) from deleted d, inserted i
   	where d.EarnType = i.EarnType
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Cannot change HQ Earnings Type'
   	goto error
   	end
   
   return
   
   error:
   		
   	select @errmsg = @errmsg + ' - cannot update HQ Earnings Type!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biHQET] ON [dbo].[bHQET] ([EarnType]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQET] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
