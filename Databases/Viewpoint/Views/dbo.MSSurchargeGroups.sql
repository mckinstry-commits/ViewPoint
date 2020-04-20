SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE view [dbo].[MSSurchargeGroups] as select a.* From bMSSurchargeGroups a









GO
GRANT SELECT ON  [dbo].[MSSurchargeGroups] TO [public]
GRANT INSERT ON  [dbo].[MSSurchargeGroups] TO [public]
GRANT DELETE ON  [dbo].[MSSurchargeGroups] TO [public]
GRANT UPDATE ON  [dbo].[MSSurchargeGroups] TO [public]
GO
