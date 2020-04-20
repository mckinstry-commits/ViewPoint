CREATE TABLE [dbo].[vPMProjectDefaultDocumentDistribution]
(
[DocCategory] [dbo].[bDocType] NOT NULL,
[DocType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ContactKeyID] [bigint] NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPMProjectDefaultDocumentDistribution] ADD CONSTRAINT [PK_vPMProjectDefaultDocumentDistribution] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPMProjectDefaultDocumentDistribution] WITH NOCHECK ADD CONSTRAINT [FK_vPMProjectDefaultDocumentDistribution_vPMProjectDefaultDistributions] FOREIGN KEY ([ContactKeyID]) REFERENCES [dbo].[vPMProjectDefaultDistributions] ([KeyID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vPMProjectDefaultDocumentDistribution] NOCHECK CONSTRAINT [FK_vPMProjectDefaultDocumentDistribution_vPMProjectDefaultDistributions]
GO
