SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* =============================================
-- Author:		Lane Gresham
-- Create date: 08/16/2011
-- Description:	Determine if Technician Preferences values exist for specified Customer or Service Site
=============================================*/
CREATE FUNCTION [dbo].[vfSMTechPrefAdvExist]
(
	@SMCo AS bCompany,
	@CustGroup AS bGroup,
	@Customer AS bCustomer,
	@ServiceSite AS varchar(20)
)
RETURNS TABLE
AS
RETURN
(
	
	SELECT CASE WHEN EXISTS(
		SELECT 1 
		FROM dbo.SMTechnicianPreferences 
		WHERE SMCo = @SMCo AND (dbo.vfIsEqual(CustGroup,@CustGroup) & dbo.vfIsEqual(Customer,@Customer) & dbo.vfIsEqual(ServiceSite,@ServiceSite) = 1)
	) THEN 'Y' ELSE 'N' END AS TechPrefExits
	
)


GO
GRANT SELECT ON  [dbo].[vfSMTechPrefAdvExist] TO [public]
GO
