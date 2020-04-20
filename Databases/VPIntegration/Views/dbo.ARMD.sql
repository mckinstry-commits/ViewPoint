SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[ARMD] as select a.* From bARMD a

GO
GRANT SELECT ON  [dbo].[ARMD] TO [public]
GRANT INSERT ON  [dbo].[ARMD] TO [public]
GRANT DELETE ON  [dbo].[ARMD] TO [public]
GRANT UPDATE ON  [dbo].[ARMD] TO [public]
GO
