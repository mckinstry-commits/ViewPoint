CREATE TABLE [dbo].[bHQAF]
(
[AttachmentID] [int] NOT NULL,
[AttachmentData] [image] NULL,
[AttachmentFileType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[SaveStamp] [timestamp] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[bHQAF] ADD CONSTRAINT [PK_bHQAF_AttachmentID] PRIMARY KEY CLUSTERED  ([AttachmentID]) ON [PRIMARY]
GO
