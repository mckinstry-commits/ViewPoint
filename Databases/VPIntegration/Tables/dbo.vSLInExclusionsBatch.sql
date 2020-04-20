CREATE TABLE [dbo].[vSLInExclusionsBatch]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Co] [dbo].[bCompany] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchSeq] [int] NOT NULL,
[Seq] [int] NOT NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Type] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[PhaseGroup] [tinyint] NULL,
[Phase] [dbo].[bPhase] NULL,
[Detail] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[DateEntered] [dbo].[bDate] NOT NULL,
[EnteredBy] [dbo].[bVPUserName] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSLInExclusionsBatch] ADD CONSTRAINT [PK_vSLInExclusionsBatch] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
