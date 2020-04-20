SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO















CREATE view [dbo].[MSSurchargeCodeRates] as select a.* From bMSSurchargeCodeRates a
















GO
GRANT SELECT ON  [dbo].[MSSurchargeCodeRates] TO [public]
GRANT INSERT ON  [dbo].[MSSurchargeCodeRates] TO [public]
GRANT DELETE ON  [dbo].[MSSurchargeCodeRates] TO [public]
GRANT UPDATE ON  [dbo].[MSSurchargeCodeRates] TO [public]
GRANT SELECT ON  [dbo].[MSSurchargeCodeRates] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSSurchargeCodeRates] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSSurchargeCodeRates] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSSurchargeCodeRates] TO [Viewpoint]
GO
