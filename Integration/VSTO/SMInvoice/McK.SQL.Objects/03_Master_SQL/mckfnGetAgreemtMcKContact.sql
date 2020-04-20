USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='mckfnGetAgreemtMcKContact' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' )
Begin
	Print 'DROP FUNCTION dbo.mckfnGetAgreemtMcKContact'
	DROP FUNCTION dbo.mckfnGetAgreemtMcKContact
End
GO

Print 'CREATE FUNCTION dbo.mckfnGetAgreemtMcKContact'
GO


CREATE FUNCTION [dbo].mckfnGetAgreemtMcKContact
(
  @BillToCustomer			bCustomer 
, @Agreement		VARCHAR(10)
, @InvoiceNumber	VARCHAR(10)
)
RETURNS TABLE
AS
 /* 
	Purpose:	Get the McKinstry Email and Phone number corresponding to Service Center and Division.
	Author:	Leo Gurdian
	Created:	7.03.2019
	HISTORY:

	07.03.2019 LG - init -TFS 4797
*/
RETURN
(
WITH a AS
(
	SELECT DISTINCT 
	  I.InvoiceNumber
	, S.ServiceSite
	, S.ServiceCenter
	, S.Division
	FROM dbo.SMAgreementExtended A
		INNER JOIN dbo.SMInvoiceList I
			ON		 I.CustGroup = A.CustGroup
				AND I.SMCo = A.SMCo
				AND I.Customer = A.Customer
		LEFT OUTER JOIN dbo.SMAgreementWorkSchedule S
			ON		 S.Agreement = A.Agreement
				AND S.SMCo = A.SMCo
				AND S.Version = A.Version
	WHERE	A.Agreement		 = @Agreement
	AND A.Customer			 = @BillToCustomer
	AND A.RevisionStatus  = 2
	AND A.AgreementStatus = 'A'
	AND RTRIM(LTRIM(ISNULL(I.InvoiceNumber,' '))) = RTRIM(LTRIM(ISNULL(@InvoiceNumber, ' ')))
), b AS 
(
	SELECT S.ServiceCenter, S.Description, D.Division, X.Email, X.PhoneNumber
	FROM dbo.udxrefSMFromEmail X
		INNER JOIN dbo.SMServiceCenter S
		ON		S.Description = X.ServiceCenter
		LEFT OUTER JOIN dbo.SMDivision D
		ON	D.ServiceCenter = S.ServiceCenter
			AND UPPER(D.Division) = UPPER(X.Division)
)
SELECT DISTINCT 
 a.InvoiceNumber
,ISNULL(b.Email,'') AS Email
, CASE WHEN b.PhoneNumber IS NOT NULL THEN 
	SUBSTRING(PhoneNumber, 1, 3) + '-' + 
							SUBSTRING(PhoneNumber, 4, 3) + '-' + 
							SUBSTRING(PhoneNumber, 7, 4)
	ELSE ''
	END AS PhoneNumber
,ISNULL(a.Division,'') AS Division
FROM a
	LEFT OUTER JOIN b
	ON		 b.Division = a.Division
		AND b.ServiceCenter = a.ServiceCenter

)

GO

Grant SELECT ON dbo.mckfnGetAgreemtMcKContact TO [MCKINSTRY\Viewpoint Users]

/* 

SELECT * FROM dbo.mckfnGetAgreemtMcKContact(214393, 10690, '10080839')

*/