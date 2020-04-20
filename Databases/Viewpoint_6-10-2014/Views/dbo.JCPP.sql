SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCPP] as select a.* From bJCPP a
GO
GRANT SELECT ON  [dbo].[JCPP] TO [public]
GRANT INSERT ON  [dbo].[JCPP] TO [public]
GRANT DELETE ON  [dbo].[JCPP] TO [public]
GRANT UPDATE ON  [dbo].[JCPP] TO [public]
GRANT SELECT ON  [dbo].[JCPP] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCPP] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCPP] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCPP] TO [Viewpoint]
GO
