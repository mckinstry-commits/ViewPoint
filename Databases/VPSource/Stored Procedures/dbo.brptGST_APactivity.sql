SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Mike Brewer
-- Create date: 4/9/09
-- Description:	GST AP section
--
-- Modifications: huyh - #138354 check for TD.Status and TD.PaidDate for retainage line
--						 , TD.PayType for non-retainage line and changed Total calculations
--					     introduced @APRetPayType for retainage determination
-- =============================================
CREATE PROCEDURE [dbo].[brptGST_APactivity]
	@GTStxCap varchar(12), 
	@GTStxNCap varchar(12), 
	@APCo  bCompany,
	@BeginDate bDate, 
	@EndDate bDate
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.
	SET NOCOUNT ON;

	/* Determine Retention PayType for current Company:
	If not using Pay Categories, return amount based on APCO Pay Type else get from APPC RetPayType */
	DECLARE @APRetPayType tinyint
	SELECT @APRetPayType = RetPayType
	FROM APPC WHERE APCo = @APCo

	IF @APRetPayType IS NULL 
	BEGIN
		SELECT @APRetPayType = RetPayType
		FROM dbo.APCO WHERE APCo = @APCo
	END

	DECLARE @GSTInvoiceList TABLE (Invoice varchar (15) )

	INSERT @GSTInvoiceList
		SELECT DISTINCT APRef FROM APTH TH
		JOIN APTL TL
			ON TH.APCo = TL.APCo 
			AND TH.Mth = TL.Mth 
			AND TH.APTrans = TL.APTrans
		WHERE (TL.TaxCode = @GTStxCap OR TL.TaxCode = @GTStxNCap )
				AND (TH.InvDate >= @BeginDate AND TH.InvDate <= @EndDate)
				AND TL.APCo = @APCo

	SELECT 
		Vendor,
		VendorName,
		Invoice,
		InvoiceDate,
		AccountingMth,
		GLAcct,
		TaxCode,
		PurchaseType,
		GSTSort,
		SUM (Amount) AS 'Amount',
		MAX (GSTTaxRate) AS 'GSTTaxRate',
		SUM (Tax) AS 'Tax',
		SUM (Retention) AS 'Retention',
		SUM (GSTonRetention) AS 'GSTonRetention',
		SUM (Total) AS 'Total'
	FROM (SELECT CAST (TH.Vendor AS varchar(6)) + ' - ' + 
				(SELECT [Name] FROM APVM WHERE Vendor = TH.Vendor AND VendorGroup = TH.VendorGroup) AS 'Vendor', 
				(SELECT [Name] FROM APVM WHERE Vendor = TH.Vendor AND VendorGroup = TH.VendorGroup) AS 'VendorName', 
				TH.APRef AS 'Invoice',
				TH.InvDate AS 'InvoiceDate', 
				TH.Mth AS 'AccountingMth', 
				TL.GLAcct AS 'GLAcct',
				TL.TaxCode AS 'TaxCode', 
				
				(CASE TL.TaxCode
					WHEN @GTStxCap THEN 'Capital Purchases'
					WHEN @GTStxNCap THEN 'Non Capital Purchases'
					ELSE 'Non GST' 
				END) AS 'PurchaseType',
		
				(CASE TL.TaxCode
					WHEN @GTStxCap THEN 1
					WHEN @GTStxNCap THEN 2
					ELSE 3 
				END) AS 'GSTSort',
				
				/*** Amount ***/
				(CASE 
					WHEN TD.Status = 2 OR (TD.Status = 1 AND TD.PaidDate IS NULL) THEN 0 
					ELSE TD.Amount - TD.GSTtaxAmt
				END) AS 'Amount',
				
				ISNULL (TX.NewRate, 0) AS 'GSTTaxRate',

				/*** Tax ***/
				(CASE 
					WHEN TD.Status = 2 OR (TD.Status = 1 AND TD.PaidDate IS NULL) THEN 0 
					ELSE TD.GSTtaxAmt
				END) AS 'Tax',

				/*** Retention ***/
				(CASE 
					WHEN TD.Status = 2 OR (TD.Status = 1 AND TD.PaidDate IS NULL) THEN TD.Amount - TD.GSTtaxAmt
					ELSE 0
				END) AS 'Retention',

				/*** GSTonRetention ***/
				(CASE 
					WHEN TD.Status = 2 OR (TD.Status = 1 AND TD.PaidDate IS NULL) THEN TD.GSTtaxAmt 
					ELSE 0 
				END) AS 'GSTonRetention',

				/*** Total ***/
				(CASE 
					WHEN TD.Status = 2 OR (TD.Status = 1 AND TD.PaidDate IS NULL)
					THEN	/*Amount*/			0 + 
							/*Tax*/				0 + 
							/*Retainage*/		TD.Amount - TD.GSTtaxAmt +
							/*GSTonRetention*/	TD.GSTtaxAmt 
					ELSE 
							/*Amount*/			TD.Amount - TD.GSTtaxAmt + 
							/*Tax*/				TD.GSTtaxAmt + 
							/*Retainage*/		0 +
							/*GSTonRetention*/	0 
				END) AS 'Total'

			FROM dbo.APTH TH
			JOIN dbo.APTL TL
				ON TH.APCo = TL.APCo 
				AND TH.Mth = TL.Mth 
				AND TH.APTrans = TL.APTrans 
			JOIN dbo.APTD TD
				ON TL.APCo = TD.APCo 
				AND TL.Mth = TD.Mth 
				AND TL.APTrans = TD.APTrans 
				AND TL.APLine = TD.APLine
			JOIN dbo.HQTX TX
				ON TL.TaxCode = TX.TaxCode
				AND TL.TaxGroup = TX.TaxGroup
			JOIN dbo.APCO
				ON TH.APCo = APCO.APCo
			WHERE TD.PayType = @APRetPayType
				  AND TH.APRef IN (SELECT Invoice FROM @GSTInvoiceList)
				  AND TL.TaxCode IN (@GTStxCap, @GTStxNCap)
				  /*TK-05350/Issue #143995:Added check to resolve the issue with incorrect calculations
				    in GST AP Activity Details subreport*/
				  AND TH.APCo = @APCo 

		UNION All

		SELECT CAST (TH.Vendor AS varchar(6)) + ' - ' + 
				(SELECT [Name] FROM APVM WHERE Vendor = TH.Vendor AND VendorGroup = TH.VendorGroup) AS 'Vendor', 
				(SELECT [Name] FROM APVM WHERE Vendor = TH.Vendor AND VendorGroup = TH.VendorGroup) AS 'VendorName', 
				TH.APRef AS 'Invoice',
				TH.InvDate AS 'InvoiceDate', 
				TH.Mth AS 'AccountingMth', 
				TL.GLAcct AS 'GLAcct',
				TL.TaxCode, 
				
				(CASE TL.TaxCode
					WHEN @GTStxCap THEN 'Capital Purchases'
					WHEN @GTStxNCap	THEN 'Non Capital Purchases'
					ELSE 'Non GST' 
				END) AS 'PurchaseType',
				
				(CASE TL.TaxCode
					WHEN @GTStxCap THEN 1
					WHEN @GTStxNCap	THEN 2
					ELSE 3 
				END) AS 'GSTSort',

				/*** Amount ***/
				(CASE 
					WHEN TD.PayType = @APRetPayType	THEN 0 
					ELSE TD.Amount - TD.GSTtaxAmt
				END) AS 'Amount',

				isnull(TX.NewRate, 0) AS 'GSTTaxRate',

				/*** Tax ***/
				(CASE 
					WHEN TD.PayType = @APRetPayType	THEN 0 
					ELSE TD.GSTtaxAmt
				END) AS 'Tax',

				/*** Retention ***/
				0 AS 'Retention',

				/*** GSTonRetention ***/
				0 AS 'GSTonRetention',

				/*** Total ***/
				(CASE 
					WHEN TD.PayType = @APRetPayType
						THEN	/*Amount*/			0 + 
								/*Tax*/				0 + 
								/*Retainage*/		0 +
								/*GSTonRetention*/	0 
					ELSE 
								/*Amount*/			TD.Amount - TD.GSTtaxAmt + 
								/*Tax*/				TD.GSTtaxAmt + 
								/*Retainage*/		0 +
								/*GSTonRetention*/	0 
				END) AS 'Total'

		FROM dbo.APTH TH
		JOIN dbo.APTL TL
			ON TH.APCo=TL.APCo 
			AND TH.Mth=TL.Mth 
			AND TH.APTrans=TL.APTrans 
		JOIN dbo.APTD TD
			ON TL.APCo=TD.APCo 
			AND TL.Mth=TD.Mth 
			AND TL.APTrans=TD.APTrans 
			AND TL.APLine=TD.APLine
		JOIN dbo.HQTX TX
			ON TL.TaxCode = TX.TaxCode
			AND TL.TaxGroup = TX.TaxGroup
		JOIN dbo.APCO
			ON TH.APCo = APCO.APCo
		WHERE TD.PayType <> @APRetPayType
			AND TH.APRef IN (SELECT Invoice FROM @GSTInvoiceList)
			AND TL.TaxCode IN (@GTStxCap, @GTStxNCap)
		    /*TK-05350/Issue #143995:Added check to resolve the issue with incorrect calculations
		      in GST AP Activity Details subreport*/
			AND TH.APCo = @APCo 

	) AS X
	GROUP BY Vendor, VendorName, Invoice, InvoiceDate, AccountingMth, GLAcct, TaxCode, PurchaseType,GSTSort

END


GO
GRANT EXECUTE ON  [dbo].[brptGST_APactivity] TO [public]
GO
