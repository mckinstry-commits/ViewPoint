CREATE TABLE [dbo].[budPayItemPhaseCodeMapping]
(
[Category] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[Sort] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[PayItem] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[McKOwner] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[CostType] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[Description] [varchar] (200) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[PhaseCode] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[PhaseCodeDescription] [varchar] (200) COLLATE Latin1_General_BIN NULL,
[PhaseCodeLIVE] [varchar] (50) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
