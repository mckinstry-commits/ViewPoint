SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*************************************
* Created By:  DAN SO 01/25/2010 - Issue #129350
* Modified By: 
*
* USAGE: Automatically create a Surcharge ticket based on MS Ticket information
*
*
* INPUT PARAMETERS
*	@msco			Company
*	@Mth			MSTB Month
*	@BatchID		MSTB BatchID
*   @BatchSeq		MSTB Batch Sequence
*	@MSTBKeyID		MSTB KeyID
*	@matlgroup		MSTB Material Group
*	@material		MSTB Material
*	@fromloc		MSTB From Location
*	@trucktype		MSTB Truck Type
*	@um				MSTB Unit of Measure
*	@zone			MSTB Zone
*	@tojcco			MSTB JCCo
*	@phasegroup		MSTB Phase Group
*	@phase			MSTB Haul Phase
*
*
* OUTPUT PARAMETERS
*	@Rate	Surcharge Rate
*	@msg    On error
*
* RETURN VALUE
*	3		Success - Surcharge Created
*   0       Success - No Surcharge Created
*   1       Failure
*
**************************************/
--CREATE PROC [dbo].[vspMSSurchargeAutoCreate]
CREATE PROC [dbo].[vspMSSurchargeAutoCreate]
(@MSCo bCompany = NULL, @Mth bMonth = NULL, @BatchID bBatchID = NULL, @BatchSeq int = NULL, 
@MSTBKeyID bigint = NULL, @MatlGroup bGroup = NULL, @Material bMatl = NULL,  
@FromLoc bLoc = NULL, @TruckType varchar(10) = NULL, @UM bUM = NULL, @Zone varchar(10) = NULL, 
@JCCo bCompany = NULL, @Job bJob = NULL, @PhaseGroup bGroup = NULL, @Phase bPhase = NULL, 
@SaleType char(1) = NULL, @CustGroup bGroup = NULL, @Customer bCustomer = NULL, 
@CustJob varchar(20) = NULL, @CustPO varchar(20) = NULL, @INCo bCompany = NULL, @ToLoc bLoc = NULL,
@msg varchar(255) output)
   
