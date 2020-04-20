SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQAX] as select a.* From bHQAX a

GO
GRANT SELECT ON  [dbo].[HQAX] TO [public]
GRANT INSERT ON  [dbo].[HQAX] TO [public]
GRANT DELETE ON  [dbo].[HQAX] TO [public]
GRANT UPDATE ON  [dbo].[HQAX] TO [public]
GRANT SELECT ON  [dbo].[HQAX] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQAX] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQAX] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQAX] TO [Viewpoint]
GO
