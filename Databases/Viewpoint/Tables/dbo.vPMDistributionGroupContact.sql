CREATE TABLE [dbo].[vPMDistributionGroupContact]
(
[DistributionGroupID] [bigint] NOT NULL,
[ContactTable] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[ContactKeyID] [bigint] NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPMDistributionGroupContact] ADD CONSTRAINT [PK_vPMDistributionGroupContact] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vPMDistributionGroupContact_ContactTable_ContactKeyID] ON [dbo].[vPMDistributionGroupContact] ([DistributionGroupID], [ContactTable], [ContactKeyID]) ON [PRIMARY]
GO
