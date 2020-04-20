SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMPF] as select a.* From bPMPF a
GO
GRANT SELECT ON  [dbo].[PMPF] TO [public]
GRANT INSERT ON  [dbo].[PMPF] TO [public]
GRANT DELETE ON  [dbo].[PMPF] TO [public]
GRANT UPDATE ON  [dbo].[PMPF] TO [public]
GO
