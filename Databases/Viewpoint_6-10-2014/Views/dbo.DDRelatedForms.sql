SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[DDRelatedForms] as select * from vDDRelatedForms
GO
GRANT SELECT ON  [dbo].[DDRelatedForms] TO [public]
GRANT INSERT ON  [dbo].[DDRelatedForms] TO [public]
GRANT DELETE ON  [dbo].[DDRelatedForms] TO [public]
GRANT UPDATE ON  [dbo].[DDRelatedForms] TO [public]
GRANT SELECT ON  [dbo].[DDRelatedForms] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDRelatedForms] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDRelatedForms] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDRelatedForms] TO [Viewpoint]
GO
