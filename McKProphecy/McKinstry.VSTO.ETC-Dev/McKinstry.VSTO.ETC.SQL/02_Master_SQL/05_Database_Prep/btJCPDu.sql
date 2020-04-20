USE [Viewpoint]
GO
/****** Object:  Trigger [dbo].[btJCPDu]    Script Date: 7/14/2016 2:55:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER trigger [dbo].[btJCPDu] on [dbo].[bJCPD] for UPDATE as
/*-----------------------------------------------------------------
* Created By:	GF	03/29/2009	-	issue #129898
* Modified By:	CHS 04/13/2009	-	issue #129898
*				JDZ 07/14/2016  -   Project Prophecy
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
--New Key line for 2016 to allow for bulk update to Trans Value D
and i.DetSeq = d.DetSeq
if @numrows <> @validcount
	begin
	select @errmsg = 'Cannot change Company, Month, Batch ID #, Sequence # '
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

