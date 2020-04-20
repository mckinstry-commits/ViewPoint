CREATE TABLE [dbo].[bPRAB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Trans] [dbo].[bTrans] NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[LeaveCode] [dbo].[bLeaveCode] NOT NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Amt] [dbo].[bHrs] NOT NULL,
[Accum1Adj] [dbo].[bHrs] NULL,
[Accum2Adj] [dbo].[bHrs] NULL,
[AvailBalAdj] [dbo].[bHrs] NULL,
[Description] [dbo].[bDesc] NULL,
[PRGroup] [dbo].[bGroup] NULL,
[PREndDate] [dbo].[bDate] NULL,
[PaySeq] [tinyint] NULL,
[OldEmployee] [dbo].[bEmployee] NULL,
[OldLeaveCode] [dbo].[bLeaveCode] NULL,
[OldActDate] [dbo].[bDate] NULL,
[OldType] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[OldAmt] [dbo].[bHrs] NULL,
[OldAccum1Adj] [dbo].[bHrs] NULL,
[OldAccum2Adj] [dbo].[bHrs] NULL,
[OldAvailBalAdj] [dbo].[bHrs] NULL,
[OldDesc] [dbo].[bDesc] NULL,
[OldPRGroup] [dbo].[bGroup] NULL,
[OldPREndDate] [dbo].[bDate] NULL,
[OldPaySeq] [tinyint] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRAB] ON [dbo].[bPRAB] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRAB] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btPRABd    Script Date: 8/28/99 9:38:09 AM ******/
   CREATE    trigger [dbo].[btPRABd] on [dbo].[bPRAB] for DELETE as 
   
    

/***  basic declares for SQL Triggers ****/
   declare @numrows int, @errmsg varchar(255), 
           @validcnt int, @validcnt2 int
           
   
   
   /*-------------------------------------------------------------- 
    *
    *  delete trigger for PRAB
    *  Created: EN 1/17/98
    *  Modified: EN 2/4/99
    *            TV 03/21/02 Delete HQAT records
    *				EN 10/9/02 - issue 18877 change double quotes to single
    *				EN 12/10/03 - issue 23061  added isnull check, with (nolock), and dbo and corrected old syle joins
	*				mh 05/14/09 - issue 133439/127603
    *
    *--------------------------------------------------------------*/
    select @numrows = @@rowcount 
    if @numrows = 0 return
   
   set nocount on
   
   /* update InUse info in leave history */
   select @validcnt2 = count(*) from deleted d 
   	join dbo.bPRLH h with (nolock) on d.Co=h.PRCo and d.Mth=h.Mth and d.Trans=h.Trans
   	where d.BatchTransType<>'A'
   
   update dbo.bPRLH
   set InUseBatchId=null from dbo.bPRLH h with (nolock)
   	join deleted d on d.Co=h.PRCo and d.Mth=h.Mth and d.Trans=h.Trans
   	where d.BatchTransType<>'A'
   if @@rowcount<>@validcnt2
   	begin
   	select @errmsg = 'Unable to remove InUse Flag from Leave History.'
   	goto error
   	end
   
   /* update InUse info in employee leave codes */
   update dbo.bPREL
   set InUseMth=null, InUseBatchId=null from dbo.bPREL e with (nolock)
   	join deleted d on d.Co=e.PRCo and d.Employee=e.Employee and d.LeaveCode=e.LeaveCode
   	where not exists(select * from dbo.bPRAB b with (nolock) where b.Co=d.Co and b.Mth=d.Mth
   		and b.BatchId=d.BatchId and b.BatchSeq<>d.BatchSeq and b.Employee=d.Employee
   		and b.LeaveCode=d.LeaveCode)
   
--   --delete HQAT entries if not exists in PRLH
--   delete dbo.bHQAT 
--   from dbo.bHQAT h with (nolock) join deleted d on h.UniqueAttchID = d.UniqueAttchID
--   where h.UniqueAttchID not in(select t.UniqueAttchID from dbo.bPRLH t with (nolock) 
--   	join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)

