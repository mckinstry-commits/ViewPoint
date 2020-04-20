CREATE TABLE [dbo].[vSMBC]
(
[SMBCID] [bigint] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NOT NULL,
[PostingCo] [dbo].[bCompany] NOT NULL,
[WorkOrder] [int] NOT NULL,
[Scope] [int] NULL,
[LineType] [tinyint] NULL,
[WorkCompleted] [int] NOT NULL,
[SMWorkCompletedID] [bigint] NULL,
[InUseMth] [dbo].[bMonth] NULL,
[InUseBatchId] [int] NULL,
[InUseBatchSeq] [int] NULL,
[Posted] [tinyint] NULL,
[PostedMth] [dbo].[bMonth] NULL,
[Trans] [dbo].[bTrans] NULL,
[Line] [smallint] NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NULL,
[Source] [dbo].[bSource] NOT NULL,
[EntryEmployee] [int] NULL,
[StartDate] [smalldatetime] NULL,
[DayOfWeek] [smallint] NULL,
[Sheet] [smallint] NULL,
[Seq] [smallint] NULL,
[UpdateInProgress] [bit] NOT NULL CONSTRAINT [DF_vSMBC_UpdateInProgress] DEFAULT ((0)),
[ARApplyMth] [dbo].[bMonth] NULL,
[ARApplyTrans] [dbo].[bTrans] NULL,
[ARApplyLine] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMBC] ADD CONSTRAINT [PK_vSMBC_KeyId] PRIMARY KEY CLUSTERED  ([SMBCID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vSMBC_Source_Co_Mth_BatchId_BatchSeq_Line] ON [dbo].[vSMBC] ([PostingCo], [InUseMth], [InUseBatchId], [InUseBatchSeq], [Line], [Source]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vSMBC_Source_SMCo_WorkOrder_LineType_WorkCompleted] ON [dbo].[vSMBC] ([SMCo], [WorkOrder], [LineType], [WorkCompleted], [Source]) ON [PRIMARY]
GO
