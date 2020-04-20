USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='mckfnCompanyList' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' )
Begin
	Print 'DROP FUNCTION dbo.mckfnCompanyList'
	DROP FUNCTION dbo.mckfnCompanyList
End
GO

Print 'CREATE FUNCTION dbo.mckfnCompanyList'
GO


CREATE FUNCTION [dbo].mckfnCompanyList()
RETURNS TABLE
AS
 /* 
	Purpose:	Get company list
	Author:		Leo Gurdian
	Created:	2019.03.11
	HISTORY:

	2019.03.11 LG - init
*/
RETURN
(
	SELECT CAST (HQCo as Varchar) + '-' + Name AS Co, HQCo FROM dbo.HQCO WITH (NOLOCK) WHERE udTESTCo = 'N' AND (HQCo = 1 OR HQCo = 20)
)

GO

Grant SELECT ON dbo.mckfnCompanyList TO [MCKINSTRY\Viewpoint Users]

--  SELECT * FROM dbo.mckfnCompanyList()