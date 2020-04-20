CREATE TABLE [dbo].[voldIMAutoImportQueue20131025]
(
[Seq] [int] NOT NULL IDENTITY(1, 1),
[ImportProfile] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[FileName] [varchar] (256) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
