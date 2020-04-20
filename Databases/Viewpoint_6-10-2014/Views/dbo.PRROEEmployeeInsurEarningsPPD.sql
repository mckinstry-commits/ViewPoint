SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRROEEmployeeInsurEarningsPPD] as select a.* From vPRROEEmployeeInsurEarningsPPD a

GO
GRANT SELECT ON  [dbo].[PRROEEmployeeInsurEarningsPPD] TO [public]
GRANT INSERT ON  [dbo].[PRROEEmployeeInsurEarningsPPD] TO [public]
GRANT DELETE ON  [dbo].[PRROEEmployeeInsurEarningsPPD] TO [public]
GRANT UPDATE ON  [dbo].[PRROEEmployeeInsurEarningsPPD] TO [public]
GRANT SELECT ON  [dbo].[PRROEEmployeeInsurEarningsPPD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRROEEmployeeInsurEarningsPPD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRROEEmployeeInsurEarningsPPD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRROEEmployeeInsurEarningsPPD] TO [Viewpoint]
GO
