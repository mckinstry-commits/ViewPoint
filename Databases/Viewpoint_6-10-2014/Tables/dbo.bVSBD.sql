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
ALTER TABLE [dbo].[bVSBD] WITH NOCHECK ADD CONSTRAINT [CK_bVSBD_Attached] CHECK (([Attached]='Y' OR [Attached]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biVSBD] ON [dbo].[bVSBD] ([BatchId], [ImageID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
