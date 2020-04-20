SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[POCB] as select a.* From bPOCB a
GO
GRANT SELECT ON  [dbo].[POCB] TO [public]
GRANT INSERT ON  [dbo].[POCB] TO [public]
GRANT DELETE ON  [dbo].[POCB] TO [public]
GRANT UPDATE ON  [dbo].[POCB] TO [public]
GO
