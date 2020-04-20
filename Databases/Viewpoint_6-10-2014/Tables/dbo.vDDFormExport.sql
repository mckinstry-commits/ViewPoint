CREATE TABLE [dbo].[vDDFormExport]
(
[TableName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[ExtractStep] [int] NOT NULL,
[ExtractOrder] [varchar] (1000) COLLATE Latin1_General_BIN NULL,
[WhereClause] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[OmitIdentity] [bit] NULL CONSTRAINT [DF_vDDFormExport_OmitIdentity] DEFAULT ((0))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [PK_vDDFormExport] ON [dbo].[vDDFormExport] ([TableName], [ExtractStep]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
