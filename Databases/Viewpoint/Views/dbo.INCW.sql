SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INCW] as select a.* From bINCW a
GO
GRANT SELECT ON  [dbo].[INCW] TO [public]
GRANT INSERT ON  [dbo].[INCW] TO [public]
GRANT DELETE ON  [dbo].[INCW] TO [public]
GRANT UPDATE ON  [dbo].[INCW] TO [public]
GO
