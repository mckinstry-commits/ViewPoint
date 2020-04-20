SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQCG] as select a.* From bHQCG a

GO
GRANT SELECT ON  [dbo].[HQCG] TO [public]
GRANT INSERT ON  [dbo].[HQCG] TO [public]
GRANT DELETE ON  [dbo].[HQCG] TO [public]
GRANT UPDATE ON  [dbo].[HQCG] TO [public]
GRANT SELECT ON  [dbo].[HQCG] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQCG] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQCG] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQCG] TO [Viewpoint]
GO
