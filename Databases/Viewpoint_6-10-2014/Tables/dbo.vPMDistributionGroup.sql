CREATE TABLE [dbo].[vPMDistributionGroup]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[GroupName] [dbo].[bItemDesc] NOT NULL,
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[PublicGroup] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vPMDistributionGroup_PublicGroup] DEFAULT ('N'),
[Username] [dbo].[bVPUserName] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPMDistributionGroup] ADD CONSTRAINT [PK_vPMDistributionGroup] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vPMDistributionGroup_PMCo_GroupName] ON [dbo].[vPMDistributionGroup] ([PMCo], [GroupName]) ON [PRIMARY]
GO
