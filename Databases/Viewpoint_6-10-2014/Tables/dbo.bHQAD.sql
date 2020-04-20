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
ALTER TABLE [dbo].[bHQAD] WITH NOCHECK ADD CONSTRAINT [CK_bHQAD_Custom] CHECK (([Custom]='Y' OR [Custom]='N'))
GO
CREATE NONCLUSTERED INDEX [IX_bHQAD_ColNameFormMod] ON [dbo].[bHQAD] ([ColumnName], [Module], [Form]) INCLUDE ([SkipIndex]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biHQAD] ON [dbo].[bHQAD] ([RecID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
