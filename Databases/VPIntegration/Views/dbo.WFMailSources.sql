SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[WFMailSources] as select a.* From vWFMailSources a
GO
GRANT SELECT ON  [dbo].[WFMailSources] TO [public]
GRANT INSERT ON  [dbo].[WFMailSources] TO [public]
GRANT DELETE ON  [dbo].[WFMailSources] TO [public]
GRANT UPDATE ON  [dbo].[WFMailSources] TO [public]
GO
