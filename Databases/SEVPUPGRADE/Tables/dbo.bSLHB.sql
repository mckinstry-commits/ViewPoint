CREATE TABLE [dbo].[bSLHB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[HoldCode] [dbo].[bHoldCode] NULL,
[PayTerms] [dbo].[bPayTerms] NULL,
[CompGroup] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Status] [tinyint] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[OldJCCo] [dbo].[bCompany] NULL,
[OldJob] [dbo].[bJob] NULL,
[OldDesc] [dbo].[bItemDesc] NULL,
[OldVendor] [dbo].[bVendor] NULL,
[OldHoldCode] [dbo].[bHoldCode] NULL,
[OldPayTerms] [dbo].[bPayTerms] NULL,
[OldCompGroup] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldStatus] [tinyint] NULL,
[OrigDate] [dbo].[bDate] NULL CONSTRAINT [DF_bSLHB_OrigDate] DEFAULT (''),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[OldOrigDate] [dbo].[bDate] NULL,
[MaxRetgOpt] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bSLHB_MaxRetgOpt] DEFAULT ('N'),
[MaxRetgPct] [dbo].[bPct] NOT NULL CONSTRAINT [DF_bSLHB_MaxRetgPct] DEFAULT ((0.0000)),
[MaxRetgAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bSLHB_MaxRetgAmt] DEFAULT ((0.00)),
[InclACOinMaxYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bSLHB_InclACOinMaxYN] DEFAULT ('Y'),
[MaxRetgDistStyle] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bSLHB_MaxRetgDistStyle] DEFAULT ('C'),
[ApprovalRequired] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bSLHB_ApprovalRequired] DEFAULT ('N'),
[udSLDrawings] [dbo].[bYN] NULL CONSTRAINT [DF__bSLHB__udSLDrawings__DEFAULT] DEFAULT ('N'),
[udSafety] [dbo].[bYN] NULL CONSTRAINT [DF__bSLHB__udSafety__DEFAULT] DEFAULT ('N'),
[udScheduleOVal] [dbo].[bYN] NULL CONSTRAINT [DF__bSLHB__udScheduleOVal__DEFAULT] DEFAULT ('N'),
[udProjSchedule] [dbo].[bYN] NULL CONSTRAINT [DF__bSLHB__udProjSchedule__DEFAULT] DEFAULT ('N'),
[udBalancing] [dbo].[bYN] NULL CONSTRAINT [DF__bSLHB__udBalancing__DEFAULT] DEFAULT ('N'),
[udConsulting] [dbo].[bYN] NULL CONSTRAINT [DF__bSLHB__udConsulting__DEFAULT] DEFAULT ('N'),
[udFacility] [dbo].[bYN] NULL CONSTRAINT [DF__bSLHB__udFacility__DEFAULT] DEFAULT ('N'),
[udScopeOfWork] [dbo].[bFormattedNotes] NULL,
[udControls] [dbo].[bYN] NULL CONSTRAINT [DF__bSLHB__udControls__DEFAULT] DEFAULT ('N'),
[udDesignServ] [dbo].[bYN] NULL CONSTRAINT [DF__bSLHB__udDesignServ__DEFAULT] DEFAULT ('N'),
[udProServTesting] [dbo].[bYN] NULL CONSTRAINT [DF__bSLHB__udProServTesting__DEFAULT] DEFAULT ('N'),
[udSoftProServ] [dbo].[bYN] NULL CONSTRAINT [DF__bSLHB__udSoftProServ__DEFAULT] DEFAULT ('N'),
[udSoftLicense] [dbo].[bYN] NULL CONSTRAINT [DF__bSLHB__udSoftLicense__DEFAULT] DEFAULT ('N'),
[udSoftSupMaintYN] [dbo].[bYN] NULL CONSTRAINT [DF__bSLHB__udSoftSupMaintYN__DEFAULT] DEFAULT ('N'),
[udSoftHost] [dbo].[bYN] NULL CONSTRAINT [DF__bSLHB__udSoftHost__DEFAULT] DEFAULT ('N'),
[udWorkOrderYN] [dbo].[bYN] NULL CONSTRAINT [DF__bSLHB__udWorkOrderYN__DEFAULT] DEFAULT ('N'),
[udFederalYN] [dbo].[bYN] NULL CONSTRAINT [DF__bSLHB__udFederalYN__DEFAULT] DEFAULT ('N'),
[udPerfBondYN] [dbo].[bYN] NULL CONSTRAINT [DF__bSLHB__udPerfBondYN__DEFAULT] DEFAULT ('N'),
[udCostPlusYN] [dbo].[bYN] NULL CONSTRAINT [DF__bSLHB__udCostPlusYN__DEFAULT] DEFAULT ('N'),
[udNegMods] [dbo].[bYN] NULL CONSTRAINT [DF__bSLHB__udNegMods__DEFAULT] DEFAULT ('N'),
[udSubType] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udGTC] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udInvYN] [dbo].[bYN] NULL CONSTRAINT [DF__bSLHB__udInvYN__DEFAULT] DEFAULT ('N'),
[udEEO] [dbo].[bYN] NULL CONSTRAINT [DF__bSLHB__udEEO__DEFAULT] DEFAULT ('N'),
[udMastSub] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btSLHBd] on [dbo].[bSLHB] for DELETE as 
	/*-------------------------------------------------------------- 
    * Created: kb 6/29/99
    * Modified: LM 01/23/00 - When coming from PM we don't want to reset the inusebatchid
    *	         TV 03/21/02 - Delete HQAT records
    *			GG 04/18/02 - #17051 cleanup, removed psuedo-cursor used to unlock SL Header
    *			DC 05/15/09 - #133440  - Ensure stored procedures/triggers are using the correct attachment delete proc
    *
    * Delete trigger for SL Subcontract Header Batch
    *
    ********************************************************/
   declare @numrows int, @errmsg varchar(255),@validcnt int
      
   select @numrows = @@rowcount 
   if @numrows = 0 return
     
   set nocount on
     
   -- do not allow removal if Items exist
	if exists(select 1 from deleted d join bSLIB b on d.Co = b.Co and d.Mth = b.Mth
   			and d.BatchId = b.BatchId and d.BatchSeq = b.BatchSeq)
   	begin
       select @errmsg = 'Subcontract Items exist in Batch'
       goto error
   	end
   
   --unlock SL Headers
   update bSLHD
   set InUseMth = null, InUseBatchId = null 
   from bSLHD h
   join deleted d on d.Co = h.SLCo and d.SL = h.SL
   where h.InUseMth = d.Mth and h.InUseBatchId = d.BatchId
   
   --DC #133440
   ----delete HQAT entries if not exists in SLHD
   --if exists(select 1 from deleted where UniqueAttchID is not null)
   --	begin
   --	delete bHQAT 
   --	from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
   --	where h.UniqueAttchID not in(select t.UniqueAttchID from bSLHD t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
   --	end
   
   --DC #133440
   insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
    select AttachmentID, suser_name(), 'Y' 
        	from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
   			where h.UniqueAttchID not in(select t.UniqueAttchID from bSLHD t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
   			and d.UniqueAttchID is not null     
   
   
   return
     
   error:
        select @errmsg = @errmsg + ' - cannot remove SLHB'
        RAISERROR(@errmsg, 11, -1);
        rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   trigger [dbo].[btSLHBi] on [dbo].[bSLHB] for INSERT as 
   

/********************************************************
    * Created: SE 6/4/97
    * Modified: kb 1/4/99
    *			GG 04/18/02 - #17050 cleanup, removed pseudo-cursor used to lock bSLHD
    *
    *	Insert trigger for SL Header Batch
    *
    ***********************************************************/
   declare @numrows int, @errmsg varchar(255), @validcnt int
    
   select @numrows = @@rowcount 
   if @numrows = 0 return
   
   set nocount on
    
   -- validate batch 
   select @validcnt = count(*)
   from bHQBC r 
   JOIN inserted i ON i.Co=r.Co and i.Mth=r.Mth and i.BatchId=r.BatchId
   where r.Status = 0
   if @validcnt<>@numrows
   	begin
   	select @errmsg = 'Invalid or ''closed'' Batch'
   	goto error
   	end
   
   -- add HQ Close Control for AP GL Co#
   insert bHQCC (Co, Mth, BatchId, GLCo)
   select i.Co, i.Mth, i.BatchId, c.GLCo
   from inserted i
   join bAPCO c on i.Co = c.APCo
   where c.GLCo not in (select h.GLCo from bHQCC h join inserted i on h.Co = i.Co and h.Mth = i.Mth 
   						and h.BatchId = i.BatchId)
   
   --lock existing SL Headers, unless the batch is from a PM Interface 
   -- PM may create both an Entry and Change Order batch in the same interface, so don't lock the Header
   update bSLHD
   set InUseMth = i.Mth, InUseBatchId = i.BatchId 
   from bSLHD h
   join inserted i on i.Co = h.SLCo and i.SL = h.SL
   join bHQBC b on i.Co = b.Co and i.Mth = b.Mth and i.BatchId = b.BatchId
   where h.InUseMth is null and h.InUseBatchId is null
   	and b.Source <> 'PM Intface' and i.BatchTransType in ('C','D')
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot insert Subcontract Header Batch entry (bSLHB)'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btSLHBu    Script Date: 8/28/99 9:38:17 AM ******/
   CREATE  trigger [dbo].[btSLHBu] on [dbo].[bSLHB] for UPDATE as 
   
    

/***  basic declares for SQL Triggers ****/
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15), 
           @errno tinyint, @audit bYN, @validcnt int, @validcnt2 int, @typecnt int
           
   
   
   /*-------------------------------------------------------------- 
    *
    *  Update trigger for SLHB
    *  Created By: SE
    *  Date: 6/4/97      
    *  Modified by: EN 3/29/00 - BatchTransType must be 'A', 'C' or 'D'; if BatchTransType = 'A' cannot change to 'C' or 'D' and vice versa
    *               EN 3/29/00 - if BatchTransType <> 'A' cannot change SL
    *
    *--------------------------------------------------------------*/
    select @numrows = @@rowcount 
    if @numrows = 0 return
    set nocount on
    
   /* check for key changes */
   select @validcnt = count(*) from deleted d, inserted i
   	where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
   
   if @numrows <> @validcnt
   	begin
   	select @errmsg = 'Cannot change Company, Month, Batch ID #, or Batch Sequence #'
   	goto error 
   	end
   
   /* BatchTransType must be 'A'-Add, 'C'-Change, 'D'-Delete */
   select @validcnt = count(*) from inserted i where i.BatchTransType='A' or i.BatchTransType='C'
   	or i.BatchTransType='D'
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Batch Action is Invalid '
   	goto error
   	end
   
   /* if BatchTransType is 'A' cannot change to 'C' or 'D' and vice versa */
   select @validcnt = count(*) from inserted i
       join deleted d on i.Co=d.Co and i.Mth=d.Mth and i.BatchId=d.BatchId and i.BatchSeq=d.BatchSeq
       where (d.BatchTransType='A' and (i.BatchTransType='C' or i.BatchTransType='D')) or
             ((d.BatchTransType='C' or d.BatchTransType='D') and i.BatchTransType='A')
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Cannot change Batch Action from Add or from Change or Delete to Add '
   	goto error
   	end
   
   /* if BatchTransType <> 'A', cannot change SLTrans, SL or SLItem */
   select @validcnt = count(*) from deleted d
       join inserted i on i.Co = d.Co and i.Mth = d.Mth and i.BatchId = d.BatchId and i.BatchSeq = d.BatchSeq
       where i.BatchTransType <> 'A' and i.SL <> d.SL
   if @validcnt <> 0
       begin
       select @errmsg = 'Cannot change SL # if type is not ''A'' '
       goto error
       end
   
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot update SLHB'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction

GO
CREATE UNIQUE CLUSTERED INDEX [biSLHB] ON [dbo].[bSLHB] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bSLHB] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
