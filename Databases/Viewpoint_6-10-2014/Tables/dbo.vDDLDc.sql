CREATE TABLE [dbo].[vDDLDc]
(
[Lookup] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [smallint] NOT NULL,
[ColumnName] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[ColumnHeading] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Hidden] [dbo].[bYN] NULL,
[Datatype] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[InputType] [tinyint] NULL,
[InputLength] [smallint] NULL,
[InputMask] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Prec] [tinyint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDDLDc] WITH NOCHECK ADD CONSTRAINT [CK_vDDLDc_Hidden] CHECK (([Hidden]='Y' OR [Hidden]='N' OR [Hidden] IS NULL))
GO
CREATE UNIQUE CLUSTERED INDEX [viDDLDc] ON [dbo].[vDDLDc] ([Lookup], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
