USE [MCK_INTEGRATION]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[AttachCompanyMove](
	[AttachCompanyMoveID] [int] IDENTITY(1,1) NOT NULL,
	[CompanyMoveID] [int] NOT NULL,
	[KeepOldAttach] [bit] NULL,
	[OldAttachDeleted] [bit] NULL,
	[FileCopied] [bit] NULL,
	[OrigFileName] [varchar](512) NULL,
	[FormName] [varchar](30) NULL,
	[TableName] [varchar](128) NULL,
	[DocName] [varchar](512) NULL,
	[AttachmentID] [int] NULL,
	[UniqueAttchID] [uniqueidentifier] NULL,
	[DestDocName] [varchar](512) NULL,
	[DestAttachmentID] [int] NULL,
	[DestUniqueAttchID] [uniqueidentifier] NULL,
	[RLBProcessNotesID] [int] NULL,
    [Created] [datetime] NULL,
	[Modified] [datetime] NULL,

 CONSTRAINT [PK_AttachCompanyMove] PRIMARY KEY CLUSTERED 
(
	[AttachCompanyMoveID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[AttachCompanyMove] ADD  CONSTRAINT [DF_AttachCompanyMove_KeepOldAttach]  DEFAULT (NULL) FOR [KeepOldAttach]
GO

ALTER TABLE [dbo].[AttachCompanyMove] ADD  CONSTRAINT [DF_AttachCompanyMove_OldAttachDeleted]  DEFAULT (NULL) FOR [OldAttachDeleted]
GO

ALTER TABLE [dbo].[AttachCompanyMove] ADD  CONSTRAINT [DF_AttachCompanyMove_FileCopied]  DEFAULT (NULL) FOR [FileCopied]
GO

ALTER TABLE [dbo].[AttachCompanyMove] ADD  CONSTRAINT [DF_AttachCompanyMove_OrigFileName]  DEFAULT (NULL) FOR [OrigFileName]
GO

ALTER TABLE [dbo].[AttachCompanyMove] ADD  CONSTRAINT [DF_AttachCompanyMove_FormName]  DEFAULT (NULL) FOR [FormName]
GO

ALTER TABLE [dbo].[AttachCompanyMove] ADD  CONSTRAINT [DF_AttachCompanyMove_TableName]  DEFAULT (NULL) FOR [TableName]
GO

ALTER TABLE [dbo].[AttachCompanyMove] ADD  CONSTRAINT [DF_AttachCompanyMove_DocName]  DEFAULT (NULL) FOR [DocName]
GO

ALTER TABLE [dbo].[AttachCompanyMove] ADD  CONSTRAINT [DF_AttachCompanyMove_AttachmentID]  DEFAULT (NULL) FOR [AttachmentID]
GO

ALTER TABLE [dbo].[AttachCompanyMove] ADD  CONSTRAINT [DF_AttachCompanyMove_UniqueAttchID]  DEFAULT (NULL) FOR [UniqueAttchID]
GO

ALTER TABLE [dbo].[AttachCompanyMove] ADD  CONSTRAINT [DF_AttachCompanyMove_DestDocName]  DEFAULT (NULL) FOR [DestDocName]
GO

ALTER TABLE [dbo].[AttachCompanyMove] ADD  CONSTRAINT [DF_AttachCompanyMove_DestAttachmentID]  DEFAULT (NULL) FOR [DestAttachmentID]
GO

ALTER TABLE [dbo].[AttachCompanyMove] ADD  CONSTRAINT [DF_AttachCompanyMove_DestUniqueAttchID]  DEFAULT (NULL) FOR [DestUniqueAttchID]
GO

ALTER TABLE [dbo].[AttachCompanyMove] ADD  CONSTRAINT [DF_AttachCompanyMove_RLBProcessNotesID]  DEFAULT (NULL) FOR [RLBProcessNotesID]
GO

ALTER TABLE [dbo].[AttachCompanyMove] ADD  CONSTRAINT [DF_AttachCompanyMove_Created]  DEFAULT (getdate()) FOR [Created]
GO

ALTER TABLE [dbo].[AttachCompanyMove] ADD  CONSTRAINT [DF_AttachCompanyMove_Modified]  DEFAULT (getdate()) FOR [Modified]
GO

ALTER TABLE [dbo].[AttachCompanyMove]  WITH CHECK ADD CONSTRAINT [FK_AttachCompanyMove_RLBProcessNotesID] FOREIGN KEY([RLBProcessNotesID])
REFERENCES [dbo].[RLBProcessNotes] ([RLBProcessNotesID])
GO
ALTER TABLE [dbo].[AttachCompanyMove] CHECK CONSTRAINT [FK_AttachCompanyMove_RLBProcessNotesID]
GO

