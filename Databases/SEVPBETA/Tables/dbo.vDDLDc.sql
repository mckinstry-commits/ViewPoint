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
CREATE UNIQUE CLUSTERED INDEX [viDDLDc] ON [dbo].[vDDLDc] ([Lookup], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vDDLDc].[Hidden]'
GO
