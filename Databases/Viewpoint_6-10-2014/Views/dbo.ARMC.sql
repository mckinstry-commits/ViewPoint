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
GRANT SELECT ON  [dbo].[ARMC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[ARMC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[ARMC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[ARMC] TO [Viewpoint]
GO
