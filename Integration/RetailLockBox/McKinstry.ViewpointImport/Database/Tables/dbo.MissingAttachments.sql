USE [MCK_INTEGRATION]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[MissingAttachments](
	[MissingAttachmentsID] [int] IDENTITY(1,1) NOT NULL,
	[Company] [tinyint] NULL,
	[FormName] [varchar](30) NULL,
	[TableName] [varchar](128) NULL,
	[KeyID] [bigint] NULL,
	[AttachmentID] [bigint] NULL,
	[UniqueAttchID] [uniqueidentifier] NULL,
	[AddedBy] [varchar](128) NULL,
    [AddDate] [datetime] NULL,
    [DocName] [varchar](512) NULL,
    [OrigFileName] [varchar](512) NULL,
	[CurrentState] [char](1) NULL,
	[FileExists] [bit] NULL,
	[Created] [datetime] NULL,
 CONSTRAINT [PK_MissingAttachments] PRIMARY KEY CLUSTERED 
(
	[MissingAttachmentsID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[MissingAttachments] ADD  CONSTRAINT [DF_MissingAttachments_Company]  DEFAULT (NULL) FOR [Company]
GO

ALTER TABLE [dbo].[MissingAttachments] ADD  CONSTRAINT [DF_MissingAttachments_FormName]  DEFAULT (NULL) FOR [FormName]
GO

ALTER TABLE [dbo].[MissingAttachments] ADD  CONSTRAINT [DF_MissingAttachments_TableName]  DEFAULT (NULL) FOR [TableName]
GO

ALTER TABLE [dbo].[MissingAttachments] ADD  CONSTRAINT [DF_MissingAttachments_KeyID]  DEFAULT (NULL) FOR [KeyID]
GO

ALTER TABLE [dbo].[MissingAttachments] ADD  CONSTRAINT [DF_MissingAttachments_AttachmentID]  DEFAULT (NULL) FOR [AttachmentID]
GO

ALTER TABLE [dbo].[MissingAttachments] ADD  CONSTRAINT [DF_MissingAttachments_UniqueAttchID]  DEFAULT (NULL) FOR [UniqueAttchID]
GO

ALTER TABLE [dbo].[MissingAttachments] ADD  CONSTRAINT [DF_MissingAttachments_AddedBy]  DEFAULT (NULL) FOR [AddedBy]
GO

ALTER TABLE [dbo].[MissingAttachments] ADD  CONSTRAINT [DF_MissingAttachments_AddDate]  DEFAULT (NULL) FOR [AddDate]
GO

ALTER TABLE [dbo].[MissingAttachments] ADD  CONSTRAINT [DF_MissingAttachments_DocName]  DEFAULT (NULL) FOR [DocName]
GO

ALTER TABLE [dbo].[MissingAttachments] ADD  CONSTRAINT [DF_MissingAttachments_OrigFileName]  DEFAULT (NULL) FOR [OrigFileName]
GO

ALTER TABLE [dbo].[MissingAttachments] ADD  CONSTRAINT [DF_MissingAttachments_CurrentState]  DEFAULT (NULL) FOR [CurrentState]
GO

ALTER TABLE [dbo].[MissingAttachments] ADD  CONSTRAINT [DF_MissingAttachments_FileExists]  DEFAULT (NULL) FOR [FileExists]
GO

ALTER TABLE [dbo].[MissingAttachments] ADD  CONSTRAINT [DF_MissingAttachments_Created]  DEFAULT (getdate()) FOR [Created]
GO


