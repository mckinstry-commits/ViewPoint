USE [MCK_INTEGRATION]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[RLBDropFolderWatcher](
	[DropFolderWatcherID] [int] IDENTITY(1,1) NOT NULL,
	[Activity] [varchar](200) NOT NULL,
	[Success] [bit] NULL,
	[RLBProcessNotesID] [int] NULL,
    [Created] [datetime] NULL,

 CONSTRAINT [PK_RLBDropFolderWatcher] PRIMARY KEY CLUSTERED 
(
	[DropFolderWatcherID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[RLBDropFolderWatcher] ADD  CONSTRAINT [DF_RLBDropFolderWatcher_Activity]  DEFAULT (NULL) FOR [Activity]
GO

ALTER TABLE [dbo].[RLBDropFolderWatcher] ADD  CONSTRAINT [DF_RLBDropFolderWatcher_Success]  DEFAULT (NULL) FOR [Success]
GO

ALTER TABLE [dbo].[RLBDropFolderWatcher] ADD  CONSTRAINT [DF_RLBDropFolderWatcher_RLBProcessNotesID]  DEFAULT (NULL) FOR [RLBProcessNotesID]
GO

ALTER TABLE [dbo].[RLBDropFolderWatcher] ADD  CONSTRAINT [DF_RLBDropFolderWatcher_Created]  DEFAULT (getdate()) FOR [Created]
GO

ALTER TABLE [dbo].[RLBDropFolderWatcher]  WITH CHECK ADD CONSTRAINT [FK_RLBDropFolderWatcher_RLBProcessNotesID] FOREIGN KEY([RLBProcessNotesID])
REFERENCES [dbo].[RLBProcessNotes] ([RLBProcessNotesID])
GO
ALTER TABLE [dbo].[RLBDropFolderWatcher] CHECK CONSTRAINT [FK_RLBDropFolderWatcher_RLBProcessNotesID]
GO

