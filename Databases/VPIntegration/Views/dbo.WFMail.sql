SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[WFMail] as select a.* From vWFMail a
GO
GRANT SELECT ON  [dbo].[WFMail] TO [public]
GRANT INSERT ON  [dbo].[WFMail] TO [public]
GRANT DELETE ON  [dbo].[WFMail] TO [public]
GRANT UPDATE ON  [dbo].[WFMail] TO [public]
GO
