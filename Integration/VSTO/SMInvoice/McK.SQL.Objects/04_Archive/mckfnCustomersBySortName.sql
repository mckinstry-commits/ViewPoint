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
	Purpose:		Get list of active or all AR Customers
	Created:		5.11.18
	Author:		Leo Gurdian
	HISTORY:
	5.11.18	-	LG - init
*/
 --SET NOCOUNT ON;
 --SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 

RETURN
(
	SELECT TOP (100000)
	  Customer
	, SortName
	, Name
	, Address
	, City
	, State
	, Zip
	, Country
	--, Status
	From ARCM (nolock) a
	Where CustGroup = 1 
			AND Status = Case @Status When 'A' Then @Status Else Status End
	Order by 'SortName'  
)

GO

Grant SELECT ON dbo.mckfnCustomersBySortName TO [MCKINSTRY\Viewpoint Users]

--Select * From dbo.mckfnCustomersBySortName('A')