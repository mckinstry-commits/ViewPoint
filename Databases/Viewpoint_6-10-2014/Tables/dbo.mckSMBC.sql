CREATE TABLE [dbo].[mckSMBC]
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
[UpdateInProgress] [bit] NOT NULL CONSTRAINT [DF_mckSMBC_UpdateInProgress] DEFAULT ((0)),
[ARApplyMth] [dbo].[bMonth] NULL,
[ARApplyTrans] [dbo].[bTrans] NULL,
[ARApplyLine] [int] NULL,
[PRTHKeyID] [bigint] NULL,
[PRTBKeyID] [bigint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mckSMBC] ADD CONSTRAINT [PK_mckSMBC_KeyId] PRIMARY KEY CLUSTERED  ([SMBCID]) ON [PRIMARY]
GO
