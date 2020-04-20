CREATE TABLE [dbo].[bJCPD]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[DetSeq] [int] NOT NULL,
[Source] [dbo].[bSource] NOT NULL,
[JCTransType] [varchar] (2) COLLATE Latin1_General_BIN NOT NULL,
[TransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bJCPD_TransType] DEFAULT ('A'),
[ResTrans] [dbo].[bTrans] NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[CostType] [dbo].[bJCCType] NOT NULL,
[BudgetCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[EMCo] [dbo].[bCompany] NULL,
[Equipment] [dbo].[bEquip] NULL,
[PRCo] [dbo].[bCompany] NULL,
[Craft] [dbo].[bCraft] NULL,
[Class] [dbo].[bClass] NULL,
[Employee] [dbo].[bEmployee] NULL,
[Description] [dbo].[bItemDesc] NULL,
[DetMth] [dbo].[bMonth] NULL,
[FromDate] [dbo].[bDate] NULL,
[ToDate] [dbo].[bDate] NULL,
[Quantity] [dbo].[bUnits] NULL,
[UM] [dbo].[bUM] NULL,
[Units] [dbo].[bUnits] NULL,
[UnitHours] [dbo].[bHrs] NULL,
[Hours] [dbo].[bHrs] NULL,
[Rate] [dbo].[bUnitCost] NULL,
[UnitCost] [dbo].[bUnitCost] NULL,
[Amount] [dbo].[bDollar] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[OldTransType] [char] (1) COLLATE Latin1_General_BIN NULL,
[OldJob] [dbo].[bJob] NULL,
[OldPhaseGroup] [dbo].[bGroup] NULL,
[OldPhase] [dbo].[bPhase] NULL,
[OldCostType] [dbo].[bJCCType] NULL,
[OldBudgetCode] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[OldEMCo] [dbo].[bCompany] NULL,
[OldEquipment] [dbo].[bEquip] NULL,
[OldPRCo] [dbo].[bCompany] NULL,
[OldCraft] [dbo].[bCraft] NULL,
[OldClass] [dbo].[bClass] NULL,
[OldEmployee] [dbo].[bEmployee] NULL,
[OldDescription] [dbo].[bItemDesc] NULL,
[OldDetMth] [dbo].[bMonth] NULL,
[OldFromDate] [dbo].[bDate] NULL,
[OldToDate] [dbo].[bDate] NULL,
[OldQuantity] [dbo].[bUnits] NULL,
[OldUM] [dbo].[bUM] NULL,
[OldUnits] [dbo].[bUnits] NULL,
[OldUnitHours] [dbo].[bHrs] NULL,
[OldHours] [dbo].[bHrs] NULL,
[OldRate] [dbo].[bUnitCost] NULL,
[OldUnitCost] [dbo].[bUnitCost] NULL,
[OldAmount] [dbo].[bDollar] NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************/
CREATE trigger [dbo].[btJCPDd] on [dbo].[bJCPD] for DELETE as
/*-----------------------------------------------------------------
* Created By:	GF 03/29/2009	- issue #129898
* Modified By:	CHS 05/15/2009	- issue #133437
*
*	Unlock any associated JCPR Detail - set InUseBatchId to null.
*
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

----select @validcnt = count(*) from deleted where ResTrans is not null

---- 'unlock' existing MS Detail
update bJCPR set InUseBatchId = null
from bJCPR t join deleted d on d.Co = t.JCCo and d.Mth = t.Mth and d.ResTrans = t.ResTrans


-- issue #133437
-- Delete attachments if they exist. Make sure UniqueAttchID is not null
insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
          select AttachmentID, suser_name(), 'Y' 
              from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID                  
              where d.UniqueAttchID is not null


return


error:
	select @errmsg = @errmsg + ' - cannot delete JC Projection Detail Batch!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************************************/
CREATE trigger [dbo].[btJCPDi] on [dbo].[bJCPD] for INSERT as
/*--------------------------------------------------------------
* Created By:	GF	03/29/2009	-	issue #129898
* Modified By:	CHS 04/13/2009	-	issue #129898
*
*
* Insert trigger bJCPD
*
* Performs validation on critical columns only.
*
* Locks bJCPD entries pulled into batch
*
* Adds bHQCC entries as needed
*
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int


select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

   
---- validate batch
select @validcnt = count(*) from bHQBC r with (nolock) 
JOIN inserted i ON i.Co=r.Co and i.Mth=r.Mth and i.BatchId=r.BatchId
if @validcnt<>@numrows
	begin
	select @errmsg = 'Invalid Batch ID#'
	goto error
	end

select @validcnt = count(*) from bHQBC r with (nolock) 
JOIN inserted i ON i.Co=r.Co and i.Mth = r.Mth and i.BatchId=r.BatchId and r.Status = 0
if @validcnt <> @numrows
	begin
	select @errmsg = 'Must be an open batch.'
	goto error
	end

---- validate TransType
if exists(select 1 from inserted where TransType not in ('A','C','D'))
	begin
	select @errmsg = 'Invalid Transaction type, must be A, C,or D!'
	goto error
	end

-- validate MS Trans#
if exists(select top 1 1 from inserted where TransType = 'A' and ResTrans is not null)
	begin
	select @errmsg = 'JC Projection Detail Trans # must be null for all type A entries!'
	goto error
	end

if exists(select * from inserted where TransType <> 'A' and ResTrans is null)
	begin
	select @errmsg = 'All Transaction type C and D entries must have an JC Projection Detail Trans #!'
	goto error
	end


---- attempt to update InUseBatchId in JCPR
select @validcnt = count(*) from inserted where TransType <> 'A'
   
update bJCPR set InUseBatchId = i.BatchId
from bJCPR t join inserted i on i.Co = t.JCCo and i.Mth = t.Mth and i.ResTrans = t.ResTrans
where t.InUseBatchId is null	-- must be unlocked
if @validcnt <> @@rowcount
	begin
	select @errmsg = 'Unable to lock existing MS Transaction!'
	goto error
	end




------ Update the Projected Final Numbers in bJCPB
--update bJCPB
--	set
--		ProjFinalCost = b.ProjFinalCost + isnull((select sum(isnull(d.Amount,0)) from bJCPD d with (nolock) where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq and d.Job = i.Job and d.PhaseGroup = i.PhaseGroup and d.Phase = i.Phase and d.CostType = i.CostType), 0),
--		ProjFinalHrs = b.ProjFinalHrs + isnull((select sum(isnull(d.Hours,0)) from bJCPD d with (nolock) where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq and d.Job = i.Job and d.PhaseGroup = i.PhaseGroup and d.Phase = i.Phase and d.CostType = i.CostType and UM = 'HRS'), 0),
--		ProjFinalUnits = b.ProjFinalUnits + isnull((select sum(isnull(d.Units,0)) from bJCPD d with (nolock) where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq and d.Job = i.Job and d.PhaseGroup = i.PhaseGroup and d.Phase = i.Phase and d.CostType = i.CostType and i.UM = d.UM), 0),
--		OldPlugged = b.Plugged, 
--		Plugged = 'Y'
--
--from bJCPB b with (nolock) 
--join inserted i with (nolock) on b.Co = i.Co and b.Mth = i.Mth and b.BatchId = i.BatchId and b.BatchSeq = i.BatchSeq and b.Job = i.Job and b.PhaseGroup = i.PhaseGroup and b.Phase = i.Phase and b.CostType = i.CostType
--where b.Co = i.Co and b.Mth = i.Mth and b.BatchId = i.BatchId and b.BatchSeq = i.BatchSeq and b.Job = i.Job and b.PhaseGroup = i.PhaseGroup and b.Phase = i.Phase and b.CostType = i.CostType




return



error:
	select @errmsg = @errmsg + ' - cannot insert JC Projection Detail Batch Entry'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btJCPDu] on [dbo].[bJCPD] for UPDATE as
/*-----------------------------------------------------------------
* Created By:	GF	03/29/2009	-	issue #129898
* Modified By:	CHS 04/13/2009	-	issue #129898
*
*
* Update trigger for bJCPD (JC Projection Detail Batch)
*
* Cannot change Company, Mth, BatchId, Seq, or Res Trans
*
*
*----------------------------------------------------------------*/

declare @numrows int, @validcount int, @errmsg varchar(255), @validcount2 int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


---- check for key changes
select @validcount = count(*)
from deleted d join inserted i on d.Co = i.Co and d.Mth = i.Mth
and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
if @numrows <> @validcount
	begin
	select @errmsg = 'Cannot change Company, Month, Batch ID #, Sequence #'
	goto error
	end

---- check for key changes on Res Trans for any deleted or changed transactions
select @validcount2 = count(*)
from inserted i  where i.TransType <> 'A'
select @validcount = count(*)
from deleted d join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId
and d.BatchSeq = i.BatchSeq and isnull(d.ResTrans,0) = isnull(i.ResTrans,0) and i.TransType <> 'A'
if @validcount2 <> @validcount
	begin
	select @errmsg = 'Cannot change ResTrans #'
	goto error
	end




------ Update the Projected Final Numbers in bJCPB
--update bJCPB
--	set
--		ProjFinalCost = b.ProjFinalCost + isnull((select sum(isnull(d.Amount,0)) from bJCPD d with (nolock) where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq and d.Job = i.Job and d.PhaseGroup = i.PhaseGroup and d.Phase = i.Phase and d.CostType = i.CostType), 0),
--		ProjFinalHrs = b.ProjFinalHrs + isnull((select sum(isnull(d.Hours,0)) from bJCPD d with (nolock) where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq and d.Job = i.Job and d.PhaseGroup = i.PhaseGroup and d.Phase = i.Phase and d.CostType = i.CostType and UM = 'HRS'), 0),
--		ProjFinalUnits = b.ProjFinalUnits + isnull((select sum(isnull(d.Units,0)) from bJCPD d with (nolock) where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq and d.Job = i.Job and d.PhaseGroup = i.PhaseGroup and d.Phase = i.Phase and d.CostType = i.CostType and i.UM = d.UM), 0),
--		OldPlugged = b.Plugged, 
--		Plugged = 'Y'
--
--from bJCPB b with (nolock) 
--join inserted i with (nolock) on b.Co = i.Co and b.Mth = i.Mth and b.BatchId = i.BatchId and b.BatchSeq = i.BatchSeq and b.Job = i.Job and b.PhaseGroup = i.PhaseGroup and b.Phase = i.Phase and b.CostType = i.CostType
--where b.Co = i.Co and b.Mth = i.Mth and b.BatchId = i.BatchId and b.BatchSeq = i.BatchSeq and b.Job = i.Job and b.PhaseGroup = i.PhaseGroup and b.Phase = i.Phase and b.CostType = i.CostType




return



error:
	select @errmsg = @errmsg + ' - cannot update JC Projection Detail Batch!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO
ALTER TABLE [dbo].[bJCPD] WITH NOCHECK ADD CONSTRAINT [CK_bJCPD_TransType] CHECK (([TransType]='A' OR [TransType]='C' OR [TransType]='D'))
GO
ALTER TABLE [dbo].[bJCPD] ADD CONSTRAINT [PK_bJCPD] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biJCPDBatchSeq] ON [dbo].[bJCPD] ([Co], [Mth], [BatchId], [BatchSeq], [DetSeq]) ON [PRIMARY]
GO
