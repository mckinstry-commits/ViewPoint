SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mike Brewer
-- Create date: 4/10/09
-- Description:	GST activity Stmt AR
-- Issue # 
-- =============================================
CREATE PROCEDURE [dbo].[brptGST_ARactivity]
	@GTSTaxCode varchar(12), 
	@ExportSales varchar (12), 
	@GTStxFree varchar(12), 
	@ARCo  bCompany,
	@BeginDate bDate, 
	@EndDate bDate
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--TK-05349/Issue #143996: Added code to lookup correct tax rates for Export Sales and GST-Free Sales
	DECLARE @MyGSTTaxRate AS decimal(9,8),
			@MyExportSales AS decimal(9,8),
			@MyGTStxFree AS decimal(9,8) 
			
	SELECT @MyGSTTaxRate = HQTX.NewRate 
	FROM dbo.HQCO 
	JOIN dbo.HQTX ON HQCO.TaxGroup = HQTX.TaxGroup 
	WHERE HQCO.HQCo = @ARCo AND HQTX.TaxCode = @GTSTaxCode
	  
	SELECT @MyExportSales = HQTX.NewRate 
	FROM dbo.HQCO 
	JOIN dbo.HQTX ON HQCO.TaxGroup = HQTX.TaxGroup 
	WHERE HQCO.HQCo = @ARCo AND HQTX.TaxCode = @ExportSales 
	
	SELECT @MyGTStxFree = HQTX.NewRate 
	FROM dbo.HQCO 
	JOIN dbo.HQTX ON HQCO.TaxGroup = HQTX.TaxGroup 
	WHERE HQCO.HQCo = @ARCo AND HQTX.TaxCode = @GTStxFree

	DECLARE @GSTInvoiceList TABLE (Invoice varchar (10))

	INSERT @GSTInvoiceList
		SELECT DISTINCT TH.Invoice 
		FROM dbo.ARTH TH
		JOIN dbo.ARTL TL ON TH.ARCo = TL.ARCo
							AND TH.Mth = TL.Mth
							AND TH.ARTrans = TL.ARTrans
		WHERE	(TL.TaxCode = @GTSTaxCode 
				OR TL.TaxCode = @ExportSales
				OR TL.TaxCode =  @GTStxFree)
				AND Invoice IS NOT NULL	
				AND TH.ARCo = @ARCo
				AND (TH.TransDate >= @BeginDate AND TH.TransDate <= @EndDate)
			
	SELECT	Customer,
			Invoice,
			SUM(Amount) AS 'Amount',
			SUM([Retention]) AS 'Retention',
			SUM(RetentionBilled) AS 'RetentionBilled',
			SUM(BASbasis) AS 'BASbasis',
			SUM(GSTCalculated) AS 'GSTCalculated',
			SalesType,
			GSTSort
	FROM (SELECT 
			(SELECT Name FROM ARCM WHERE Customer = ARTH.Customer AND CustGroup = ARTH.CustGroup) AS 'Customer',
			LTRIM(RTRIM(ARTH.Invoice)) AS 'Invoice',
			ISNULL(ARTL.TaxBasis,0) + ISNULL(ARTL.Retainage,0) - ISNULL(ARTL.RetgTax,0) AS 'Amount',  
			ISNULL(ARTL.Retainage, 0) - ISNULL(ARTL.RetgTax,0) AS 'Retention',
			0 AS 'RetentionBilled',
			ISNULL(ARTL.Amount, 0) - ISNULL(ARTL.TaxAmount,0)- ISNULL(ARTL.Retainage,0) AS 'BASbasis',

			--TK-05349/Issue #143996: Getting correct tax rates for Export Sales AND GST-Free Sales. Commented code used the GST Sales tax rate for all calculations
			--(ISNULL(ARTL.Amount,0) - ISNULL(ARTL.TaxAmount,0)- ISNULL(ARTL.Retainage,0)) * ISNULL(@MyGSTTaxRate,0)  as 'GSTCalculated',
			(ISNULL(ARTL.Amount,0) - ISNULL(ARTL.TaxAmount,0)- ISNULL(ARTL.Retainage,0)) * 
				(
				CASE ARTL.TaxCode  
					WHEN @GTSTaxCode THEN @MyGSTTaxRate 
					WHEN @ExportSales THEN @MyExportSales  
					WHEN @GTStxFree THEN @MyGTStxFree 
					ELSE 0 END
				) AS 'GSTCalculated',
	 
			CASE ARTL.TaxCode
				WHEN @GTSTaxCode THEN 'Total sales G1'
				WHEN @ExportSales THEN 'Export sales G2'
				WHEN @GTStxFree THEN 'Other GST-free sales G3'
				ELSE 'Other' END AS 'SalesType',

			CASE ARTL.TaxCode
				WHEN @GTSTaxCode THEN 1
				WHEN @ExportSales THEN 2
				WHEN @GTStxFree THEN 3
				ELSE 4 END AS 'GSTSort'
		FROM dbo.ARTH
		JOIN dbo.ARTL ON ARTL.ARCo = ARTH.ARCo 
						 AND ARTL.Mth = ARTH.Mth 
						 AND ARTL.ARTrans = ARTH.ARTrans 
		WHERE  
			--TK-05349/Issue #143996:Added check to resolve the issue with incorrect calculations in GST AR Activity Details subreport
			ARTH.ARCo = @ARCo 
			AND(ARTL.TaxCode = @GTSTaxCode
				OR ARTL.TaxCode = @ExportSales
				OR ARTL.TaxCode = @GTStxFree)
			AND ARTL.ARCo=@ARCo
			AND ARTH.ARTransType = 'I'
			AND ARTH.Invoice IN (SELECT Invoice FROM @GSTInvoiceList)

		UNION ALL

		SELECT 
			(SELECT Name FROM ARCM WHERE Customer = ARTH.Customer AND CustGroup = ARTH.CustGroup) AS 'Customer',
			LTRIM (RTRIM (ARTH.Invoice) ) AS 'Invoice',
			0 AS 'Amount', 
			ARTL.Retainage AS 'Retention',
			ISNULL(ARTL.Amount,0) - ISNULL(ARTL.TaxAmount,0) AS 'RetentionBilled',
			ISNULL(ARTL.Amount,0) - ISNULL (ARTL.TaxAmount,0) AS 'BASbasis',
			(ISNULL(ARTL.Amount,0) - ISNULL(ARTL.TaxAmount,0))* ISNULL(@MyGSTTaxRate,0)  AS 'GSTCalculated',	
			
			CASE ARTL.TaxCode
				WHEN @GTSTaxCode THEN 'Total sales G1'
				WHEN @ExportSales THEN 'Export sales G2'
				WHEN @GTStxFree THEN 'Other GST-free sales G3'
				ELSE 'Other' END AS 'SalesType',

			CASE ARTL.TaxCode
				WHEN @GTSTaxCode THEN 1
				WHEN @ExportSales THEN 2
				WHEN @GTStxFree THEN 3
				ELSE 4 END AS 'GSTSort'
		FROM dbo.ARTL 
		INNER JOIN dbo.HQCO	ON ARTL.ARCo = HQCO.HQCo 
		LEFT OUTER JOIN dbo.ARTH ON ARTL.ARCo = ARTH.ARCo 
									AND ARTL.Mth = ARTH.Mth 
									AND ARTL.ARTrans = ARTH.ARTrans 
		WHERE
			ARTL.ARCo = @ARCo --TK-05349/Issue #143996:Added check to resolve the issue with incorrect calculations 
							  --in GST AR Activity Details subreport
			AND (ARTL.TaxCode = @GTSTaxCode
				OR ARTL.TaxCode = @ExportSales
				OR ARTL.TaxCode =  @GTStxFree)
			AND ARTL.ARCo=@ARCo 
			AND ARTH.ARTransType = 'R'
			AND ARTH.Invoice IN (SELECT Invoice FROM @GSTInvoiceList) 
	)AS T
	GROUP BY Customer, Invoice,	SalesType, GSTSort

END


GO
GRANT EXECUTE ON  [dbo].[brptGST_ARactivity] TO [public]
GO
