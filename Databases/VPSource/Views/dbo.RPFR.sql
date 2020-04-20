SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[RPFR] as select a.* From vRPFR a
GO
GRANT SELECT ON  [dbo].[RPFR] TO [public]
GRANT INSERT ON  [dbo].[RPFR] TO [public]
GRANT DELETE ON  [dbo].[RPFR] TO [public]
GRANT UPDATE ON  [dbo].[RPFR] TO [public]
GO
