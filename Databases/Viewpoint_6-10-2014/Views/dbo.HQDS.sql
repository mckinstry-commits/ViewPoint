SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQDS] as select a.* From bHQDS a

GO
GRANT SELECT ON  [dbo].[HQDS] TO [public]
GRANT INSERT ON  [dbo].[HQDS] TO [public]
GRANT DELETE ON  [dbo].[HQDS] TO [public]
GRANT UPDATE ON  [dbo].[HQDS] TO [public]
GRANT SELECT ON  [dbo].[HQDS] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQDS] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQDS] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQDS] TO [Viewpoint]
GO
