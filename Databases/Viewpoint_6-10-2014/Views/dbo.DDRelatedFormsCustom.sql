SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[DDRelatedFormsCustom] as select * from vDDRelatedFormsCustom
GO
GRANT SELECT ON  [dbo].[DDRelatedFormsCustom] TO [public]
GRANT INSERT ON  [dbo].[DDRelatedFormsCustom] TO [public]
GRANT DELETE ON  [dbo].[DDRelatedFormsCustom] TO [public]
GRANT UPDATE ON  [dbo].[DDRelatedFormsCustom] TO [public]
GRANT SELECT ON  [dbo].[DDRelatedFormsCustom] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDRelatedFormsCustom] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDRelatedFormsCustom] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDRelatedFormsCustom] TO [Viewpoint]
GO
