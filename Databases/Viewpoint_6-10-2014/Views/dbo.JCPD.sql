SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCPD] as select a.* From bJCPD a

GO
GRANT SELECT ON  [dbo].[JCPD] TO [public]
GRANT INSERT ON  [dbo].[JCPD] TO [public]
GRANT DELETE ON  [dbo].[JCPD] TO [public]
GRANT UPDATE ON  [dbo].[JCPD] TO [public]
GRANT SELECT ON  [dbo].[JCPD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCPD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCPD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCPD] TO [Viewpoint]
GO
