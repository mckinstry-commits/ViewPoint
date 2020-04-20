SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMTechnicianPreferred]
AS
Select Distinct * from (

SELECT SMTechnician.SMCo, SMTechnician.Technician, PREH.LastName+', '+ PREH.FirstName Name, SMTechnician.PRCo,SMTechnician.Employee,
	'Primary' Status,
	SMServiceSite.ServiceSite,
	NULL CustGroup,
	NULL Customer
FROM SMTechnician
INNER JOIN PREH
	ON PREH.PRCo=SMTechnician.PRCo 
	AND PREH.Employee=SMTechnician.Employee
INNER JOIN SMServiceSite
	ON SMServiceSite.SMCo = SMTechnician.SMCo
	AND SMServiceSite.PrimaryTechnician = SMTechnician.Technician

UNION 

SELECT SMTechnician.SMCo, SMTechnician.Technician, PREH.LastName+', '+ PREH.FirstName Name, SMTechnician.PRCo,SMTechnician.Employee,
CASE WHEN SMServiceSite.PrimaryTechnician=SMTechnician.Technician THEN 'Primary'
	WHEN NOT SitePref.Technician IS NULL THEN 
		SUBSTRING(DDCI.DisplayValue,3,99)
	END Status,
	SMServiceSite.ServiceSite,
	NULL CustGroup,
	NULL Customer
FROM SMTechnician
INNER JOIN PREH
	ON PREH.PRCo=SMTechnician.PRCo 
	AND PREH.Employee=SMTechnician.Employee
INNER JOIN SMTechnicianPreferences SitePref
	ON SitePref.SMCo=SMTechnician.SMCo
	AND SitePref.Technician=SMTechnician.Technician
INNER JOIN SMServiceSite
	ON SMServiceSite.SMCo = SitePref.SMCo
	AND SMServiceSite.ServiceSite = SitePref.ServiceSite
INNER JOIN DDCI ON DDCI.ComboType='SMTechnicianPreferen'
	AND DDCI.DatabaseValue = SitePref.Status

UNION 

SELECT SMTechnician.SMCo, SMTechnician.Technician, PREH.LastName+', '+ PREH.FirstName Name, SMTechnician.PRCo,SMTechnician.Employee,
	'Primary' Status,
	NULL ServiceSite,
	SMCustomer.CustGroup,
	SMCustomer.Customer
FROM SMTechnician
INNER JOIN PREH
	ON PREH.PRCo=SMTechnician.PRCo 
	AND PREH.Employee=SMTechnician.Employee
INNER JOIN SMCustomer
	ON SMCustomer.SMCo = SMTechnician.SMCo
	AND SMCustomer.PrimaryTechnician = SMTechnician.Technician

UNION

SELECT SMTechnician.SMCo, SMTechnician.Technician, PREH.LastName+', '+ PREH.FirstName Name, SMTechnician.PRCo,SMTechnician.Employee,
CASE WHEN SMCustomer.PrimaryTechnician=SMTechnician.Technician THEN 'Primary'
	WHEN NOT CustomerPref.Technician IS NULL THEN 
		SUBSTRING(DDCI.DisplayValue,3,99)
	END Status,
	NULL ServiceSite,
	SMCustomer.CustGroup,
	SMCustomer.Customer
FROM SMTechnician
INNER JOIN PREH
	ON PREH.PRCo=SMTechnician.PRCo 
	AND PREH.Employee=SMTechnician.Employee
INNER JOIN SMTechnicianPreferences CustomerPref
	ON CustomerPref.SMCo=SMTechnician.SMCo
	AND CustomerPref.Technician=SMTechnician.Technician
INNER JOIN SMCustomer 
	ON SMCustomer.SMCo=SMTechnician.SMCo
	AND SMCustomer.Customer=CustomerPref.Customer
	AND SMCustomer.CustGroup=CustomerPref.CustGroup
INNER JOIN DDCI ON DDCI.ComboType='SMTechnicianPreferen'
	AND DDCI.DatabaseValue = CustomerPref.Status

) a where Status IS NOT NULL

GO
GRANT SELECT ON  [dbo].[SMTechnicianPreferred] TO [public]
GRANT INSERT ON  [dbo].[SMTechnicianPreferred] TO [public]
GRANT DELETE ON  [dbo].[SMTechnicianPreferred] TO [public]
GRANT UPDATE ON  [dbo].[SMTechnicianPreferred] TO [public]
GO
