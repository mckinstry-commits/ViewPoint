SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBIL] as select a.* From bJBIL a
GO
GRANT SELECT ON  [dbo].[JBIL] TO [public]
GRANT INSERT ON  [dbo].[JBIL] TO [public]
GRANT DELETE ON  [dbo].[JBIL] TO [public]
GRANT UPDATE ON  [dbo].[JBIL] TO [public]
GRANT SELECT ON  [dbo].[JBIL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JBIL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JBIL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JBIL] TO [Viewpoint]
GO
