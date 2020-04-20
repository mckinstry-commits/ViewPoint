SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*************************************
* Created By:  DAN SO 09/24/2009 - ISSUE #129350
* Modified By: AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables-  
*
*
* USAGE:   Validate Surcharge Code entered in the Surcharge tab in MS Ticket Entry 
*
*
* INPUT PARAMETERS
*	@msco				MS Company
*	@SurchargeCode		SurchargeCode
*	
*
* OUTPUT PARAMETERS
*	@SurchargeMaterial	Surcharge Materail associated with Surcharge Code
*	@Basis				Haul Basis Type
*	@SurchargeRate      Surcharge Rate
*	@Taxable			Surcharge Taxable?
*	@msg				Haul code description or error message
*   
* RETURN VALUE
*   0         Success
*   1         Failure
*
**************************************/
--CREATE PROC [dbo].[vspMSSurchargeCodeValWithInfo]
CREATE  PROC [dbo].[vspMSSurchargeCodeValWithInfo]
(@msco bCompany = NULL, @Mth bMonth = NULL, @BatchID bBatchID = NULL, @BatchSeq int = NULL, 
 @Quote varchar(10) = NULL, @SurchargeCode smallint = NULL,  @matlgroup bGroup = NULL, 
 @material bMatl = NULL, @category varchar(10) = NULL, @locgroup bGroup = NULL, 
 @fromloc bLoc = NULL, @trucktype varchar(10) = NULL, @um bUM = NULL, @zone varchar(10) = NULL, 
 @SurchargeMaterial bMatl = NULL output, @Basis tinyint = 0 output, @SurchargeRate bUnitCost = 0 output, 
 @TaxRate bRate = 0 output, @Taxable bYN = 'N' output, @PayCode bPayCode = NULL output, 
 @SurchargeMinAmt bDollar = 0 output, @DiscountApply bYN = 'N' output, @SurchargeUM bUM output, 
 @msg varchar(255) = NULL output)


AS
SET NOCOUNT ON
	-- #142350 renaming @MatlGroup   and @Material
	DECLARE	@rcode			int,
			@TaxGroup		bGroup,
			@TaxType		tinyint,
			@TaxCode		bTaxCode,
			@CompDate		bDate,
			@MaterialGroup		bGroup,
			@Matl		bMatl,
			@MatlTaxable	bYN,
			@TempMsg		varchar(255),
			@RetCode		int


	------------------
	-- PRIME VALUES --
	------------------
	SET @rcode = 0
	
	
	----------------------------------
	-- VALIDATE INCOMING PARAMETERS --
	----------------------------------
	IF @msco IS NULL
		BEGIN
			SELECT @msg = 'Missing MS Company', @rcode = 1
			GOTO vspexit
		END
		
	IF @Mth IS NULL
		BEGIN
			SELECT @msg = 'Missing Batch Month', @rcode = 1
			GOTO vspexit
		END
		
	IF @BatchID IS NULL
		BEGIN
			SELECT @msg = 'Missing Batch ID', @rcode = 1
			GOTO vspexit
		END
		
	IF @BatchSeq IS NULL
		BEGIN
			SELECT @msg = 'Missing Batch Sequence', @rcode = 1
			GOTO vspexit
		END

	IF @SurchargeCode IS NULL
		BEGIN
			SELECT @msg = 'Missing Surcharge Code', @rcode = 1
			GOTO vspexit
		END

	IF @locgroup IS NULL
		BEGIN
			SELECT @msg = 'Missing Location Group', @rcode = 1
			GOTO vspexit
		END

	if @matlgroup is null
		BEGIN
			SELECT @msg = 'Missing Material Group', @rcode = 1
			GOTO vspexit
		END
		
		
 	-------------------
	-- GET MISC INFO --
	-------------------
	SELECT @TaxGroup = TaxGroup, @TaxType = TaxType, @TaxCode = TaxCode, @CompDate = SaleDate, 
		   @Matl = Material, @MaterialGroup = MatlGroup
	  FROM bMSTB WITH (NOLOCK)
	 WHERE Co = @msco
	   AND Mth = @Mth
	   AND BatchId = @BatchID
	   AND BatchSeq = @BatchSeq	
	   
	   
	-------------------------------
	-- GET SURCHARGE INFORMATION --
	-------------------------------
	SELECT	@msg = Description, @SurchargeMaterial = SurchargeMaterial, @PayCode = PayCode,
			@Basis = SurchargeBasis, @Taxable = TaxableYN, @DiscountApply = DiscountsYN
	  FROM	bMSSurchargeCodes
	 WHERE	MSCo = @msco
	   AND	SurchargeCode = @SurchargeCode

	IF @@ROWCOUNT = 0
		BEGIN
			SELECT @msg = 'Invalid Surcharge Code', @rcode = 1
			GOTO vspexit
		END
			
	-- DETERMINE CORRECT UM FOR SURCHARGE MATERIAL --
	SELECT @SurchargeUM = SalesUM
	  FROM bHQMT WITH (NOLOCK)
	 WHERE MatlGroup = @MaterialGroup
	   AND Material = @SurchargeMaterial

	 IF @Basis = 2
		SET @SurchargeUM = @um
			
		
	------------------------
	-- GET SURCHARGE RATE --
	------------------------
	EXEC @RetCode = dbo.vspMSSurchargeRateGet 
						@msco, @SurchargeCode, @matlgroup, @material, @category, @locgroup,
						@fromloc, @trucktype, @um, @Quote, @zone, @CompDate, @Basis,
						@SurchargeRate output, @SurchargeMinAmt output, @TempMsg output  				
   									
	IF @RetCode = 1
		BEGIN
			SELECT @msg = 'Error Getting Surcharge Rate - ' + @TempMsg, @rcode = 1
			GOTO vspexit
		END
	ELSE
		SET @rcode = @RetCode	-- @RetCode VALUE OF 3 -> RATE WAS FOUND
								-- @RetCode VALUE OF 1 -> ERROR
								-- @RetCode VALUE OF 0 -> SUCCESSFULLY COMPLETED, BUT RATE NOT FOUND


	-----------------------
	-- MATERIAL TAXABLE? --
	-----------------------
	SELECT @MatlTaxable = ISNULL(Taxable, 'N')
	  FROM bHQMT
	 WHERE MatlGroup = @MaterialGroup
	   AND Material = @Matl
	   

	------------------
	-- GET TAX RATE --
	------------------
	IF @Taxable = 'Y' AND @MatlTaxable = 'Y' AND @TaxCode IS NOT NULL
		BEGIN			
		
			EXEC @RetCode = dbo.vspMSHQTaxRateGet @TaxGroup, @TaxType, @TaxCode, @CompDate,
								@TaxRate output, @TempMsg output
								
			IF @RetCode = 1
			BEGIN
				SELECT @msg = 'Error Getting Tax Rate - ' + @TempMsg, @rcode = 1
				GOTO vspexit
			END
		END --IF @Taxable = 'Y'
		

	-----------------
	-- END ROUTINE --
	-----------------
	vspexit:
		IF @rcode = 1 
			SET @msg = ISNULL(@msg,'')
		RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[vspMSSurchargeCodeValWithInfo] TO [public]
GO
