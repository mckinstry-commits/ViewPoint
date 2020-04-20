CREATE TABLE [dbo].[bPOHB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NULL,
[Description] [dbo].[bItemDesc] NULL,
[OrderDate] [dbo].[bDate] NULL,
[OrderedBy] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ExpDate] [dbo].[bDate] NULL,
[Status] [tinyint] NOT NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[INCo] [dbo].[bCompany] NULL,
[Loc] [dbo].[bLoc] NULL,
[ShipLoc] [dbo].[bShipLoc] NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[ShipIns] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[HoldCode] [dbo].[bHoldCode] NULL,
[PayTerms] [dbo].[bPayTerms] NULL,
[CompGroup] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[OldVendorGroup] [dbo].[bGroup] NULL,
[OldVendor] [dbo].[bVendor] NULL,
[OldDesc] [dbo].[bItemDesc] NULL,
[OldOrderDate] [dbo].[bDate] NULL,
[OldOrderedBy] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldExpDate] [dbo].[bDate] NULL,
[OldStatus] [tinyint] NULL,
[OldJCCo] [dbo].[bCompany] NULL,
[OldJob] [dbo].[bJob] NULL,
[OldINCo] [dbo].[bCompany] NULL,
[OldLoc] [dbo].[bLoc] NULL,
[OldShipLoc] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[OldCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[OldState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[OldZip] [dbo].[bZip] NULL,
[OldShipIns] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[OldHoldCode] [dbo].[bHoldCode] NULL,
[OldPayTerms] [dbo].[bPayTerms] NULL,
[OldCompGroup] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Attention] [dbo].[bDesc] NULL,
[OldAttention] [dbo].[bDesc] NULL,
[PayAddressSeq] [tinyint] NULL,
[OldPayAddressSeq] [tinyint] NULL,
[POAddressSeq] [tinyint] NULL,
[OldPOAddressSeq] [tinyint] NULL,
[Address2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[OldAddress2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Country] [char] (2) COLLATE Latin1_General_BIN NULL,
[OldCountry] [char] (2) COLLATE Latin1_General_BIN NULL,
[udOrderedBy] [int] NULL,
[udMCKPONumber] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udShipToJobYN] [dbo].[bYN] NULL CONSTRAINT [DF__bPOHB__udShipToJobYN__DEFAULT] DEFAULT ('N'),
[udPRCo] [dbo].[bCompany] NULL,
[udAddressName] [dbo].[bDesc] NULL,
[udPOFOB] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udShipMethod] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udPurchaseContact] [dbo].[bEmployee] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   
   CREATE     trigger [dbo].[btPOHBd] on [dbo].[bPOHB] for DELETE as 
	/***************************************************
    * Created: SE 5/14/97
    * Modified: LM 01/23/00 - When coming from PM we don't want to reset the inusebatchid
    *            Lord TV 03/21/02 Delete HQAT records
    *			GG 04/18/02 - #17051 - cleanup, removed psuedo-cursor used to unlock PO Header
    *			DC 5/15/09 - #133438 - Ensure stored procedures/triggers are using the correct attachment delete proc
    *
    * Delete trigger for PO Purchase Order Header Batch
    *
    ****************************************************/
   declare @numrows int, @errmsg varchar(255), @validcnt int
   
   select @numrows = @@rowcount 
   if @numrows = 0 return
   
   set nocount on
   
   -- do not allow removal if Items exist
   if exists(select 1 from deleted d join bPOIB b on d.Co = b.Co and d.Mth = b.Mth
   			and d.BatchId = b.BatchId and d.BatchSeq = b.BatchSeq)
	   begin
       select @errmsg = 'Purchase Order Items exist in Batch'
       goto error
       end
   
   --unlock PO Headers
   update bPOHD
   set InUseMth = null, InUseBatchId = null 
   from bPOHD h
   join deleted d on d.Co = h.POCo and d.PO = h.PO
   where h.InUseMth = d.Mth and h.InUseBatchId = d.BatchId
   
   --DC #133440
   --delete HQAT entries if not exists in POHD
   --if exists(select 1 from deleted where UniqueAttchID is not null)
   --	begin
   --	delete bHQAT 
   --	from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
   --	where h.UniqueAttchID not in(select t.UniqueAttchID from bPOHD t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
   --	end
   	   	
   --DC #133440
   insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
   select AttachmentID, suser_name(), 'Y' 
        	from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
   			where h.UniqueAttchID not in(select t.UniqueAttchID from bPOHD t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
   			and d.UniqueAttchID is not null     
   	   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot remove PO Header Batch'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btPOHBi    Script Date: 8/28/99 9:38:06 AM ******/
   CREATE     trigger [dbo].[btPOHBi] on [dbo].[bPOHB] for INSERT as
   

/*********************************************************
    * Created: SE 5/14/97
    * Modified: kb 1/4/99
    *           lm 4/1/99
    *			GG 04/18/02 - #17051 cleanup, removed pseudo-cursor used to lock bPOHD
    *			DANF 09/30/2004 - #20918 Correct insert statement of HQCC for rowset insert for RQ. 
    *
    *	Insert trigger for PO Header Batch
    *
    ***********************************************************/
   declare @numrows int, @errmsg varchar(255), @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- validate batch
   select @validcnt = count(*)
   from bHQBC r
   JOIN inserted i ON i.Co = r.Co and i.Mth = r.Mth and i.BatchId = r.BatchId
   where r.Status = 0
   if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid Batch or incorrect status, must be ''open'''
    	goto error
    	end
   -- validate Batch Trans Type
   if exists(select 1 from inserted where BatchTransType not in ('A','C','D'))
   	begin
    	select @errmsg = 'Invalid Batch Transaction Type, must be ''A'',''C'', or ''D'''
    	goto error
    	end
   
   -- add HQ Close Control for AP/PO GL Co#
   insert bHQCC (Co, Mth, BatchId, GLCo)
   select i.Co, i.Mth, i.BatchId, c.GLCo
   from inserted i
   join bAPCO c on i.Co = c.APCo
   where c.GLCo not in (select h.GLCo from bHQCC h join inserted i on h.Co = i.Co and h.Mth = i.Mth 
   						and h.BatchId = i.BatchId)
   group by  i.Co, i.Mth, i.BatchId, c.GLCo
    
   -- lock existing PO Headers, unless the batch is from a PM Interface 
   -- PM may create both an Entry and Change Order batch in the same interface, so don't lock the Header
   -- if PM source, batch trans type will be 'C'
   select @validcnt = count(*)
   from inserted i
   join bHQBC b on i.Co = b.Co and i.Mth = b.Mth and i.BatchId = b.BatchId
   where b.Source <> 'PM Intface' and i.BatchTransType in ('C','D')
   if @validcnt <> 0
   	begin
   	update bPOHD
   	set InUseMth = i.Mth, InUseBatchId = i.BatchId 
   	from bPOHD h
   	join inserted i on i.Co = h.POCo and i.PO = h.PO
   	join bHQBC b on i.Co = b.Co and i.Mth = b.Mth and i.BatchId = b.BatchId
   	where h.InUseMth is null and h.InUseBatchId is null
   		and b.Source <> 'PM Intface' and i.BatchTransType in ('C','D')
   	if @@rowcount <> @validcnt
   	 	begin
   	 	select @errmsg = 'Unable to lock Purchase Order Header'
   	 	goto error
   	 	end
   	end	
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot insert PO Header Batch entry'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  trigger [dbo].[btPOHBu] on [dbo].[bPOHB] for UPDATE as
   

/*--------------------------------------------------------------
    *  Created: SE 5/14/97
    *  Modified: EN 11/5/98
    *			GG 04/29/02 - #17051 - cleanup
	*			DC 10/11/2007 - 125594 - Changing PO number in PO batch should update RQRL.PO column
	*			DC 12/22/2008 - #130129 - Combine RQ and PO into a single module
	*			GP 7/27/2011 - TK-07144 changed bPO to varchar(30)
    *
    *	Update trigger on PO Header Batch
    *--------------------------------------------------------------*/
   
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
           @errno tinyint, @audit bYN, @validcnt int, @validcnt2 int, @typecnt int,
			@ipo varchar(30), @dpo varchar(30)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   /* check for key changes */
   select @validcnt = count(*)
   from deleted d
   join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
   if @numrows <> @validcnt
   	begin
   	select @errmsg = 'Cannot change Company, Month, Batch ID #, or Batch Seq#'
   	goto error
   	end
   
   /* check for change in BatchTransType */
   select @validcnt = count(*)
   from deleted d
   join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
   where (d.BatchTransType = 'A' and i.BatchTransType in ('C','D'))
   	or (d.BatchTransType in ('C','D') and i.BatchTransType = 'A')
   if @validcnt > 0
   	begin
   	select @errmsg = 'Cannot change from ''add'' to ''change'' or ''delete'' or vice-versa'
   	goto error
   	end
   
   /* if change or delete, cannot change PO */
   select @validcnt = count(*)
   from deleted d
   join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
   where i.BatchTransType in ('C','D') and d.PO <> i.PO
   if @validcnt > 0
   	begin
   	select @errmsg = 'Cannot change PO# on ''change'' or ''delete'''
   	goto error
   	end
   

   -- DC #125594
	--  If the PO # is being updated, and that PO # exists in RQRL.PO then we need to 
	-- update RQRL also to keep the two records in sync.
	select @ipo = i.PO, @dpo = d.PO
	from deleted d
	join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
	
	if @ipo <> @dpo
		BEGIN
   			-- first check to see if the POIB company exist in RQCO.  If the customer does not have RQ then 
   			-- exit because I don't want to add additional overhead to this trigger.
   			--DC #130129
   			--if exists(SELECT top 1 1 FROM inserted i join RQCO c with (NOLOCK) on c.RQCo = i.Co)
   				--BEGIN
				-- if the deleted PO exists in RQRL, then reset RQRL.PO to the inserted PO
   				if exists(SELECT top 1 1 
							FROM RQRL r with (NOLOCK)
								join deleted d with (NOLOCK) on d.Co = r.RQCo and r.PO = @dpo)
   					BEGIN
   						UPDATE RQRL
   						Set PO = @ipo
   						FROM RQRL r with (NOLOCK)
   							join deleted d with (NOLOCK) on d.Co = r.RQCo and r.PO = @dpo   							
   					END
   				--END
		END


   return
   
   error:
      select @errmsg = @errmsg + ' - cannot update PO Header Batch (bPOHB)'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 11/13/13
-- Description:	Trigger for Address Updates
-- =============================================
CREATE TRIGGER [dbo].[mcktrShipToJob] 
   ON  [dbo].[bPOHB] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	IF UPDATE(udShipToJobYN) AND (SELECT udShipToJobYN FROM INSERTED) = 'Y'
		AND (SELECT Job FROM INSERTED) IS NOT NULL
	BEGIN
		DECLARE @Batch TINYINT, @BatchMonth bDate, @Seq TINYINT
		SELECT @Batch = BatchId, @BatchMonth= Mth, @Seq = BatchSeq FROM INSERTED
		
		UPDATE bPOHB
		SET Address = CASE WHEN j.ShipAddress IS NULL THEN j.MailAddress ELSE j.ShipAddress END, 
			Address2 = CASE WHEN j.ShipAddress2 IS NULL THEN j.MailAddress ELSE j.ShipAddress2 END, 
			City = CASE WHEN j.ShipCity IS NULL  THEN j.MailCity ELSE j.ShipCity END, 
			State = CASE WHEN j.ShipState IS NULL THEN j.MailState ELSE j.ShipState END, 
			Zip = CASE WHEN j.ShipZip IS NULL THEN j.MailZip ELSE j.ShipZip END, 
			Country = CASE WHEN j.ShipCountry IS NULL THEN j.MailCountry ELSE j.ShipCountry END
		FROM JCJM j 
			INNER JOIN inserted i ON j.JCCo = i.JCCo AND j.Job = i.Job
		WHERE i.BatchId=@Batch AND i.Mth=@BatchMonth AND i.BatchSeq=@Seq		
	END
	ELSE
	IF (SELECT Job FROM INSERTED) IS NULL AND (SELECT udShipToJobYN FROM INSERTED) = 'Y'
	BEGIN
		RAISERROR('Ship to Job has been checked but no Job has been selected.  Please select a Job and try again.',16,11)
		ROLLBACK TRAN
	END
END

GO
CREATE UNIQUE CLUSTERED INDEX [biPOHB] ON [dbo].[bPOHB] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPOHB] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
