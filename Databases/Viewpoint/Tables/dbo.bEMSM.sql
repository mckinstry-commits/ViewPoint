CREATE TABLE [dbo].[bEMSM]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[EMTrans] [dbo].[bTrans] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[ReadingDate] [dbo].[bDate] NOT NULL,
[BeginOdo] [dbo].[bUnits] NOT NULL,
[EndOdo] [dbo].[bUnits] NOT NULL,
[InUseMth] [dbo].[bMonth] NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biEMSM] ON [dbo].[bEMSM] ([Co], [Mth], [EMTrans]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMSM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  

    CREATE trigger [dbo].[btEMSMd] on [dbo].[bEMSM] for DELETE as
    

/*-----------------------------------------------------------------
     *	Created :	GP 05/26/09
     *	Modified:	
     *
     *	Delete trigger for EMSM
     *
     */----------------------------------------------------------------
    
    declare @errmsg varchar(255), @numrows int, @validcnt int
    
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
    
	-- Delete attachments if they exist. Make sure UniqueAttchID is not null
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
    select AttachmentID, suser_name(), 'Y' 
    from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID                  
    where d.UniqueAttchID is not null  
    
    
    return
    
    error:
    	select @errmsg = isnull(@errmsg,'') + ' - cannot delete EMSM record!'
        RAISERROR(@errmsg, 11, -1);
    
        rollback transaction
    
    
    
    
    
    
   
   
   
   
   
  
 



GO
