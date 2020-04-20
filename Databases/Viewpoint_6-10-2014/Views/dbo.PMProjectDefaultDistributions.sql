SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMProjectDefaultDistributions] as select a.* From vPMProjectDefaultDistributions a
GO
GRANT SELECT ON  [dbo].[PMProjectDefaultDistributions] TO [public]
GRANT INSERT ON  [dbo].[PMProjectDefaultDistributions] TO [public]
GRANT DELETE ON  [dbo].[PMProjectDefaultDistributions] TO [public]
GRANT UPDATE ON  [dbo].[PMProjectDefaultDistributions] TO [public]
GRANT SELECT ON  [dbo].[PMProjectDefaultDistributions] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMProjectDefaultDistributions] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMProjectDefaultDistributions] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMProjectDefaultDistributions] TO [Viewpoint]
GO
