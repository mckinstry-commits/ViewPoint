CREATE TABLE [dbo].[vVPWorkCenterUserLibrary]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[LibraryName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[Owner] [dbo].[bVPUserName] NOT NULL,
[WorkCenterInfo] [xml] NULL,
[PublicShare] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPWorkCenterUserLibrary_PublicShare] DEFAULT ('N'),
[DateModified] [smalldatetime] NULL CONSTRAINT [DF_vVPWorkCenterUserLibrary_DateModified] DEFAULT (getdate()),
[Notes] [dbo].[bNotes] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vVPWorkCenterUserLibrary_LibraryName_Owner] ON [dbo].[vVPWorkCenterUserLibrary] ([LibraryName], [Owner]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
