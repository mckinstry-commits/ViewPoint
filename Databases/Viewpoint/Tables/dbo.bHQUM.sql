CREATE TABLE [dbo].[bHQUM]
(
[UM] [dbo].[bUM] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ExcludeFromLookup] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQUM_ExcludeFromLookup] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biHQUM] ON [dbo].[bHQUM] ([UM]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQUM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btHQUMd    Script Date: 8/28/99 9:37:36 AM ******/
   CREATE  trigger [dbo].[btHQUMd] on [dbo].[bHQUM] for DELETE as
   

/*----------------------------------------------------------
    *	This trigger rejects delete in bHQUM (HQ Unit of Measure) if a 
    *	dependent record is found in:
    *
    *		HQMT Material
    *		HQMU Material Units of Measure
    *
    *
    *   Modified: RM 01/29/03 - Cannot delete LS or HRS datatypes per issue 20154
    *
    */---------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   
   /*Do not allow deletion of LS or HRS datatypes, Issue#20154*/
   if exists(select * from deleted where UM='LS' or UM='HRS')
   	begin
   		select @errmsg = 'Cannot delete ''LS'' or ''HRS'' datatypes.  They are required.'
   		goto error
   	end
   
   
   /* check if used in HQMT as a Standard or Purchase U/M */
   if exists(select * from bHQMT s, deleted d where s.StdUM = d.UM or
   	s.PurchaseUM = d.UM or s.SalesUM = d.UM)
   	begin
   	select @errmsg = 'Used as a Standard or Purchase or Sales U/M in HQ Materials'
   	goto error
   	end
   
   /* check HQMU.UM */
   if exists(select * from bHQMU s, deleted d where s.UM = d.UM)
   	begin
   	select @errmsg = 'Used as an alternative U/M on some materials'
   	goto error
   	end
      
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete HQ Unit of Measure!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btHQUMu    Script Date: 8/28/99 9:37:36 AM ******/
   CREATE  trigger [dbo].[btHQUMu] on [dbo].[bHQUM] for UPDATE as
   

declare @errmsg varchar(255), @numrows int, @validcount int
   
   /*-----------------------------------------------------------------
    *	This trigger rejects update in bHQUM (HQ Unit of Measure) if the 
    *	following error condition exists:
    *
    *		Cannot change HQ Unit of Measure HQUM.UM
    *
    */----------------------------------------------------------------
   
   /* initialize */
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* reject key changes */
   select @validcount = count(*) from deleted d, inserted i
   	where d.UM = i.UM
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Cannot change HQ Unit of Measure'
   	goto error
   	end
   
   return
   
   error:
   		
   	select @errmsg = @errmsg + ' - cannot update HQ Unit of Measure!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
