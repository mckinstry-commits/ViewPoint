SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udGenTerms] as select a.* From budGenTerms a
GO
GRANT SELECT ON  [dbo].[udGenTerms] TO [public]
GRANT INSERT ON  [dbo].[udGenTerms] TO [public]
GRANT DELETE ON  [dbo].[udGenTerms] TO [public]
GRANT UPDATE ON  [dbo].[udGenTerms] TO [public]
GRANT SELECT ON  [dbo].[udGenTerms] TO [Viewpoint]
GRANT INSERT ON  [dbo].[udGenTerms] TO [Viewpoint]
GRANT DELETE ON  [dbo].[udGenTerms] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[udGenTerms] TO [Viewpoint]
GO
