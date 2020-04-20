SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[IMTR] as select a.* From bIMTR a

GO
GRANT SELECT ON  [dbo].[IMTR] TO [public]
GRANT INSERT ON  [dbo].[IMTR] TO [public]
GRANT DELETE ON  [dbo].[IMTR] TO [public]
GRANT UPDATE ON  [dbo].[IMTR] TO [public]
GO
