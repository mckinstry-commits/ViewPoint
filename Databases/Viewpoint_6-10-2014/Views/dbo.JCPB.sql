SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCPB] as select a.* From bJCPB a
GO
GRANT SELECT ON  [dbo].[JCPB] TO [public]
GRANT INSERT ON  [dbo].[JCPB] TO [public]
GRANT DELETE ON  [dbo].[JCPB] TO [public]
GRANT UPDATE ON  [dbo].[JCPB] TO [public]
GRANT SELECT ON  [dbo].[JCPB] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCPB] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCPB] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCPB] TO [Viewpoint]
GO
