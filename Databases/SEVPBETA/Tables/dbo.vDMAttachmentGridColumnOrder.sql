CREATE TABLE [dbo].[vDMAttachmentGridColumnOrder]
(
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[ColumnName] [varchar] (max) COLLATE Latin1_General_BIN NOT NULL,
[ColumnOrder] [int] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
