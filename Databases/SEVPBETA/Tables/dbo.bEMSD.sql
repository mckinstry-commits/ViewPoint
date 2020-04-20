CREATE TABLE [dbo].[bEMSD]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[EMTrans] [dbo].[bTrans] NOT NULL,
[Line] [int] NOT NULL,
[UsageDate] [dbo].[bDate] NOT NULL,
[PostedDate] [dbo].[bDate] NOT NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[OnRoadLoaded] [dbo].[bHrs] NULL,
[OnRoadUnLoaded] [dbo].[bHrs] NULL,
[OffRoad] [dbo].[bHrs] NULL,
[InUseMth] [dbo].[bMonth] NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

    CREATE       trigger [dbo].[btEMSDd] on [dbo].[bEMSD] for DELETE as
    

/*-----------------------------------------------------------------
     *	CREATED BY:		GP 05/26/09
     *	MODIFIED By:	
     *
     *	Delete trigger for EMSD
     *
     */----------------------------------------------------------------
    
    declare @errmsg varchar(255),
    	@nullcnt int,
    	@numrows int,
    	@source bSource
    
    select @numrows = @@rowcount
    
    set nocount on
    
    if @numrows = 0 return
    
	-- Delete attachments if they exist. Make sure UniqueAttchID is not null
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
    select AttachmentID, suser_name(), 'Y' 
	from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID                  
	where d.UniqueAttchID is not null    
    
    return
    
    error:
    	select @errmsg = isnull(@errmsg,'') + ' - cannot delete EMSD record!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
    
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biEMSD] ON [dbo].[bEMSD] ([Co], [Mth], [EMTrans], [Line]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMSD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
