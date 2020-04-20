SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






















CREATE view [dbo].[MSSurchargeOverrides] as select a.* From bMSSurchargeOverrides a























GO
GRANT SELECT ON  [dbo].[MSSurchargeOverrides] TO [public]
GRANT INSERT ON  [dbo].[MSSurchargeOverrides] TO [public]
GRANT DELETE ON  [dbo].[MSSurchargeOverrides] TO [public]
GRANT UPDATE ON  [dbo].[MSSurchargeOverrides] TO [public]
GO
