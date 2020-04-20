SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udPOSpecTerms] as select a.* From budPOSpecTerms a
GO
GRANT SELECT ON  [dbo].[udPOSpecTerms] TO [public]
GRANT INSERT ON  [dbo].[udPOSpecTerms] TO [public]
GRANT DELETE ON  [dbo].[udPOSpecTerms] TO [public]
GRANT UPDATE ON  [dbo].[udPOSpecTerms] TO [public]
GO
