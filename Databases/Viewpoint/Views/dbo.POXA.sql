SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[POXA] as select a.* From bPOXA a

GO
GRANT SELECT ON  [dbo].[POXA] TO [public]
GRANT INSERT ON  [dbo].[POXA] TO [public]
GRANT DELETE ON  [dbo].[POXA] TO [public]
GRANT UPDATE ON  [dbo].[POXA] TO [public]
GO
