SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udSpecTerms] as select a.* From budSpecTerms a
GO
GRANT SELECT ON  [dbo].[udSpecTerms] TO [public]
GRANT INSERT ON  [dbo].[udSpecTerms] TO [public]
GRANT DELETE ON  [dbo].[udSpecTerms] TO [public]
GRANT UPDATE ON  [dbo].[udSpecTerms] TO [public]
GO
