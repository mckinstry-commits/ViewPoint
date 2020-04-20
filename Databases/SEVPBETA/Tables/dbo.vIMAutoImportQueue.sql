CREATE TABLE [dbo].[vIMAutoImportQueue]
(
[Seq] [int] NOT NULL IDENTITY(1, 1),
[ImportProfile] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[FileName] [varchar] (256) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [viIMAutoImportQueue] ON [dbo].[vIMAutoImportQueue] ([Seq]) ON [PRIMARY]
GO
