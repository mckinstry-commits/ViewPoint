CREATE TABLE [dbo].[bHQAD]
(
[RecID] [int] NOT NULL,
[ColumnName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[ParentColumn] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Custom] [dbo].[bYN] NOT NULL,
[Module] [char] (2) COLLATE Latin1_General_BIN NULL,
[Form] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[SkipIndex] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQAD_SkipIndex] DEFAULT ('N')
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bHQAD_ColNameFormMod] ON [dbo].[bHQAD] ([ColumnName], [Module], [Form]) INCLUDE ([SkipIndex]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biHQAD] ON [dbo].[bHQAD] ([RecID]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHQAD].[Custom]'
GO
