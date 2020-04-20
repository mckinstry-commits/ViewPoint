SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INRI] as select a.* From bINRI a

GO
GRANT SELECT ON  [dbo].[INRI] TO [public]
GRANT INSERT ON  [dbo].[INRI] TO [public]
GRANT DELETE ON  [dbo].[INRI] TO [public]
GRANT UPDATE ON  [dbo].[INRI] TO [public]
GO