-- Delete attachments if they exist. Make sure UniqueAttchID is not null.
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
		select AttachmentID, suser_name(), 'Y' 
		from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
		where h.UniqueAttchID not in(select t.UniqueAttchID from bPRLH t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
		and d.UniqueAttchID is not null     
   
   	
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot remove PRAB'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btPRABi    Script Date: 8/28/99 9:38:09 AM ******/
   CREATE   trigger [dbo].[btPRABi] on [dbo].[bPRAB] for INSERT as 
   
    

/***  basic declares for SQL Triggers ****/
   declare @numrows int, @errmsg varchar(255), 
          @validcnt int, @validcnt2 int
   
   
   /*-------------------------------------------------------------- 
    *
    *  Insert trigger for PRAB
    *  Created: EN 1/17/98
    *  Modified: EN 2/3/99
    *				EN 10/9/02 - issue 18877 change double quotes to single
    *				EN 12/10/03 - issue 23061  added isnull check, with (nolock), and dbo and corrected old syle joins
    *
    *--------------------------------------------------------------*/
    select @numrows = @@rowcount 
    if @numrows = 0 return
    set nocount on
    
   /* validate batch */
   
   
   
   select @validcnt = count(*) from dbo.bHQBC r with (nolock)
          JOIN inserted i ON i.Co=r.Co and i.Mth=r.Mth and i.BatchId=r.BatchId
   if @validcnt<>@numrows
   	begin
   	select @errmsg = 'Invalid Batch ID#'
   	goto error
   	end
   
   select @validcnt = count(*) from dbo.bHQBC r with (nolock)
   
           JOIN inserted i ON i.Co=r.Co and i.Mth=r.Mth and 
                i.BatchId=r.BatchId and not r.BatchId is null
                
   if @validcnt<>@numrows
   	begin
   	select @errmsg = 'Batch ''In Use'' name must first be updated.'
   	goto error
   	end
   
   
   select @validcnt = count(*) from dbo.bHQBC r with (nolock)
          JOIN inserted i ON i.Co=r.Co and i.Mth=r.Mth and 
               i.BatchId=r.BatchId and r.Status=0
   if @validcnt<>@numrows
   	begin
   	select @errmsg = 'Must be an open batch.'
   	goto error
   	end
   
   /* mark PREL as in use */
   update dbo.bPREL
   set InUseMth=i.Mth, InUseBatchId=i.BatchId from dbo.bPREL e with (nolock)
   	join inserted i on i.Co=e.PRCo and i.Employee=e.Employee and i.LeaveCode=e.LeaveCode
   
   /* mark PRLH as in use */
   select @validcnt = count(*) from inserted where BatchTransType <> 'A'
   			
   update dbo.bPRLH
   set InUseBatchId=i.BatchId from dbo.bPRLH r with (nolock)
   	join inserted i on i.Co=r.PRCo and i.Mth=r.Mth and i.Trans=r.Trans
   	where i.BatchTransType <> 'A'
   
   if @@rowcount<>@validcnt
   	begin
   	select @errmsg = 'Unable to flag Transaction as ''In Use''.'
   	goto error
   	end
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot insert PRAB'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btPRABu    Script Date: 8/28/99 9:38:09 AM ******/
   CREATE   trigger [dbo].[btPRABu] on [dbo].[bPRAB] for UPDATE as 
   
    

/***  basic declares for SQL Triggers ****/
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15), 
           @errno tinyint, @audit bYN, @validcnt int, @validcnt2 int, @typecnt int
           
   
   
   /*-------------------------------------------------------------- 
    *
    *  Update trigger for PRAB
    *  Created By: EN
    *  Date: 1/17/98   
    *  Modified by: EN 10/9/02 - issue 18877 change double quotes to single
    *				EN 12/10/03 - issue 23061  added isnull check, with (nolock), and dbo and corrected old syle joins
    *
    *
    *--------------------------------------------------------------*/
    select @numrows = @@rowcount 
    if @numrows = 0 return
    set nocount on
    
   /* check for key changes */
   select @validcnt = count(*) from deleted d 
   	join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
   
   if @numrows <> @validcnt
   	begin
   	select @errmsg = 'Cannot change Company, Month, Batch ID #, or Batch Sequence #'
   	goto error 
   	end
   
   /* if employee or leave code was modified, update InUse flags in PREL accordingly */
   update dbo.bPREL
   set InUseMth=null, InUseBatchId=null from dbo.bPREL e with (nolock) 
   	join deleted d on d.Co=e.PRCo and d.Employee=e.Employee and d.LeaveCode=e.LeaveCode
   
   update dbo.bPREL
   set InUseMth=i.Mth, InUseBatchId=i.BatchId from dbo.bPREL e with (nolock)
   	join inserted i on i.Co=e.PRCo and i.Employee=e.Employee and i.LeaveCode=e.LeaveCode
   
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot update PRAB'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
  
 



GO

EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRAB].[Amt]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRAB].[Accum1Adj]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRAB].[Accum2Adj]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRAB].[AvailBalAdj]'
GO
