CREATE TABLE [dbo].[bHQPT]
(
[PayTerms] [dbo].[bPayTerms] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[DiscOpt] [tinyint] NOT NULL,
[DaysTillDisc] [tinyint] NULL,
[DiscDay] [tinyint] NULL,
[DueOpt] [tinyint] NOT NULL,
[DaysTillDue] [tinyint] NULL,
[DueDay] [tinyint] NULL,
[CutOffDay] [tinyint] NULL,
[DiscRate] [dbo].[bPct] NOT NULL,
[MatlDisc] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[RollAheadTwoMonths] [tinyint] NOT NULL CONSTRAINT [DF_bHQPT_RollAheadTwoMonths] DEFAULT ((1))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biHQPT] ON [dbo].[bHQPT] ([PayTerms]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQPT] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btHQPTi    Script Date: 8/28/99 9:37:35 AM ******/
   CREATE  trigger [dbo].[btHQPTi] on [dbo].[bHQPT] for INSERT as
   

/*-----------------------------------------------------------------
    *	This trigger rejects insertion in bHQPT (HQ PayTerms) if the
    *	following error condition exists:
    *
    *		no validation necessary
    *
   
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   	
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   select @validcnt = count(*) from inserted where DueOpt =3 and DaysTillDue is not null
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Cannot set the DaysTillDue when the DueOpt is set to 3 (None).'
   	goto error
   	end
   
   select @validcnt = count(*) from inserted where DueOpt =3 and DueDay is not null
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Cannot set the DueDay when the DueOpt is set to 3 (None).'
   	goto error
   	end
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot insert HQ Pay Terms!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btHQPTu    Script Date: 8/28/99 9:37:35 AM ******/
   CREATE  trigger [dbo].[btHQPTu] on [dbo].[bHQPT] for UPDATE as
   

declare @errmsg varchar(255), @numrows int, @validcount int
   
   /*-----------------------------------------------------------------
    *	This trigger rejects update in bHQPT (HQ Payment Terms) if the 
    *	following error condition exists:
    *
    *		Cannot change HQ PayTerms
    *
    */----------------------------------------------------------------
   
   /* initialize */
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* reject key changes */
   
   select @validcount = count(*) from deleted d, inserted i
   	where d.PayTerms = i.PayTerms
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Cannot change HQ Payment Terms'
   	goto error
   	end
   
   if update(DueOpt) or update(DaysTillDue) or update(DueDay)
   	begin
   	select @validcount = count(*) from inserted where DueOpt=3 and DaysTillDue is not null
   	if @validcount <> 0
   		begin
   		select @errmsg = 'Cannot set the (DaysTillDue) when the Due Date Option is set to none'
   		goto error
   		end
   
   	select @validcount = count(*) from inserted where DueOpt=3 and DueDay is not null
   	if @validcount <> 0
   		begin
   		select @errmsg = 'Cannot set the (DueDay) when the Due Date Option is set to none'
   		goto error
   		end
   	end
   
   return
   
   error:
   		
   	select @errmsg = @errmsg + ' - cannot update HQ Payment Terms!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHQPT].[MatlDisc]'
GO
