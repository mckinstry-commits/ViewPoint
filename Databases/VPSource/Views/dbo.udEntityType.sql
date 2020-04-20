SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udEntityType] as select a.* From budEntityType a
GO
GRANT SELECT ON  [dbo].[udEntityType] TO [public]
GRANT INSERT ON  [dbo].[udEntityType] TO [public]
GRANT DELETE ON  [dbo].[udEntityType] TO [public]
GRANT UPDATE ON  [dbo].[udEntityType] TO [public]
GO
