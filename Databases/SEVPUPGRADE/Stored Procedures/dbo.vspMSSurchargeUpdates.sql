SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*************************************
* Created By:  DAN SO 10/07/2009 - ISSUE #129350
* Modified By: 
*
*
* USAGE:   When an MSTicEntry is created/updated/deleted - update associated
*			MS Surcharges as necessary
*
*
* INPUT PARAMETERS
*	@MSTBKeyID		Parent Key ID of Surcharge Record(s)
*
* OUTPUT PARAMETERS
*	@msg            Error message
*   
* RETURN VALUE
*   0         Success
*   1         Failure
*
**************************************/
--CREATE PROC [dbo].[vspMSSurchargeUpdates]
CREATE  PROC [dbo].[vspMSSurchargeUpdates]
 
(@MSTBKeyID bigint = NULL, @MatlTotal bDollar = NULL, @MatlUnits bUnits = NULL, 
	@HaulCharge bDollar = NULL, @HaulUnits bUnits = NULL, 
	@Distance bUnits = NULL, @Loads smallint = NULL, 
	@msg varchar(255) = NULL output)
 

AS
SET NOCOUNT ON

	DECLARE	@rcode				int,
			@RowID				int,		-- SurchargeTable 
			@Code				bHaulCode,	-- SurchargeTable 
			@Rate				bUnitCost,	-- SurchargeTable 
			@RateBasis			tinyint,	-- SurchargeTable 
			@SurchargeTaxable	bYN,		-- SurchargeTable 
			@MatlTaxRate		bUnitCost,
			@SurchargeTotal		bUnits,
			@TaxGroup			bGroup,
			@TaxType			tinyint,
			@TaxCode			bTaxCode,
			@TaxBasis			bUnits,
			@TaxTotal			bUnits,
			@CompDate			bDate,
			@MatlGroup			bGroup,
			@Material			bMatl,
			@MatlTaxable		bYN,
			@CalcBasis			bUnits,
			@TempMsg			varchar(255),
			@RowCnt				int,
			@MaxRows			int,
			@RetCode			int

				
	----------------------------------
	-- VALIDATE INCOMING PARAMETERS --
	----------------------------------
	IF @MSTBKeyID IS NULL
		BEGIN
			SELECT @msg = 'Missing MS Parent KeyID', @rcode = 1
			GOTO vspexit
		END
		
		
	---------------------------------
	-- CREATE/LOAD SURCHARGE TABLE --
	---------------------------------
	-- CREATE TABLE --
	DECLARE @SurchargesTable TABLE
		(	
			RowID				int			IDENTITY(1,1),	-- Row ID
			Code				SMALLINT,					-- MSSurcharges 
			Rate				bUnitCost,					-- MSSurcharges
			RateBasis			tinyint,					-- MSSurchargeCodes
			SurchargeTaxable	bYN							-- MSSurchargeCodes
		)
		 
	-- LOAD TABLE --
	INSERT INTO @SurchargesTable (Code, Rate, RateBasis, SurchargeTaxable)
		SELECT	sur.SurchargeCode, sur.SurchargeRate, e.SurchargeBasis, e.TaxableYN 
		  FROM	MSSurcharges sur WITH (NOLOCK)
		  JOIN	MSTB b WITH (NOLOCK) ON b.KeyID = sur.MSTBKeyID 
	      JOIN	HQMT t WITH (NOLOCK) ON t.MatlGroup = b.MatlGroup 
		   AND	t.Material = sur.SurchargeMaterial 
		  JOIN	MSSurchargeCodes e WITH (NOLOCK) ON e.SurchargeCode = sur.SurchargeCode
	     WHERE	MSTBKeyID = @MSTBKeyID
	 
	  
	-------------------
	-- GET MISC INFO --
	-------------------
	SELECT	@TaxGroup = b.TaxGroup, @TaxType = b.TaxType, @TaxCode = b.TaxCode, 
			@CompDate = b.SaleDate, @MatlTaxable = t.Taxable
	  FROM	MSTB b WITH (NOLOCK)
	  JOIN	HQMT t WITH (NOLOCK) ON t.MatlGroup = b.MatlGroup 
	   AND	t.Material = b.Material
	 WHERE	b.KeyID = @MSTBKeyID


	------------------
	-- PRIME VALUES --
	------------------
	SET @rcode = 0
	SET @RowCnt = 1
	SELECT @MaxRows = COUNT(*) FROM @SurchargesTable


	---------------------------------
	-- LOOP THROUGH ALL SURCHARGES --
	---------------------------------
	WHILE @RowCnt <= @MaxRows
		BEGIN
		
			SELECT	@Code = Code, @Rate = Rate, @RateBasis = RateBasis, 
					@SurchargeTaxable = SurchargeTaxable
			  FROM  @SurchargesTable
		     WHERE	RowID = @RowCnt

		

			-- SET/REST VARIABLES --
			SET @MatlTaxRate = 0
			SET @CalcBasis = 0
			SET @SurchargeTotal = 0
			SET @TaxBasis = 0
			SET @TaxTotal = 0
			
			
			---------------------------------
			-- DETERMINE THE CORRECT BASIS -- 
			---------------------------------
			SELECT @CalcBasis = CASE @RateBasis 
				WHEN 1 THEN ISNULL(@MatlTotal, 0)
				WHEN 2 THEN ISNULL(@MatlUnits, 0)
				WHEN 3 THEN ISNULL(@HaulCharge, 0)
				WHEN 4 THEN ISNULL(@HaulUnits, 0)
				WHEN 5 THEN ISNULL(@Distance, 0)
				WHEN 6 THEN ISNULL(@Loads, 0)
				WHEN 7 THEN 1		-- Fixed Amount WILL ALWAYS HAVE A BASIS OF 1
				ELSE 1
				END
				
				
			------------------
			-- CALCULATIONS --
			------------------
			SET @SurchargeTotal = @CalcBasis * ISNULL(@Rate, 0)
				
			-- GET TAX RATE --
			IF @SurchargeTaxable = 'Y' AND @MatlTaxable = 'Y'
				BEGIN			
				
					EXEC @RetCode = dbo.vspMSHQTaxRateGet @TaxGroup, @TaxType, @TaxCode, @CompDate,
										@MatlTaxRate output, @TempMsg output
										
					IF @RetCode = 1
						BEGIN
							SELECT @msg = 'Error Getting Tax Rate - ' + @TempMsg, @rcode = 1
							GOTO vspexit
						END
					ELSE
						BEGIN
							-- TAX --
							SET @TaxBasis = @SurchargeTotal
							SET @TaxTotal = @TaxBasis * ISNULL(@MatlTaxRate, 0)
							
						END --IF @RetCode = 1
				END --IF @SurTaxable = 'Y' AND @MatlTaxable = 'Y

		
			----------------------------------------
			-- MAKE CHANGES TO MSSurcharges TABLE --
			----------------------------------------
			UPDATE  MSSurcharges
			   SET  SurchargeBasis = @CalcBasis,
					SurchargeTotal = @SurchargeTotal,
					TaxBasis = @TaxBasis,
					TaxTotal = @TaxTotal
			 WHERE	SurchargeCode = @Code
			   AND	MSTBKeyID = @MSTBKeyID
					
					
			----------------------
			-- UPDATE ROW COUNT --
			----------------------
			SET @RowCnt = @RowCnt + 1

		END -- WHILE @RowCnt <= @MaxRows
		
	
-----------------
-- END ROUTINE --
-----------------
vspexit:
	IF @rcode <> 0 
		SET @msg = isnull(@msg,'')
		
	RETURN @rcode
		
		
		
		


		


GO
GRANT EXECUTE ON  [dbo].[vspMSSurchargeUpdates] TO [public]
GO
