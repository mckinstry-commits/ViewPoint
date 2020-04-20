SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[vrvSMTechnicianList]
AS 

/***********************************************************************
*
*	Created: 10/18/2011
*	Author : Czeslaw Czapla
*
*	Purpose: 
*	This view lists SM Technicians and their assignments to Customers, 
*	Service Sites, and Service Centers.
*
*	Six flags indicate specifics about a given Technician's assignments. 
*	For example, a '1'	value in column TechForCustPrimary indicates 
*	that the Technician is assigned to the Customer as Primary Technician; 
*	a '1' value in column TechForCustAlt indicates assignment as Alternate 
*	Technician; a '1' value in column TechForCustDoNotUse indicates a 
*	'Do Not Use' designation in SM Technician Preferences for that Customer.
*	Similar flags indicate assignments vis-a-vis the Service Site.
*
*	Any Technician assigned to a Customer (as Primary, Alternate,
*	or Do Not Use) is associated by inheritance with each Service Site
*	for that Customer, and to the Service Center associated with
*	each such Service Site. Thus, a Technician assigned to the Customer
*	as Primary may appear as Primary for the Customer in multiple
*	rows, one row for each Service Site associated with that Customer.
*
*	Reports: SMCustList.rpt
*
*	Mods:	 
*
***********************************************************************/

