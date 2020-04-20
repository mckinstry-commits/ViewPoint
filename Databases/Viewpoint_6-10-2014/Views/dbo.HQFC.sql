SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQFC] as select a.* From bHQFC a

GO
GRANT SELECT ON  [dbo].[HQFC] TO [public]
GRANT INSERT ON  [dbo].[HQFC] TO [public]
GRANT DELETE ON  [dbo].[HQFC] TO [public]
GRANT UPDATE ON  [dbo].[HQFC] TO [public]
GRANT SELECT ON  [dbo].[HQFC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQFC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQFC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQFC] TO [Viewpoint]
GO
