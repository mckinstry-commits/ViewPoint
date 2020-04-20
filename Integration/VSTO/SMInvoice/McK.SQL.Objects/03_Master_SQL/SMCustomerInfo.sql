USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.VIEWS Where TABLE_NAME='SMCustomerInfo' and TABLE_SCHEMA='dbo')
Begin
	Print 'DROP VIEW dbo.SMCustomerInfo'
	DROP VIEW dbo.SMCustomerInfo
End
GO

Print 'CREATE VIEW dbo.SMCustomerInfo'
GO


CREATE VIEW [dbo].SMCustomerInfo
/*******************************************************************************
Project:	SM Invoice VSTO
Author:		?? 

Purpose:	Get SM Customer info

Change Log:
04.09.2019 LG added join HQPT for PayTerms Description 
*******************************************************************************/
AS
SELECT     SMCustomer.SMCo, SMCustomer.CustGroup, SMCustomer.Customer, ARCM.Name, ARCM.SortName, ARCM.[Address], ARCM.City, ARCM.[State], ARCM.Zip, ARCM.Address2, 
                      ARCM.Phone, ARCM.Fax, ARCM.Country, SMCustomer.Active, SMCustomer.NonBillable AS NonBillableByCustomer, SMCustomer.RateTemplate AS DefaultRateTemplate, HQPT.Description AS PayTerms
FROM       dbo.SMCustomer 
			   INNER JOIN dbo.ARCM 
				  ON SMCustomer.CustGroup = ARCM.CustGroup AND ARCM.Customer = SMCustomer.Customer
					 LEFT OUTER JOIN dbo.HQPT HQPT
						ON HQPT.PayTerms = ARCM.PayTerms -- for HQPT.Description
GO

Grant SELECT ON dbo.SMCustomerInfo TO [MCKINSTRY\Viewpoint Users]


/*

Select * from SMCustomerInfo
Where Customer = 201703

Select * from SMCustomerInfo
Where Customer = 200046    

*/