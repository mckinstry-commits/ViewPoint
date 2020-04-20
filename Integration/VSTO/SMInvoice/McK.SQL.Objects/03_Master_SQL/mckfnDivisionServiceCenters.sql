USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='mckfnDivisionServiceCenters' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' )
Begin
	Print 'DROP FUNCTION dbo.mckfnDivisionServiceCenters'
	DROP FUNCTION dbo.mckfnDivisionServiceCenters
End
GO

Print 'CREATE FUNCTION dbo.mckfnDivisionServiceCenters'
GO


CREATE FUNCTION [dbo].mckfnDivisionServiceCenters
(
	@Division	varchar(10)
)
RETURNS TABLE
AS
 /* 
	Purpose:		Get Service Centers based on Division ONLY where there are Invoices pending or already invoiced.
	Created:		08.24.2018
	Author:		Leo Gurdian

	HISTORY:

	04.17.2019 LG - add SMDivision.Description 
	08.24.2018 LG - init concept
*/
RETURN
(
	/* TEST 
		DECLARE @Division VARCHAR(10)
	*/

	Select top 1000 d.Division, d.Description, c.ServiceCenter, c.Description As ServiceCenterDescription, x.Email
	From SMDivision d 
		INNER JOIN SMServiceCenter c  with (nolock) on
				 d.SMCo = c.SMCo
			AND d.ServiceCenter = c.ServiceCenter
			LEFT JOIN udxrefSMFromEmail x with (nolock) on
					 UPPER(x.ServiceCenter) = UPPER(c.Description)
				AND UPPER(x.Division)		= UPPER(d.Division)
	Where (d.Division = @Division OR @Division IS NULL)
			AND d.Active = 'Y'
	Order by ServiceCenterDescription

)

GO

Grant SELECT ON dbo.mckfnDivisionServiceCenters TO [MCKINSTRY\Viewpoint Users]

GO

/*

Select * From dbo.mckfnDivisionServiceCenters(null)
Select * From dbo.mckfnDivisionServiceCenters('HVAC')

*/
