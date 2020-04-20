SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRCC] as select a.* From bPRCC a
GO
GRANT SELECT ON  [dbo].[PRCC] TO [public]
GRANT INSERT ON  [dbo].[PRCC] TO [public]
GRANT DELETE ON  [dbo].[PRCC] TO [public]
GRANT UPDATE ON  [dbo].[PRCC] TO [public]
GO
