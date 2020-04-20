SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBAR] as select a.* From bJBAR a
GO
GRANT SELECT ON  [dbo].[JBAR] TO [public]
GRANT INSERT ON  [dbo].[JBAR] TO [public]
GRANT DELETE ON  [dbo].[JBAR] TO [public]
GRANT UPDATE ON  [dbo].[JBAR] TO [public]
GRANT SELECT ON  [dbo].[JBAR] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JBAR] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JBAR] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JBAR] TO [Viewpoint]
GO
