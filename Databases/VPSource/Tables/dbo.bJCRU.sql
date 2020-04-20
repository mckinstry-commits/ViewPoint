CREATE TABLE [dbo].[bJCRU]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[RollupCode] [varchar] (5) COLLATE Latin1_General_BIN NOT NULL,
[RollupDesc] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[RollupType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[RollupSel] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[RollupSourceAP] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[RollupSourceMS] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[RollupSourceIN] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[RollupSourcePR] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[RollupSourceAR] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[RollupSourceJC] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[RollupSourceEM] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[SummaryLevel] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[MonthsBack] [int] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biJCRU] ON [dbo].[bJCRU] ([JCCo], [RollupCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
