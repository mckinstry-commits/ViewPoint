SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRAG] as select a.* From bHRAG a
GO
GRANT SELECT ON  [dbo].[HRAG] TO [public]
GRANT INSERT ON  [dbo].[HRAG] TO [public]
GRANT DELETE ON  [dbo].[HRAG] TO [public]
GRANT UPDATE ON  [dbo].[HRAG] TO [public]
GO
