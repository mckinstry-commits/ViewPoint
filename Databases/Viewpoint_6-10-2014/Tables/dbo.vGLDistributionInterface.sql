CREATE TABLE [dbo].[vGLDistributionInterface]
(
[GLDistributionInterfaceID] [bigint] NOT NULL IDENTITY(1, 1),
[Source] [dbo].[bSource] NOT NULL,
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[InterfaceLevel] [tinyint] NOT NULL,
[Journal] [dbo].[bJrnl] NULL,
[SummaryDescription] [dbo].[bTransDesc] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vGLDistributionInterface] ADD CONSTRAINT [PK_vGLDistributionInterface] PRIMARY KEY CLUSTERED  ([GLDistributionInterfaceID]) ON [PRIMARY]
GO
