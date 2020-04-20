 USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='MCKspInvoiceDetail' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
Begin
	Print 'DROP PROCEDURE dbo.MCKspInvoiceDetail'
	DROP PROCEDURE dbo.MCKspInvoiceDetail
End
GO

Print 'CREATE PROCEDURE dbo.MCKspInvoiceDetail'
GO


CREATE PROCEDURE [dbo].MCKspInvoiceDetail
(
  @SMCo		dbo.bCompany
, @WordOrder INT					
, @InvoiceNumber varchar(10)	-- WO may have multiple invoices, so filter it
, @HideTandMLaborRate BIT = 1			-- make 'Detail' T&M as default
)
AS
 /* 
	Purpose:	Get Invoice details from Work Order
	Author:	Leo Gurdian
	Created:	9.11.2018
	HISTORY: 

	07.15.2019 LG - Bug Fix: unable to pull detail due to missing scope 1.  TFS 4828
	07.11.2019 LG - Bug Fix: some flat price invoices not pulling detail due to missing WorkOrder in SMInvoice. TFS 4812
	06.25.2019 LG - FIRE ONLY: - TFS 4780
						- Description "Repair Service" is now "Service Repair"
						- Add "Fire Protection" to TYPE Column
	06.20.2019 LG - FIRE ONLY: 
					  - fixed when fitter notes missing, Work Performed Description is BLANK - TFS 4172
					  - T&M "Hide Rate", Do Not Display Price or Quantity - TFS 4765
	06.18.2019 LG - Allow hide/show T&M labor rate
   06.13.2019 LG - *** separating Labor, Materials, Truck & Env. Safety Fee for T&M
	06.12.2019 LG - FIRE template was wrongly applying to all Divisions - Fixed
	04.15.2019 LG - Consolidate T&M detail to 1 line: "Labor & Materials" - TFS 3937
						 Consolidate T&M detail to 1 line + SM WO from Quote: "Labor and Materials Per Quote # _________"
						 Flat Price to include quote # when SM WO is derived from Quote
					    Restructured T&M detail CTE to only execute main query once
						 make 'Summary' T&M as default
	12.13.2018 LG - Display correct amount and tax when Flat price has more than 1 split lines 
	12.06.2018 LG - Exlude NoCharge
	11.21.2018 LG - Ungrouping Labor Tax to allow proper consolidation
	11.09.2018 LG - Separated Flat Price vs T&M logic to apply sorting only to T&M
	10.19.2018 LG - Sort by cteOrder Seq instead per Pam Norton
	10.18.2018 LG - Sort by PriceMethod so when Flat Price is always on top
	10.16.2018 LG - Exlude PriceMethod = N (non-billable)
	09.11.2018 LG - Init concept from VP trace
*/
BEGIN

	/* performance improvement when you redeclare variables | credits to Ben Wilson */ 
	DECLARE @smco				dbo.bCompany = @SMCo
	DECLARE @workOrder		INT			 = @WordOrder
	DECLARE @invoiceNumber	VARCHAR(10)  = @InvoiceNumber 
	DECLARE @hideTandMLaborRate		INT			 = @HideTandMLaborRate
	Declare @errmsg			VARCHAR(800) = ''

