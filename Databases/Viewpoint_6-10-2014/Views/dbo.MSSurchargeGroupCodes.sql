SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE view [dbo].[MSSurchargeGroupCodes] as select a.* From bMSSurchargeGroupCodes a









GO
GRANT SELECT ON  [dbo].[MSSurchargeGroupCodes] TO [public]
GRANT INSERT ON  [dbo].[MSSurchargeGroupCodes] TO [public]
GRANT DELETE ON  [dbo].[MSSurchargeGroupCodes] TO [public]
GRANT UPDATE ON  [dbo].[MSSurchargeGroupCodes] TO [public]
GRANT SELECT ON  [dbo].[MSSurchargeGroupCodes] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSSurchargeGroupCodes] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSSurchargeGroupCodes] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSSurchargeGroupCodes] TO [Viewpoint]
GO