WITH cteTechnicianList
AS (

/* Technician assigned to Customer as Primary */
SELECT				SMC.SMCo								AS SMCo,
					SMC.CustGroup							AS CustGroup,
					SMC.Customer							AS Customer,
					SMSS.ServiceSite						AS ServiceSite,
					SMSC.ServiceCenter						AS ServiceCenter,
					SMC.PrimaryTechnician					AS Technician,
					PREH.LastName + ', ' + PREH.FirstName	AS TechName,
					1										AS TechForCustPrimary,
					0										AS TechForCustAlt,
					0										AS TechForCustDoNotUse,
					0										AS TechForSitePrimary,
					0										AS TechForSiteAlt,
					0										AS TechForSiteDoNotUse
					
FROM				SMCustomer					SMC

LEFT OUTER JOIN		SMServiceSite				SMSS
					ON	SMSS.SMCo				= SMC.SMCo
					AND	SMSS.CustGroup			= SMC.CustGroup
					AND	SMSS.Customer			= SMC.Customer

LEFT OUTER JOIN		SMServiceCenter				SMSC
					ON	SMSC.SMCo				= SMSS.SMCo
					AND	SMSC.ServiceCenter		= SMSS.DefaultServiceCenter
					
LEFT OUTER JOIN		SMTechnician				SMTE
					ON	SMTE.SMCo				= SMC.SMCo
					AND	SMTE.Technician			= SMC.PrimaryTechnician
					
LEFT OUTER JOIN		PREH						PREH
					ON	PREH.PRCo				= SMTE.PRCo
					AND	PREH.Employee			= SMTE.Employee
					
WHERE				SMC.PrimaryTechnician IS NOT NULL

UNION ALL

/* Technician assigned to Customer as Alternate */
SELECT				SMTP.SMCo								AS SMCo,
					SMTP.CustGroup							AS CustGroup,
					SMTP.Customer							AS Customer,
					SMSS.ServiceSite						AS ServiceSite,
					SMSC.ServiceCenter						AS ServiceCenter,
					SMTP.Technician							AS Technician,
					PREH.LastName + ', ' + PREH.FirstName	AS TechName,
					0										AS TechForCustPrimary,
					1										AS TechForCustAlt,
					0										AS TechForCustDoNotUse,
					0										AS TechForSitePrimary,
					0										AS TechForSiteAlt,
					0										AS TechForSiteDoNotUse

FROM				SMTechnicianPreferences		SMTP

LEFT OUTER JOIN		SMServiceSite				SMSS
					ON	SMSS.SMCo				= SMTP.SMCo
					AND	SMSS.CustGroup			= SMTP.CustGroup
					AND	SMSS.Customer			= SMTP.Customer

LEFT OUTER JOIN		SMServiceCenter				SMSC
					ON	SMSC.SMCo				= SMSS.SMCo
					AND	SMSC.ServiceCenter		= SMSS.DefaultServiceCenter
					
LEFT OUTER JOIN		SMTechnician				SMTE
					ON	SMTE.SMCo				= SMTP.SMCo
					AND	SMTE.Technician			= SMTP.Technician
					
LEFT OUTER JOIN		PREH						PREH
					ON	PREH.PRCo				= SMTE.PRCo
					AND	PREH.Employee			= SMTE.Employee
					
WHERE				SMTP.Status			= 'A'
AND					SMTP.ServiceSite	IS NULL

UNION ALL

/* Technician assigned to Customer as Do Not Use */
SELECT				SMTP.SMCo								AS SMCo,
					SMTP.CustGroup							AS CustGroup,
					SMTP.Customer							AS Customer,
					SMSS.ServiceSite						AS ServiceSite,
					SMSC.ServiceCenter						AS ServiceCenter,
					SMTP.Technician							AS Technician,
					PREH.LastName + ', ' + PREH.FirstName	AS TechName,
					0										AS TechForCustPrimary,
					0										AS TechForCustAlt,
					1										AS TechForCustDoNotUse,
					0										AS TechForSitePrimary,
					0										AS TechForSiteAlt,
					0										AS TechForSiteDoNotUse

FROM				SMTechnicianPreferences		SMTP

LEFT OUTER JOIN		SMServiceSite				SMSS
					ON	SMSS.SMCo				= SMTP.SMCo
					AND	SMSS.CustGroup			= SMTP.CustGroup
					AND	SMSS.Customer			= SMTP.Customer

LEFT OUTER JOIN		SMServiceCenter				SMSC
					ON	SMSC.SMCo				= SMSS.SMCo
					AND	SMSC.ServiceCenter		= SMSS.DefaultServiceCenter
					
LEFT OUTER JOIN		SMTechnician				SMTE
					ON	SMTE.SMCo				= SMTP.SMCo
					AND	SMTE.Technician			= SMTP.Technician
					
LEFT OUTER JOIN		PREH						PREH
					ON	PREH.PRCo				= SMTE.PRCo
					AND	PREH.Employee			= SMTE.Employee
					
WHERE				SMTP.Status			= 'D'
AND					SMTP.ServiceSite	IS NULL

UNION ALL

/* Technician assigned to ServiceSite as Primary */
SELECT				SMSS.SMCo								AS SMCo,
					SMSS.CustGroup							AS CustGroup,
					SMSS.Customer							AS Customer,
					SMSS.ServiceSite						AS ServiceSite,
					SMSC.ServiceCenter						AS ServiceCenter,
					SMSS.PrimaryTechnician					AS Technician,
					PREH.LastName + ', ' + PREH.FirstName	AS TechName,
					0										AS TechForCustPrimary,
					0										AS TechForCustAlt,
					0										AS TechForCustDoNotUse,
					1										AS TechForSitePrimary,
					0										AS TechForSiteAlt,
					0										AS TechForSiteDoNotUse
                        
FROM				SMServiceSite				SMSS

LEFT OUTER JOIN		SMServiceCenter				SMSC
					ON	SMSC.SMCo				= SMSS.SMCo
					AND	SMSC.ServiceCenter		= SMSS.DefaultServiceCenter
					
LEFT OUTER JOIN		SMTechnician				SMTE
					ON	SMTE.SMCo				= SMSS.SMCo
					AND	SMTE.Technician			= SMSS.PrimaryTechnician
					
LEFT OUTER JOIN		PREH						PREH
					ON	PREH.PRCo				= SMTE.PRCo
					AND	PREH.Employee			= SMTE.Employee
					
WHERE				SMSS.PrimaryTechnician IS NOT NULL
					
UNION ALL

/* Technician assigned to ServiceSite as Alternate */
SELECT				SMTP.SMCo								AS SMCo,
					SMSS.CustGroup							AS CustGroup,
					SMSS.Customer							AS Customer,
					SMTP.ServiceSite						AS ServiceSite,
					SMSC.ServiceCenter						AS ServiceCenter,
					SMTP.Technician							AS Technician,
					PREH.LastName + ', ' + PREH.FirstName	AS TechName,
					0										AS TechForCustPrimary,
					0										AS TechForCustAlt,
					0										AS TechForCustDoNotUse,
					0										AS TechForSitePrimary,
					1										AS TechForSiteAlt,
					0										AS TechForSiteDoNotUse

FROM				SMTechnicianPreferences		SMTP

LEFT OUTER JOIN		SMServiceSite				SMSS
					ON	SMSS.SMCo				= SMTP.SMCo
					AND	SMSS.ServiceSite		= SMTP.ServiceSite

LEFT OUTER JOIN		SMServiceCenter				SMSC
					ON	SMSC.SMCo				= SMSS.SMCo
					AND	SMSC.ServiceCenter		= SMSS.DefaultServiceCenter
					
LEFT OUTER JOIN		SMTechnician				SMTE
					ON	SMTE.SMCo				= SMTP.SMCo
					AND	SMTE.Technician			= SMTP.Technician
					
LEFT OUTER JOIN		PREH						PREH
					ON	PREH.PRCo				= SMTE.PRCo
					AND	PREH.Employee			= SMTE.Employee
					
WHERE				SMTP.Status			= 'A'
AND					SMTP.CustGroup		IS NULL
AND					SMTP.Customer		IS NULL

UNION ALL

/* Technician assigned to ServiceSite as Do Not Use */
SELECT				SMTP.SMCo								AS SMCo,
					SMSS.CustGroup							AS CustGroup,
					SMSS.Customer							AS Customer,
					SMTP.ServiceSite						AS ServiceSite,
					SMSC.ServiceCenter						AS ServiceCenter,
					SMTP.Technician							AS Technician,
					PREH.LastName + ', ' + PREH.FirstName	AS TechName,
					0										AS TechForCustPrimary,
					0										AS TechForCustAlt,
					0										AS TechForCustDoNotUse,
					0										AS TechForSitePrimary,
					0										AS TechForSiteAlt,
					1										AS TechForSiteDoNotUse

FROM				SMTechnicianPreferences		SMTP

LEFT OUTER JOIN		SMServiceSite				SMSS
					ON	SMSS.SMCo				= SMTP.SMCo
					AND	SMSS.ServiceSite		= SMTP.ServiceSite

LEFT OUTER JOIN		SMServiceCenter				SMSC
					ON	SMSC.SMCo				= SMSS.SMCo
					AND	SMSC.ServiceCenter		= SMSS.DefaultServiceCenter

LEFT OUTER JOIN		SMTechnician				SMTE
					ON	SMTE.SMCo				= SMTP.SMCo
					AND	SMTE.Technician			= SMTP.Technician
					
LEFT OUTER JOIN		PREH						PREH
					ON	PREH.PRCo				= SMTE.PRCo
					AND	PREH.Employee			= SMTE.Employee
					
WHERE				SMTP.Status			= 'D'
AND					SMTP.CustGroup		IS NULL
AND					SMTP.Customer		IS NULL

)			



/* FINAL select statement */
SELECT				SMCo,
					CustGroup,
					Customer,
					ServiceSite,
					ServiceCenter,
					Technician,
					TechName,
					MAX(TechForCustPrimary)		AS TechForCustPrimary,
					MAX(TechForCustAlt)			AS TechForCustAlt,
					MAX(TechForCustDoNotUse)	AS TechForCustDoNotUse,
					MAX(TechForSitePrimary)		AS TechForSitePrimary,
					MAX(TechForSiteAlt)			AS TechForSiteAlt,
					MAX(TechForSiteDoNotUse)	AS TechForSiteDoNotUse
FROM				cteTechnicianList
GROUP BY			SMCo,
					CustGroup,
					Customer,
					ServiceSite,
					ServiceCenter,
					Technician,
					TechName
GO
GRANT SELECT ON  [dbo].[vrvSMTechnicianList] TO [public]
GRANT INSERT ON  [dbo].[vrvSMTechnicianList] TO [public]
GRANT DELETE ON  [dbo].[vrvSMTechnicianList] TO [public]
GRANT UPDATE ON  [dbo].[vrvSMTechnicianList] TO [public]
GO
