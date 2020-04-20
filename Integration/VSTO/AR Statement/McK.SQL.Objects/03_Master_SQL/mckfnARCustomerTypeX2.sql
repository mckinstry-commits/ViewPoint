USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='mckfnARCustomerTypeX2' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' )
Begin
	Print 'DROP FUNCTION dbo.mckfnARCustomerTypeX2'
	DROP FUNCTION dbo.mckfnARCustomerTypeX2
End
GO

Print 'CREATE FUNCTION dbo.mckfnARCustomerTypeX2'
GO


CREATE FUNCTION [dbo].mckfnARCustomerTypeX2
(
   @ARCo			bCompany 	
  ,@Customer		bCustomer 	
  ,@FinancialPeriod bDate
)
RETURNS TABLE
AS
/*******************************************************************************
Project:	MCK AR Open Item Statement Excel VSTO
Author:		Chris Lounsbury, Business Information Group

Purpose:	Determine the customer type based on unique business criteria

Change Log:
	
	20190416 LG - default unapplied payments (single lines) to X (per Cheryl)
	20190411 JZ - Restructure to further improve performance
	20190408 LG - removed bad join (SMInvoiceDetail.InvoiceDetail = ARTL.ARLine) blocking some transaction 
	20190405 LG	- made 0999 and '0250,0520' S-ervice
				- made 0250 (unapplied) to not report itself as 0250
	20190404 JZ - Restructure to Improve Performance	
	20190404 LG - removed ARTH.Mth = @FinancialPeriod
	20190314 LG - made 0250 & 0251 responsibility of C – Corporate
	20190109 CRL	Initial Development
*******************************************************************************/
RETURN
(


	WITH CustomerList AS
					 (SELECT
						DISTINCT
								  ARCo
								, CustGroup
								, Customer
								, GLDepartmentNumber
								--, InvoiceContract
								, Invoice
						FROM	[mfnARAgingSummary] (@FinancialPeriod)
						WHERE (coalesce([Current],0) + coalesce(Aged1to30,0) + coalesce(Aged31to60,0) + coalesce(Aged61to90,0) + coalesce(AgedOver90,0)) <> 0
							AND ARCo = @ARCo
							AND ((@Customer IS NULL) OR (Customer = @Customer)))
		, CustomerMain AS
					 (SELECT
						DISTINCT
								  ARCo
								, CustGroup
								, Customer
						FROM	[mfnARAgingSummary] (@FinancialPeriod)
						WHERE (coalesce([Current],0) + coalesce(Aged1to30,0) + coalesce(Aged31to60,0) + coalesce(Aged61to90,0) + coalesce(AgedOver90,0)) <> 0
							AND ARCo = @ARCo
							AND ( (@Customer IS NULL) OR (Customer = @Customer)))
	SELECT	  cmain.ARCo
			, cmain.CustGroup
			, cmain.Customer
			--, CASE WHEN (((ct.ContractFlag = 7) OR (ISNULL(st.ContractFlag2,0) = 7))   AND (ISNULL(ct.ServiceFlag,0) = 0) AND (ISNULL(st.ServiceFlag2,0) = 0)) THEN 'C'
			--		WHEN ((ISNULL(ct.ContractFlag,0) = 0) AND (ISNULL(st.ContractFlag2,0) = 0) AND ((ct.ServiceFlag = 3) OR (st.ServiceFlag2 = 3)) AND (cmain.ARCo <> 20)) THEN 'S'
			--		WHEN (((ct.ContractFlag = 7) OR (st.ContractFlag2 = 7)) AND ((ct.ServiceFlag = 3) OR (st.ServiceFlag2 = 3)) AND (cmain.ARCo <> 20)) THEN 'B'
			--		ELSE 'S'
			--		END AS CustomerType

			, CASE (ISNULL(ct.ContractFlag,0) + ISNULL(st.ContractFlag2,0) + ISNULL(ct.ServiceFlag,0) + ISNULL(st.ServiceFlag2,0)) 
					WHEN 14 THEN 'C'
					WHEN 7 THEN 'C'
					WHEN 6 THEN 'S'
					WHEN 3 THEN 'S'
					WHEN 10 THEN CASE WHEN (cmain.ARCo <> 20) THEN 'B' ELSE 'S' END
					WHEN 13 THEN CASE WHEN (cmain.ARCo <> 20) THEN 'B' ELSE 'S' END
					WHEN 17 THEN CASE WHEN (cmain.ARCo <> 20) THEN 'B' ELSE 'S' END
					WHEN 20 THEN CASE WHEN (cmain.ARCo <> 20) THEN 'B' ELSE 'S' END
					ELSE 'X'
					END AS CustomerType
		FROM CustomerMain AS cmain
			--Trust Aging Summary GLDepartmentNumber for most Data
				LEFT OUTER JOIN (SELECT	  cla.ARCo
										, cla.CustGroup
										, cla.Customer
										--, jdm.udGLDept
										--, cla.GLDepartmentNumber
										, MAX(CASE WHEN cla.GLDepartmentNumber NOT IN ('0520', '0521', '0522','0999','0250,0520') THEN 7 else 0 end) as ContractFlag
										, MAX(CASE WHEN cla.GLDepartmentNumber IN ('0520', '0521', '0522', '0999','0250,0520') THEN 3 else 0 end) as ServiceFlag
									FROM CustomerList AS cla
									WHERE cla.GLDepartmentNumber IS NOT NULL
										AND cla.Invoice <> 'Unapplied'
									GROUP BY cla.ARCo
										, cla.CustGroup
										, cla.Customer
						) AS ct
				ON	ct.ARCo = cmain.ARCo
					AND ct.CustGroup = cmain.CustGroup
					AND ct.Customer = cmain.Customer 
			-- Attempt to look up Service department for remaining data
			LEFT OUTER JOIN (	SELECT	  clb.ARCo
										, clb.CustGroup
										, clb.Customer
										, MAX(CASE WHEN dep.udGLDept NOT IN ('0520', '0521', '0522','0999','0250,0520') THEN 7 else 0 end) as ContractFlag2
										, MAX(CASE WHEN dep.udGLDept IN ('0520', '0521', '0522', '0999','0250,0520') THEN 3 else 0 end) as ServiceFlag2
												--		(CASE WHEN dep.udGLDept = 0999 THEN 
												---- look for old astea WOs to get GL Dept.
												--			CASE WHEN (SELECT TOP(1) A.udGLDept FROM dbo.SMDepartment A
												--						WHERE Department = 
												--							(SELECT TOP(1) S.SMDepartmentID FROM mvwSMWorkOrderGLDept S WHERE S.WorkOrder = smid.WorkOrder)) = 0999 THEN div.Department
												--			END 
												--	ELSE  COALESCE(dep.udGLDept, '')
												--	END)) AS udGLDept
									FROM CustomerList clb --dep.udGLDept, 
										INNER JOIN SMInvoice b
											ON clb.ARCo = b.SMCo
												AND RTRIM(LTRIM(clb.Invoice)) = LTRIM(RTRIM(b.InvoiceNumber))
										INNER JOIN dbo.SMInvoiceLine il
											ON il.SMCo = b.SMCo 
												AND il.Invoice = b.Invoice 
										INNER JOIN SMInvoiceDetail AS smid
											ON b.SMCo = smid.SMCo
												AND b.Invoice = smid.Invoice
												AND il.InvoiceDetail = smid.InvoiceDetail
										INNER JOIN dbo.SMWorkOrderScope s 
											ON b.SMCo = s.SMCo
												AND b.WorkOrder = s.WorkOrder
												AND ISNULL(smid.Scope,1) = s.Scope
										INNER JOIN dbo.SMDivision AS div
											ON div.SMCo = b.SMCo
												AND div.ServiceCenter = s.ServiceCenter
										INNER JOIN SMDepartment AS dep
											ON	dep.SMCo = b.SMCo
												AND dep.Department = div.Department
								WHERE clb.GLDepartmentNumber IS NULL 
									AND clb.Invoice <>'Unapplied' 
								GROUP BY   clb.ARCo
										, clb.CustGroup
										, clb.Customer

									--WHERE COALESCE(clb.GLDepartmentNumber, (CASE WHEN dep.udGLDept = 0999 THEN
									--						-- look for old astea WOs to get GL Dept.
									--						CASE WHEN (SELECT TOP(1) A.udGLDept FROM dbo.SMDepartment A
									--									WHERE Department = 
									--										(SELECT TOP(1) S.SMDepartmentID FROM mvwSMWorkOrderGLDept S WHERE S.WorkOrder = smid.WorkOrder)) = 0999 THEN div.Department
									--						END 
									--						ELSE  COALESCE(dep.udGLDept, '') END)
									--				) IN ('0999')
							) AS st
				ON	st.ARCo = cmain.ARCo
					AND st.CustGroup = cmain.CustGroup
					AND st.Customer = cmain.Customer
			)
GO

Grant SELECT ON dbo.mckfnARCustomerTypeX2 TO [MCKINSTRY\Viewpoint Users]

/*

SELECT * From dbo.mckfnARCustomerType(1, 244940)

SELECT * From dbo.mckfnARCustomerType(1, 208904, '03/01/2019')

SELECT DISTINCT * From dbo.mckfnARCustomerType(1, 210211, '03/01/2019')

SELECT DISTINCT * From dbo.mckfnARCustomerType(1, 201542, '03/01/2019')

SELECT * From dbo.mckfnARCustomerTypeX2(1, null, '03/01/2019')

*/