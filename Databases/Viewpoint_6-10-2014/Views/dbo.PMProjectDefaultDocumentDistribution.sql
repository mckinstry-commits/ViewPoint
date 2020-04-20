SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[PMProjectDefaultDocumentDistribution] as select a.* From vPMProjectDefaultDocumentDistribution a

GO
GRANT SELECT ON  [dbo].[PMProjectDefaultDocumentDistribution] TO [public]
GRANT INSERT ON  [dbo].[PMProjectDefaultDocumentDistribution] TO [public]
GRANT DELETE ON  [dbo].[PMProjectDefaultDocumentDistribution] TO [public]
GRANT UPDATE ON  [dbo].[PMProjectDefaultDocumentDistribution] TO [public]
GRANT SELECT ON  [dbo].[PMProjectDefaultDocumentDistribution] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMProjectDefaultDocumentDistribution] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMProjectDefaultDocumentDistribution] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMProjectDefaultDocumentDistribution] TO [Viewpoint]
GO
