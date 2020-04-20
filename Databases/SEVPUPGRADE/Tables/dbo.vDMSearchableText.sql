CREATE TABLE [dbo].[vDMSearchableText]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[AttachmentID] [int] NOT NULL,
[SearchText] [nvarchar] (max) COLLATE Latin1_General_BIN NOT NULL,
[Source] [nvarchar] (15) COLLATE Latin1_General_BIN NOT NULL,
[RowTimeStamp] [timestamp] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDMSearchableText] ADD CONSTRAINT [PK_vDMSearchableText] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
