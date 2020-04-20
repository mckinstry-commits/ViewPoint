USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='MCKsp_AROpenItemStatement' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
Begin
	Print 'DROP PROCEDURE dbo.MCKsp_AROpenItemStatement'
	DROP PROCEDURE dbo.MCKsp_AROpenItemStatement
End
GO

Print 'CREATE PROCEDURE dbo.MCKsp_AROpenItemStatement'
GO

CREATE Procedure dbo.MCKsp_AROpenItemStatement
(
  @ARCO				bCompany = NULLa
, @Customer			bCustomer = NULL 
, @CustomerType		CHAR(1) = NULL -- (S)ervice, (C)ontract, (B)oth
, @StatementMonth	bDate	= NULL
, @TransThruDate	bDate	= NULL
)
AS
 /* 
	Purpose:	Get 'AR Open Item Statements' based off mfnARAgingSummary (underlaying table gets refreshed every 4 hrs.) - Credits to BillO. 
				up to 90 days of aged open items
	Created:	02.11.2019
	Author:	Leo Gurdian / Jonathan Ziebel

	07.16.19 LG - TFS 4825 - Populate every row with N and Ys per stmtprint
					- remove WITH (NOLOCK)
	05.17.19 LG - make [Send / Preview Statement Y/N] default to NULL when ARCM.StmntPrint = 'Y' ELSE 'N'
	04.30.19 LG - hide Combine Customer Numbers, Bill To Name, # of Invoices - TFS 4351
	04.12.19 JZ - mckfnARCustomerTypeX2- re-structured by Jonathan Ziebel to fix expcetions that were causing bad categorization. + performance improvement
	04.04.19 JZ - mckfnARCustomerType - re-structured by Jonathan Ziebel to fix balances and speed improvement
	04.02.19 LG - Now Invoice Amt = Invoiced Amt - Retainage
	03.20.19 LG - rewrote logic to use window function partition
	03.19.19 LG - Move 'Invoice Amt' column in front of 'Current' column 
					- update AR Customer Group logic
	03.14.19 LG - CustomerType logic now only applies to single Company not across multiple companies
	03.11.19 LG - rename 'Customer Email' to 'Statement Email'
	02.27.19 LG - mod rule: bring in any aging not equal to zero
	02.25.19 LG - use statement MONTH as financial period default trans due date to last day of statement date only show trans with bal. due
						2/26 - Only show 1 'Y' per statement for 'Send/Preview Statement YN' columns
	02.21.19 LG - fixed aging buckets, dept.#/desc, renamed columns
	02.11.19 LG - Initial
*/
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

BEGIN

/* TEST 

DECLARE @ARCO			bCompany = 20
DECLARE @Customer	bCustomer = 201045     --NULL -- 248153 -- 209957 -- 200743 --
--DECLARE @CustomerEnd	bCustomer = 201317 
DECLARE @CustomerType	CHAR(1) =  NULL --'C' -- (S)ervice, (C)ontract, (B)oth
DECLARE @StatementMonth	bDate = CAST('03/01/2019' AS SMALLDATETIME) -- FINANCIAL PERIOD
DECLARE @TransThruDate	bDate 

*/

SET @StatementMonth = ISNULL(@StatementMonth, CAST(CURRENT_TIMESTAMP AS SMALLDATETIME)) 
-- Default Trans Thru Date to last day of the Statement Month if no trans thru date passed
SET @TransThruDate = ISNULL(@TransThruDate, DATEADD (dd, -1, DATEADD(mm, DATEDIFF(mm, 0, @StatementMonth) + 1, 0)))

DECLARE @FinancialPeriod bDate = DATEADD(month, DATEDIFF(month, 0, @StatementMonth), 0)  -- StartOfMonth

DECLARE @errmsg VARCHAR(800) = ''

BEGIN TRY

