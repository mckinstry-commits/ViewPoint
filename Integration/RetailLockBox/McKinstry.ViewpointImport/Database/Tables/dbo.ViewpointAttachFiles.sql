USE [MCK_INTEGRATION]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[ViewpointAttachFiles](
	[ViewpointAttachFilesID] [int] IDENTITY(1,1) NOT NULL,
	[Environment] [varchar](20) NULL,
	[FileName] [varchar](200) NULL,
	[Company] [varchar](100) NULL,
	[Module] [varchar](30) NULL,
	[FormName] [varchar](30) NULL,
	[Month] [varchar](20) NULL,
	[FullFilePath] [varchar](512) NULL,
	[FileCreationTime] [datetime2] NULL,
	[Created] [datetime] NULL,
 CONSTRAINT [PK_ViewpointAttachFiles] PRIMARY KEY CLUSTERED 
(
	[ViewpointAttachFilesID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[ViewpointAttachFiles] ADD  CONSTRAINT [DF_ViewpointAttachFiles_Environment]  DEFAULT (NULL) FOR [Environment]
GO

ALTER TABLE [dbo].[ViewpointAttachFiles] ADD  CONSTRAINT [DF_ViewpointAttachFiles_FileName]  DEFAULT (NULL) FOR [FileName]
GO

ALTER TABLE [dbo].[ViewpointAttachFiles] ADD  CONSTRAINT [DF_ViewpointAttachFiles_Company]  DEFAULT (NULL) FOR [Company]
GO

ALTER TABLE [dbo].[ViewpointAttachFiles] ADD  CONSTRAINT [DF_ViewpointAttachFiles_Module]  DEFAULT (NULL) FOR [Module]
GO

ALTER TABLE [dbo].[ViewpointAttachFiles] ADD  CONSTRAINT [DF_ViewpointAttachFiles_FormName]  DEFAULT (NULL) FOR [FormName]
GO

ALTER TABLE [dbo].[ViewpointAttachFiles] ADD  CONSTRAINT [DF_ViewpointAttachFiles_Month]  DEFAULT (NULL) FOR [Month]
GO

ALTER TABLE [dbo].[ViewpointAttachFiles] ADD  CONSTRAINT [DF_ViewpointAttachFiles_FullFilePath]  DEFAULT (NULL) FOR [FullFilePath]
GO

ALTER TABLE [dbo].[ViewpointAttachFiles] ADD  CONSTRAINT [DF_ViewpointAttachFiles_FileCreationTime]  DEFAULT (getdate()) FOR [FileCreationTime]
GO

ALTER TABLE [dbo].[ViewpointAttachFiles] ADD  CONSTRAINT [DF_ViewpointAttachFiles_Created]  DEFAULT (getdate()) FOR [Created]
GO


