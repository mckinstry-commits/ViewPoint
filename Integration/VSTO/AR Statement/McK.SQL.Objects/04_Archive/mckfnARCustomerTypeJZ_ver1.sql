USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='mckfnARCustomerType' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' )
Begin
	Print 'DROP FUNCTION dbo.mckfnARCustomerType'
	DROP FUNCTION dbo.mckfnARCustomerType
End
GO

Print 'CREATE FUNCTION dbo.mckfnARCustomerType'
GO


CREATE FUNCTION [dbo].mckfnARCustomerType
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
	
	20190404 JZ   Restructure to Improve Performance	
	20190404 LG - removed ARTH.Mth = @FinancialPeriod
	20190314 LG - made 0250 & 0251 responsibility of C – Corporate
	20190109 CRL	Initial Development
*******************************************************************************/
RETURN
(

/*
DECLARE @ARCo		bCompany = 1
DECLARE @Customer	bCustomer = 221134
DECLARE @FinancialPeriod bDate = CAST('03/01/2019' AS SMALLDATETIME) ;
*/



	WITH CustomerList AS
					 (SELECT
						DISTINCT
								  ARCo
								, CustGroup
								, Customer
								, GLDepartmentNumber
								, InvoiceContract
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
								--, GLDepartmentNumber
								--, InvoiceContract
						FROM	[mfnARAgingSummary] (@FinancialPeriod)
						WHERE (coalesce([Current],0) + coalesce(Aged1to30,0) + coalesce(Aged31to60,0) + coalesce(Aged61to90,0) + coalesce(AgedOver90,0)) <> 0
							AND ARCo = @ARCo
							AND ( (@Customer IS NULL) OR (Customer = @Customer)))
	SELECT	  cmain.ARCo
			, cmain.CustGroup
			, ct.udGLDept AS contGLDept
			, st.udGLDept AS servGLDept
			, cmain.Customer
			--, cmain.GLDepartmentNumber
			, CASE WHEN (ct.Customer IS NOT NULL AND st.Customer IS NULL) THEN 'C'
					WHEN ct.Customer IS NULL AND st.Customer IS NOT NULL AND cmain.ARCo <> 20 THEN 'S'
					WHEN ct.Customer IS NOT NULL AND st.Customer IS NOT NULL AND cmain.ARCo <> 20 THEN 'B'
					ELSE 'S'
					END AS CustomerType
		FROM CustomerMain AS cmain
			--bARCM AS cm
				LEFT OUTER JOIN (SELECT	  cla.ARCo
										, cla.CustGroup
										, cla.Customer
										, jdm.udGLDept
									FROM CustomerList AS cla
										INNER JOIN ARTH AS th
											ON cla.ARCo = th.ARCo
												AND cla.Customer = th.Customer
												AND cla.CustGroup  = th.CustGroup
												AND cla.InvoiceContract = th.Contract
										INNER JOIN ARTL AS tl
											ON th.ARCo = tl.ARCo
												AND th.Mth = tl.Mth
												AND th.ARTrans = tl.ARTrans
										INNER JOIN ARCM AS cm
											ON th.CustGroup = cm.CustGroup
												AND th.Customer = cm.Customer
										INNER JOIN dbo.JCCM AS jcm
											ON th.JCCo	= jcm.JCCo 
												AND th.Contract= jcm.Contract 
										INNER JOIN dbo.bJCDM AS jdm
											ON jdm.JCCo = jcm.JCCo
												AND jdm.Department = jcm.Department
									WHERE COALESCE(jdm.udGLDept, '') NOT IN ('0520', '0521', '0522')
							UNION
								SELECT	  clb.ARCo
										, clb.CustGroup
										, clb.Customer
										, COALESCE(clb.GLDepartmentNumber, (CASE WHEN dep.udGLDept = 0999 THEN 
												-- look for old astea WOs to get GL Dept.
															CASE WHEN (SELECT TOP(1) A.udGLDept FROM dbo.SMDepartment A
																		WHERE Department = 
																			(SELECT TOP(1) S.SMDepartmentID FROM mvwSMWorkOrderGLDept S WHERE S.WorkOrder = smid.WorkOrder)) = 0999 THEN div.Department
															END 
													ELSE  COALESCE(dep.udGLDept, '')
													END)) AS udGLDept
									FROM CustomerList AS clb
										INNER JOIN ARTH AS th
											ON clb.ARCo = th.ARCo
												AND clb.Customer = th.Customer
												AND clb.CustGroup  = th.CustGroup
										INNER JOIN ARTL AS tl
											ON	th.ARCo = tl.ARCo
												AND th.Mth = tl.Mth
												AND th.ARTrans = tl.ARTrans
										INNER JOIN ARCM AS cm
											ON	th.CustGroup = cm.CustGroup
												AND th.Customer = cm.Customer
										INNER JOIN	SMInvoice AS smi
											ON	smi.ARCo = th.ARCo
												AND smi.ARPostedMth = th.Mth
												AND smi.ARTrans = th.ARTrans
										INNER JOIN	SMInvoiceDetail AS smid
											ON	smi.SMCo = smid.SMCo
												AND smi.Invoice = smid.Invoice
												AND smid.InvoiceDetail = tl.ARLine
										INNER JOIN SMWorkOrder AS wo
											ON	smid.SMCo = wo.SMCo
												AND smid.WorkOrder = wo.WorkOrder
										INNER JOIN dbo.SMWorkOrderScope s 
											ON smi.SMCo = s.SMCo
												AND smid.WorkOrder = s.WorkOrder
												AND ISNULL(smid.Scope,1) = s.Scope
										INNER JOIN SMServiceCenter AS sc
											ON	sc.SMCo = wo.SMCo
												AND sc.ServiceCenter = wo.ServiceCenter
										LEFT JOIN dbo.SMDivision AS div
											ON div.SMCo = smi.SMCo
												AND div.ServiceCenter = s.ServiceCenter
										LEFT JOIN vSMDepartment AS dep
											ON	dep.SMCo = sc.SMCo
												AND dep.Department = sc.Department
									WHERE COALESCE( clb.GLDepartmentNumber, (CASE WHEN dep.udGLDept = 0999 THEN 
																					-- look for old astea WOs to get GL Dept.
																					CASE WHEN (SELECT TOP(1) A.udGLDept FROM dbo.SMDepartment A
																								WHERE Department = 
																									(SELECT TOP(1) S.SMDepartmentID FROM mvwSMWorkOrderGLDept S WHERE S.WorkOrder = smid.WorkOrder)) = 0999 THEN div.Department
																					END 
																			ELSE  COALESCE(dep.udGLDept, '')
																			END)) NOT IN ('0520', '0521', '0522')

						) AS ct
				ON	ct.ARCo = cmain.ARCo
					AND ct.CustGroup = cmain.CustGroup
					AND ct.Customer = cmain.Customer 
			LEFT OUTER JOIN (	SELECT	  clb.ARCo
										, clb.CustGroup
										, clb.Customer
										, COALESCE(clb.GLDepartmentNumber, (CASE WHEN dep.udGLDept = 0999 THEN 
												-- look for old astea WOs to get GL Dept.
															CASE WHEN (SELECT TOP(1) A.udGLDept FROM dbo.SMDepartment A
																		WHERE Department = 
																			(SELECT TOP(1) S.SMDepartmentID FROM mvwSMWorkOrderGLDept S WHERE S.WorkOrder = smid.WorkOrder)) = 0999 THEN div.Department
															END 
													ELSE  COALESCE(dep.udGLDept, '')
													END)) AS udGLDept
									FROM CustomerList AS clb
										INNER JOIN ARTH AS th
											ON clb.ARCo = th.ARCo
												AND clb.Customer = th.Customer
												AND clb.CustGroup  = th.CustGroup
										INNER JOIN ARTL AS tl
											ON	th.ARCo = tl.ARCo
												AND th.Mth = tl.Mth
												AND th.ARTrans = tl.ARTrans
										INNER JOIN ARCM AS cm
											ON	th.CustGroup = cm.CustGroup
												AND th.Customer = cm.Customer
										INNER JOIN	SMInvoice AS smi
											ON	smi.ARCo = th.ARCo
												AND smi.ARPostedMth = th.Mth
												AND smi.ARTrans = th.ARTrans
										INNER JOIN	SMInvoiceDetail AS smid
											ON	smi.SMCo = smid.SMCo
												AND smi.Invoice = smid.Invoice
												AND smid.InvoiceDetail = tl.ARLine
										INNER JOIN SMWorkOrder AS wo
											ON	smid.SMCo = wo.SMCo
												AND smid.WorkOrder = wo.WorkOrder
										INNER JOIN dbo.SMWorkOrderScope s 
											ON smi.SMCo = s.SMCo
												AND smid.WorkOrder = s.WorkOrder
												AND ISNULL(smid.Scope,1) = s.Scope
										INNER JOIN SMServiceCenter AS sc
											ON	sc.SMCo = wo.SMCo
												AND sc.ServiceCenter = wo.ServiceCenter
										LEFT JOIN dbo.SMDivision AS div
											ON div.SMCo = smi.SMCo
												AND div.ServiceCenter = s.ServiceCenter
										LEFT JOIN vSMDepartment AS dep
											ON	dep.SMCo = sc.SMCo
												AND dep.Department = sc.Department
									WHERE COALESCE(clb.GLDepartmentNumber, (CASE WHEN dep.udGLDept = 0999 THEN 
															-- look for old astea WOs to get GL Dept.
															CASE WHEN (SELECT TOP(1) A.udGLDept FROM dbo.SMDepartment A
																		WHERE Department = 
																			(SELECT TOP(1) S.SMDepartmentID FROM mvwSMWorkOrderGLDept S WHERE S.WorkOrder = smid.WorkOrder)) = 0999 THEN div.Department
															END 
													ELSE  COALESCE(dep.udGLDept, '') END)) IN ('0520', '0521', '0522')
							UNION
								SELECT	  cla.ARCo
										, cla.CustGroup
										, cla.Customer
										, jdm.udGLDept
									FROM CustomerList AS cla
										INNER JOIN ARTH AS th
											ON cla.ARCo = th.ARCo
												AND cla.Customer = th.Customer
												AND cla.CustGroup  = th.CustGroup
												AND cla.InvoiceContract = th.Contract
										INNER JOIN ARTL AS tl
											ON th.ARCo = tl.ARCo
												AND th.Mth = tl.Mth
												AND th.ARTrans = tl.ARTrans
										INNER JOIN ARCM AS cm
											ON th.CustGroup = cm.CustGroup
												AND th.Customer = cm.Customer
										INNER JOIN dbo.JCCM AS jcm
											ON th.JCCo	= jcm.JCCo 
												AND th.Contract= jcm.Contract 
										INNER JOIN dbo.bJCDM AS jdm
											ON jdm.JCCo = jcm.JCCo
												AND jdm.Department = jcm.Department
									WHERE COALESCE(jdm.udGLDept, '') IN ('0520', '0521', '0522')
							) AS st
				ON	st.ARCo = cmain.ARCo
					AND st.CustGroup = cmain.CustGroup
					AND st.Customer = cmain.Customer 

)
GO

Grant SELECT ON dbo.mckfnARCustomerType TO [MCKINSTRY\Viewpoint Users]

/*

SELECT * From dbo.mckfnARCustomerType(20, 244940)

DECLARE @StatementMonth	bDate = CAST('03/01/2019' AS SMALLDATETIME) -- FINANCIAL PERIOD
SELECT DISTINCT * From dbo.mckfnARCustomerType(null, 206647, @StatementMonth)

*/