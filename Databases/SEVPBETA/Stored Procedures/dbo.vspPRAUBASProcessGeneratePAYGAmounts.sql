SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


	CREATE  procedure [dbo].[vspPRAUBASProcessGeneratePAYGAmounts]
	/******************************************************
	* CREATED BY:	MV 03/22/11	PR AU BAS Epic
	* MODIFIED By:	MV 06/22/11 #144147 PAYG start and end dates are not months
	*					use bPREA to get subject, eligible and amounts 
	*
	* Usage:	Initializes data into vPRAUEmployerBASAmounts table
	*			for PAYG Witholding. 
	*			Called from PRAUBASProcess.
	*
	* Input params:
	*
	*	@Co - PR Company
	*	@Taxyear - Tax Year
	*	@Seq - sequence
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
	DECLARE @rcode INT, @StartMonth bMonth, @EndMonth bMonth,@W1Amt bDollar,
		@W2Amt bDollar, @W1Amt2 bDollar, @Counter INT
	
	SELECT @rcode = 0, @Counter = 0, @W1Amt = 0, @W2Amt=0

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
		
	--Get begin and end dates
	SELECT @StartMonth = PAYGWthStartDate, @EndMonth = PAYGWthEndDate  
	FROM dbo.PRAUEmployerBAS
	WHERE PRCo=@Co AND TaxYear=@TaxYear AND Seq=@Seq
	
	-- Clear any PAYG Witholding amounts from PRAUEmployerBASAmounts
	BEGIN
		DELETE FROM dbo.PRAUEmployerBASAmounts
		WHERE PRCo=@Co AND TaxYear=@TaxYear AND Seq=@Seq AND Item like 'W%'
	END
	
	-- First W1 amount - use Subject amount for ATOCategory T
	SELECT @W1Amt = SUM(SubjectAmt)
	FROM dbo.PREA a
	JOIN dbo.PRDL d ON a.PRCo=d.PRCo AND a.EDLType=d.DLType AND a.EDLCode=d.DLCode
	WHERE a.PRCo=@Co AND (a.Mth BETWEEN @StartMonth AND @EndMonth) AND d.ATOCategory = 'T'
	--FROM dbo.PRDT t
	--JOIN dbo.PRSQ s ON t.PRCo=s.PRCo AND t.PRGroup=s.PRGroup AND t.PREndDate=s.PREndDate 
	--	AND t.Employee=s.Employee AND t.PaySeq=s.PaySeq
	--JOIN dbo.PRDL d ON t.PRCo=d.PRCo AND t.EDLType=d.DLType AND t.EDLCode=d.DLCode
	--WHERE t.PRCo=@Co AND (s.PaidDate BETWEEN @StartMonth AND @EndMonth) AND d.ATOCategory = 'T'
	
	IF @W1Amt IS NULL
	BEGIN
		SELECT @W1Amt = 0
	END
	
	-- Second W1 amount - use Eligible amount for ATOCategory TE
	SELECT @W1Amt2 = SUM(EligibleAmt)
	FROM dbo.PREA a
	JOIN dbo.PRDL d ON a.PRCo=d.PRCo AND a.EDLType=d.DLType AND a.EDLCode=d.DLCode
	WHERE a.PRCo=@Co AND (a.Mth BETWEEN @StartMonth AND @EndMonth) AND d.ATOCategory = 'TE'
	--FROM dbo.PRDT t
	--JOIN dbo.PRSQ s ON t.PRCo=s.PRCo AND t.PRGroup=s.PRGroup AND t.PREndDate=s.PREndDate 
	--	AND t.Employee=s.Employee AND t.PaySeq=s.PaySeq
	--JOIN dbo.PRDL d ON t.PRCo=d.PRCo AND t.EDLType=d.DLType AND t.EDLCode=d.DLCode
	--JOIN dbo.PRDL l ON t.EDLType=l.DLType AND t.EDLCode=l.DLCode
	--WHERE t.PRCo=@Co AND (s.PaidDate BETWEEN @StartMonth AND @EndMonth) AND d.ATOCategory = 'TE'
	
	IF @W1Amt2 IS NULL
	BEGIN
		SELECT @W1Amt2 = 0
	END
	
	
	-- W2 amount 
	SELECT @W2Amt = SUM(Amount)
	FROM dbo.PREA a
	JOIN dbo.PRDL d ON a.PRCo=d.PRCo AND a.EDLType=d.DLType AND a.EDLCode=d.DLCode
	WHERE a.PRCo=@Co AND (a.Mth BETWEEN @StartMonth AND @EndMonth) AND d.ATOCategory in ('T', 'TE')
	--SELECT @W2Amt = SUM(CASE OverAmt WHEN 0 THEN Amount ELSE OverAmt END)
	--FROM dbo.PRDT t
	--JOIN dbo.PRSQ s ON t.PRCo=s.PRCo AND t.PRGroup=s.PRGroup AND t.PREndDate=s.PREndDate 
	--	AND t.Employee=s.Employee AND t.PaySeq=s.PaySeq
	--JOIN dbo.PRDL d ON t.PRCo=d.PRCo AND t.EDLType=d.DLType AND t.EDLCode=d.DLCode
	--JOIN dbo.PRDL l ON t.EDLType=l.DLType AND t.EDLCode=l.DLCode
	--WHERE t.PRCo=@Co AND (s.PaidDate BETWEEN @StartMonth AND @EndMonth) AND d.ATOCategory in ('T', 'TE')
	
	IF @W2Amt IS NULL
	BEGIN
		SELECT @W2Amt = 0
	END
			
	-- Insert W1 record
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
	SELECT @Co,@TaxYear,@Seq,'W1',NULL,NULL, NULL,(@W1Amt + @W1Amt2)
	-- insert W2 record
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
	SELECT @Co,@TaxYear,@Seq,'W2',NULL,NULL, NULL,@W2Amt
	
	SELECT @Counter = COUNT(Item)
	FROM dbo.PRAUEmployerBASAmounts
	WHERE PRCo=@Co AND TaxYear=@TaxYear AND Seq=@Seq and Item like 'W%'
	 
	vspexit:

	IF @rcode=0
	BEGIN
		SELECT @Msg = 'Generated ' + convert(varchar(10),@Counter) + ' PAYG Withholding Amounts.'
	END
	
	RETURN @rcode



GO
GRANT EXECUTE ON  [dbo].[vspPRAUBASProcessGeneratePAYGAmounts] TO [public]
GO
