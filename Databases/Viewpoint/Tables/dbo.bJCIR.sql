CREATE TABLE [dbo].[bJCIR]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[Contract] [dbo].[bContract] NOT NULL,
[Item] [dbo].[bContractItem] NOT NULL,
[ActualDate] [dbo].[bDate] NOT NULL,
[RevProjUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCIR_RevProjUnits] DEFAULT ((0)),
[RevProjDollars] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCIR_RevProjDollars] DEFAULT ((0)),
[PrevRevProjUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCIR_PrevRevProjUnits] DEFAULT ((0)),
[PrevRevProjDollars] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCIR_PrevRevProjDollars] DEFAULT ((0)),
[RevProjPlugged] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCIR_RevProjPlugged] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[BatchSeq] [int] NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Department] [dbo].[bDept] NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[bJCIR] ADD 
CONSTRAINT [PK_bJCIR] PRIMARY KEY CLUSTERED  ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [biJCIR] ON [dbo].[bJCIR] ([Co], [Mth], [BatchId], [Contract], [Item]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCIR] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCIR].[RevProjPlugged]'
GO
