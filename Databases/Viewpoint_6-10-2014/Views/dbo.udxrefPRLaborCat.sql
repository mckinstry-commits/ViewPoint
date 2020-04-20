SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[udxrefPRLaborCat] as select a.* From budxrefPRLaborCat a
GO
GRANT SELECT ON  [dbo].[udxrefPRLaborCat] TO [public]
GRANT INSERT ON  [dbo].[udxrefPRLaborCat] TO [public]
GRANT DELETE ON  [dbo].[udxrefPRLaborCat] TO [public]
GRANT UPDATE ON  [dbo].[udxrefPRLaborCat] TO [public]
GO
