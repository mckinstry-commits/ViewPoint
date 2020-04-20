SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQWL] as select a.* From bHQWL a

GO
GRANT SELECT ON  [dbo].[HQWL] TO [public]
GRANT INSERT ON  [dbo].[HQWL] TO [public]
GRANT DELETE ON  [dbo].[HQWL] TO [public]
GRANT UPDATE ON  [dbo].[HQWL] TO [public]
GRANT SELECT ON  [dbo].[HQWL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQWL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQWL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQWL] TO [Viewpoint]
GO
