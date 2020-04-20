SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[SMWorkOrderContactDefault]
AS
SELECT SMWorkOrder.SMCo, SMWorkOrder.WorkOrder,
CASE WHEN NOT SMServiceSiteContact.ContactSeq IS NULL THEN
		SMServiceSiteContact.ContactGroup
	 WHEN NOT SMCustomerContact.ContactSeq IS NULL THEN
		SMCustomerContact.ContactGroup
	 END ContactGroup,
CASE WHEN NOT SMServiceSiteContact.ContactSeq IS NULL THEN
		SMServiceSiteContact.ContactSeq
	 WHEN NOT SMCustomerContact.ContactSeq IS NULL THEN
		SMCustomerContact.ContactSeq
	 END ContactSeq,
CASE WHEN NOT SMServiceSiteContact.ContactSeq IS NULL THEN
		SMSiteContactInfo.FirstName
	 WHEN NOT SMCustomerContact.ContactSeq IS NULL THEN
		SMCustomerContactInfo.FirstName
	 END FirstName,
CASE WHEN NOT SMServiceSiteContact.ContactSeq IS NULL THEN
		SMSiteContactInfo.LastName
	 WHEN NOT SMCustomerContact.ContactSeq IS NULL THEN
		SMCustomerContactInfo.LastName
	 END LastName,
CASE WHEN NOT SMServiceSiteContact.ContactSeq IS NULL THEN
		SMSiteContactInfo.Phone
	 WHEN NOT SMCustomerContact.ContactSeq IS NULL THEN
		SMCustomerContactInfo.Phone
	 END Phone
FROM SMWorkOrder
LEFT JOIN SMServiceSiteContact ON SMServiceSiteContact.SMCo = SMWorkOrder.SMCo
AND SMServiceSiteContact.ServiceSite = SMWorkOrder.ServiceSite
LEFT JOIN SMContact as SMSiteContactInfo ON SMSiteContactInfo.ContactGroup = SMServiceSiteContact.ContactGroup
AND SMSiteContactInfo.ContactSeq = SMServiceSiteContact.ContactSeq
LEFT JOIN SMCustomerContact ON SMCustomerContact.SMCo = SMWorkOrder.SMCo
AND SMCustomerContact.CustGroup = SMWorkOrder.CustGroup
AND SMCustomerContact.Customer = SMWorkOrder.Customer
LEFT JOIN SMContact as SMCustomerContactInfo ON SMCustomerContactInfo.ContactGroup = SMCustomerContact.ContactGroup
AND SMCustomerContactInfo.ContactSeq = SMCustomerContact.ContactSeq


GO
GRANT SELECT ON  [dbo].[SMWorkOrderContactDefault] TO [public]
GRANT INSERT ON  [dbo].[SMWorkOrderContactDefault] TO [public]
GRANT DELETE ON  [dbo].[SMWorkOrderContactDefault] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkOrderContactDefault] TO [public]
GRANT SELECT ON  [dbo].[SMWorkOrderContactDefault] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMWorkOrderContactDefault] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMWorkOrderContactDefault] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMWorkOrderContactDefault] TO [Viewpoint]
GO
