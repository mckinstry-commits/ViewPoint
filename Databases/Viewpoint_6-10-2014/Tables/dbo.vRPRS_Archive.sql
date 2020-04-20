CREATE TABLE [dbo].[vRPRS_Archive]
(
[Co] [smallint] NOT NULL,
[ReportID] [int] NOT NULL,
[SecurityGroup] [int] NOT NULL,
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[Access] [tinyint] NOT NULL,
[ArchiveDate] [datetime] NULL CONSTRAINT [DF__vRPRS_Arc__Archi__03364247] DEFAULT (getdate()),
[ArchiveID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
