CREATE TABLE [dbo].[budxrefPRStates]
(
[CMSUnion] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[InsState] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[LocalCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[McKGroup] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ResidentState] [varchar] (2) COLLATE Latin1_General_BIN NOT NULL,
[TaxState] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[UnempState] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[UseIns] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[UseInsState] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[UseLocal] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[UseState] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[UseUnempState] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[WOTaxState] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biudxrefPRStates] ON [dbo].[budxrefPRStates] ([CMSUnion], [ResidentState]) ON [PRIMARY]
GO
