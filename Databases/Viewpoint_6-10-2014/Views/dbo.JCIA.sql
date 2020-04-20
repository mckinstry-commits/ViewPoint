SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCIA] as select a.* From bJCIA a
GO
GRANT SELECT ON  [dbo].[JCIA] TO [public]
GRANT INSERT ON  [dbo].[JCIA] TO [public]
GRANT DELETE ON  [dbo].[JCIA] TO [public]
GRANT UPDATE ON  [dbo].[JCIA] TO [public]
GRANT SELECT ON  [dbo].[JCIA] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCIA] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCIA] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCIA] TO [Viewpoint]
GO
