SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SLCD] as select a.* From bSLCD a
GO
GRANT SELECT ON  [dbo].[SLCD] TO [public]
GRANT INSERT ON  [dbo].[SLCD] TO [public]
GRANT DELETE ON  [dbo].[SLCD] TO [public]
GRANT UPDATE ON  [dbo].[SLCD] TO [public]
GO
