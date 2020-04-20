CREATE TABLE [dbo].[bINAB]
(
[Co] [dbo].[bCompany] NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[INTrans] [int] NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[Units] [dbo].[bUnits] NOT NULL,
[UnitCost] [dbo].[bUnitCost] NOT NULL,
[ECM] [dbo].[bECM] NOT NULL,
[TotalCost] [dbo].[bDollar] NOT NULL,
[OldLoc] [dbo].[bLoc] NULL,
[OldMaterial] [dbo].[bMatl] NULL,
[OldActDate] [dbo].[bDate] NULL,
[OldDescription] [dbo].[bDesc] NULL,
[OldGLAcct] [dbo].[bGLAcct] NULL,
[OldUnits] [dbo].[bUnits] NULL,
[OldUnitCost] [dbo].[bUnitCost] NULL,
[OldECM] [dbo].[bECM] NULL,
[OldTotalCost] [dbo].[bDollar] NULL,
[BatchType] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
ALTER TABLE [dbo].[bINAB] ADD
CONSTRAINT [CK_bINAB_BatchTransType] CHECK (([BatchTransType]='A' OR [BatchTransType]='C' OR [BatchTransType]='D'))
ALTER TABLE [dbo].[bINAB] ADD
CONSTRAINT [CK_bINAB_ECM] CHECK (([ECM]='E' OR [ECM]='C' OR [ECM]='M'))
ALTER TABLE [dbo].[bINAB] ADD
CONSTRAINT [CK_bINAB_OldECM] CHECK (([OldECM]='E' OR [OldECM]='C' OR [OldECM]='M' OR [OldECM] IS NULL))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE   trigger [dbo].[btINABd] on [dbo].[bINAB] for DELETE as
   

/*-----------------------------------------------------------------
    * Created : GR 12/14/99
    * Modified: GG 03/02/00 - remove checks for # of rows updated
    *           TV 03/21/02 - Delete HQAT records
    *			GP 05/15/09 - Issue 133436 Removed HQAT delete, added new insert
    *
    *	Unlock any associated IN Detail - set InUseBatchId to null.
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- 'unlock' existing IN Detail
   update bINDT
   set InUseBatchId = null
   from bINDT t
   join deleted d on d.Co = t.INCo and d.Mth = t.Mth and d.INTrans = t.INTrans
   
	-- Delete attachments if they exist. Make sure UniqueAttchID is not null.
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
    select AttachmentID, suser_name(), 'Y' 
    from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
    where h.UniqueAttchID not in(select t.UniqueAttchID from bINDT t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
		and d.UniqueAttchID is not null   
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete Adjustments Batch!'
       RAISERROR(@errmsg, 11, -1);
   
       rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE   TRIGGER [dbo].[btINABi] ON [dbo].[bINAB] FOR INSERT AS
/*----------------------------------------------------------------------------
*Created:	GR  12/10/1999
*Modified:	GWC 06/09/2004 - #24357 Removed ability to add non "IN Adj" records
*						   - modified header information to look more standard
*			GG 09/15/06 - #120561 - insert bHQCC entries 
*
*----------------------------------------------------------------------------
*/
    
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int

select @numrows = @@rowcount

if @numrows = 0 return
set nocount on

--Validate batch
select @validcnt = count(*)
from bHQBC r
JOIN inserted i ON i.Co=r.Co and i.Mth=r.Mth and i.BatchId=r.BatchId
if @validcnt<>@numrows
	begin
	select @errmsg = 'Invalid Batch ID#'
	goto error
	end

select @validcnt = count(*)
from bHQBC r
jOIN inserted i ON i.Co=r.Co and i.Mth=r.Mth and
           i.BatchId=r.BatchId and r.Status=0
if @validcnt<>@numrows
	begin
	select @errmsg = 'Must be an open batch.'
	goto error
	end
   
--Validate that all records being inserted have a Source of IN Adj
IF EXISTS(SELECT TOP 1 1 FROM bINDT t INNER JOIN inserted i ON
   i.Co = t.INCo AND i.Mth = t.Mth AND i.INTrans = t.INTrans AND  t.Source <> 'IN Adj')
   	BEGIN
   	SELECT @errmsg = 'Unable to insert records whose source is not "IN Adj"'
   	GOTO error
   	END

-- add HQ Close Control for IN GL Co#
insert bHQCC (Co, Mth, BatchId, GLCo)
select i.Co, i.Mth, i.BatchId, c.GLCo
from inserted i
join bINCO c on i.Co = c.INCo
where c.GLCo not in (select h.GLCo from bHQCC h join inserted i on h.Co = i.Co and h.Mth = i.Mth 
						and h.BatchId = i.BatchId)
-- add HQ Close Control for posted GL Co#s 
insert bHQCC (Co, Mth, BatchId, GLCo)
select Co, Mth, BatchId, GLCo
from inserted 
where GLCo not in (select h.GLCo from bHQCC h join inserted i on h.Co = i.Co and h.Mth = i.Mth 
						and h.BatchId = i.BatchId)
    
   
select @validcnt = count(*) from inserted where BatchTransType <> 'A'
   
update bINDT
set InUseBatchId = i.BatchId
from bINDT t, inserted i
where i.Co=t.INCo and i.Mth = t.Mth and i.INTrans=t.INTrans and i.BatchTransType<>'A'
if @validcnt <> @@rowcount
	begin
	select @errmsg = 'Unable to flag IN Trans as (In Use).'
	goto error
	end
   
return

error:
	select @errmsg = @errmsg + ' - cannot insert IN Adjustment Batch'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
   
   
   
   
  
 




GO
CREATE UNIQUE CLUSTERED INDEX [biINAB] ON [dbo].[bINAB] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bINAB] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINAB].[ECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINAB].[OldECM]'
GO
