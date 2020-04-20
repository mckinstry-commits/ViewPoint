SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udLegalGuide] as select a.* From budLegalGuide a
GO
GRANT SELECT ON  [dbo].[udLegalGuide] TO [public]
GRANT INSERT ON  [dbo].[udLegalGuide] TO [public]
GRANT DELETE ON  [dbo].[udLegalGuide] TO [public]
GRANT UPDATE ON  [dbo].[udLegalGuide] TO [public]
GO
