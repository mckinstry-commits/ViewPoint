CREATE TABLE [dbo].[vDDFTc]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Tab] [tinyint] NOT NULL,
[Title] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[GridForm] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[LoadSeq] [tinyint] NULL,
[IsVisible] [dbo].[bYN] NULL,
[Type] [tinyint] NOT NULL CONSTRAINT [DF_vDDFTc_Type] DEFAULT ((0)),
[QueryName] [varchar] (50) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDDFTc] WITH NOCHECK ADD CONSTRAINT [CK_vDDFTc_IsVisible] CHECK (([IsVisible]='Y' OR [IsVisible]='N' OR [IsVisible] IS NULL))
GO
CREATE UNIQUE CLUSTERED INDEX [viDDFTc] ON [dbo].[vDDFTc] ([Form], [Tab]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
