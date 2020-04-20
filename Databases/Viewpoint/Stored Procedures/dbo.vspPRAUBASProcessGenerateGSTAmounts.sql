SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

	CREATE  procedure [dbo].[vspPRAUBASProcessGenerateGSTAmounts]
	/******************************************************
	* CREATED BY:	MV 03/21/11	PR AU BAS Epic
	* MODIFIED By:	MV 03/30/11 Create G2, G3, G10 and G11 for both Option 1 and 2
	*				MV 04/25/11 Add GST amounts from CMDT
	*				MV 06/09/11 Exclude TransType 'P' from AR invoices
	*				MV 06/13/11 Amount of TransType 'M' - Misc cash receipts must be -(value)
	*				MV 06/16/11 144135 - use Mth to get range of data from bARTH, bAPTH and bCMDT
	*
	* Usage:	Initializes data into vPRAUEmployerBASAmounts table
	*			for GST. 
	*			Called from PRAUBASProcess.
	*
	* Input params:
	*
	*	@Co - PR Company
	*	@Taxyear - Tax Year
	*	@Seq - sequence
	*	@ReInitialize - flag to delete existing records
	*	@GSTOption - flag to indicate which GST option is selected.
	*	
	*
	* Output params:
	*	@Msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@Co bCompany,@TaxYear char(4), @Seq int,@Msg varchar(100) output)
   	
	AS
	SET NOCOUNT ON
	DECLARE @rcode INT, @StartMonth bDate, @EndMonth bDate,
	 @APRetPayType int, @GSTOption tinyint, @G1IncludesGST bYN,@Counter INT
	 DECLARE @Table table
		(
			Item VARCHAR(3),
			Mth bDate,
			Trans int,
			Line int,
			SalesOrPurchAmt  bDollar,
			SalesOrPurchAmtGST bDollar,
			TaxAmt bDollar
		)

	SELECT @rcode = 0, @Counter = 0

	if @Co IS NULL
	BEGIN
		SELECT @Msg = 'Missing PR Company.', @rcode = 1	
		GOTO  vspexit
	END

	IF @TaxYear IS NULL
	BEGIN	
		SELECT @Msg = 'Missing Tax Year.', @rcode = 1
		GOTO  vspexit
	END
	
	IF @Seq IS NULL
	BEGIN	
		SELECT @Msg = 'Missing Sequence.', @rcode = 1
		GOTO  vspexit
	END

	-- Validate vPRAUEmployerBASGSTTaxCodes.
	IF NOT EXISTS (
				SELECT 1 
				FROM dbo.vPRAUEmployerBASGSTTaxCodes 
				WHERE PRCo=@Co AND TaxYear=@TaxYear AND Seq=@Seq 
			  ) 
	BEGIN
		SELECT @Msg = 'GST Tax Codes do not exist.', @rcode = 1
		GOTO  vspexit   
	END
	
	--Get begin and end dates
	SELECT @StartMonth = GSTStartDate, @EndMonth = GSTEndDate,@GSTOption=GSTOption,@G1IncludesGST=G1IncludesGST   
	FROM dbo.PRAUEmployerBAS
	WHERE PRCo=@Co AND TaxYear=@TaxYear AND Seq=@Seq
	
	--Get AP Retainage Pay Type
	SELECT @APRetPayType = p.RetPayType
	FROM dbo.APPC p
	JOIN dbo.APCO c ON p.APCo=c.APCo AND p.PayCategory=c.PayCategory 
	WHERE p.APCo = @Co

	IF @APRetPayType IS NULL
	BEGIN
		SELECT @APRetPayType = RetPayType
		from APCO where APCo = @Co
	END
	
	-- Clear any GST amounts from PRAUEmployerBASAmounts
	BEGIN
		DELETE FROM dbo.PRAUEmployerBASAmounts
		WHERE PRCo=@Co AND TaxYear=@TaxYear AND Seq=@Seq AND Item like 'G%'
	END
	
	-- Get AR GST G1 amounts
	INSERT INTO @Table (Item, Mth,Trans,Line, SalesOrPurchAmt,SalesOrPurchAmtGST, TaxAmt)
	SELECT DISTINCT 'G1',l.Mth,l.ARTrans,l.ARLine,
		CASE h.ARTransType WHEN 'M' THEN -((l.Amount - (l.Retainage + l.TaxAmount))) ELSE (l.Amount - (l.Retainage + l.TaxAmount)) END,
		CASE h.ARTransType WHEN 'M' THEN -((l.Amount - l.Retainage)) ELSE (l.Amount - l.Retainage) END,
		CASE h.ARTransType WHEN 'M' THEN -(l.TaxAmount) ELSE l.TaxAmount END
	FROM dbo.ARTH h
	JOIN dbo.ARTL l ON h.ARCo=l.ARCo AND h.Mth=l.Mth AND h.ARTrans=l.ARTrans
	JOIN dbo.PRAUEmployerBASGSTTaxCodes t ON t.PRCo=l.ARCo AND t.TaxGroup=l.TaxGroup AND t.TaxCode=l.TaxCode
	WHERE h.ARCo=@Co 
			AND (h.Mth BETWEEN @StartMonth	AND @EndMonth)
			AND h.ARTransType <> 'P' 
			AND t.Item='G1' 
			AND t.PRCo=@Co 
			AND t.TaxYear=@TaxYear
			AND t.Seq=@Seq
			
	-- Get CM GST G1 amounts
	INSERT INTO @Table (Item, Mth,Trans,Line, SalesOrPurchAmt,SalesOrPurchAmtGST, TaxAmt)
	SELECT DISTINCT 'G1', d.Mth,d.CMTrans,1,ABS(d.Amount), ABS(d.Amount),0
	FROM dbo.CMDT d 
	JOIN dbo.PRAUEmployerBASGSTTaxCodes t ON d.CMCo=t.PRCo AND d.TaxGroup=t.TaxGroup AND d.TaxCode=t.TaxCode
	WHERE t.PRCo=@Co 
			AND (d.Mth BETWEEN @StartMonth AND @EndMonth) 
			AND t.Item='G1' 
			AND t.PRCo=@Co 
			AND t.TaxYear=@TaxYear
			AND t.Seq=@Seq
-------------------------------------------------------------------------------------------------------------------
	--IF @GSTOption = 1
	--BEGIN
	INSERT INTO @Table (Item, Mth,Trans,Line, SalesOrPurchAmt,SalesOrPurchAmtGST, TaxAmt)
	SELECT DISTINCT 'G2',l.Mth,l.ARTrans,l.ARLine,
		CASE h.ARTransType WHEN 'M' THEN -((l.Amount - (l.Retainage + l.TaxAmount))) ELSE (l.Amount - (l.Retainage + l.TaxAmount)) END,
		CASE h.ARTransType WHEN 'M' THEN -((l.Amount - l.Retainage)) ELSE (l.Amount - l.Retainage) END,
		CASE h.ARTransType WHEN 'M' THEN -(l.TaxAmount) ELSE l.TaxAmount END
	FROM ARTH h
	JOIN dbo.ARTL l ON h.ARCo=l.ARCo AND h.Mth=l.Mth AND h.ARTrans=l.ARTrans
	JOIN dbo.PRAUEmployerBASGSTTaxCodes t ON t.PRCo=l.ARCo AND t.TaxGroup=l.TaxGroup AND t.TaxCode=l.TaxCode
	WHERE h.ARCo=@Co 
			AND (h.Mth BETWEEN @StartMonth	AND @EndMonth)
			AND h.ARTransType <> 'P' 
			AND t.Item='G2' 
			AND t.PRCo=@Co 
			AND t.TaxYear=@TaxYear
			AND t.Seq=@Seq
			
	-- Get CM GST G2 amounts
	INSERT INTO @Table (Item, Mth,Trans,Line, SalesOrPurchAmt,SalesOrPurchAmtGST, TaxAmt)
	SELECT DISTINCT 'G2', d.Mth,d.CMTrans,1,ABS(d.Amount), ABS(d.Amount),0
	FROM dbo.CMDT d 
	JOIN dbo.PRAUEmployerBASGSTTaxCodes t ON d.CMCo=t.PRCo AND d.TaxGroup=t.TaxGroup AND d.TaxCode=t.TaxCode
	WHERE t.PRCo=@Co 
			AND (d.Mth BETWEEN @StartMonth AND @EndMonth) 
			AND t.Item='G2' 
			AND t.PRCo=@Co 
			AND t.TaxYear=@TaxYear
			AND t.Seq=@Seq
--------------------------------------------------------------------------------------------------------------

	-- Get AR GST G3 amounts
	INSERT INTO @Table (Item, Mth,Trans,Line, SalesOrPurchAmt,SalesOrPurchAmtGST, TaxAmt)
	SELECT DISTINCT 'G3',l.Mth,l.ARTrans,l.ARLine,
		CASE h.ARTransType WHEN 'M' THEN -((l.Amount - (l.Retainage + l.TaxAmount))) ELSE (l.Amount - (l.Retainage + l.TaxAmount)) END,
		CASE h.ARTransType WHEN 'M' THEN -((l.Amount - l.Retainage)) ELSE (l.Amount - l.Retainage) END,
		CASE h.ARTransType WHEN 'M' THEN -(l.TaxAmount) ELSE l.TaxAmount END
	FROM ARTH h
	JOIN dbo.ARTL l ON h.ARCo=l.ARCo AND h.Mth=l.Mth AND h.ARTrans=l.ARTrans
	JOIN dbo.PRAUEmployerBASGSTTaxCodes t ON t.PRCo=l.ARCo AND t.TaxGroup=l.TaxGroup AND t.TaxCode=l.TaxCode
	WHERE h.ARCo=@Co 
		AND (h.Mth BETWEEN @StartMonth	AND @EndMonth)
		AND h.ARTransType <> 'P' 
		AND t.Item='G3' 
		AND t.PRCo=@Co 
		AND t.TaxYear=@TaxYear
		AND t.Seq=@Seq
			
	-- Get CM GST G3 amounts
	INSERT INTO @Table (Item, Mth,Trans,Line, SalesOrPurchAmt,SalesOrPurchAmtGST, TaxAmt)
	SELECT DISTINCT 'G3', d.Mth,d.CMTrans,1,ABS(d.Amount), ABS(d.Amount),0
	FROM dbo.CMDT d 
	JOIN dbo.PRAUEmployerBASGSTTaxCodes t ON d.CMCo=t.PRCo AND d.TaxGroup=t.TaxGroup AND d.TaxCode=t.TaxCode
	WHERE t.PRCo=@Co 
			AND (d.Mth BETWEEN @StartMonth AND @EndMonth) 
			AND t.Item='G3' 
			AND t.PRCo=@Co 
			AND t.TaxYear=@TaxYear
			AND t.Seq=@Seq
--------------------------------------------------------------------------------------------------------------
		-- Get AP GST G10 - Non Retention 
	INSERT INTO @Table (Item, Mth,Trans,Line,SalesOrPurchAmt,SalesOrPurchAmtGST,TaxAmt)
	SELECT DISTINCT 'G10', l.Mth,l.APTrans,l.APLine,
	  (d.Amount) - (d.GSTtaxAmt),
	  (d.Amount),
	  (d.GSTtaxAmt)
	FROM dbo.APTH h
	JOIN dbo.APTL l ON h.APCo=l.APCo AND h.Mth=l.Mth AND h.APTrans=l.APTrans
	JOIN dbo.APTD d ON l.APCo=d.APCo AND l.Mth=d.Mth AND l.APTrans=d.APTrans AND l.APLine=d.APLine
	JOIN PRAUEmployerBASGSTTaxCodes t ON t.PRCo=l.APCo AND t.TaxGroup=l.TaxGroup AND t.TaxCode=l.TaxCode
	WHERE h.APCo=@Co 
		AND (h.Mth BETWEEN @StartMonth AND @EndMonth) 
		AND (d.PayType <> @APRetPayType
		AND d.Status <> 4)
		AND t.Item='G10'
		AND t.PRCo=@Co 
		AND t.TaxYear=@TaxYear
		AND t.Seq=@Seq 
		
	-- Get AP GST G10 Retention amounts	
	INSERT INTO @Table (Item, Mth,Trans,Line,SalesOrPurchAmt,SalesOrPurchAmtGST,TaxAmt)
	SELECT DISTINCT 'G10', l.Mth,l.APTrans,l.APLine,
	  (d.Amount) - (d.GSTtaxAmt),
	  (d.Amount),
	  (d.GSTtaxAmt)
	FROM dbo.APTH h
	JOIN dbo.APTL l ON h.APCo=l.APCo AND h.Mth=l.Mth AND h.APTrans=l.APTrans
	JOIN dbo.APTD d ON l.APCo=d.APCo AND l.Mth=d.Mth AND l.APTrans=d.APTrans AND l.APLine=d.APLine
	JOIN PRAUEmployerBASGSTTaxCodes t ON t.PRCo=l.APCo AND t.TaxGroup=l.TaxGroup AND t.TaxCode=l.TaxCode
	WHERE h.APCo=@Co
		AND (d.PaidMth BETWEEN @StartMonth AND @EndMonth)
		AND (d.PayType = @APRetPayType 
		AND d.Status = 3)
		AND t.Item='G10'
		AND t.PRCo=@Co 
		AND t.TaxYear=@TaxYear
		AND t.Seq=@Seq 
		
	-- Get CM GST G10 amounts
	INSERT INTO @Table (Item, Mth,Trans,Line, SalesOrPurchAmt,SalesOrPurchAmtGST, TaxAmt)
	SELECT DISTINCT 'G10', d.Mth,d.CMTrans,1,ABS(d.Amount), ABS(d.Amount),0
	FROM dbo.CMDT d 
	JOIN dbo.PRAUEmployerBASGSTTaxCodes t ON d.CMCo=t.PRCo AND d.TaxGroup=t.TaxGroup AND d.TaxCode=t.TaxCode
	WHERE t.PRCo=@Co 
			AND (d.Mth BETWEEN @StartMonth AND @EndMonth) 
			AND t.Item='G10' 
			AND t.PRCo=@Co 
			AND t.TaxYear=@TaxYear
			AND t.Seq=@Seq
----------------------------------------------------------------------------------------------------------------------------
			
		-- Get AP GST G11 - Non Retention amounts
		INSERT INTO @Table (Item, Mth,Trans,Line,SalesOrPurchAmt,SalesOrPurchAmtGST,TaxAmt)
		SELECT DISTINCT 'G11', l.Mth,l.APTrans,l.APLine,
		  (d.Amount) - (d.GSTtaxAmt),
		  (d.Amount),
		  (d.GSTtaxAmt)
		FROM dbo.APTH h
		JOIN dbo.APTL l ON h.APCo=l.APCo AND h.Mth=l.Mth AND h.APTrans=l.APTrans
		JOIN dbo.APTD d ON l.APCo=d.APCo AND l.Mth=d.Mth AND l.APTrans=d.APTrans AND l.APLine=d.APLine
		JOIN PRAUEmployerBASGSTTaxCodes t ON t.PRCo=l.APCo AND t.TaxGroup=l.TaxGroup AND t.TaxCode=l.TaxCode
		WHERE h.APCo=@Co 
			AND (h.Mth BETWEEN @StartMonth AND @EndMonth) 
			AND (d.PayType <> @APRetPayType 
			AND d.Status <> 4)
			AND t.Item='G11'
			AND t.PRCo=@Co 
			AND t.TaxYear=@TaxYear
			AND t.Seq=@Seq  
		
		-- Get AP GST G11 - Retention amounts	
		INSERT INTO @Table (Item, Mth,Trans,Line,SalesOrPurchAmt,SalesOrPurchAmtGST,TaxAmt)
		SELECT DISTINCT 'G11', l.Mth,l.APTrans,l.APLine,
		  (d.Amount) - (d.GSTtaxAmt),
		  (d.Amount),
		  (d.GSTtaxAmt)
		FROM dbo.APTH h
		JOIN dbo.APTL l ON h.APCo=l.APCo AND h.Mth=l.Mth AND h.APTrans=l.APTrans
		JOIN dbo.APTD d ON l.APCo=d.APCo AND l.Mth=d.Mth AND l.APTrans=d.APTrans AND l.APLine=d.APLine
		JOIN PRAUEmployerBASGSTTaxCodes t ON t.PRCo=l.APCo AND t.TaxGroup=l.TaxGroup AND t.TaxCode=l.TaxCode
		WHERE h.APCo=@Co AND (d.PaidMth BETWEEN @StartMonth AND @EndMonth) 
			AND (d.PayType = @APRetPayType 
			AND d.Status = 3)
			AND t.Item='G11'
			AND t.PRCo=@Co 
			AND t.TaxYear=@TaxYear
			AND t.Seq=@Seq
			
	-- Get CM GST G11 amounts
	INSERT INTO @Table (Item, Mth,Trans,Line, SalesOrPurchAmt,SalesOrPurchAmtGST, TaxAmt)
	SELECT DISTINCT 'G11', d.Mth,d.CMTrans,1,ABS(d.Amount), ABS(d.Amount),0
	FROM dbo.CMDT d 
	JOIN dbo.PRAUEmployerBASGSTTaxCodes t ON d.CMCo=t.PRCo AND d.TaxGroup=t.TaxGroup AND d.TaxCode=t.TaxCode
	WHERE t.PRCo=@Co 
			AND (d.Mth BETWEEN @StartMonth AND @EndMonth) 
			AND t.Item='G11' 
			AND t.PRCo=@Co 
			AND t.TaxYear=@TaxYear
			AND t.Seq=@Seq
		
	--END		

	-- Sum up amounts and insert into vPRAUEmployerBASAmounts
	INSERT INTO dbo.PRAUEmployerBASAmounts
		(
			PRCo,                          
			TaxYear,                       
			Seq,                           
			Item,                          
			SalesOrPurchAmt,               
			SalesOrPurchAmtGST,            
			GSTTaxAmt,                     
			WithholdingAmt                
		)
	SELECT @Co,@TaxYear,@Seq,Item,
		SUM(isnull(SalesOrPurchAmt, 0)),
		SUM(isnull(SalesOrPurchAmtGST, 0)),
		SUM(isnull(TaxAmt, 0)), NULL
	
	FROM @Table
	GROUP BY Item
	ORDER BY Item
	
	SELECT @Counter = COUNT(Item)
	FROM dbo.PRAUEmployerBASAmounts
	WHERE PRCo=@Co AND TaxYear=@TaxYear AND Seq=@Seq and Item like 'G%'
	 
	vspexit:

	IF @rcode=0
	BEGIN
		SELECT @Msg = 'Generated ' + convert(varchar(10),@Counter) + ' GST Amounts.'
	END
	
	RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRAUBASProcessGenerateGSTAmounts] TO [public]
GO
