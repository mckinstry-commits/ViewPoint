SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQDR] as select a.* From bHQDR a

GO
GRANT SELECT ON  [dbo].[HQDR] TO [public]
GRANT INSERT ON  [dbo].[HQDR] TO [public]
GRANT DELETE ON  [dbo].[HQDR] TO [public]
GRANT UPDATE ON  [dbo].[HQDR] TO [public]
GRANT SELECT ON  [dbo].[HQDR] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQDR] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQDR] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQDR] TO [Viewpoint]
GO