AS
SET NOCOUNT ON

	DECLARE	@rcode				int,
			@LocGroup			bGroup,
			@Category			bCat,
			@Quote				varchar(10),
			@CoSurchargeGroup	int,	-- AKA DfltSurchargeGroup IN MS COMPANY
			@QtApplySurcharges	bYN,
			@QtSurchargeGroup	int,
			@RowCnt				int,
			@NumRows			int,
			@SurchargeSeq		int,
			@SurchargeCode		smallint,
			@PayCode			bPayCode,
			@SurchargeMaterial	bMatl,
			@Basis				tinyint, 
			@SurchargeUM		bUM,
			@SurchargeBasisAmt	bUnits,
			@SurchargeRate		bUnitCost, 
			@SurchargeTotal		bUnits,
			@SurchargeMinAmt	bDollar,
			@TaxRate			bUnitCost, 
			@TaxBasis			bUnits,
			@TaxTotal			bUnits,
			@SurchargeTaxable	bYN,
			@MatlTaxable		bYN,
			@DiscountsYN		bYN,
			@DiscountOpt		tinyint,
			@DiscountType		char(1),
			@DiscountRate		bUnitCost,
			@DiscountOffered	bDollar,
			@TaxDiscount		bDollar
	
			
	----------------------------------
	-- VALIDATE INCOMING PARAMETERS --
	----------------------------------
	IF @MSCo IS NULL
		BEGIN
			SET @msg = 'Missing MS Company'
			SET @rcode = 1
			GOTO vspexit
		END

	IF @Mth IS NULL
		BEGIN
			SET @msg = 'Missing Batch Month'
			SET @rcode = 1
			GOTO vspexit
		END
		
	IF @BatchID IS NULL
		BEGIN
			SET @msg = 'Missing BatchId'
			SET @rcode = 1
			GOTO vspexit
		END
		
	IF @BatchSeq IS NULL
		BEGIN
			SET @msg = 'Missing Batch Sequence' 
			SET @rcode = 1
			GOTO vspexit
		END
		
	IF @MSTBKeyID IS NULL
		BEGIN
			SET @msg = 'Missing MSTBKeyID'
			SET @rcode = 1
			GOTO vspexit
		END
		
	IF @UM IS NULL
		BEGIN
			SET @msg = 'Missing Unit of Measure'
			SET @rcode = 1
			GOTO vspexit
		END	   	
   	  
	---------------------  
	-- PRIME VARIABLES --
	---------------------
	SET @rcode = 0
	SET @QtApplySurcharges = 'N'
	SET @RowCnt = 1
	SET @NumRows = 0
	SET @SurchargeSeq = 0				
	SET @SurchargeRate = 0
	SET @Basis = 0 
 
	-----------------------------------------
	-- GET MSTB RECORD RELATED INFORMATION --
	-----------------------------------------
	-- LOCATION GROUP --
	SELECT @LocGroup = LocGroup
	  FROM bINLM
	 WHERE INCo = @MSCo
	   AND Loc = @FromLoc

	-- CATEGORY --
	SELECT @Category = Category
	  FROM bHQMT
	 WHERE Material = @Material
	   AND MatlGroup = @MatlGroup

	-- QUOTE --
	EXEC @rcode = bspMSTicTemplateGet @MSCo, @SaleType, @CustGroup, @Customer, @CustJob,
										  @CustPO, @JCCo, @Job, @INCo, @ToLoc, @FromLoc,
										  @Quote output, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
										  NULL, NULL, @msg output
										 
	IF @rcode <> 0
		BEGIN
			SET @msg = 'Error obtaining Quote: ' + ISNULL(@msg, '')
			SET @rcode = 1
			GOTO vspexit
		END


    ------------------------------
    -- GET/APPLY SURCHARGE INFO -- 
    ---------------------------------------------------------	
    -- MS QUOTE INFO TAKES PRECEDENCE OVER MS COMPANY INFO --
    ---------------------------------------------------------
	-- MS QUOTE --
	SELECT @QtApplySurcharges = ApplySurchargesYN, @QtSurchargeGroup = SurchargeGroup
	  FROM bMSQH
	 WHERE MSCo = @MSCo
	   AND Quote = @Quote
	   
	-- IF MS QUOTE SURCHARGE GROUP IS NULL - CHECK MS COMPANY --
	IF @QtSurchargeGroup IS NULL
		BEGIN
		
			-- MS COMPANY SURCHARGE GROUP --
			SELECT @CoSurchargeGroup = DfltSurchargeGroup
			  FROM bMSCO
			 WHERE MSCo = @MSCo	
			 
			 -- IF BOTH MS QUOTE AND MS COMPANY SURCHARGE GROUPS ARE NULL - NO SURCHARGES APPLY --
			 IF @CoSurchargeGroup IS NULL
				BEGIN
					SET @msg = 'Not applying Surcharge(s)'	-- NOT AN ERROR - INFO ONLY
					GOTO vspexit
				END		
						
		END	-- IF @QtSurchargeGroup IS NULL

	
	----------------------------------------
	-- CREATE/LOAD @SurchargesTable TABLE --
	----------------------------------------
	-- CREATE TABLE --
	DECLARE @SurchargesTable TABLE
		(	
			RowID			int			IDENTITY(1,1),	
			SurchargeCode	smallint
		)
		 
	-- LOAD TABLE --
	INSERT INTO @SurchargesTable (SurchargeCode)
		SELECT g.SurchargeCode
		  FROM bMSSurchargeGroupCodes g WITH (NOLOCK)
		  JOIN bMSSurchargeCodes c WITH (NOLOCK) ON c.MSCo = g.MSCo 
		   AND c.SurchargeCode = g.SurchargeCode
		 WHERE g.MSCo = @MSCo
		   AND SurchargeGroup in (@CoSurchargeGroup, @QtSurchargeGroup) 
		   AND c.Active = 'Y'
		   
	-- GET THE NUMBER OF ROWS FOR LOOP --
	SELECT @NumRows = COUNT(*) FROM @SurchargesTable

	
	---------------------------------
	-- LOOP THROUGH ALL SURCHARGES --
	---------------------------------
	WHILE @RowCnt <= @NumRows
		BEGIN
		
			-- RESET VALUES --
			SET	@TaxRate = 0	
			SET @TaxBasis = 0		 
			SET	@TaxTotal = 0	
			SET @DiscountOffered = 0
			SET @TaxDiscount = 0
		
			-- GET RECORD --
			SELECT	@SurchargeCode = SurchargeCode
			  FROM  @SurchargesTable
			 WHERE	RowID = @RowCnt		
			 					
			-- GET SURCHARGE INFO TO INSERT INTO bMSSurcharges --
			EXEC @rcode = dbo.vspMSSurchargeCodeValWithInfo @MSCo, @Mth, @BatchID, 
									@BatchSeq, @Quote, @SurchargeCode,  
									@MatlGroup, @Material, @Category, @LocGroup, 
									@FromLoc, @TruckType, @UM, @Zone, 
									@SurchargeMaterial output, @Basis output, 
									@SurchargeRate output, @TaxRate output, 
									@SurchargeTaxable output, @PayCode output, 
									@SurchargeMinAmt output, @DiscountsYN output,
									@SurchargeUM output, @msg output

			-------------------------------------
			-- SURCHARGE FOUND - CREATE RECORD --
			-------------------------------------												
			IF @rcode = 3
				BEGIN
					
					-- GET NEXT SURCHARGE SEQ NUMBER --
					SELECT	@SurchargeSeq = ISNULL(MAX(SurchargeSeq),0) + 1
					  FROM	bMSSurcharges WITH (NOLOCK)
					 WHERE	Co = @MSCo
					   AND	Mth = @Mth
					   AND	BatchId = @BatchID 
					   AND	BatchSeq = @BatchSeq

					-- DETERMINE THE CORRECT BASIS -- 
					SELECT	@SurchargeBasisAmt = CASE @Basis
							WHEN 1 THEN ISNULL(MatlTotal, 0)
							WHEN 2 THEN ISNULL(MatlUnits, 0)
							WHEN 3 THEN ISNULL(HaulTotal, 0)
							WHEN 4 THEN ISNULL(HaulBasis, 0)
							WHEN 5 THEN ISNULL(Miles, 0)	-- ALSO REFERRED TO AS 'Distance'
							WHEN 6 THEN ISNULL(Loads, 0)
							WHEN 7 THEN 1					-- FIXED AMOUNT		
							ELSE 1							-- CATCH ALL
							END
					  FROM	bMSTB WITH (NOLOCK) 
					 WHERE  KeyID = @MSTBKeyID
										 
					 
					---------------------------
					-- CALC SURCHARGE AMOUNT --
					---------------------------
					SET @SurchargeTotal = @SurchargeBasisAmt * @SurchargeRate
					
					-- CHECK MIN AMOUNT --
					IF (@SurchargeMinAmt > @SurchargeTotal) AND (@SurchargeMinAmt <> 0)
						BEGIN
							SET @SurchargeTotal = @SurchargeMinAmt
						END
						
					--------------------			
					-- CALC DISCOUNTS --
					--------------------
					-- 0 - N -> No Discount
					-- 1 - U -> Unit Based
					-- 2 - R -> Dollar Based
					
					-- SURCHARGE CODE ALLOWS DISCOUNTS AND CUSTOMER SALE ? --
					IF @DiscountsYN = 'Y' AND @SaleType = 'C'
						BEGIN
							SELECT @DiscountOpt = h.DiscOpt, @DiscountRate = m.DiscRate, @DiscountType = q.PayDiscType
							  FROM bARCM a WITH (NOLOCK)
							  JOIN bHQPT h WITH (NOLOCK) ON  h.PayTerms = a.PayTerms
							  JOIN bMSTB m WITH (NOLOCK) ON m.CustGroup = a.CustGroup AND m.Customer = a.Customer
							  JOIN bHQMT q WITH (NOLOCK) ON q.MatlGroup = m.MatlGroup AND q.Material = m.Material
							 WHERE m.KeyID = @MSTBKeyID
				 							 					
				 			-- ATTEMPTED TO RECREATE LOGIC IN MSTicEntry.CalcBasisTotal PROCEDURE --
							IF @DiscountOpt = 2 AND @DiscountType = 'R'
								BEGIN
									SET @DiscountOffered = ISNULL(@SurchargeTotal * @DiscountRate, 0)
									SET @TaxDiscount = ISNULL(@DiscountOffered * @TaxRate, 0)
								END
						END -- IF @DiscountsYN = 'Y'
						
					----------------
					-- CALC TAXES --
					----------------	
					-- MATERIAL TAXABLE ? --
					SELECT @MatlTaxable = ISNULL(Taxable, 'N')
					  FROM HQMT
					 WHERE MatlGroup = @MatlGroup
					   AND Material = @Material
						   				
					-- BOTH MATERIAL AND SURCHARGE MUST BE TAXABLE --
					IF @MatlTaxable = 'Y' AND ISNULL(@SurchargeTaxable, 'N') = 'Y'
						BEGIN
							SET @TaxBasis = @SurchargeTotal
							SET @TaxTotal = @TaxBasis * @TaxRate
						END	
								
					   	
					--------------------------------------			
					-- INSERT RECORD INTO bMSSurcharges --
					--------------------------------------					
					INSERT INTO bMSSurcharges(Co, Mth, BatchId, BatchSeq, BatchTransType, UM,
												SurchargeSeq, SurchargeCode, SurchargeMaterial, 
												SurchargeBasis, SurchargeRate, SurchargeTotal, 
												TaxBasis, TaxTotal, DiscountOffered, TaxDiscount,
												MSTBKeyID)
						 VALUES (@MSCo, @Mth, @BatchID, @BatchSeq, 'A', @SurchargeUM,
												@SurchargeSeq, @SurchargeCode, @SurchargeMaterial,
												@SurchargeBasisAmt, @SurchargeRate, @SurchargeTotal,
												@TaxBasis, @TaxTotal, @DiscountOffered, @TaxDiscount,
												@MSTBKeyID)

					-- RESET CODE --
					SET @rcode = 0
				END
			
			-- UPDATE ROW COUNT --
			SET @RowCnt = @RowCnt + 1
		END 


	-----------------
	-- END ROUTINE --
	-----------------
	vspexit:

		IF @rcode <> 0 
			SET @msg = ISNULL(@msg,'')
			
		RETURN @rcode



GO
GRANT EXECUTE ON  [dbo].[vspMSSurchargeAutoCreate] TO [public]
GO
