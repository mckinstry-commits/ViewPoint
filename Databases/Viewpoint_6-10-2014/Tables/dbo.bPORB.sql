CREATE TABLE [dbo].[bPORB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[POTrans] [dbo].[bTrans] NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[POItem] [dbo].[bItem] NOT NULL,
[RecvdDate] [dbo].[bDate] NOT NULL,
[RecvdBy] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Description] [dbo].[bDesc] NULL,
[UnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bPORB_UnitCost] DEFAULT ((0)),
[ECM] [dbo].[bECM] NULL,
[RecvdUnits] [dbo].[bUnits] NOT NULL,
[RecvdCost] [dbo].[bDollar] NOT NULL,
[BOUnits] [dbo].[bUnits] NOT NULL,
[BOCost] [dbo].[bDollar] NOT NULL,
[OldPO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[OldPOItem] [dbo].[bItem] NULL,
[OldRecvdDate] [dbo].[bDate] NULL,
[OldRecvdBy] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldDesc] [dbo].[bDesc] NULL,
[OldUnitCost] [dbo].[bUnitCost] NULL,
[OldECM] [dbo].[bECM] NULL,
[OldRecvdUnits] [dbo].[bUnits] NULL,
[OldRecvdCost] [dbo].[bDollar] NULL,
[OldBOUnits] [dbo].[bUnits] NULL,
[OldBOCost] [dbo].[bDollar] NULL,
[Receiver#] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[OldReceiver#] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[InvdFlag] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPORB_InvdFlag] DEFAULT ('N'),
[OldInvdFlag] [dbo].[bYN] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[APTrans] [dbo].[bTrans] NULL,
[APLine] [int] NULL,
[UISeq] [int] NULL,
[UILine] [int] NULL,
[APMth] [dbo].[bMonth] NULL,
[UIMth] [dbo].[bMonth] NULL,
[OldPOItemLine] [int] NULL,
[POItemLine] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/****** Object:  Trigger dbo.btPORBd    Script Date: 8/28/99 9:38:08 AM ******/
CREATE     trigger [dbo].[btPORBd] on [dbo].[bPORB] for DELETE as 
/*******************************************************
*  Created: ??
*  Modified: DanF 05/11/00 - Added Delete of PORA and PORI
*            TV(DanF's humble servant) 03/21/02 Delete HQAT records      
*			GG 04/29/02 - #17051 - cleanup
*			DC 05/15/09 - #133438 - Ensure stored procedures/triggers are using the correct attachment delete proc
*			GF 08/21/2011 TK-07879 PO Item Line
*			GF 06/13/2012 TK-15700 delete from rest of distribution tables 
*
*
*	Delete trigger for PO Receipts Batch
*
*****************************************************/
declare @numrows int, @errmsg varchar(255)
       

select @numrows = @@rowcount 
if @numrows = 0 return
set nocount on
   
   /* remove rows from bPORA for new entries only */
   delete bPORA
       from bPORA c
       join deleted d on c.POCo = d.Co and c.Mth = d.Mth and c.BatchId = d.BatchId and c.BatchSeq = d.BatchSeq
       join bHQBC e on e.Co = d.Co and e.Mth = d.Mth and e.BatchId = d.BatchId
       where e.Status <> 4
   
   /* remove rows from bPORI for new entries only */
   delete bPORI
       from bPORI c
       join deleted d on c.POCo = d.Co and c.Mth = d.Mth and c.BatchId = d.BatchId and c.BatchSeq = d.BatchSeq
       join bHQBC e on e.Co = d.Co and e.Mth = d.Mth and e.BatchId = d.BatchId
       where e.Status <> 4
   
   ---- TK-15700 remove rows from bPORG for new entries only
   delete bPORG
       from bPORG c
       join deleted d on c.POCo = d.Co and c.Mth = d.Mth and c.BatchId = d.BatchId and c.BatchSeq = d.BatchSeq
       join bHQBC e on e.Co = d.Co and e.Mth = d.Mth and e.BatchId = d.BatchId
       where e.Status <> 4
   
   
   
   -- unlock existing PO Receipt transactions pulled into batch for change or delete
   if exists(select 1 from deleted where BatchTransType in ('C','D'))
   	begin
   	update bPORD
   	set InUseBatchId=null
   	from deleted d
   	join bPORD t on d.Co = t.POCo and d.PO = t.PO and d.POItem = t.POItem
   		and d.POTrans = t.POTrans 
   	end



---- unlock PO Item Line if no other entries in batch for this Item Line TK-07879
UPDATE dbo.vPOItemLine
	SET InUseBatchId = null,
		InUseMth = null
FROM DELETED d
INNER JOIN dbo.vPOItemLine t ON d.Co=t.POCo AND d.PO=t.PO AND d.POItem=t.POItem AND d.POItemLine=t.POItemLine
WHERE d.POItemLine NOT IN (SELECT POItemLine FROM dbo.bPORB r WHERE r.Co=d.Co 
			AND r.PO=d.PO AND r.POItem=d.POItem AND r.POItemLine=d.POItemLine
			AND r.Mth=d.Mth AND r.BatchId=d.BatchId)



   -- unlock PO Item if no other entries in batch for this Item
   update dbo.bPOIT
   set InUseBatchId = null, InUseMth = null
   from deleted d
   join dbo.bPOIT t on d.Co = t.POCo and d.PO = t.PO and d.POItem = t.POItem
   where d.POItem not in (select POItem from bPORB r where r.Co = d.Co 
   	and r.PO = d.PO and r.POItem = d.POItem and r.Mth = d.Mth and r.BatchId = d.BatchId)
   
   -- unlock PO Header if no other entries in batch for this PO
   update dbo.bPOHD
   set InUseBatchId = null, InUseMth = null
   from deleted d
   join dbo.bPOHD t on d.Co = t.POCo and d.PO = t.PO
   where d.PO not in (select PO from bPORB r where r.Co = d.Co and r.PO = d.PO
   	and r.Mth = d.Mth and r.BatchId = d.BatchId)
   
   --DC #133438
   --delete HQAT entries if not exists in PORD
   --if exists(select 1 from deleted where UniqueAttchID is not null)
   --	begin
   --	delete bHQAT 
   --	from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
   --	where h.UniqueAttchID not in(select t.UniqueAttchID from bPORD t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
   --	end
   
   --DC #133438
   insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
   select AttachmentID, suser_name(), 'Y' 
        	from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
   			where h.UniqueAttchID not in(select t.UniqueAttchID from bPORD t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
   			and d.UniqueAttchID is not null           
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot delete PO Receipts Batch entry (bPORB)'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btPORBi    Script Date: 8/28/99 9:38:08 AM ******/
CREATE   trigger [dbo].[btPORBi] on [dbo].[bPORB] for INSERT as 
   

/************************************************
    *	Created: ???
    *  Modified: kb 1/4/99
    *			GG 04/18/02 - #17051 cleanup, removed pseudo-cursor 
    *			GF 08/21/2011 - TK-07879 PO Item Line Enhancement
    *
    * 
    * Insert trigger for PO Receipt Batch entries
    *
    *********************************************/
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
   
   -- add HQ Close Control for GL Co#s referenced by PO Item
   insert bHQCC (Co, Mth, BatchId, GLCo)
   select i.Co, i.Mth, i.BatchId, p.GLCo
   from inserted i
   join bPOIT p on i.Co = p.POCo and i.PO = p.PO and i.POItem = p.POItem
   where p.GLCo not in (select h.GLCo from bHQCC h join inserted i on h.Co = i.Co and h.Mth = i.Mth 
   						and h.BatchId = i.BatchId)
   
   --lock existing bPORD Receipt Detail entries pulled into batch
   select @validcnt = count(*) from inserted where BatchTransType in ('C','D')
   if @validcnt <> 0
   	begin
   	update bPORD
   	set InUseBatchId = i.BatchId
   	from bPORD d
   	join inserted i on i.Co = d.POCo and i.Mth = d.Mth and i.POTrans = d.POTrans
   	if @@rowcount <> @validcnt
    		begin
    		select @errmsg = 'Unable to lock PO Receipt Detail'
    		goto error
    		end
    	end	
   
--lock existing PO Headers
update dbo.bPOHD
set InUseMth = i.Mth, InUseBatchId = i.BatchId 
from dbo.bPOHD h
join inserted i on i.Co = h.POCo and i.PO = h.PO
where h.InUseMth is null and h.InUseBatchId is null

-- lock existing PO Items
update dbo.bPOIT
set InUseMth = i.Mth, InUseBatchId = i.BatchId 
from dbo.bPOIT t
join inserted i on i.Co = t.POCo and i.PO = t.PO and i.POItem = t.POItem
where t.InUseMth is null and t.InUseBatchId is null
   
---- lock existing PO Item Line TK-07879
UPDATE dbo.vPOItemLine
		SET InUseMth = i.Mth,
			InUseBatchId = i.BatchId 
FROM dbo.vPOItemLine t
JOIN INSERTED i ON i.Co = t.POCo and i.PO = t.PO and i.POItem = t.POItem AND i.POItemLine = t.POItemLine
WHERE t.InUseMth is null and t.InUseBatchId is null



return

error:
	select @errmsg = @errmsg + ' - cannot insert PO Receipts Batch entry (PORB)'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/****** Object:  Trigger dbo.btPORBu    Script Date: 8/28/99 9:38:08 AM ******/
CREATE  trigger [dbo].[btPORBu] on [dbo].[bPORB] for UPDATE as 
/*-------------------------------------------------------------- 
*
*  Update trigger for PORB
*  Created By: 
*  Modified By:	GF 08/21/2011 TK-07879 PO Item Line       
*
*
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255),
		@validcnt int, @validcnt2 INT
		
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
   
/* Validate PO */
if update(PO)
	begin
	select @validcnt = count(*) from bPOHD r,inserted i where
		i.Co = r.POCo
    		and i.PO = r.PO
	if @validcnt <> @numrows
		begin
 		select @errmsg = 'PO is Invalid '
 		goto error
 		end

	update bPOHD
		set InUseBatchId=null, InUseMth=null from deleted d, bPOHD t
		where d.Co=t.POCo and d.PO=t.PO and d.PO not in (select PO from bPORB r where

		r.Co=d.Co and r.PO=d.PO and r.Mth=d.Mth and r.BatchId=d.BatchId)
	update bPOHD
		set InUseBatchId=i.BatchId, InUseMth=i.Mth from inserted i, bPOHD t
		where i.Co=t.POCo and i.PO=t.PO 
   	end
   
   
/* validate PO Item */
if update(POItem)
   	begin
   	select @validcnt = count(*) from bPOIT r,inserted i where
   	    i.Co = r.POCo
   	    and i.PO = r.PO
   	    and i.POItem = r.POItem
   	if @validcnt <> @numrows
   	      begin
   	      select @errmsg = 'PO Item is Invalid '
   	      goto error
   	      end
   	update bPOIT
   		set InUseBatchId=null, InUseMth=null from deleted d, bPOIT t
   		where d.Co=t.POCo and d.PO=t.PO and d.POItem=t.POItem and
   		d.POItem not in (select POItem from bPORB r where r.Co=d.Co 
   		and r.PO=d.PO and r.POItem=d.POItem and r.Mth=d.Mth and r.BatchId=d.BatchId)
   	update bPOIT
   		set InUseBatchId=i.BatchId, InUseMth=i.Mth from inserted i, bPOIT t
   		where i.Co=t.POCo and i.PO=t.PO and i.POItem=t.POItem
   	end
   
---- validate PO Item Line TK-07879
IF UPDATE(POItemLine)
	BEGIN
   	select @validcnt = count(*) from dbo.vPOItemLine r,inserted i where
   	    i.Co = r.POCo
   	    and i.PO = r.PO
   	    and i.POItem = r.POItem
   	    AND i.POItemLine = r.POItemLine
   	if @validcnt <> @numrows
   	      begin
   	      select @errmsg = 'PO Item Line is Invalid '
   	      goto error
   	      END
   	      
   	UPDATE dbo.vPOItemLine
		SET InUseBatchId=null,
			InUseMth=NULL
	FROM DELETED  d JOIN dbo.vPOItemLine t ON t.POCo=d.Co AND t.PO=d.PO AND t.POItem=d.POItem AND t.POItemLine=d.POItemLine
	WHERE d.Co=t.POCo 
			AND d.PO=t.PO 
			AND d.POItem=t.POItem 
			AND d.POItemLine=t.POItemLine
			AND d.POItemLine NOT IN (select POItemLine FROM dbo.bPORB r WHERE r.Co=d.Co
					AND r.PO=d.PO AND r.POItem=d.POItem AND r.POItemLine=d.POItemLine
					AND r.Mth=d.Mth and r.BatchId=d.BatchId)
					
   	UPDATE dbo.vPOItemLine
		SET InUseBatchId=i.BatchId,
			InUseMth=i.Mth
	FROM INSERTED i JOIN dbo.vPOItemLine t ON t.POCo=i.Co AND t.PO=i.PO AND t.POItem=i.POItem AND t.POItemLine=i.POItemLine
   	WHERE i.Co=t.POCo and i.PO=t.PO
   		AND i.POItem = t.POItem
   		AND i.POItemLine = t.POItemLine
	
	
	END
	
   
   
   
   /* BatchTransType must be 'A'-Add, 'C'-Change, 'D'-Delete */
   select @validcnt = count(*) from inserted i where i.BatchTransType='A' or i.BatchTransType='C'
   	or i.BatchTransType='D'
   
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Batch Action is Invalid '
   	goto error
   	end
   
   /* validate existing PO trans - if one is referenced */
   
   
   select @validcnt2 = count(*) from bPORD r,inserted i where
   	i.Co=r.POCo and i.Mth=r.Mth and i.POTrans=r.POTrans and i.POTrans is not null
   if @validcnt2>1
   	begin
   	select @validcnt = count(*) from bPORD r,inserted i where
   	i.Co=r.POCo and i.Mth=r.Mth and i.POTrans=r.POTrans and InUseBatchId is null
   	if @validcnt<>@validcnt2
   		begin
   		select @errmsg = 'PO transaction in use by another batch.'
   		goto error
   		end
   
   	update bPORD
   	set InUseBatchId=i.BatchId from bPORD r, inserted i
   
   		where i.Co=r.POCo and i.Mth=r.Mth and i.POTrans=r.POTrans and i.POTrans is not null	
   	if @@rowcount<>@validcnt2
   		begin
   		select @errmsg = 'Unable to update PO Receipts Detail as InUse.'
   /*PO Receipts Detail as 'In Use'.'*/
   		goto error
   		end
   	end
   	
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot update PORB'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction


GO
ALTER TABLE [dbo].[bPORB] WITH NOCHECK ADD CONSTRAINT [CK_bPORB_ECM] CHECK (([ECM]='E' OR [ECM]='C' OR [ECM]='M' OR [ECM] IS NULL))
GO
ALTER TABLE [dbo].[bPORB] WITH NOCHECK ADD CONSTRAINT [CK_bPORB_InvdFlag] CHECK (([InvdFlag]='Y' OR [InvdFlag]='N'))
GO
ALTER TABLE [dbo].[bPORB] WITH NOCHECK ADD CONSTRAINT [CK_bPORB_OldECM] CHECK (([OldECM]='E' OR [OldECM]='C' OR [OldECM]='M' OR [OldECM] IS NULL))
GO
ALTER TABLE [dbo].[bPORB] WITH NOCHECK ADD CONSTRAINT [CK_bPORB_OldInvdFlag] CHECK (([OldInvdFlag]='Y' OR [OldInvdFlag]='N' OR [OldInvdFlag] IS NULL))
GO
CREATE UNIQUE CLUSTERED INDEX [biPORB] ON [dbo].[bPORB] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPORB] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
