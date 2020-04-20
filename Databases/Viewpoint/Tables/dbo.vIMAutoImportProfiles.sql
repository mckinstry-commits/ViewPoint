CREATE TABLE [dbo].[vIMAutoImportProfiles]
(
[ProfileName] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NOT NULL,
[PickupDirectory] [varchar] (1024) COLLATE Latin1_General_BIN NOT NULL,
[ArchiveDirectory] [varchar] (1024) COLLATE Latin1_General_BIN NULL,
[ErrorDirectory] [varchar] (1024) COLLATE Latin1_General_BIN NULL,
[LogDirectory] [varchar] (1024) COLLATE Latin1_General_BIN NULL,
[Template] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[DefaultCompany] [int] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [viIMAutoImportProfiles] ON [dbo].[vIMAutoImportProfiles] ([ProfileName]) ON [PRIMARY]
GO
