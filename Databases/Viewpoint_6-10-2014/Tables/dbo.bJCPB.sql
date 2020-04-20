CREATE TABLE [dbo].[bJCPB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [tinyint] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[CostType] [dbo].[bJCCType] NOT NULL,
[ActualDate] [dbo].[bDate] NOT NULL,
[ActualHours] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bJCPB_ActualHours] DEFAULT ((0)),
[ActualUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCPB_ActualUnits] DEFAULT ((0)),
[ActualCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCPB_ActualCost] DEFAULT ((0)),
[CurrEstHours] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bJCPB_CurrEstHours] DEFAULT ((0)),
[CurrEstUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCPB_CurrEstUnits] DEFAULT ((0)),
[CurrEstCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCPB_CurrEstCost] DEFAULT ((0)),
[ProjFinalUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCPB_ProjFinalUnits] DEFAULT ((0)),
[ProjFinalHrs] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bJCPB_ProjFinalHrs] DEFAULT ((0)),
[ProjFinalCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCPB_ProjFinalCost] DEFAULT ((0)),
[ProjFinalUnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bJCPB_ProjFinalUnitCost] DEFAULT ((0)),
[ForecastFinalUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCPB_ForecastFinalUnits] DEFAULT ((0)),
[ForecastFinalHrs] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bJCPB_ForecastFinalHrs] DEFAULT ((0)),
[ForecastFinalCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCPB_ForecastFinalCost] DEFAULT ((0)),
[ForecastFinalUnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bJCPB_ForecastFinalUnitCost] DEFAULT ((0)),
[RemainCmtdUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCPB_RemainCmtdUnits] DEFAULT ((0)),
[RemainCmtdCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCPB_RemainCmtdCost] DEFAULT ((0)),
[TotalCmtdUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCPB_TotalCmtdUnits] DEFAULT ((0)),
[TotalCmtdCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCPB_TotalCmtdCost] DEFAULT ((0)),
[PrevProjUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCPB_PrevProjUnits] DEFAULT ((0)),
[PrevProjHours] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bJCPB_PrevProjHours] DEFAULT ((0)),
[PrevProjCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCPB_PrevProjCost] DEFAULT ((0)),
[PrevProjUnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bJCPB_PrevProjUnitCost] DEFAULT ((0)),
[PrevForecastUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCPB_PrevForecastUnits] DEFAULT ((0)),
[PrevForecastHours] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bJCPB_PrevForecastHours] DEFAULT ((0)),
[PrevForecastCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCPB_PrevForecastCost] DEFAULT ((0)),
[PrevForecastUnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bJCPB_PrevForecastUnitCost] DEFAULT ((0)),
[FutureCOHours] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bJCPB_FutureCOHours] DEFAULT ((0)),
[FutureCOUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCPB_FutureCOUnits] DEFAULT ((0)),
[FutureCOCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCPB_FutureCOCost] DEFAULT ((0)),
[CurrProjHours] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bJCPB_CurrProjHours] DEFAULT ((0)),
[CurrProjUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCPB_CurrProjUnits] DEFAULT ((0)),
[CurrProjCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCPB_CurrProjCost] DEFAULT ((0)),
[OrigEstHours] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bJCPB_OrigEstHours] DEFAULT ((0)),
[OrigEstUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCPB_OrigEstUnits] DEFAULT ((0)),
[OrigEstCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCPB_OrigEstCost] DEFAULT ((0)),
[ActualCmtdUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCPB_ActualCmtdUnits] DEFAULT ((0)),
[ActualCmtdCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCPB_ActualCmtdCost] DEFAULT ((0)),
[LinkedToCostType] [dbo].[bJCCType] NULL,
[Plugged] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCPB_Plugged] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Item] [dbo].[bContractItem] NULL,
[IncludedCOs] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCPB_IncludedCOs] DEFAULT ((0)),
[COCalcIncluded] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCPB_COCalcIncluded] DEFAULT ('N'),
[IncludedHours] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCPB_IncludedHours] DEFAULT ((0)),
[IncludedUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCPB_IncludedUnits] DEFAULT ((0)),
[OldPlugged] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[DisplayedCOs] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCPB_DisplayedCOs] DEFAULT ((0)),
[FutureActualCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCPB_FutureActualCost] DEFAULT ((0)),
[UncommittedCosts] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCPB_UncommittedCosts] DEFAULT ((0))
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************/
 CREATE trigger [dbo].[btJCPBd] on [dbo].[bJCPB] for DELETE as
/*-----------------------------------------------------------------
* Created By:	GF 05/12/2009 - issue #129898
* Modified By:	JonathanP 05/29/2009 - #133437 - Added attachment deletion code.
*
*
*	Delete worksheet projection detail for batch sequence from bJCPD*
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


---- delete bJCPD detail records related to bJCPB batch and sequence
--delete bJCPD
--from bJCPD join deleted d on d.Co=bJCPD.Co and d.Mth=bJCPD.Mth and d.BatchId=bJCPD.BatchId and d.BatchSeq=bJCPD.BatchSeq



-- Issue #133437
-- Delete attachments if they exist. Make sure UniqueAttchID is not null.
insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
	  select AttachmentID, suser_name(), 'Y' 
		  from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
		  where h.UniqueAttchID not in(select t.UniqueAttchID from bJCPR t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
		  and d.UniqueAttchID is not null  




return


error:
	select @errmsg = @errmsg + ' - cannot delete JC Projection Batch Sequence!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO
ALTER TABLE [dbo].[bJCPB] WITH NOCHECK ADD CONSTRAINT [CK_bJCPB_Plugged] CHECK (([Plugged]='Y' OR [Plugged]='N'))
GO
ALTER TABLE [dbo].[bJCPB] ADD CONSTRAINT [PK_bJCPB] PRIMARY KEY CLUSTERED  ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biJCPB] ON [dbo].[bJCPB] ([Co], [Mth], [BatchId], [Job], [PhaseGroup], [Phase], [CostType]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCPB] ([KeyID]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
