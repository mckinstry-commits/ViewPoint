SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[udGenTerms] as select a.* From budGenTerms a
GO
GRANT SELECT ON  [dbo].[udGenTerms] TO [public]
GRANT INSERT ON  [dbo].[udGenTerms] TO [public]
GRANT DELETE ON  [dbo].[udGenTerms] TO [public]
GRANT UPDATE ON  [dbo].[udGenTerms] TO [public]
GO
