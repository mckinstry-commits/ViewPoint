CREATE TABLE [dbo].[vDMTokens]
(
[Company] [dbo].[bCompany] NULL,
[TableName] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[TableKeyField] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[FormName] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[PMDocumentAttachment] [dbo].[bYN] NULL,
[StandAloneAttachment] [dbo].[bYN] NULL,
[Token] [varchar] (32) COLLATE Latin1_General_BIN NULL,
[AttachmentID] [int] NULL,
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[AutoResponseAttachment] [dbo].[bYN] NOT NULL CONSTRAINT [DF__vDMTokens__AutoR__0479434D] DEFAULT ('N')
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDMTokens] ADD CONSTRAINT [PK_vDMTokens] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
