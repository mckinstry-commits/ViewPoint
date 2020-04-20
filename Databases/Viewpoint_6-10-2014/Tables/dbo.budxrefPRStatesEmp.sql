CREATE TABLE [dbo].[budxrefPRStatesEmp]
(
[Employee] [dbo].[bEmployee] NOT NULL,
[TaxState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[InsState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[UnempState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[LocalCode] [dbo].[bLocalCode] NULL,
[WOTaxState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[UseIns] [dbo].[bYN] NOT NULL CONSTRAINT [DF_udxrefPRStatesEmp_UseIns] DEFAULT ('N'),
[UseInsState] [dbo].[bYN] NOT NULL CONSTRAINT [DF_udxrefPRStatesEmp_UseInsState] DEFAULT ('N'),
[UseLocal] [dbo].[bYN] NOT NULL CONSTRAINT [DF_udxrefPRStatesEmp_UseLocal] DEFAULT ('N'),
[UseState] [dbo].[bYN] NOT NULL CONSTRAINT [DF_udxrefPRStatesEmp_UseState] DEFAULT ('N'),
[UseUnempState] [dbo].[bYN] NOT NULL CONSTRAINT [DF_udxrefPRStatesEmp_UseUnempState] DEFAULT ('N')
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biudxrefPRStatesEmp] ON [dbo].[budxrefPRStatesEmp] ([Employee]) ON [PRIMARY]
GO
