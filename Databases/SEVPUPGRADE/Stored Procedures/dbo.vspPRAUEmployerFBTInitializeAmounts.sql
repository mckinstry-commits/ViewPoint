SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


	CREATE  procedure [dbo].[vspPRAUEmployerFBTInitializeAmounts]
	/******************************************************
	* CREATED BY:	MV 01/11/11
	* MODIFIED By: 
	*
	* Usage:	Validates for Category in vPRAUEmployerItems.  
	*			Initializes data into vPRAUEmployerCodes table
	*			by tax year, summarizing amounts from bPREA accums
	*			by FBT Type,EDL Code.
	*			Called from PRAUEmployerFBTItems.
	*
	* Input params:
	*
	*	@PRCo - PR Company
	*	@Taxyear - Tax Year
	*	@ReInitialize - flag to delete existing records
	*	
	*
	* Output params:
	*	@Msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@PRCo bCompany,@TaxYear char(4), @ReInitialize bYN, @Msg varchar(100) output)
   	
	AS
	SET NOCOUNT ON
	DECLARE @rcode INT, @BegTaxDate bDate, @EndTaxDate bDate,
	 @FBTType varchar(4), @EDLType char(1), @EDLCode bEDLCode,
	 @Category char(1), @OpenCursor tinyint, @Amount bDollar,
	 @Counter INT

	SELECT @rcode = 0, @OpenCursor = 0, @Counter = 0

	if @PRCo IS NULL
	BEGIN
		SELECT @Msg = 'Missing PR Company.', @rcode = 1	
		GOTO  vspexit
	END

	IF @TaxYear IS NULL
	BEGIN	
		SELECT @Msg = 'Missing Tax Year.', @rcode = 1
		GOTO  vspexit
	END

	-- Validate vPRAUEmployerFBTItems.
	IF NOT EXISTS (
				SELECT 1 
				FROM dbo.PRAUEmployerFBTItems 
				WHERE PRCo=@PRCo AND TaxYear=@TaxYear 
			  ) 
	BEGIN
		SELECT @Msg = 'FBT Info does not exist.', @rcode = 1
		GOTO  vspexit   
	END
	ELSE
	BEGIN
		-- Validate vPRAUEmployerFBTItems for a Category in each record.
		IF EXISTS (
					SELECT 1 
					FROM dbo.PRAUEmployerFBTItems 
					WHERE PRCo=@PRCo AND TaxYear=@TaxYear AND ISNULL(Category, '') = ''
				  ) 
		BEGIN
			SELECT @Msg = 'One or more FBT Info items is missing a Category.', @rcode = 1
			GOTO  vspexit   
		END
	END
	
	-- Reinitialize - user wants all FBTCodes deleted first
	IF @ReInitialize = 'Y'
	BEGIN
		DELETE FROM dbo.vPRAUEmployerFBTCodes
		WHERE PRCo=@PRCo AND TaxYear=@TaxYear
	END
	
	-- Set up FBT tax year for query purposes
	SELECT @BegTaxDate = '4/1/' + CONVERT(CHAR(4),CONVERT(SMALLINT,@TaxYear)-1)
	SELECT @EndTaxDate = '3/1/' + @TaxYear
	
	-- Loop through FBTItems
	DECLARE vcFBTCodes cursor for
    SELECT FBTType,EDLType,EDLCode,Category
    FROM dbo.vPRAUEmployerFBTItems
    WHERE PRCo=@PRCo AND TaxYear=@TaxYear 
    
    OPEN vcFBTCodes
    SELECT @OpenCursor = 1
    
FBTCodes_loop:
    	FETCH NEXT FROM vcFBTCodes into @FBTType, @EDLType, @EDLCode, @Category
    
    	IF @@FETCH_STATUS <> 0 GOTO vspexit
    	
    	--Insert int FBTCodes
    	IF NOT EXISTS 
    		(
    			SELECT 1 FROM dbo.vPRAUEmployerFBTCodes d
				JOIN dbo.vPRAUEmployerFBTItems s
				ON d.PRCo=s.PRCo AND d.TaxYear=s.TaxYear AND d.FBTType=s.FBTType 
					AND d.EDLType=s.EDLType AND d.EDLCode=s.EDLCode
					AND d.Category=s.Category
				WHERE d.PRCo=@PRCo AND d.TaxYear=@TaxYear AND d.FBTType=@FBTType
					AND d.EDLType=@EDLType AND d.EDLCode=@EDLCode AND d.Category=@Category
			)
		BEGIN
			-- Get Amount
			SELECt @Amount = 0
			SELECT @Amount= SUM(Amount)
							FROM dbo.bPREA 
							WHERE PRCo=@PRCo AND EDLType=@EDLType AND EDLCode=@EDLCode
								AND (Mth >= @BegTaxDate AND Mth <= @EndTaxDate)
							GROUP BY PRCo, EDLType,EDLCode
							
			IF @Amount IS NULL SELECT @Amount = 0
			
			-- Insert new rec into FBTCodes
			INSERT INTO dbo.vPRAUEmployerFBTCodes
			(	
				PRCo,                          
				TaxYear,                       
				FBTType,                       
				EDLType,                       
				EDLCode,                       
				Category,                      
				Amount
			)
			SELECT @PRCo, @TaxYear, @FBTType, @EDLType, @EDLCode,@Category,@Amount
			-- bump the counter
			SELECT @Counter = @Counter + 1
			
		END
	    	
    	GOTO FBTCodes_loop

	 
	vspexit:
	IF @OpenCursor = 1
	BEGIN
		CLOSE vcFBTCodes
		DEALLOCATE vcFBTCodes
	END
	IF @rcode=0
	BEGIN
		SELECT @Msg = 'Generated ' + convert(varchar(10),@Counter) + ' Reportable Amounts.'
	END
	
	RETURN @rcode




GO
GRANT EXECUTE ON  [dbo].[vspPRAUEmployerFBTInitializeAmounts] TO [public]
GO
