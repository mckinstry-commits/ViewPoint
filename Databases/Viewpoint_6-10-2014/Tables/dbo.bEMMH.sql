CREATE TABLE [dbo].[bEMMH]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[EMTrans] [dbo].[bTrans] NULL,
[BatchTransType] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[PostedDate] [dbo].[bDate] NULL,
[ReadingDate] [dbo].[bDate] NOT NULL,
[BeginOdo] [dbo].[bUnits] NOT NULL,
[EndOdo] [dbo].[bUnits] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[OldEquipment] [dbo].[bEquip] NULL,
[OldPostedDate] [dbo].[bDate] NULL,
[OldReadingDate] [dbo].[bDate] NULL,
[OldBeginOdo] [dbo].[bUnits] NULL,
[OldEndOdo] [dbo].[bUnits] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btAPHBd    Script Date: 8/28/99 9:36:53 AM ******/
    CREATE             trigger [dbo].[btEMMHd] on [dbo].[bEMMH] for DELETE as
    

/*-----------------------------------------------------------------
     *	Created : 11/01/02
     *	Modified:   TV 02/11/04 - 23061 added isnulls
     *				GP 05/26/09 - 133434 removed HQAT code, added new insert
     *
     *	Delete trigger for EM Miles by State Batch Header Batch
     *
     */----------------------------------------------------------------
    
    declare @errmsg varchar(255), @numrows int, @validcnt int
    
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
    
    --check for existing Batch Lines
    select @validcnt = count(*)
    from bEMML l
    join deleted d on l.Co=d.Co and l.Mth=d.Mth and l.BatchId=d.BatchId and l.BatchSeq=d.BatchSeq
    if @validcnt > 0
    	begin
    	select @errmsg = 'Batch lines exist'
    	goto error
    	end
    
    -- unlock existing AP trans - if they still exist
    update bEMSM
    set InUseMth = null, InUseBatchId = null
    from bEMSM h
    join deleted d on d.Co = h.Co and d.Mth = h.Mth and d.EMTrans = h.EMTrans
    
    -- Delete attachments if they exist. Make sure UniqueAttchID is not null.
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
    select AttachmentID, suser_name(), 'Y' 
    from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
    where h.UniqueAttchID not in(select t.UniqueAttchID from bEMSM t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
		and d.UniqueAttchID is not null  
    
    
    return
    
    error:
    	select @errmsg = isnull(@errmsg,'') + ' - cannot delete AP Batch Header!'
        RAISERROR(@errmsg, 11, -1);
    
        rollback transaction
    
    
    
    
    
    
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biEMMH] ON [dbo].[bEMMH] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMMH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bEMMH] WITH NOCHECK ADD CONSTRAINT [FK_bEMMH_bEMEM_Equipment] FOREIGN KEY ([Co], [Equipment]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment])
GO
ALTER TABLE [dbo].[bEMMH] NOCHECK CONSTRAINT [FK_bEMMH_bEMEM_Equipment]
GO
