CREATE TABLE [dbo].[vPMContractChangeOrderCommit]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Contract] [dbo].[bContract] NOT NULL,
[ID] [smallint] NOT NULL,
[Seq] [smallint] NOT NULL,
[Project] [dbo].[bProject] NOT NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[Type] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[SLPO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ChangeOrder] [dbo].[bChgOrder] NULL,
[Status] [dbo].[bStatus] NULL,
[Amount] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPMContractChangeOrderCommit_Amount] DEFAULT ((0)),
[DateSent] [dbo].[bDate] NULL,
[DateDueBack] [dbo].[bDate] NULL,
[DateReceived] [dbo].[bDate] NULL,
[DateApproved] [dbo].[bDate] NULL,
[ACO] [dbo].[bACO] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPMContractChangeOrderCommit] ADD CONSTRAINT [PK_vPMContractChangeOrderCommit] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPMContractChangeOrderCommitSeq] ON [dbo].[vPMContractChangeOrderCommit] ([PMCo], [Contract], [ID], [Seq]) ON [PRIMARY]
GO
