CREATE TABLE [dbo].[vVSBI]
(
[BatchID] [int] NOT NULL,
[ImageID] [int] NOT NULL,
[PageNumber] [int] NOT NULL,
[ImageData] [image] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
