SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udAwardAgcy] as select a.* From budAwardAgcy a
GO
GRANT SELECT ON  [dbo].[udAwardAgcy] TO [public]
GRANT INSERT ON  [dbo].[udAwardAgcy] TO [public]
GRANT DELETE ON  [dbo].[udAwardAgcy] TO [public]
GRANT UPDATE ON  [dbo].[udAwardAgcy] TO [public]
GO
