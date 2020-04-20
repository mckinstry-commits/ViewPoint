SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[ARMC] as select a.* From bARMC a

GO
GRANT SELECT ON  [dbo].[ARMC] TO [public]
GRANT INSERT ON  [dbo].[ARMC] TO [public]
GRANT DELETE ON  [dbo].[ARMC] TO [public]
GRANT UPDATE ON  [dbo].[ARMC] TO [public]
GO
