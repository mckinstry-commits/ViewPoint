SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[vrvSMContactList]
AS 

/***********************************************************************
*
*	Created: 11/1/2011
*	Author : Tim Schmick
*
*	Purpose: 
*	To provide a list of contacts by Company, Customer Group, Customer, and ServiceSite.
*	Primary contacts are identified as the contact on the Customer or Site level. Other
*	contacts are all other contacts identified through the SMCustomerContact and 
*	SMServiceSiteContact tables.
*	
*	Reports: SMContactList.rpt
*
*	Mods:	 
*
***********************************************************************/

WITH Contacts AS 
(
	-- Primary Customer Contacts 
	SELECT 
		'Primary' AS [Type],
/*Key*/	SMCo AS SMCompany, SMCustomer.CustGroup AS CustomerGroup, SMCustomer.Customer, 
		NULL AS ServiceSite, NULL AS HQContactID, -- primary contact is from ARCM, so no Site/HQContact link
		Contact AS ContactName,	  
		NULL AS Title,			
		Phone,					
		ContactExt AS Extension, 
		NULL AS Mobile, 
		Fax,					
		EMail AS Email,
		Active
	FROM 
		SMCustomer
			INNER JOIN
		ARCM ARCustomer
			ON SMCustomer.CustGroup = ARCustomer.CustGroup 
			AND SMCustomer.Customer = ARCustomer.Customer
	WHERE 
		Contact IS NOT NULL

	UNION ALL
	
	SELECT 
		'Primary',
/*Key*/	SMCo, CustGroup, Customer, ServiceSite, HQContactID,
		ISNULL(FirstName,'') + ' ' + ISNULL(MiddleInitial + ' ', '') +  ISNULL(LastName, ''),
		Title,
		HQContact.Phone,
		PhoneExtension,
		Cell,
		Fax,
		Email,
		Active
	FROM
		SMServiceSite
			INNER JOIN 
		HQContact HQContact
			ON  SMServiceSite.ContactGroup = HQContact.ContactGroup 
			AND SMServiceSite.ContactSeq = HQContact.ContactSeq

	UNION ALL

	-- Other Customer Contacts
	SELECT 
		'Other',
/*Key*/	SMCustomerContact.SMCo,	SMCustomerContact.CustGroup,	SMCustomerContact.Customer, NULL AS ServiceSite, HQContactID,
		ISNULL(FirstName,'') + ' ' + ISNULL(MiddleInitial + ' ', '') +  ISNULL(LastName, ''),
		Title,
		Phone,
		PhoneExtension,
		Cell,
		Fax,
		Email,
		Active
	FROM 
		SMCustomer
			INNER JOIN
		SMCustomerContact
			ON  SMCustomer.SMCo = SMCustomerContact.SMCo
			AND SMCustomer.CustGroup = SMCustomerContact.CustGroup
			AND SMCustomer.Customer = SMCustomerContact.Customer
			INNER JOIN
		HQContact
			ON dbo.SMCustomerContact.ContactSeq = dbo.HQContact.ContactSeq
			AND dbo.SMCustomerContact.ContactGroup = dbo.HQContact.ContactGroup
			
	UNION ALL

	-- Other Site Contacts
	SELECT 
		'Other',
/*Key*/	SMServiceSite.SMCo, CustGroup, Customer, SMServiceSite.ServiceSite, HQContactID,
		ISNULL(FirstName,'') + ' ' + ISNULL(MiddleInitial + ' ', '') +  ISNULL(LastName, ''),
		Title,
		HQContact.Phone,
		PhoneExtension,
		Cell,
		Fax,
		Email,
		Active
	FROM
		SMServiceSite
			INNER JOIN
		SMServiceSiteContact 
			ON  SMServiceSite.SMCo = SMServiceSiteContact.SMCo
			AND SMServiceSite.ServiceSite = SMServiceSiteContact.ServiceSite
			INNER JOIN
		HQContact 
			ON  SMServiceSiteContact.ContactGroup = HQContact.ContactGroup 
			AND SMServiceSiteContact.ContactSeq = HQContact.ContactSeq
	WHERE 
			-- The default contact will automatically be added to the SMServiceSiteContact table
			SMServiceSiteContact.ContactGroup <> ISNULL(SMServiceSite.ContactGroup, '')
		OR SMServiceSiteContact.ContactSeq <> ISNULL(SMServiceSite.ContactSeq, '')

) 

SELECT * FROM Contacts

-- Other fields used in report; consider adding as joins to above select statement
-- ARCM, Name
-- SMServiceCenter, Description
-- SMServiceSite, Description, Status
-- SMCustomer, Status
GO
GRANT SELECT ON  [dbo].[vrvSMContactList] TO [public]
GRANT INSERT ON  [dbo].[vrvSMContactList] TO [public]
GRANT DELETE ON  [dbo].[vrvSMContactList] TO [public]
GRANT UPDATE ON  [dbo].[vrvSMContactList] TO [public]
GRANT SELECT ON  [dbo].[vrvSMContactList] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvSMContactList] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvSMContactList] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvSMContactList] TO [Viewpoint]
GO
