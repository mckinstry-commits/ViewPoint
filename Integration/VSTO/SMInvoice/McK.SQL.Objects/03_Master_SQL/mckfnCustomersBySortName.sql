USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='mckfnCustomersBySortName' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' )
Begin
	Print 'DROP FUNCTION dbo.mckfnCustomersBySortName'
	DROP FUNCTION dbo.mckfnCustomersBySortName
End
GO

Print 'CREATE FUNCTION dbo.mckfnCustomersBySortName'
GO


CREATE FUNCTION [dbo].mckfnCustomersBySortName
(
	@Status		char(1) = 'A'
)
RETURNS TABLE
AS
 /* 
	Purpose:	Get list of active or all AR Customers
	Created:	5.11.18
	Author:		Leo Gurdian
	HISTORY:
	03.12.18 LG - Add AR Customer Statement Email Address & Delivery Method
	05.11.18 LG - init
*/

RETURN
(
	SELECT
	  Customer
	, SortName
	, Name
	, Address
	, City
	, State
	, Zip
	, Country
	, Status
	, CASE WHEN udARDeliveryMethod = 1 THEN 'Email' Else 'Mail' END AS DeliveryMethod
	, udEmail AS Email
	From dbo.ARCM WITH(NOLOCK) 
	Where CustGroup = 1 
			AND Status = Case @Status When 'A' Then @Status Else Status End
)

GO

Grant SELECT ON dbo.mckfnCustomersBySortName TO [MCKINSTRY\Viewpoint Users]

--Select * From dbo.mckfnCustomersBySortName('A') Order by SortName ASC