BEGIN TRY	
 DECLARE @flat CHAR(1) = (SELECT TOP (1) 1
						  FROM dbo.SMInvoice I
							INNER JOIN dbo.SMInvoiceDetail D    
								ON I.SMCo = D.SMCo
										AND I.Invoice = D.Invoice
							INNER JOIN dbo.SMInvoiceLine L
								ON I.SMCo = L.SMCo
										AND I.Invoice = L.Invoice
										AND D.InvoiceDetail = L.InvoiceDetail
										AND L.Invoice IS NOT NULL 
							INNER JOIN dbo.SMWorkOrderScope S 
								ON I.SMCo = S.SMCo
										AND D.WorkOrder = S.WorkOrder
										AND ISNULL(D.Scope,1) = S.Scope
						  WHERE S.WorkOrder = @workOrder AND S.PriceMethod IN ('F')
								AND RTRIM(LTRIM(ISNULL(I.InvoiceNumber,' '))) >= RTRIM(LTRIM(ISNULL(@invoiceNumber, ' ')))
						 )

 IF @flat = 1
  BEGIN
	/* Flat rate doesn't have sorting*/
	SELECT DISTINCT --TOP (10) 
			  I.SMCo
			, S.WorkScope
			, I.InvoiceNumber
			, smid.WorkOrder
			, CASE WHEN smdiv.udGLDept IN ('0250','0251') AND S.PriceMethod = 'F' THEN		-- TFS 4172 (FIRE gets description from Scope Sequence 6.11.19 LG

						CASE WHEN Q.WorkOrderQuote IS NULL THEN 

									-- quote # NOT found
									CASE WHEN (S.PriceMethod = 'F' OR smid.WorkCompleted IS NULL) THEN LTRIM(COALESCE(S.Description + ' ',''))  + ISNULL(T.Notes,'')
									ELSE LTRIM(COALESCE(WC.Description, S.CallType, '') + ' ') + ISNULL(T.Notes,'')
									END

						ELSE		-- quote # exists
									CASE WHEN (S.PriceMethod = 'F' OR smid.WorkCompleted IS NULL) THEN LTRIM(ISNULL(S.Description,'') + ' Per Quote # ')  + LTRIM(RTRIM(COALESCE(Q.WorkOrderQuote + ' ',''))) + ISNULL(T.Notes,'')
									ELSE LTRIM(COALESCE(WC.Description, S.CallType, '') + ' Per Quote # ') + LTRIM(RTRIM(COALESCE(Q.WorkOrderQuote + ' ',''))) + ISNULL(T.Notes,'')
									END
						END	
				ELSE	
				WO.Description	
			 
			  END	 AS [WorkOrderDesc]

			, CASE WHEN smdiv.udGLDept IN ('0250','0251') THEN 'Fire Protection' -- TFS 4780
					ELSE (SELECT MAX(Description) From dbo.SMLineType t Where t.LineType = WC.Type) 
			  END AS [Type]

			, CASE WHEN smdiv.udGLDept IN ('0250','0251') AND S.PriceMethod = 'F' THEN 'Service Repair' -- TFS 4172, 4780 FIRE STANDARD description 6.11.19 LG
					ELSE	
						CASE WHEN Q.WorkOrderQuote IS NULL THEN
							  CASE WHEN (S.PriceMethod = 'F' OR smid.WorkCompleted IS NULL) THEN S.Description
							  ELSE ISNULL(WC.Description, S.CallType)
							  END						
						  ELSE
								-- TFS 3937
								CASE WHEN (S.PriceMethod = 'F' OR smid.WorkCompleted IS NULL) THEN LTRIM(ISNULL(S.Description,'') + ' Per Quote # ') + LTRIM(RTRIM(Q.WorkOrderQuote))
								ELSE LTRIM(COALESCE(WC.Description, S.CallType, '') + ' Per Quote # ') + LTRIM(RTRIM(Q.WorkOrderQuote))
								END	
						END	
			  END	AS [Description]

			, CASE WHEN S.Division = 'CONV' AND smdiv.udGLDept IN ('0250','0251') THEN 'FIRE'
					 ELSE S.Division
					END AS Division
			, CASE WHEN il.Amount IS NOT NULL AND WC.PriceQuantity IS NULL THEN 1 
				   WHEN WC.Type in (2,3) THEN WC.PriceQuantity 
				Else WC.Quantity 
			  END									AS [Qty]
			, WC.PriceRate						AS [Rate]
			, InvoiceLineSum.Amount			AS [Price]
			, InvoiceLineSum.TaxAmount		AS [Tax]
			, ISNULL(InvoiceLineSum.Amount,0)  + ISNULL(InvoiceLineSum.TaxAmount,0) As [TotalPrice]
			, S.PriceMethod
			, WC.ServiceSite
			,	(CASE WHEN smdiv.udGLDept = '0999' THEN 
				-- look for old astea WOs to get GL Dept.
							CASE WHEN (SELECT TOP(1) A.udGLDept
										  FROM dbo.SMDepartment A
										  WHERE Department = (SELECT TOP(1) S.SMDepartmentID 
																	 FROM mvwSMWorkOrderGLDept S 
																	 WHERE S.WorkOrder = smid.WorkOrder)
										  ) = '0999' THEN smdiv.Department
							END 
					ELSE  COALESCE(smdiv.udGLDept, '')
					END) AS udGLDept
			, T.Notes
		, il.Invoice
FROM dbo.SMInvoice I
			INNER JOIN dbo.SMInvoiceLine il
				ON		 il.SMCo = I.SMCo 
					AND il.Invoice = I.Invoice 
			INNER JOIN dbo.SMInvoiceDetail AS smid
				ON		 I.SMCo = smid.SMCo
					AND I.Invoice = smid.Invoice
					AND il.InvoiceDetail = smid.InvoiceDetail
			INNER JOIN dbo.SMWorkOrderScope S 
				ON		 I.SMCo = S.SMCo
					AND S.WorkOrder = smid.WorkOrder -- TFS 4812 fix
					AND S.Scope  = ISNULL(smid.Scope, (SELECT MIN(Scope) FROM dbo.SMWorkOrderScope s WHERE s.WorkOrder = @workOrder)) -- TFS 4828 when missing scope seq, get next available
			-- GET DEPT
			INNER JOIN dbo.SMDivision AS div
				ON		 div.SMCo = I.SMCo
					AND div.ServiceCenter = S.ServiceCenter
					AND div.Division = S.Division
			INNER JOIN dbo.SMDepartment AS smdiv
				ON		 smdiv.SMCo = I.SMCo
					AND smdiv.Department = div.Department
			-- END GET DEPT 
			INNER JOIN	dbo.SMWorkOrder WO
				ON WO.SMCo = S.SMCo
						AND WO.WorkOrder = S.WorkOrder
			LEFT OUTER JOIN dbo.SMWorkCompleted WC 
				ON	WC.WorkOrder	 = smid.WorkOrder
					AND WC.WorkCompleted = smid.WorkCompleted
			LEFT OUTER JOIN 	dbo.vSMWorkOrderQuote Q
					ON Q.SMCo = S.SMCo
						AND Q.WorkOrderQuote = S.WorkOrderQuote
			LEFT OUTER JOIN dbo.SMTrip T -- to get Notes to append to "Work Completed" (WorkOrderDesc)
				ON T.WorkOrder = smid.WorkOrder 
			CROSS APPLY (SELECT	SUM(SMInvoiceLine.Amount) AS Amount, 
								SUM(SMInvoiceLine.TaxAmount) AS TaxAmount
							FROM		dbo.SMInvoiceLine
							WHERE		smid.SMCo 			= SMInvoiceLine.SMCo
								AND 	smid.Invoice 		= SMInvoiceLine.Invoice
								AND 	smid.InvoiceDetail = SMInvoiceLine.InvoiceDetail) InvoiceLineSum
	WHERE I.InvoiceType IN ('W','A')
			AND I.VoidDate IS NULL
			AND smid.IsRemoved = 0
			AND smid.WorkOrder = @workOrder
			AND RTRIM(LTRIM(ISNULL(I.InvoiceNumber,' '))) = RTRIM(LTRIM(ISNULL(@invoiceNumber , ' ')))  
END	

ELSE IF @flat IS NULL

  BEGIN	

-- DETAIL T&M
WITH cteMain
AS
(
SELECT	 
			MAX(I.SMCo)					AS SMCo
		, I.InvoiceNumber				AS InvoiceNumber
		, D.WorkOrder					AS WorkOrder
		, (SELECT MAX(Description) From dbo.SMLineType t Where t.LineType = WC.Type) As Type
		, D.WorkCompleted				AS WorkCompleted
		, WO.Description				As WorkOrderDesc
		, S.Description				AS ScopeDesc
		, WC.Description				AS WCDescription
		, MAX(S.CallType)				AS CallType
		, WC.PayType					AS WCPayType
		, WC.Type						AS WCType
		, MAX(WC.PriceQuantity)		AS PriceQuantity
		, MAX(WC.Quantity)			AS WCQuantity
		, WC.PriceRate					AS Rate
		, SUM(L.Amount)				AS Price
		, SUM(L.TaxAmount)			AS Tax
		, SUM(ISNULL(L.Amount,0)  + ISNULL(L.TaxAmount,0))	AS TotalPrice
		, MAX(S.PriceMethod)			AS PriceMethod
		, MAX(WC.PayType)				AS PayType
		, MAX(S.Division)				as Division
FROM dbo.SMInvoice I
		INNER JOIN dbo.SMInvoiceDetail D
			ON I.SMCo = D.SMCo
					AND I.Invoice = D.Invoice
		INNER JOIN dbo.SMInvoiceLine L
			ON I.SMCo = L.SMCo
					AND I.Invoice = L.Invoice
					AND D.InvoiceDetail = L.InvoiceDetail
					AND L.Invoice IS NOT NULL 
		INNER JOIN dbo.SMWorkOrderScope S 
			ON I.SMCo = S.SMCo
					AND D.WorkOrder = S.WorkOrder
					AND S.Scope  = ISNULL(D.Scope, (SELECT MIN(Scope) FROM dbo.SMWorkOrderScope s WHERE s.WorkOrder = @workOrder)) -- TFS 4828 when missing scope seq, get next available
		INNER JOIN	dbo.SMWorkOrder WO
			ON WO.SMCo = S.SMCo
					AND WO.WorkOrder = S.WorkOrder
		LEFT OUTER JOIN dbo.SMWorkCompleted WC 
			ON	WC.WorkOrder		 = D.WorkOrder
				AND WC.WorkCompleted = D.WorkCompleted
WHERE I.InvoiceType IN ('W','A')
		AND I.VoidDate IS NULL
		AND D.IsRemoved = 0
		AND L.NoCharge = 'N' -- charged (billable lines)
		AND L.Amount <> 0		-- TFS 4667 LG 6.18.19
		AND D.WorkOrder = @workOrder
		AND RTRIM(LTRIM(ISNULL(I.InvoiceNumber,' '))) = RTRIM(LTRIM(ISNULL(@invoiceNumber, ' ')))
GROUP BY 
			I.SMCo
		, WC.Type				
		, I.InvoiceNumber
		, D.WorkOrder
		, S.Description
		, WO.Description
		, WC.Description
		, WC.PriceRate
		, WC.PayType
		, D.WorkCompleted
), CTE_1 
AS
(	-- LABOR ONLY - SUMMURIZED
	SELECT	 
			 1 AS SortOrder
			, SMCo							AS SMCo
			, InvoiceNumber				AS InvoiceNumber
			, WorkOrder						AS WorkOrder
			, (SELECT MAX(Description) From dbo.SMLineType t Where t.LineType = WCType) As Type
			, WorkOrderDesc				AS WorkOrderDesc
			, MAX(CallType) + ' Labor ' + (SELECT MAX(Description) FROM dbo.SMPayType WHERE PayType = WCPayType) As Description
			--TFS 4667 LG 6.18.19

			, CASE WHEN @hideTandMLaborRate = 1 THEN NULL 
				ELSE SUM(COALESCE(PriceQuantity, WCQuantity, 1))
			  END								AS Qty

			, CASE WHEN @hideTandMLaborRate = 1 THEN NULL -- (Rate * SUM(PriceQuantity)) TFS 4765 6.20.19 Leo Gurdian 
				ELSE Rate
			  END								AS Rate
			-- END TFS 4667
			, SUM(Price)					AS Price
			, SUM(Tax)						AS Tax
			, MAX(PriceMethod)			AS PriceMethod
			, MAX(WCPayType)				AS PayType
			, NULL AS udGLDept
			, MAX(Division)				as Division
	FROM cteMain
	WHERE WCType = 2 -- LABOR 
	GROUP BY 
			 SMCo
			, WCType				
			, InvoiceNumber
			, WorkOrder
			, WorkOrderDesc
			--, PriceQuantity -- uncomment out to break out labor detail
			, Rate
			, WCPayType
), CTE_2
AS
(	 -- PURCHASES ONLY - SUMMURIZED
	SELECT	 
			  2								AS SortOrder
			, SMCo							AS SMCo
			, InvoiceNumber				AS InvoiceNumber
			, WorkOrder						AS WorkOrder
			, (SELECT MAX(Description) From dbo.SMLineType t Where t.LineType = WCType) As Type
			, WorkOrderDesc				AS WorkOrderDesc
			, MAX(CallType)				AS Description
			, CASE WHEN SUM(ISNULL(Price,0)) <> 0 THEN 1 ELSE NULL END AS Qty
			, SUM(ISNULL(Price,0))		AS Rate
			, SUM(ISNULL(Price,0))		AS Price
			, SUM(ISNULL(Tax,0))			AS Tax
			, MAX(PriceMethod)			AS PriceMethod
			, NULL							AS PayType
			, NULL AS udGLDept
			, MAX(Division)				as Division
	FROM cteMain
	WHERE WCType = 5 -- PURCHASE
	GROUP BY 
			  SMCo
			, WCType				
			, InvoiceNumber
			, WorkOrder
			, WorkOrderDesc
			, WCPayType
), CTE_3
AS 
(
	/* non flat rate has sorting */
	SELECT	 
			 -- sorting per Pam Norton
			 CASE  -- WHEN WC.Type = 2 THEN 1 -- LABOR IS GROUP IN THE ABOVE CTE
				    -- WHEN WC.Type = 5 THEN 2 -- Purchase
				   WHEN WCType = 3 THEN 3 -- Miscellaneous
				   WHEN WCType = 5 THEN 4 -- Equipment
				   WHEN WCType = 4 THEN 5 -- Inventory
				   ELSE 6 -- Other
			 END								AS SortOrder
			, SMCo							AS SMCo
			, InvoiceNumber				AS InvoiceNumber
			, WorkOrder						AS WorkOrder
			, Type							AS Type
			, WorkOrderDesc				AS WorkOrderDesc
			, CASE WHEN PriceMethod = 'F'THEN ScopeDesc
				    WHEN WorkCompleted IS NULL THEN ScopeDesc
				ELSE ISNULL(WCDescription, CallType)
			  END								AS Description
			, CASE WHEN Price IS NOT NULL 
							AND PriceQuantity IS NULL THEN 1 
				    WHEN WCType = 3 THEN PriceQuantity 
				Else WCQuantity 
			  END								AS Qty
			, Rate							AS Rate
			, SUM(ISNULL(Price,0))		AS Price	
			, Tax								AS Tax
			, PriceMethod					AS PriceMethod
			, WCPayType						AS PayType
			, NULL AS udGLDept
			, MAX(Division)				as Division
	FROM cteMain
	WHERE		 WCType <> 2 -- Labor
			AND WCType <> 5 -- Purchase
	GROUP BY 
		  WCType
		, SMCo
		, InvoiceNumber
		, WorkOrder
		, WorkOrderDesc
		, PriceMethod
		, WorkCompleted
		, ScopeDesc
		, WCDescription
		, CallType
		, Price
		, PriceQuantity
		, WCQuantity
		, Rate
		, Tax
		, WCPayType
		, Type
		, Division
	)
	SELECT * FROM CTE_1 -- LABOR
	UNION ALL
	SELECT * FROM CTE_2 -- PURCHASES
	UNION ALL
	SELECT * FROM CTE_3 -- Miscellaneous, Equipment, Inventory
  
  END	

END TRY

	Begin Catch
		Set @errmsg =  ERROR_PROCEDURE() + ', ' + N'Line:' + CAST(ERROR_LINE() AS VARCHAR(MAX)) + ' | ' + ERROR_MESSAGE();
		Goto i_exit
	End Catch

i_exit:

	if (@errmsg <> '')
		Begin
		 RAISERROR(@errmsg, 11, -1);
		End
End

GO


Grant EXEC ON dbo.MCKspInvoiceDetail TO [MCKINSTRY\Viewpoint Users]

GO

/* TEST 


-- multiple labor
 EXEC dbo.MCKspInvoiceDetail 1, 9528836, '10071645', 1

 EXEC dbo.MCKspInvoiceDetail 1, 9529571, '10067494', 0

 EXEC dbo.MCKspInvoiceDetail 1, 8027878, 2209517 -- FLAT FIRE

 EXEC dbo.MCKspInvoiceDetail 1, 9523973  
 EXEC dbo.MCKspInvoiceDetail 1, 9523861, 9523860  --invoice w/ 2 WOs 
 EXEC dbo.MCKspInvoiceDetail 1, 9524191  
 EXEC dbo.MCKspInvoiceDetail 1, 8025848, 1220117
 EXEC dbo.MCKspInvoiceDetail 1, 9529770, NEW
 EXEC dbo.MCKspInvoiceDetail 1, 9527951, '10071163', 1 
 EXEC dbo.MCKspInvoiceDetail 1, 9527951, '10071163', 0  -- per quote
 EXEC dbo.MCKspInvoiceDetail 1, 9527939, '10071432', 1
 EXEC dbo.MCKspInvoiceDetail 1, 9527939, '10071432', 0


 -- PROD - FLAT
 EXEC dbo.MCKspInvoiceDetail 1, 8032983, 0115218
 EXEC dbo.MCKspInvoiceDetail 1, 8034902, 10057365 - FLAT
 EXEC dbo.MCKspInvoiceDetail 1, 8040055  
 EXEC dbo.MCKspInvoiceDetail 1, 8043004   --INV 10057267  VOIDED  rebilled as 10057327 - flat price 
 EXEC dbo.MCKspInvoiceDetail 1, 9528082  
 EXEC dbo.MCKspInvoiceDetail 1, 9528622, 10059548


-- PROD - T&M
 EXEC dbo.MCKspInvoiceDetail 1, 8043235, 10057532
 EXEC dbo.MCKspInvoiceDetail 1, 8042711, 10057357
 EXEC dbo.MCKspInvoiceDetail 1, 8032989, 10057262
 EXEC dbo.MCKspInvoiceDetail 1, 8039098   --INV 10057367  VOIDED  rebilled 
 EXEC dbo.MCKspInvoiceDetail 1, 8042983   --INV 10057288 (VOIDED) no rebilled


EXEC dbo.MCKspInvoiceDetail 1,  9531469	, 10080916


EXEC dbo.MCKspInvoiceDetail 1,  9524167, 10053454
EXEC dbo.MCKspInvoiceDetail 1,  9536865, 10087323

-- Flat Price derived from Quote 1001900
EXEC dbo.MCKspInvoiceDetail 1,  9535642,  10079911 

 */