CREATE TABLE [dbo].[bPMSS]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[SLCo] [dbo].[bCompany] NOT NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[SendToFirm] [dbo].[bFirm] NULL,
[SendToContact] [dbo].[bEmployee] NULL,
[ResponsibleFirm] [dbo].[bFirm] NULL,
[ResponsiblePerson] [dbo].[bEmployee] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMSS] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMSS] ON [dbo].[bPMSS] ([PMCo], [Project], [SLCo], [SL]) ON [PRIMARY]
GO
