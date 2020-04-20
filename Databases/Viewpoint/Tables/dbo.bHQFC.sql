CREATE TABLE [dbo].[bHQFC]
(
[Frequency] [dbo].[bFreq] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biHQFC] ON [dbo].[bHQFC] ([Frequency]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQFC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
CREATE trigger [dbo].[btHQFCd] on [dbo].[bHQFC] for DELETE as
/*----------------------------------------------------------
* Created: DC  04/17/09  <--???
* Modified:  TJL  12/18/08 - Issue #131499, Fixed conversion error during record delete.
*
*
*
*	This trigger rejects delete in bHQFC (HQ Freqency Codes) if a
*	dependent record is found in:
*		ARCM
*		MSQH
*		PRDL
*		PREC
*		PRAF
*
*/---------------------------------------------------------
declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount
set nocount on
if @numrows = 0 return

/* check ARCM */
if exists(select top 1 1 from dbo.bARCM s with (nolock) join deleted d on s.BillFreq = d.Frequency)
	begin
	select @errmsg = 'HQ Frequency Code exists in AR Customers.'
	goto error
	end
/* check MSQH */
if exists(select top 1 1 from dbo.bMSQH s with (nolock) join deleted d on s.BillFreq = d.Frequency)
	begin
	select @errmsg = 'HQ Frequency Code exists in MS Quotes'
	goto error
	end
/* check PRDL */
if exists(select top 1 1 from dbo.bPRDL s with (nolock) join deleted d on s.Frequency = d.Frequency)
	begin
	select @errmsg = 'HQ Frequency Code exists in PR Deductions/Liabilities'
	goto error
	end
/* check PREC */
if exists(select top 1 1 from dbo.bPREC s with (nolock) join deleted d on s.Frequency = d.Frequency)
	begin
	select @errmsg = 'HQ Frequency Code exists in PR Earnings Codes'
	goto error
	end
/* check PRED */
if exists(select top 1 1 from dbo.bPRED s with (nolock) join deleted d on s.Frequency = d.Frequency)
	begin
	select @errmsg = 'HQ Frequency Code exists in PR Employee Dedns/Liabs'
	goto error
	end
/* check PRAF */
if exists(select top 1 1 from dbo.bPRAF s with (nolock) join deleted d on s.Frequency = d.Frequency)
	begin
	select @errmsg = 'HQ Frequency Code exists in PR Pay Period Control / Active Frequency Codes.'
	goto error
	end

---- Audit HQ Frequency deletions
--insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
--select 'bHQFC', 'Frequency: ' + convert(varchar(10),Frequency), Frequency, 'D', null, null, null, getdate(), SUSER_SNAME()
--from deleted



return

error:
	select @errmsg = @errmsg + ' - cannot delete HQ Frequency Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btHQFCu    Script Date: 8/28/99 9:37:33 AM ******/
   CREATE  trigger [dbo].[btHQFCu] on [dbo].[bHQFC] for UPDATE as
   

declare @errmsg varchar(255), @numrows int, @validcount int
   
   /*-----------------------------------------------------------------
    *	This trigger rejects update in bHQFC (HQ Frequency Codes) if the 
    *	following error condition exists:
    *
    *		Cannot change HQ Frequency Code
    *
    */----------------------------------------------------------------
   
   /* initialize */
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* reject key changes */
   select @validcount = count(*) from deleted d, inserted i
   	where d.Frequency = i.Frequency
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Cannot change HQ Frequency Code'
   	goto error
   	end
   
   return
   
   error:
   		
   	select @errmsg = @errmsg + ' - cannot update HQ Frequency Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
