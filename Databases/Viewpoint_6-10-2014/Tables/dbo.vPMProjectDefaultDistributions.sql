CREATE TABLE [dbo].[vPMProjectDefaultDistributions]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[FirmNumber] [dbo].[bFirm] NOT NULL,
[ContactCode] [dbo].[bEmployee] NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPMProjectDefaultDistributions] ADD CONSTRAINT [PK_vPMProjectDefaultDistributions] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPMProjectDefaultDistributions] ADD CONSTRAINT [UK_vPMProjectDefaultDistributions] UNIQUE NONCLUSTERED  ([PMCo], [Project], [FirmNumber], [ContactCode]) ON [PRIMARY]
GO
