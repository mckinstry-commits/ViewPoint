SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQPO] as select a.* From bHQPO a

GO
GRANT SELECT ON  [dbo].[HQPO] TO [public]
GRANT INSERT ON  [dbo].[HQPO] TO [public]
GRANT DELETE ON  [dbo].[HQPO] TO [public]
GRANT UPDATE ON  [dbo].[HQPO] TO [public]
GRANT SELECT ON  [dbo].[HQPO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQPO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQPO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQPO] TO [Viewpoint]
GO