WITH cte
AS
(
SELECT  
   A.ARCo
 , DATENAME(MONTH, @StatementMonth) + ' ' + CAST(YEAR(@StatementMonth) AS VARCHAR(4)) AS [Statement Month]
 , MAX(@TransThruDate)	AS [Through Date]
 , ARCM.StmntPrint		AS [Send Statement Y/N] -- clone StmntPrint. Fill all rows with Ys and Ns, respectively.
 , CASE WHEN ARCM.StmntPrint = 'Y' THEN NULL -- default no preview
			ELSE 'N'
   END AS [Preview Statement Y/N]
 , custType.CustomerType AS [AR Customer Group]
  , CASE WHEN A.GLDepartmentNumber IS NULL
		THEN
			CASE WHEN EXISTS(SELECT 1 FROM mvwSMWorkOrderGLDept S WHERE S.WorkOrder = mvwSMWorkOrderGLDept.WorkOrder) 
				  THEN	
					-- get GL Dept from -> WO
					(SELECT TOP(1) A.udGLDept FROM dbo.SMDepartment A 
						WHERE Department = 
									(SELECT TOP(1) S.SMDepartmentID FROM mvwSMWorkOrderGLDept S WHERE S.WorkOrder = mvwSMWorkOrderGLDept.WorkOrder))-- SERVICE
			WHEN CHARINDEX('WO:', A.ContractDesc) > 0 
				  THEN 
				  (SELECT TOP(1) newWO.GLDept FROM dbo.mckSMWorkOrderInfo newWO
					WHERE newWO.WorkOrder = SUBSTRING(A.ContractDesc,CHARINDEX(':',A.ContractDesc)+1,LEN(A.ContractDesc))
				  )
			ELSE	
				-- get GL Dept from Inv -> WO
				(SELECT TOP(1) newWO.GLDept FROM dbo.mckSMWorkOrderInfo newWO
					WHERE newWO.WorkOrder = 
										(SELECT TOP(1) D.WorkOrder
											FROM dbo.SMInvoiceListDetail D 
												INNER JOIN dbo.SMWorkOrder W ON
														D.SMCo = W.SMCo
												AND W.Customer = D.Customer
												AND W.WorkOrder = D.WorkOrder
											WHERE  (RTRIM(LTRIM(ISNULL(D.InvoiceNumber,'')))) = (RTRIM(LTRIM(ISNULL(A.Invoice,''))))
										)
				) 
			END
   ELSE A.GLDepartmentNumber
   END					AS [GL Dept#]
  , CASE WHEN A.GLDepartmentName IS NULL
		 THEN 
			CASE WHEN EXISTS(SELECT 1 FROM mvwSMWorkOrderGLDept S WHERE S.WorkOrder = mvwSMWorkOrderGLDept.WorkOrder) 
				 THEN	
					(SELECT TOP(1) S.SMDepartmentDesc FROM mvwSMWorkOrderGLDept S 
						WHERE S.WorkOrder = mvwSMWorkOrderGLDept.WorkOrder) -- SERVICE
			ELSE --No WO available, go grab it from Inv. then grab GL Dept. 
				(SELECT TOP(1) S.Description FROM dbo.SMDepartment S
						WHERE S.udGLDept = 
										(SELECT TOP(1) newWO.GLDept FROM dbo.mckSMWorkOrderInfo newWO
											WHERE newWO.WorkOrder = 
																	(SELECT TOP(1) D.WorkOrder
																		FROM dbo.SMInvoiceListDetail D 
																			INNER JOIN dbo.SMWorkOrder W ON
																					D.SMCo = W.SMCo
																			AND W.Customer = D.Customer
																			AND W.WorkOrder = D.WorkOrder
																		WHERE  (RTRIM(LTRIM(ISNULL(D.InvoiceNumber,'')))) = (RTRIM(LTRIM(ISNULL(A.Invoice,''))))
																	)
												  AND newWO.GLDept IS NOT NULL
										) 
				) 
			END
	  ELSE A.GLDepartmentName
	END					AS [GL Dept Name]
 , A.CustomerName		AS [Customer Name]
 , A.Customer			AS [Customer No.]
 --, NULL					AS [Combine Customer Numbers] 
 , ARCM.SortName		AS [Customer Sort Name]
 , ARCM.udEmail			AS [Statement Email]
 , CASE WHEN ARCM.udARDeliveryMethod = 1 THEN 'Email'
		WHEN ARCM.udARDeliveryMethod = 2 THEN 'Mail'
   ELSE 'Unspecified'
   END						AS [Customer Delivery Method]
 --, ARCM.Name				AS [Bill To Name]
 , ARCM.BillAddress		AS [Bill To Address]
 , ARCM.BillAddress2		AS [Bill To Address2]
 , ARCM.BillCity			AS [Bill To City]
 , ARCM.BillState			AS [Bill To State]
 , ARCM.BillZip			AS [Bill To Zip]
 , LTRIM(RTRIM(A.Invoice))	AS [Invoice# / CheckNo]
 , A.InvoiceTransDate		AS [Invoice Date]
 , A.InvoiceDueDate			AS [Invoice Due Date]
 , A.InvoiceContract			AS [Contract#]
 , CASE WHEN A.ContractDesc LIKE 'WO:%' 
		THEN A.ContractDesc --SUBSTRING(A.ContractDesc,CHARINDEX(':',A.ContractDesc)+1,LEN(A.ContractDesc))
	ELSE 'WO:' + CAST(mvwSMWorkOrderGLDept.WorkOrder AS VARCHAR(10))
   END AS [WO#]
 , SMAgreement.Agreement			AS [Agreement]
 , CASE WHEN mvwSMWorkOrderGLDept.SiteDesc > '' THEN mvwSMWorkOrderGLDept.SiteDesc
		WHEN SMAgreement.Description > ''			THEN SMAgreement.Description
		WHEN A.Invoice = 'Unapplied'					THEN 'Chk: ' + ARTH.CheckNo
		WHEN A.InvoiceContract IS NOT NULL			THEN (SELECT TOP(1) Description FROM dbo.JCCM WHERE Contract = A.InvoiceContract)	
		WHEN A.Invoice IS NOT NULL THEN -- get Site Desc
										(SELECT TOP(1) Description
												FROM dbo.SMServiceSite
												WHERE ServiceSite = 
																(SELECT TOP(1) W.ServiceSite
																From dbo.SMInvoiceListDetail D 
																	INNER JOIN dbo.SMWorkOrder W ON
																			D.SMCo = W.SMCo
																	AND W.Customer = D.Customer
																	AND W.WorkOrder = D.WorkOrder
																Where  (RTRIM(LTRIM(ISNULL(D.InvoiceNumber,'')))) = (RTRIM(LTRIM(ISNULL(A.Invoice,''))))
																Group by W.ServiceSite
																) 
											)
		ELSE A.Invoice
   END AS [Contract Description]
 , ISNULL(A.Invoiced - A.Retainage, ARTH.Invoiced - ISNULL(ARTH.Retainage, 0))  AS [Invoice Amt]
 , A.[Current]
 , A.Aged1to30		AS [1-30 Days]
 , A.Aged31to60		AS [31-60 Days]
 , A.Aged61to90		AS [61-90 Days]
 , A.AgedOver90		AS [Over 90 Days]
 , (coalesce([Current],0)+coalesce(Aged1to30,0)+coalesce(Aged31to60,0)+coalesce(Aged61to90,0)+coalesce(AgedOver90,0)) AS [Balance Due] --SUM(ARTL.Amount - ARTL.Retainage) AS [Balance Due]
 --, [# of Invoices] = COUNT(ISNULL(A.Invoice,0))  OVER( PARTITION BY A.CustomerName )
 , [Last Invoice Date] = MAX(A.InvoiceTransDate) OVER( PARTITION BY A.CustomerName ) 
 , ARCM.StmntPrint AS [Do Not Print Y/N]
FROM [dbo].[mfnARAgingSummary] (@FinancialPeriod) A 
		-- TRANSACTIONS
		INNER JOIN dbo.ARTL ARTL 
			ON ARTL.ARCo = A.ARCo 
			AND ARTL.Mth = A.ApplyMth 
			AND ARTL.ARTrans = A.ApplyTrans 
		INNER JOIN dbo.ARTH ARTH 
			ON ARTL.ARCo=ARTH.ARCo 
			AND ARTL.Mth=ARTH.Mth 
			AND ARTL.ARTrans=ARTH.ARTrans 
		INNER JOIN dbo.ARCM ARCM 
			ON 	ARCM.CustGroup = A.CustGroup
			AND ARCM.Customer = A.Customer
		INNER JOIN
		(
			SELECT * From dbo.mckfnARCustomerTypeX2(@ARCO, @Customer, @FinancialPeriod)
		) custType
		ON	custType.CustGroup = A.CustGroup
		AND custType.Customer = A.Customer

		-- WORK ORDER
		LEFT OUTER JOIN Viewpoint.dbo.mvwARTHSMWorkOrderInfo AS mvwARTHSMWorkOrderInfo 
			ON ARTH.ARCo=mvwARTHSMWorkOrderInfo.ARCo 
			AND ARTH.Mth=mvwARTHSMWorkOrderInfo.Mth 
			AND ARTH.ARTrans=mvwARTHSMWorkOrderInfo.ARTrans
		LEFT OUTER JOIN Viewpoint.dbo.mvwSMWorkOrderGLDept AS mvwSMWorkOrderGLDept 
			ON mvwARTHSMWorkOrderInfo.udSMWorkOrderID = mvwSMWorkOrderGLDept.SMWorkOrderID 
			AND mvwARTHSMWorkOrderInfo.udSMCo=mvwSMWorkOrderGLDept.SMCo
		--- AGREEMENT
		LEFT OUTER JOIN Viewpoint.dbo.SMAgreementBillingSchedule AS SMAgreementBillingSchedule 
			ON ARTL.SMAgreementBillingScheduleID = SMAgreementBillingSchedule.SMAgreementBillingScheduleID
		LEFT OUTER JOIN Viewpoint.dbo.SMAgreement SMAgreement 
			ON SMAgreementBillingSchedule.SMCo = SMAgreement.SMCo 
			AND SMAgreementBillingSchedule.Agreement = SMAgreement.Agreement 
			AND SMAgreementBillingSchedule.Revision = SMAgreement.Revision
WHERE 1=1
	AND A.ARCo = @ARCO
	--AND ((A.Customer >= @Customer AND A.Customer <= @CustomerEnd) OR @Customer IS NULL)
	AND (A.Customer = @Customer OR  @Customer IS NULL)
	AND (custType.CustomerType = @CustomerType OR @CustomerType IS NULL)
	AND A.InvoiceTransDate <= @TransThruDate
	AND (coalesce([Current],0)+coalesce(Aged1to30,0)+coalesce(Aged31to60,0)+coalesce(Aged61to90,0)+coalesce(AgedOver90,0)) <> 0  -- [Balance Due]
GROUP BY 
   A.ARCo 
, ARTH.ARTransType
, mvwSMWorkOrderGLDept.SMDepartmentID
, A.CustomerName
, A.Invoice
, A.InvoiceTransDate
, custType.CustomerType
, A.GLDepartmentNumber 
, A.GLDepartmentName	
, A.CustomerName	
, A.Customer		
, ARCM.SortName
, ARCM.udEmail
, ARCM.udARDeliveryMethod
, ARCM.Name		
, ARCM.BillAddress		
, ARCM.BillAddress2	
, ARCM.BillCity	
, ARCM.BillState	
, ARCM.BillZip
, ARTH.CheckNo 			
, A.Invoice		
, A.InvoiceTransDate
, A.InvoiceDueDate
, A.InvoiceContract
, A.Retainage
, ARTH.Invoiced
, ARTH.Retainage
, mvwSMWorkOrderGLDept.WorkOrder
, SMAgreement.Agreement
-- CONTRACT DESCRIPTION
, mvwSMWorkOrderGLDept.SiteDesc
, SMAgreement.Description
, A.ContractDesc
-----------------
, A.[Current]
, A.Aged1to30
, A.Aged31to60
, A.Aged61to90
, A.AgedOver90
, A.Invoiced
, ARCM.StmntPrint
 )
 SELECT * FROM cte
 ORDER BY cte.ARCo, [Customer Sort Name] 


END TRY

BEGIN CATCH
	SET @errmsg =  ERROR_PROCEDURE() + ', ' + N'Line:' + CAST(ERROR_LINE() AS VARCHAR(MAX)) + ' | ' + ERROR_MESSAGE();
	GOTO i_exit
END CATCH

i_exit:

	if (@errmsg <> '')
		BEGIN
			RAISERROR(@errmsg, 11, -1);
		END

END


GO

Grant EXECUTE ON dbo.MCKsp_AROpenItemStatement TO [MCKINSTRY\Viewpoint Users]

/* 

EXEC dbo.MCKsp_AROpenItemStatement 20, null, 'C', '06/01/2019', NULL

*/