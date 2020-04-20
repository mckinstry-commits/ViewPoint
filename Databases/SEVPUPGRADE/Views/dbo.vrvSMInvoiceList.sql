SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  view [dbo].[vrvSMInvoiceList]
as

/*==================================================================================

Author:     
	Scott Alvey   
  
Create date:     
	09/21/2012     
  
Usage:  
	Drives the SM Invoice List report.   
  
Things to keep in mind regarding this report and proc:   
	Really the only thing to keep in mind is the CTE. Customer value can either
	come from the SM Service Site if the Type is Customer or from the JC Contract
	if the Type is Job. We need customer for ths report.
	   
  
Related reports:     
	SM Service Site List Report(ID#: 1195)        
  
Revision History        
	Date  Author   Issue      Description  
	

==================================================================================*/      

 SELECT 
	HQCO.HQCo
	, HQCO.Name as HQName
	, ARCM.Name
	, SMCustomer.SMCo
	, SMServiceCenter.ServiceCenter
	, SMServiceItems.ServiceItem
	, SMServiceItems.Class
	, SMServiceItems.Type
	, vrvSMTechnicianList.Technician
	, vrvSMTechnicianList.TechName
	, SMCustomer.Customer
	, SMServiceSite.ServiceSite
	, SMServiceSite.TrueDescription as Description
	, SMServiceSite.Address1
	, SMServiceSite.City
	, SMServiceSite.State
	, SMServiceSite.Zip
	, HQContact.FirstName
	, HQContact.LastName
	, SMServiceSite.Phone as ServiceSitePhone
	, HQContact.Phone
	, SMServiceSite.Active
	, SMServiceSite.Type as ServiceSiteType
 FROM  
	HQCO HQCO 
INNER JOIN
	SMCustomer SMCustomer ON 
		HQCO.HQCo=SMCustomer.SMCo
		and HQCO.CustGroup = SMCustomer.CustGroup 
INNER JOIN
	vrvSMServiceSiteCustomer SMServiceSite ON 
		SMCustomer.SMCo=SMServiceSite.SMCo 
		AND SMCustomer.CustGroup=SMServiceSite.TrueCustGroup 
		AND SMCustomer.Customer=SMServiceSite.TrueCustomer 
LEFT OUTER JOIN
	ARCM ARCM ON 
		SMCustomer.CustGroup=ARCM.CustGroup 
		AND SMCustomer.Customer=ARCM.Customer 
LEFT OUTER JOIN 
	vrvSMTechnicianList vrvSMTechnicianList ON 
		SMCustomer.SMCo=vrvSMTechnicianList.SMCo 
		AND SMCustomer.CustGroup=vrvSMTechnicianList.CustGroup 
		AND SMCustomer.Customer=vrvSMTechnicianList.Customer 
LEFT OUTER JOIN
	SMServiceCenter SMServiceCenter ON	
		SMServiceSite.SMCo=SMServiceCenter.SMCo 
		AND SMServiceSite.DefaultServiceCenter=SMServiceCenter.ServiceCenter 
LEFT OUTER JOIN
	SMServiceItems SMServiceItems ON 
		SMServiceSite.SMCo=SMServiceItems.SMCo 
		AND SMServiceSite.ServiceSite=SMServiceItems.ServiceSite 
LEFT OUTER JOIN
	HQContact HQContact ON 
		SMServiceSite.ContactGroup=HQContact.ContactGroup 
		AND SMServiceSite.ContactSeq=HQContact.ContactSeq


GO
GRANT SELECT ON  [dbo].[vrvSMInvoiceList] TO [public]
GRANT INSERT ON  [dbo].[vrvSMInvoiceList] TO [public]
GRANT DELETE ON  [dbo].[vrvSMInvoiceList] TO [public]
GRANT UPDATE ON  [dbo].[vrvSMInvoiceList] TO [public]
GO
