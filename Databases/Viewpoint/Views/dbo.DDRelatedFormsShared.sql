SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[DDRelatedFormsShared] 
as 

select * from DDRelatedForms
UNION
select * from DDRelatedFormsCustom c where not exists( select top 1 1 from DDRelatedForms where Form=c.Form and Tab=c.Tab)

GO
GRANT SELECT ON  [dbo].[DDRelatedFormsShared] TO [public]
GRANT INSERT ON  [dbo].[DDRelatedFormsShared] TO [public]
GRANT DELETE ON  [dbo].[DDRelatedFormsShared] TO [public]
GRANT UPDATE ON  [dbo].[DDRelatedFormsShared] TO [public]
GO
