SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE VIEW [dbo].[SMCustomerInfo]
AS
SELECT     SMCustomer.SMCo, SMCustomer.CustGroup, SMCustomer.Customer, ARCM.Name, ARCM.SortName, ARCM.[Address], ARCM.City, ARCM.[State], ARCM.Zip, ARCM.Address2, 
                      ARCM.Phone, ARCM.Fax, ARCM.Country, SMCustomer.Active, SMCustomer.NonBillable AS NonBillableByCustomer
FROM         dbo.SMCustomer INNER JOIN
                      dbo.ARCM ON SMCustomer.CustGroup = ARCM.CustGroup AND ARCM.Customer = SMCustomer.Customer






GO
GRANT SELECT ON  [dbo].[SMCustomerInfo] TO [public]
GRANT INSERT ON  [dbo].[SMCustomerInfo] TO [public]
GRANT DELETE ON  [dbo].[SMCustomerInfo] TO [public]
GRANT UPDATE ON  [dbo].[SMCustomerInfo] TO [public]
GRANT SELECT ON  [dbo].[SMCustomerInfo] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMCustomerInfo] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMCustomerInfo] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMCustomerInfo] TO [Viewpoint]
GO
