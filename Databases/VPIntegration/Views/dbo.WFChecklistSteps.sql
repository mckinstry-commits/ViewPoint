SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[WFChecklistSteps] as select a.* From vWFChecklistSteps a
GO
GRANT SELECT ON  [dbo].[WFChecklistSteps] TO [public]
GRANT INSERT ON  [dbo].[WFChecklistSteps] TO [public]
GRANT DELETE ON  [dbo].[WFChecklistSteps] TO [public]
GRANT UPDATE ON  [dbo].[WFChecklistSteps] TO [public]
GO
