-- ================================================
-- Template generated from Template Explorer using:
-- Create Trigger (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- See additional Create Trigger templates for more
-- examples of different Trigger statements.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
USE [Viewpoint]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 8/12/14
-- Description:	Trigger to populate the Work Edit Tables with records from HR.Net
-- =============================================
/*--COMMENTED OUT ALL CREATE TRIGGER FUNCTIONALITY UNTIL WE ARE FURTHER ALONG.
CREATE TRIGGER dbo.mtr_budPREmpImport_I 
   ON  dbo.budPREmpImport 
   AFTER INSERT
AS */
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	DECLARE @ImportID VARCHAR(15)
	SELECT TOP 1 @ImportID=ImportID --FROM INSERTED
	FROM dbo.budPREmpImport

	SELECT @ImportID AS ImportID,
		CASE WHEN e.Employee IS NULL THEN 'NEW' ELSE 'UPDATE' END AS UpdateType,
		COMPANYREFNO,REFERENCENUMBER, LASTNAME,FIRSTNAME ,
		--LastName AS VPLastName,
		CASE WHEN LEN(MIDDLENAMES) < 15 THEN MIDDLENAMES ELSE LEFT(MIDDLENAMES,1) END AS MIDDLENAMES, SUFFIX, 
		ADDRESS1, ADDRESS2, CITY, COUNTY, POSTCODE, EMAILPRIMARY, HOMETELEPHONE, NINUMBER,
		EEOETHINICITY, GENDER, DATEOFBIRTH, DATEOFJOIN, CASE PRIMARYUNION WHEN 'MEMBER' THEN 2 WHEN 'NONMEMBER' THEN 1 ELSE 1 END AS PRGroup,
		CODE, COSTCODE, EXEMPTSTATUS, HOURLYRATE, SALARIEDANNUALAMOUNT, DATEOFLEAVING,
		CASE STATUS WHEN 'A' THEN'Y' WHEN 'T' THEN 'N' ELSE 'N' END AS ActiveYN,
		EEOJOBCATEGORIES
	FROM MCK_INTEGRATION.dbo.HRNETVPExport h
		LEFT OUTER JOIN dbo.PREH e ON h.COMPANYREFNO = e.PRCo AND h.REFERENCENUMBER = e.Employee
	WHERE CURRENTRECORD = 'YES' 

	--SELECT 'NEW EMPLOYEES', COUNT(*) AS EmployeeCount
	--FROM MCK_INTEGRATION.dbo.HRNETVPExport h
	--	LEFT OUTER JOIN dbo.PREH e ON h.COMPANYREFNO = e.PRCo AND h.REFERENCENUMBER = e.Employee
	--WHERE CURRENTRECORD = 'YES' AND e.Employee IS NULL
	--union
	--SELECT 'EXISTING EMPLOYEES', COUNT(*) AS EmployeeCount
	--FROM MCK_INTEGRATION.dbo.HRNETVPExport h
	--	LEFT OUTER JOIN dbo.PREH e ON h.COMPANYREFNO = e.PRCo AND h.REFERENCENUMBER = e.Employee
	--WHERE CURRENTRECORD = 'YES' AND e.Employee IS NOT NULL
END
GO
