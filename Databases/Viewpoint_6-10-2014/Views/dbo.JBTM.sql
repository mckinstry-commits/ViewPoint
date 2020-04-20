SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBTM] as select a.* From bJBTM a
GO
GRANT SELECT ON  [dbo].[JBTM] TO [public]
GRANT INSERT ON  [dbo].[JBTM] TO [public]
GRANT DELETE ON  [dbo].[JBTM] TO [public]
GRANT UPDATE ON  [dbo].[JBTM] TO [public]
GRANT SELECT ON  [dbo].[JBTM] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JBTM] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JBTM] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JBTM] TO [Viewpoint]
GO
