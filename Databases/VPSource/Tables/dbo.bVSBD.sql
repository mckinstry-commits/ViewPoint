CREATE TABLE [dbo].[bVSBD]
(
[BatchId] [int] NOT NULL,
[ImageID] [int] NOT NULL,
[PageCount] [int] NOT NULL,
[Attached] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bVSBD_Attached] DEFAULT ('N'),
[OriginalImageData] [varbinary] (max) NULL,
[OriginalFileName] [varchar] (512) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biVSBD] ON [dbo].[bVSBD] ([BatchId], [ImageID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bVSBD].[Attached]'
GO
