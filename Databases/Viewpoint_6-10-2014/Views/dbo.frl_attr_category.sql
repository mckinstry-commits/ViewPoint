SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[frl_attr_category] as select a.* From vfrl_attr_category a

GO
GRANT SELECT ON  [dbo].[frl_attr_category] TO [public]
GRANT INSERT ON  [dbo].[frl_attr_category] TO [public]
GRANT DELETE ON  [dbo].[frl_attr_category] TO [public]
GRANT UPDATE ON  [dbo].[frl_attr_category] TO [public]
GRANT SELECT ON  [dbo].[frl_attr_category] TO [Viewpoint]
GRANT INSERT ON  [dbo].[frl_attr_category] TO [Viewpoint]
GRANT DELETE ON  [dbo].[frl_attr_category] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[frl_attr_category] TO [Viewpoint]
GO
