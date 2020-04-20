SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRDT] as select a.* from bPRDT a 
GO
GRANT SELECT ON  [dbo].[PRDT] TO [public]
GRANT INSERT ON  [dbo].[PRDT] TO [public]
GRANT DELETE ON  [dbo].[PRDT] TO [public]
GRANT UPDATE ON  [dbo].[PRDT] TO [public]
GRANT SELECT ON  [dbo].[PRDT] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRDT] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRDT] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRDT] TO [Viewpoint]
GO