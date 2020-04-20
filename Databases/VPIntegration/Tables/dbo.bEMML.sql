CREATE TABLE [dbo].[bEMML]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[Line] [int] NOT NULL,
[BatchTransType] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[EMTrans] [dbo].[bTrans] NULL,
[UsageDate] [dbo].[bDate] NOT NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[OnRoadLoaded] [dbo].[bHrs] NULL,
[OnRoadUnLoaded] [dbo].[bHrs] NULL,
[OffRoad] [dbo].[bHrs] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[OldTrans] [dbo].[bTrans] NULL,
[OldUsageDate] [dbo].[bDate] NULL,
[OldState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[OldOnRoadLoaded] [dbo].[bUnits] NULL,
[OldOnRoadUnLoaded] [dbo].[bUnits] NULL,
[OldOffRoad] [dbo].[bUnits] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btEMBMd    Script Date: 8/28/99 9:37:14 AM ******/
    CREATE       trigger [dbo].[btEMMLd] on [dbo].[bEMML] for DELETE as
    

/*-----------------------------------------------------------------
     *	CREATED BY: JM   8/12/02
     *	MODIFIED By:  TV 02/11/04 - 23061 added isnulls
     *						TV 03/30/05 27298 - Clean up mileage tables
     *					GP 05/26/09 - 133434, added HQAT insert
     *
     *	This trigger updates EM Miles by State transaction detail table
     *  	bEMMS to remove InUseBatchId when deletion(s) are made from bEMML.
     *
     *	Rejects deletion if the following error condition exists:
     *
     */----------------------------------------------------------------
    
    declare @errmsg varchar(255),
    	@nullcnt int,
    	@numrows int,
    	@source bSource
    
    select @numrows = @@rowcount
    
    set nocount on
    
    if @numrows = 0 return
    
    /* Remove InUseBatchId from Transaction Detail table for rows pointed to by deleted batch entries 
    update bEMSM set InUseBatchID = null from bEMSM c, deleted d
    where c.EMCo = d.Co and c.Mth = d.Mth and c.EMTrans = d.EMTrans*/
    
    /*delete HQAT records if not exists in EMMS
    delete bHQAT from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
    where h.UniqueAttchID not in(select t.UniqueAttchID from bEMSM t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)*/
    
    -- Delete attachments if they exist. Make sure UniqueAttchID is not null.
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
    select AttachmentID, suser_name(), 'Y' 
    from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
    where h.UniqueAttchID not in(select t.UniqueAttchID from bEMSD t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
		and d.UniqueAttchID is not null    
    
    return
    
    error:
    	select @errmsg = isnull(@errmsg,'') + ' - cannot delete EM Detail Batch entry!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
    
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btEMSMi    Script Date: 8/28/99 9:38:20 AM ******/
    CREATE        trigger [dbo].[btEMMLi] on [dbo].[bEMML] for INSERT as
     

/*-----------------------------------------------------------------
      *	CREATED BY: JM   8/12/02
      *	MODIFIED By: RM 01/08/03 - Cleanup for new table structure.
      *				  TV 02/11/04 - 23061 added isnulls
      * 	 	        DANF 03/15/05 - #27294 - Remove scrollable cursor.
      *	This trigger rejects insertion in bEMML (EM Batch) if any of the
      * following error conditions exist:
      *
      * 	Invalid Batch ID#
      *	Batch associated with another source or table
      *	Batch in use by someone else
      *	Batch status not 'open'
      *	EMRef to a EMSM trans that doesn't exist
      *	EMSM trans already in use by a batch
      *	EMSM trans created from a source other than EM
      *
      *	Updates InUseBatchId in bEMSM for existing transactions.
      *	Updates InUseBatchId of reversal trans if adding reversal
      *
      *	Adds entry to HQ Close Control as needed.
      *----------------------------------------------------------------*/
     declare @batchid bBatchID,
     	@batchseq int,
     	@checktable varchar(30),
     	@co bCompany,
     	@detailsource bSource,
     	@EMSMsource bSource,
     	@emtrans bTrans,
     	@errmsg varchar(255),
     	@errtext varchar(60),
     	@glco bCompany,
     	@inusebatchid bBatchID,
     	@inuseby bVPUserName,
     	@mth bMonth,
     	@numrows int,
     	@origemtrans bTrans,
     	@origmth bMonth,
     	@rcode tinyint,
     	@reversalstatus tinyint,
     	@status tinyint,
     	@tablename char(20),
     	@transsource bSource
    
     select @numrows = @@rowcount
    
     if @numrows = 0 return
    
     set nocount on
    
    
    
     if @numrows = 1
     	select @co = Co, @mth = Mth, @batchid = BatchId, @batchseq = BatchSeq, @emtrans = EMTrans
     	from inserted
     else
     	begin
     	/* use a cursor to process each inserted row */
     	declare bEMSM_insert cursor local fast_forward for select Co, Mth, BatchId, BatchSeq, EMTrans from inserted
     	open bEMSM_insert
     	fetch next from bEMSM_insert into @co, @mth, @batchid, @batchseq, @emtrans
     	if @@fetch_status <> 0
     		begin
     		select @errmsg = 'Cursor error'
     		goto error
     		end
     	end
    
     insert_check:
    
    /* Get GLCo from bEMCO */
    select @glco = GLCo from bEMCO where EMCo = @co
    
     /* validate HQ Batch */
     select @checktable = 'EMMH'
     exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'EMMiles', @checktable, @errtext output, @status output
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
    
    /* validate existing EM trans */
    if @emtrans is not null
        begin
    	select @detailsource = 'EMMiles'--, @inusebatchid = InUseBatchID
    	from bEMSD where Co = @co and Mth = @mth and EMTrans = @emtrans
    	select @numrows = @@rowcount
     	if @numrows = 0
     		begin
     		select @errmsg = 'EM Detail transaction not found'
     		goto error
     		end
     	if @inusebatchid is not null
     		begin
     		select @errmsg = 'EM Detail transaction in use by another Batch'
     		goto error
     		end
     	if @detailsource <> 'EMMiles'
     		begin
     		select @errmsg = 'EM transaction was created with another source'
     		goto error
     		end
   
   	--Shouldnt need following code, header will be marked as in use.
     	/* update EM transaction as 'in use' 
    	update bEMSD set InUseBatchID = @batchid where EMCo = @co and Mth = @mth and EMTrans = @emtrans
    	select @numrows = @@rowcount
     	if @numrows <> 1
     		begin
     		select @errmsg = 'Unable to update EM Detail as In Use'
     		goto error
     		end*/
    	end
    
    /* add entry to HQ Close Control as needed */
    if not exists(select * from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco)
    	insert bHQCC (Co, Mth, BatchId, GLCo) values (@co, @mth, @batchid, @glco)
     	if @numrows > 1
     		begin
     		  fetch next from bEMSM_insert into @co, @mth, @batchid, @batchseq, @emtrans
     		  if @@fetch_status = 0
     			goto insert_check
     		else
     			begin
     			  close bEMSM_insert
     			  deallocate bEMSM_insert
     			end
     		end
    
     return
     error:
     	if @numrows > 1
     		begin
     		close bEMSM_insert
     		deallocate bEMSM_insert
     		end
         	select @errmsg = isnull(@errmsg,'') + ' - cannot insert EM Detail Batch entry!'
         	RAISERROR(@errmsg, 11, -1);
         	rollback transaction
    
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biEMML] ON [dbo].[bEMML] ([Co], [Mth], [BatchId], [BatchSeq], [Line]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMML] ([KeyID]) ON [PRIMARY]
GO
