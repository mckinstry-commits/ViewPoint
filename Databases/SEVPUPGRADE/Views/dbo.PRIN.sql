SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRIN] as select a.* From bPRIN a

GO
GRANT SELECT ON  [dbo].[PRIN] TO [public]
GRANT INSERT ON  [dbo].[PRIN] TO [public]
GRANT DELETE ON  [dbo].[PRIN] TO [public]
GRANT UPDATE ON  [dbo].[PRIN] TO [public]
GO
