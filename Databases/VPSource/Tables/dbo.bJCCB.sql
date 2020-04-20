CREATE TABLE [dbo].[bJCCB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[Source] [dbo].[bSource] NOT NULL,
[TransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CostTrans] [dbo].[bTrans] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[CostType] [dbo].[bJCCType] NULL,
[ActualDate] [dbo].[bDate] NULL,
[JCTransType] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[Description] [dbo].[bTransDesc] NULL,
[GLCo] [dbo].[bCompany] NULL,
[GLTransAcct] [dbo].[bGLAcct] NULL,
[GLOffsetAcct] [dbo].[bGLAcct] NULL,
[ReversalStatus] [tinyint] NULL,
[OrigMth] [dbo].[bMonth] NULL,
[OrigCostTrans] [dbo].[bTrans] NULL,
[UM] [dbo].[bUM] NULL,
[Hours] [dbo].[bHrs] NULL,
[Units] [dbo].[bUnits] NULL,
[Cost] [dbo].[bDollar] NULL,
[PstUM] [dbo].[bUM] NULL,
[PstUnits] [dbo].[bUnits] NULL,
[PstUnitCost] [dbo].[bUnitCost] NULL,
[PstECM] [dbo].[bECM] NULL,
[AllocCode] [smallint] NULL,
[PRCo] [dbo].[bCompany] NULL,
[Employee] [dbo].[bEmployee] NULL,
[Craft] [dbo].[bCraft] NULL,
[Class] [dbo].[bClass] NULL,
[Crew] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[EarnFactor] [dbo].[bRate] NULL,
[EarnType] [dbo].[bEarnType] NULL,
[Shift] [tinyint] NULL,
[LiabilityType] [dbo].[bLiabilityType] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[APCo] [dbo].[bCompany] NULL,
[APTrans] [dbo].[bTrans] NULL,
[APLine] [smallint] NULL,
[APRef] [dbo].[bAPReference] NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[POItem] [dbo].[bItem] NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[SLItem] [dbo].[bItem] NULL,
[MO] [dbo].[bMO] NULL,
[MOItem] [dbo].[bItem] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Material] [dbo].[bMatl] NULL,
[INCo] [dbo].[bCompany] NULL,
[Loc] [dbo].[bLoc] NULL,
[INStdUM] [dbo].[bUM] NULL,
[INStdUnitCost] [dbo].[bUnitCost] NULL,
[INStdECM] [dbo].[bECM] NULL,
[MSTrans] [dbo].[bTrans] NULL,
[MSTicket] [dbo].[bTic] NULL,
[JBBillStatus] [char] (1) COLLATE Latin1_General_BIN NULL,
[JBBillMonth] [dbo].[bMonth] NULL,
[JBBillNumber] [int] NULL,
[EMCo] [dbo].[bCompany] NULL,
[EMEquip] [dbo].[bEquip] NULL,
[EMRevCode] [dbo].[bRevCode] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[TaxType] [tinyint] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxBasis] [dbo].[bDollar] NULL,
[TaxAmt] [dbo].[bDollar] NULL,
[OldJob] [dbo].[bJob] NULL,
[OldPhaseGroup] [dbo].[bGroup] NULL,
[OldPhase] [dbo].[bPhase] NULL,
[OldCostType] [dbo].[bJCCType] NULL,
[OldActualDate] [dbo].[bDate] NULL,
[OldJCTransType] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[OldGLCo] [dbo].[bCompany] NULL,
[OldDescription] [dbo].[bTransDesc] NULL,
[OldGLTransAcct] [dbo].[bGLAcct] NULL,
[OldGLOffsetAcct] [dbo].[bGLAcct] NULL,
[OldReversalStatus] [tinyint] NULL,
[OldUM] [dbo].[bUM] NULL,
[OldHours] [dbo].[bHrs] NULL,
[OldUnits] [dbo].[bUnits] NULL,
[OldCost] [dbo].[bDollar] NULL,
[OldPstUM] [dbo].[bUM] NULL,
[OldPstUnits] [dbo].[bUnits] NULL,
[OldPstUnitCost] [dbo].[bUnitCost] NULL,
[OldPstECM] [dbo].[bECM] NULL,
[OldPRCo] [dbo].[bCompany] NULL,
[OldEmployee] [dbo].[bEmployee] NULL,
[OldCraft] [dbo].[bCraft] NULL,
[OldClass] [dbo].[bClass] NULL,
[OldCrew] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldEarnFactor] [dbo].[bRate] NULL,
[OldEarnType] [dbo].[bEarnType] NULL,
[OldShift] [tinyint] NULL,
[OldLiabilityType] [dbo].[bLiabilityType] NULL,
[OldVendorGroup] [dbo].[bGroup] NULL,
[OldVendor] [dbo].[bVendor] NULL,
[OldAPCo] [dbo].[bCompany] NULL,
[OldAPTrans] [dbo].[bTrans] NULL,
[OldAPLine] [smallint] NULL,
[OldAPRef] [dbo].[bAPReference] NULL,
[OldPO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[OldPOItem] [dbo].[bItem] NULL,
[OldSL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[OldSLItem] [dbo].[bItem] NULL,
[OldMO] [dbo].[bMO] NULL,
[OldMOItem] [dbo].[bItem] NULL,
[OldMatlGroup] [dbo].[bGroup] NULL,
[OldMaterial] [dbo].[bMatl] NULL,
[OldINCo] [dbo].[bCompany] NULL,
[OldLoc] [dbo].[bLoc] NULL,
[OldINStdUM] [dbo].[bUM] NULL,
[OldINStdUnitCost] [dbo].[bUnitCost] NULL,
[OldINStdECM] [dbo].[bECM] NULL,
[OldMSTrans] [dbo].[bTrans] NULL,
[OldMSTicket] [dbo].[bTic] NULL,
[OldJBBillStatus] [char] (1) COLLATE Latin1_General_BIN NULL,
[OldJBBillMonth] [dbo].[bMonth] NULL,
[OldJBBillNumber] [int] NULL,
[OldEMCo] [dbo].[bCompany] NULL,
[OldEMEquip] [dbo].[bEquip] NULL,
[OldEMRevCode] [dbo].[bRevCode] NULL,
[OldEMGroup] [dbo].[bGroup] NULL,
[OldTaxType] [tinyint] NULL,
[OldTaxGroup] [dbo].[bGroup] NULL,
[OldTaxCode] [dbo].[bTaxCode] NULL,
[OldTaxBasis] [dbo].[bDollar] NULL,
[OldTaxAmt] [dbo].[bDollar] NULL,
[TaxPhase] [dbo].[bPhase] NULL,
[TaxCostType] [dbo].[bJCCType] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[ToJCCo] [dbo].[bCompany] NULL,
[OldToJCCo] [dbo].[bCompany] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[TaxGLTransAcct] [dbo].[bGLAcct] NULL,
[OffsetGLCo] [dbo].[bCompany] NULL,
[OldOffsetGLCo] [dbo].[bCompany] NULL,
[OldPOItemLine] [int] NULL,
[POItemLine] [int] NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[bJCCB] ADD
CONSTRAINT [CK_bJCCB_INStdECM] CHECK (([INStdECM]='E' OR [INStdECM]='C' OR [INStdECM]='M' OR [INStdECM] IS NULL))
ALTER TABLE [dbo].[bJCCB] ADD
CONSTRAINT [CK_bJCCB_OldINStdECM] CHECK (([OldINStdECM]='E' OR [OldINStdECM]='C' OR [OldINStdECM]='M' OR [OldINStdECM] IS NULL))
ALTER TABLE [dbo].[bJCCB] ADD
CONSTRAINT [CK_bJCCB_OldPstECM] CHECK (([OldPstECM]='E' OR [OldPstECM]='C' OR [OldPstECM]='M' OR [OldPstECM] IS NULL))
ALTER TABLE [dbo].[bJCCB] ADD
CONSTRAINT [CK_bJCCB_PstECM] CHECK (([PstECM]='E' OR [PstECM]='C' OR [PstECM]='M' OR [PstECM] IS NULL))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
/****** Object:  Trigger dbo.btJCCBd    Script Date: 8/28/99 9:37:41 AM ******/
CREATE  trigger [dbo].[btJCCBd] on [dbo].[bJCCB] for DELETE as


/*-----------------------------------------------------------------
*	This trigger updates bJCCD (Cost Detail) to remove InUseBatchId
*	when deletion(s) are made from bJCCB (Cost Adj Batch).
*
*	Modified By:	GF 05/11/2004 - #24561 changed join and where clause for UniqueAttchID delete statement. Speed up.
*					GF 06/24/2008 - issue #128722 changed batch delete statement.
*					CHS	05/15/2009	-	Issue #133437
*
*	Rejects deletion if the following
*	error condition exists:
*
*----------------------------------------------------------------*/
declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- -- remove rows from bJCDA for new entries only
   delete bJCDA
   from bJCDA c
   join deleted d on c.JCCo = d.Co and c.Mth = d.Mth and c.BatchId = d.BatchId and c.BatchSeq = d.BatchSeq
   join bHQBC e on e.Co = d.Co and e.Mth = d.Mth and e.BatchId = d.BatchId
   where e.Status <> 4
   
   -- -- remove InUseBatchId from bJCCD rows pointed to by deleted batch entries
   update bJCCD set InUseBatchId = null
   from bJCCD c, deleted d
   where c.JCCo = d.Co and c.Mth = d.Mth and c.CostTrans = d.CostTrans
   
   -- -- remove InUseBatchId for reversals
   update bJCCD set InUseBatchId = null
   from bJCCD c, deleted d
   where c.JCCo = d.Co and c.Mth = d.OrigMth and c.CostTrans = d.OrigCostTrans
     
   
	-- Issue #133437
	-- Delete attachments if they exist. Make sure UniqueAttchID is not null.
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
			  select AttachmentID, suser_name(), 'Y' 
				  from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
				  where h.UniqueAttchID not in(select t.UniqueAttchID from bJCCD t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
				  and d.UniqueAttchID is not null     
	   
	   
   return
   
   error:
     	select @errmsg = @errmsg + ' - cannot delete JC Cost Detail Batch entry!'
     	RAISERROR(@errmsg, 11, -1);
     	rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btJCCBi    Script Date: 8/28/99 9:38:22 AM ******/
   CREATE trigger [dbo].[btJCCBi] on [dbo].[bJCCB] for INSERT as
   

declare @batchid bBatchID, @errmsg varchar(255), @numrows int, @seq int, 
   		@co bCompany, @mth bMonth, @source bSource, @status tinyint, @opencursor int,
   		@costtrans bTrans, @dtsource bSource, @glco bCompany,
   		@inusebatchid bBatchID, @errtext varchar(100), @rcode tinyint,
   		@reversalstatus tinyint, @origmth bMonth, @origcosttrans bTrans
   /*-----------------------------------------------------------------
    * Modified By:	Dan F 05/24/00 - Added 'JC MatUse' as a vailid source
    *				SHAYONAR 5/7/02 - added @source as parameter to fetch on line 162
    *				GF 10/09/2002 - changed dbl quotes to single quotes
    *				GF 12/02/2003 - issue #23130 - changed to local cursor for performance
    *	
    *	This trigger rejects insertion in bJCCB (Cost Adj Batch) if
    *	any of the following error conditions exist:
    *
    * 		Invalid Batch ID#
    *		Batch associated with another source or table
    *		Batch in use by someone else
    *		Batch status not 'open'
    *
    *		Reference to a JCCD trans that doesn't exist
    *		JCCD trans already in use by a batch
    *		JCCD trans created from a source other than JC
    *
    *	use bspJCCBVal to fully validate all entries in a JCCB batch
    *	prior to posting.
    *
    *	Updates InUseBatchId in bJCCD for existing transactions.
    *	Updates InUseBatchId of reversal trans if adding reversal
    *
    * 	Adds entry to HQ Close Control as needed.
    *
    *----------------------------------------------------------------*/
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   set @opencursor = 0
   
   if @numrows = 1
   	begin
   	select @co = Co, @mth = Mth, @batchid = BatchId, @seq = BatchSeq,
    		@costtrans = CostTrans, @glco=GLCo, @reversalstatus=ReversalStatus,
    		@origmth = OrigMth, @origcosttrans=OrigCostTrans, @source=Source 
   	from inserted
   	end
   else
   	begin
   	-- use a cursor to process each inserted row
    	declare bJCCB_insert cursor LOCAL FAST_FORWARD
   		for select Co, Mth, BatchId, BatchSeq, CostTrans, GLCo, ReversalStatus, 
   			OrigMth, OrigCostTrans, Source 
   	from inserted
   
    	open bJCCB_insert
   	set @opencursor = 1
   
    	fetch next from bJCCB_insert into @co, @mth, @batchid, @seq, @costtrans, @glco, @reversalstatus, 
   			@origmth, @origcosttrans, @source
   
    	if @@fetch_status <> 0
    		begin
    		select @errmsg = 'Cursor error'
    		goto error
    		end
    	end
   
   
   insert_check:
   -- validate HQ Batch
   exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, @source, 'JCCB', @errtext output, @status output
   if @rcode <> 0
   	begin
   	select @errmsg = @errtext, @rcode = 1
   	goto error
   	end
   
   if @status <> 0
    	begin
    	select @errmsg = 'Must be an open batch'
    	goto error
    	end
   
   
   -- validate existing JC trans - if one is referenced
   if @costtrans is not null
   	begin
   	select @dtsource = Source, @inusebatchid = InUseBatchId
   	from bJCCD with (nolock) where CostTrans = @costtrans and Mth = @mth and JCCo = @co 
   	if @@rowcount = 0
   		begin
   		select @errmsg = 'JC Cost Detail transaction not found'
   		goto error
   		end
   
   	if @inusebatchid is not null
   		begin
   		select @errmsg = 'JC Cost Detail transaction in use by another Batch'
   		goto error
   		end
   
   	if @dtsource <> 'JC CostAdj' and @dtsource <> 'JC MatUse'
   		begin
   		select @errmsg = 'JC transaction was created with another source'
   		goto error
   		end
   
   	-- update JC transaction as 'in use'
   	update bJCCD set InUseBatchId = @batchid
   	where CostTrans = @costtrans and Mth = @mth and JCCo = @co 
   	if @@rowcount <> 1
   		begin
   		select @errmsg = 'Unable to update JC Cost Detail as (In Use)'
   		goto error
   		end
   	end
   
   
   -- validate existing JC trans - if one is referenced
   if @reversalstatus = 2
   	begin
   	select @dtsource = Source, @inusebatchid = InUseBatchId
   	from bJCCD with (nolock) where CostTrans = @origcosttrans and Mth = @origmth and JCCo = @co 
   	if @@rowcount = 0
   		begin
   		select @errmsg = 'Original Cost Detail transaction ' + isnull(convert(varchar(10), @origmth),'')
   			+ ':' + isnull(convert(varchar(5), @origcosttrans),'') + ' for reversal not found'
   		goto error
   		end
   
   	if @inusebatchid is not null
   		begin
   		select @errmsg = 'Original Cost Detail transaction for reversal is in use by another Batch'
   		goto error
   		end
   
   	if @dtsource <> 'JC CostAdj'
   		begin
   		select @errmsg = 'Original Cost Detail transaction for reversal was created with another source'
   		goto error
   		end
   
   	-- update JC transaction as 'in use'
   	update bJCCD set InUseBatchId = @batchid
   	where CostTrans = @origcosttrans and Mth = @origmth and JCCo = @co 
   	if @@rowcount <> 1
   		begin
   		select @errmsg = 'Unable to update original Cost Detail transaction as (In Use)'
   		goto error
   		end
   	end
   
   
   -- add entry to HQ Close Control as needed
   if not exists(select top 1 1 from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco)
   	begin
   	insert bHQCC (Co, Mth, BatchId, GLCo)
   	values (@co, @mth, @batchid, @glco)
   	end
   
   
   if @numrows > 1
   	begin
   	fetch next from bJCCB_insert into @co, @mth, @batchid, @seq, @costtrans, @glco, @reversalstatus, 
   			@origmth, @origcosttrans, @source
   	if @@fetch_status = 0 goto insert_check
   
   
   	close bJCCB_insert
   	deallocate bJCCB_insert
   	set @opencursor = 0
   	end
   
   
   
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot insert JC Cost Detail Batch entry!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biJCCB] ON [dbo].[bJCCB] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCCB] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bJCCB].[PstECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bJCCB].[INStdECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bJCCB].[OldPstECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bJCCB].[OldINStdECM]'
GO
