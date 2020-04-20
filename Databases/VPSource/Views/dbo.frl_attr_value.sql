SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[frl_attr_value] as select a.* From vfrl_attr_value a

GO
GRANT SELECT ON  [dbo].[frl_attr_value] TO [public]
GRANT INSERT ON  [dbo].[frl_attr_value] TO [public]
GRANT DELETE ON  [dbo].[frl_attr_value] TO [public]
GRANT UPDATE ON  [dbo].[frl_attr_value] TO [public]
GO
