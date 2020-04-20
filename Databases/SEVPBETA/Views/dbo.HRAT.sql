SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRAT] as select a.* From bHRAT a
GO
GRANT SELECT ON  [dbo].[HRAT] TO [public]
GRANT INSERT ON  [dbo].[HRAT] TO [public]
GRANT DELETE ON  [dbo].[HRAT] TO [public]
GRANT UPDATE ON  [dbo].[HRAT] TO [public]
GO
