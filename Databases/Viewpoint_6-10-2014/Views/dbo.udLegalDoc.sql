SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udLegalDoc] as select a.* From budLegalDoc a
GO
GRANT SELECT ON  [dbo].[udLegalDoc] TO [public]
GRANT INSERT ON  [dbo].[udLegalDoc] TO [public]
GRANT DELETE ON  [dbo].[udLegalDoc] TO [public]
GRANT UPDATE ON  [dbo].[udLegalDoc] TO [public]
GO
