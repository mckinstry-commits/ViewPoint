-- ================================================
-- Template generated from Template Explorer using:
-- Create Procedure (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the procedure.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 8/13/2014
-- Description:	Proc to Import PR Employees from HR.Net to ud based work edit tables.
-- =============================================
CREATE PROCEDURE mckPRImportToWorkEdit 
	-- Add the parameters for the stored procedure here
	@ImportID varchar(15) = 0, 
	@ReturnMessage VARCHAR(255) = '' OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @rcode INT = 0
	--DECLARE @ImportID VARCHAR(15) = 'TEST'
	INSERT INTO budPREmpWorkEdit (ImportID, ImportSequence,
		PRCo, Employee, LastName, FirstName,MidName, Suffix,Address, Address2, City, State, Zip, Email, Phone, SSN,
		Race, Sex, BirthDate, HireDate, PRGroup,
		PRDept, 
		Craft, Class, 
		udExempt, HrlyRate,SalaryAmt, TermDate, 
		ActiveYN, 
		OccupCat)
		--DECLARE @ImportID VARCHAR(15) = 'TEST'
	SELECT @ImportID AS ImportID, ROW_NUMBER() OVER (ORDER BY COMPANYREFNO, CONVERT(NUMERIC(10,0),REFERENCENUMBER)) AS [ImportSequence],
		--CASE WHEN e.Employee IS NULL THEN 'NEW' ELSE 'UPDATE' END AS UpdateType,
		CONVERT(INT,COMPANYREFNO) AS [PRCo], CONVERT(INT, REFERENCENUMBER) AS [Employee], LASTNAME,FIRSTNAME ,
		--LastName AS VPLastName,
		CASE WHEN LEN(MIDDLENAMES) < 15 THEN MIDDLENAMES ELSE LEFT(MIDDLENAMES,1) END AS MIDDLENAMES, SUFFIX, 
		ADDRESS1, ADDRESS2, CITY, COUNTY AS [State], POSTCODE, EMAILPRIMARY, HOMETELEPHONE, NINUMBER,
		EEOETHINICITY, GENDER, DATEOFBIRTH, DATEOFJOIN, CASE PRIMARYUNION WHEN 'MEMBER' THEN 2 WHEN 'NONMEMBER' THEN 1 ELSE 1 END AS PRGroup,
		COALESCE(d.PRDept,d2.PRDept, dmp.VPPRDeptNumber) AS PRDept, 
		--COMMENT OUT BELOW [PRDept Source] FOR LIVE PROCESS.
		--CASE WHEN COALESCE(d.PRDept,d2.PRDept,dmp.VPPRDeptNumber) IS NULL THEN 'NO SOURCE '+LEFT(CODE,3) WHEN COALESCE(d.PRDept,d2.PRDept) IS NULL THEN 'dmp' WHEN d.PRDept IS NULL THEN 'd2' END AS [PRDept Source], 
		COALESCE(c.Craft, c2.Craft, cxr.Craft) AS Craft, COALESCE(c.Class ,c2.Class, cxr.Class) AS [Class], 
		EXEMPTSTATUS, HOURLYRATE, SALARIEDANNUALAMOUNT, DATEOFLEAVING,
		CASE STATUS WHEN 'A' THEN'Y' WHEN 'T' THEN 'N' ELSE 'N' END AS ActiveYN,
		EEOJOBCATEGORIES
	FROM MCK_INTEGRATION.dbo.HRNETVPExport h
		LEFT OUTER JOIN dbo.PREH e ON h.COMPANYREFNO = e.PRCo AND CONVERT(INT,h.REFERENCENUMBER) = e.Employee
		LEFT OUTER JOIN dbo.PRDP d ON d.PRCo = CONVERT(INT,COMPANYREFNO) AND d.PRDept = CONVERT(VARCHAR(10),h.CODE)
		LEFT OUTER JOIN dbo.udxrefPRDept_McK dmp ON CONVERT(INT,RIGHT(dmp.CGCCompany,2)) = CONVERT(INT,COMPANYREFNO) AND dmp.CGCPRDeptNumber = CONVERT(VARCHAR(10),SUBSTRING(h.CODE,1,3))
		LEFT OUTER JOIN dbo.PRDP d2 ON dmp.VPProductionCompany = d2.PRCo AND dmp.VPPRDeptNumber = d2.PRDept
		LEFT OUTER JOIN dbo.PRCC c ON c.Class = COSTCODE AND c.PRCo = CONVERT(INT,COMPANYREFNO)
		
		LEFT OUTER JOIN (SELECT TOP 1 CMSClass, Company, CMSType, Craft, Class FROM dbo.udxrefUnion) AS cxr ON cxr.CMSClass = LEFT(COSTCODE,3) AND cxr.Company = CONVERT(INT,COMPANYREFNO) AND cxr.CMSType = RIGHT(COSTCODE,2)
		LEFT OUTER JOIN dbo.PRCC c2 ON c2.PRCo = cxr.Company AND c2.Class = cxr.Class AND c2.Craft = cxr.Craft
	WHERE CURRENTRECORD = 'YES' 
	

	
END
GO
