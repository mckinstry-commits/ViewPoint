SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udPhaseCategories] as select a.* From budPhaseCategories a
GO
GRANT SELECT ON  [dbo].[udPhaseCategories] TO [public]
GRANT INSERT ON  [dbo].[udPhaseCategories] TO [public]
GRANT DELETE ON  [dbo].[udPhaseCategories] TO [public]
GRANT UPDATE ON  [dbo].[udPhaseCategories] TO [public]
GO
