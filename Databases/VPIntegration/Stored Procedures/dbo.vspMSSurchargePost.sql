SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*************************************
* Created By:  DAN SO 10/12/2009 - ISSUE #129350
* Modified By:  Mark H 10/21/2010 - Issue #141538.  Need to allow for a negative surcharge/pay total.
*
*
* USAGE:	Cycle through all Surcharges associated with a batch and "post" them into MSTB to be
*			processed/posted like a normal MS Tickets into MSTD. 
*			Surcharges will be in bMSTB only briefly while a batch of MS Tickets are posting.  They
*			will usually be located in bMSSurcharges or bMSTD
*		
*
* INPUT PARAMETERS
*	@msco				MS Company
*	@Mth				Batch Month
*	@BatchID			Batch ID
*	
*
* OUTPUT PARAMETERS
*	@msg				Error message
*   
* RETURN VALUE
*   0         Success
*   1         Failure
*
**************************************/
--CREATE PROC [dbo].[vspMSSurchargePost]
CREATE  PROC [dbo].[vspMSSurchargePost]
 
(@msco bCompany = NULL, @Mth bMonth = NULL, @BatchID bBatchID = NULL,
 @msg varchar(MAX) = NULL output)
 

AS
SET NOCOUNT ON

	DECLARE	@rcode				int,
			@MSTrans			bTrans,
			@BatchTransType		char(1),
			@SaleType			char(1),
			@PayCode			bPayCode,
			@RevCode			bRevCode,
			@SurchargeCode		smallint,	
			@SurchargeMaterial	bMatl,
			@SurchargeBasis		bUnits,
			@SurchargeRate		bUnitCost,
			@SurchargeTotal		bDollar,
			@TaxBasis			bUnits,
			@TaxTotal			bDollar,
			@SurchargeUM		bUM,
			@FromLoc			bLoc,
			@TruckType			varchar(10),
			@Truck				bTruck,
			@Zone				varchar(10),
			@VendorGroup		bGroup,
			@HaulerType			char(1),
			@HaulVendor			bVendor,
			@MatlGroup			bGroup,
			@Category			varchar(10),
			@EMCo				bCompany,
			@EMGroup			bGroup,
			@Equipment			bEquip,	
			@JCCo				bCompany,		
			@Job				bJob,	
			@HaulCode			bHaulCode,	
			@Hours				bHrs,			-- NOT USED - PLACE HOLDER
			@RevBasisAmt		bUnits,			-- NOT USED - PLACE HOLDER
			@RevBasis			bUnits,			
			@RevRate			bUnitCost,
			@RevTotal			bDollar,
			@Basis				char(1),		-- NOT USED - PLACE HOLDER
			@BasisToolTip		varchar(255),	-- NOT USED - PLACE HOLDER 
			@TotalToolTip		varchar(255),	-- NOT USED - PLACE HOLDER
			@HaulBased			bYN,			-- NOT USED - PLACE HOLDER
			@HaulUM				bUM,			-- NOT USED - PLACE HOLDER
			@AllowRateOride		bYN,			-- NOT USED - PLACE HOLDER
			@MSTBKeyID			bigint,
			@MSTDKeyID			bigint,
			@MSSurKeyID			bigint,
			@BatchSeq			int,
			@LocGroup			bGroup,
			@DiscountRate		bRate,
			@DiscountOffered	bDollar,
			@TaxDiscount		bDollar,
			@PayRate			bRate,
			@PayBasis			bUnits,
			@PayMinAmt			bDollar,
			@PayTotal			bDollar,
			@PMatlPhase			bPhase,			-- PARENT TICKET MatlPhase
			@PMatlCT			bJCCType,		-- PARENT TICKET MatlCT
			@PHaulPhase			bPhase,			-- PARENT TICKET HaulPhase
			@PHaulCT			bJCCType,		-- PARENT TICKET HaulCT
			@MatlPhase			bPhase,			
			@MatlCT				bJCCType,
			@HaulPhase			bPhase,
			@HaulCT				bJCCType,
			@TotalSurchargeVal	bDollar,		-- (SurchargeTotal + TaxTotal) - (DiscountOffered + TaxDiscount)
			@RowCnt				int,
			@NumRows			int,
			@StartSeq			int,
			@TempMsg			varchar(255),
			@RetCode			int
			
	
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
	
	------------------
	-- PRIME VALUES --
	------------------
	SET @rcode = 0
	SET @RowCnt = 1
	SET @BatchSeq = 0
	SET @StartSeq = 0	
			
			
	----------------------------------
	-- PROCESSING SURCHARGE RECORDS --
	----------------------------------
	
	----------------------------------------
	-- CREATE/LOAD @SurchargesTable TABLE --
	----------------------------------------
	-- CREATE TABLE --										
	DECLARE @SurchargesTable TABLE
		(	
			RowID				int			IDENTITY(1,1),	
			BatchTransType		char(1),
			SaleType			char(1),
			PayCode				bPayCode	NULL,
			RevCode				bRevCode	NULL,
			SurchargeCode		smallint,
			SurchargeMaterial	bMatl,
			SurchargeBasis		bUnits,
			SurchargeRate		bUnitCost,
			SurchargeTotal		bDollar,
			TaxBasis			bUnits,
			TaxTotal			bDollar,
			SurchargeUM			bUM			NULL,		
			FromLoc				bLoc,
			TruckType			varchar(10),
			Truck				bTruck,
			Zone				varchar(10),
			VendorGroup			bGroup,
			HaulerType			char(1),
			HaulVendor			bVendor		NULL,
			MatlGroup			bGroup,
			Category			varchar(10),
			LocGroup			bGroup,
			EMCo				bCompany	NULL,
			EMGroup				bGroup		NULL,		
			Equipment			bEquip		NULL,
			JCCo				bCompany	NULL,
			Job					bJob		NULL,
			HaulCode			bHaulCode	NULL,
			PMatlPhase			bPhase		NULL,
			PMatlCT				bJCCType	NULL,
			PHaulPhase			bPhase		NULL,
			PHaulCT				bJCCType	NULL,
			DiscountRate		bRate,
			DiscountOffered		bDollar,
			TaxDiscount			bDollar,
			MSTBKeyID			bigint,
			MSTDKeyID			bigint,
			MSSurKeyID			bigint
		)
		  
	-- LOAD TABLE --   
	INSERT INTO @SurchargesTable (BatchTransType, SaleType, PayCode, RevCode, 
								SurchargeCode, SurchargeMaterial, SurchargeBasis, 
								SurchargeRate, SurchargeTotal, TaxBasis, TaxTotal, 
								SurchargeUM, FromLoc, TruckType, Truck, Zone, 
								VendorGroup, HaulerType, HaulVendor, MatlGroup, 
								Category, LocGroup, EMCo, EMGroup, Equipment, 
								JCCo, Job, HaulCode, PMatlPhase, PMatlCT, 
								PHaulPhase, PHaulCT, DiscountRate, DiscountOffered, 
								TaxDiscount, MSTBKeyID, MSTDKeyID, MSSurKeyID)
	SELECT	s.BatchTransType, b.SaleType, c.PayCode, c.RevCode, s.SurchargeCode, s.SurchargeMaterial, 
			s.SurchargeBasis, s.SurchargeRate, s.SurchargeTotal, s.TaxBasis, s.TaxTotal, 
			s.UM, b.FromLoc, b.TruckType, b.Truck, b.Zone, b.VendorGroup, b.HaulerType, b.HaulVendor,
			t.MatlGroup, t.Category, m.LocGroup, b.EMCo, b.EMGroup, b.Equipment, b.JCCo, b.Job,
			b.HaulCode, b.MatlPhase, b.MatlJCCType, b.HaulPhase, b.HaulJCCType,
			b.DiscRate, ISNULL(s.DiscountOffered, 0), ISNULL(s.TaxDiscount, 0),
			b.KeyID, s.MSTDKeyID, s.KeyID
	  FROM	bMSTB b WITH (NOLOCK)
	  JOIN	bMSSurcharges s WITH (NOLOCK) ON s.MSTBKeyID = b.KeyID
	  JOIN  bMSSurchargeCodes c WITH (NOLOCK) ON c.MSCo = s.Co AND c.SurchargeCode = s.SurchargeCode
	  JOIN  bHQMT t WITH (NOLOCK) ON b.MatlGroup = t.MatlGroup AND s.SurchargeMaterial = t.Material
	  JOIN  bINLM m WITH (NOLOCK) ON m.INCo = b.Co AND m.Loc = b.FromLoc
	 WHERE	b.Co = @msco
	   AND	b.Mth = @Mth
	   AND	b.BatchId = @BatchID
	    
	    
	-- GET THE NUMBER OF ROWS FOR LOOP --
	SELECT @NumRows = COUNT(*) FROM @SurchargesTable
	       
	-------------------------------
	-- GET LAST BATCH SEQ NUMBER --
	-------------------------------
	SELECT @StartSeq = MAX(BatchSeq)
	  FROM MSTB WITH (NOLOCK)
	 WHERE Co = @msco
	   AND Mth = @Mth
	   AND BatchId = @BatchID 
   
	--------------------------------------------------------
	-- SET BATCH STATUS TO 0 TO GET THROUGH MSTBi TRIGGER --
	--------------------------------------------------------
	UPDATE bHQBC SET [Status] = 0 WHERE Co = @msco AND Mth = @Mth AND BatchId = @BatchID

	---------------------------------
	-- LOOP THROUGH ALL SURCHARGES --
	---------------------------------
	WHILE @RowCnt <= @NumRows
		BEGIN
										
			-- GET RECORD --			   		
			SELECT	@BatchTransType = BatchTransType, @SaleType = SaleType, @PayCode = PayCode, @RevCode = RevCode, 
					@SurchargeCode = SurchargeCode, @SurchargeMaterial = SurchargeMaterial, @SurchargeBasis = SurchargeBasis, 
					@SurchargeRate = SurchargeRate, @SurchargeTotal = SurchargeTotal, @TaxBasis = TaxBasis, @TaxTotal = TaxTotal, 
					@SurchargeUM = SurchargeUM, @FromLoc = FromLoc, @TruckType = TruckType, @Truck = Truck, @Zone = Zone, 
					@VendorGroup = VendorGroup, @HaulerType = HaulerType, @HaulVendor = HaulVendor, @MatlGroup = MatlGroup,	
					@Category = Category, @LocGroup = LocGroup, @EMCo = EMCo, @EMGroup = EMGroup, @Equipment = Equipment, 
					@JCCo = JCCo, @Job = Job, @HaulCode = HaulCode, @PMatlPhase = PMatlPhase, @PMatlCT = PMatlCT, 
					@PHaulPhase = PHaulPhase, @PHaulCT = PHaulCT, @DiscountRate = DiscountRate, @DiscountOffered = DiscountOffered, 
					@TaxDiscount = TaxDiscount, @MSTBKeyID = MSTBKeyID, @MSTDKeyID = MSTDKeyID, @MSSurKeyID = MSSurKeyID
			  FROM  @SurchargesTable
			 WHERE	RowID = @RowCnt
			
			
			--------------------------------
			-- CALC TOTAL SURCHARGE VALUE --
			--------------------------------
			SET @TotalSurchargeVal = ISNULL((@SurchargeTotal + @TaxTotal) - (@DiscountOffered + @TaxDiscount), 0)
			
			--------------------------------------------
			-- CALC PAY INFORMATION FOR HAULER VENDOR --
			--------------------------------------------
			IF @HaulerType = 'H' AND @PayCode IS NOT NULL
				BEGIN

					-- PRIME PAY INFORMATION --
					SET @PayBasis = @TotalSurchargeVal	
					SET @PayTotal = 0
					SET @PayMinAmt = 0
					SET @RetCode = 0
					
					-- GET PAY RATE --
					EXEC @RetCode = dbo.bspMSTicPayCodeRateGet @msco, @PayCode, @MatlGroup, @SurchargeMaterial, 
															@Category, @LocGroup, @FromLoc, NULL, @TruckType, 
															@VendorGroup, @HaulVendor, @Truck, @SurchargeUM, 
															@Zone, 1,
															@PayRate output, @PayMinAmt output, @TempMsg output

															
					-- CHECK FOR SUCCESS --
					IF @RetCode <> 0 
						BEGIN
							Set @msg = 'SurchargeCode: ' + ISNULL(CAST(@SurchargeCode as varchar(3)), 'N/A') 
														+ ' - PayCode: ' + ISNULL(@PayCode, 'N/A') 
														+ ' - ' + ISNULL(@TempMsg, 'NA')
							SET @rcode = 1
							GOTO vspexit
						END
						
					-- DETERMINE CORRECT PAY --
					SET @PayTotal = ISNULL(@PayBasis * @PayRate, 0)
					
					--141538 - Ignore Minimum Amount check if Pay Code's min amt is 0 or negative.
					IF (@PayMinAmt is not null) and (@PayMinAmt > 0)
					BEGIN
						IF @PayTotal < @PayMinAmt
							SET @PayTotal = @PayMinAmt
					END
					
				END	
			ELSE
				BEGIN
					-- RESET VALUES --
					SET @PayCode = NULL
					SET @PayBasis = NULL
					SET @PayRate = NULL
					SET @PayTotal = NULL	
				END -- IF @HaulerType = 'H' .....
					
					
			--------------------------------------------
			-- CALC REVENUE INFORMATION FOR EQUIPMENT --
			--------------------------------------------
			IF @HaulerType = 'E' AND @RevCode IS NOT NULL
				BEGIN
	
					-- PRIME REV INFORMATION --
					SET @RevBasis = @TotalSurchargeVal	
					SET @RevRate = 0
					SET @RevTotal = 0
					SET @RetCode = 0
					SET @Hours = 0 -- not used
					
					-- GET REV RATE --
					EXEC @RetCode = dbo.bspMSTicRevCodeVal @msco, @EMCo, @EMGroup, @RevCode, @Equipment, @Category,
														@JCCo, @Job, @MatlGroup, @SurchargeMaterial, @FromLoc, 
														@SurchargeBasis, @SurchargeRate, @Hours,
														@RevBasisAmt output, @RevRate output, @Basis output, 
														@BasisToolTip output, @TotalToolTip output, @HaulCode, 
														@HaulBased output, @HaulUM, @AllowRateOride output,
														@TempMsg output					
					
					-- CHECK FOR SUCCESS --
					IF @RetCode <> 0 
						BEGIN
							Set @msg = 'SurchargeCode: ' + ISNULL(CAST(@SurchargeCode as varchar(3)), 'N/A') 
														+ ' - RevCode: ' + ISNULL(@RevCode, 'N/A') 
														+ ' - ' + ISNULL(@TempMsg, 'NA')
							SET @rcode = 1
							GOTO vspexit
						END
						
					-- CALC REV TOTAL --
					SET @RevTotal = ISNULL(@RevRate * @RevBasis, 0)
					
				END	
			ELSE
				BEGIN
					-- RESET VALUES --
					SET @RevCode = NULL
					SET @RevBasis = NULL
					SET @RevRate = NULL
					SET @RevTotal = NULL				
				END -- IF @HaulerType = 'E' ...
					
							
			-------------------------------------------
			-- DETERIMINE PHASE AND COST TYPE VALUES --
			-------------------------------------------
			IF @SaleType = 'J'
				BEGIN
						
					-- DETERMINE PHASE AND COST TYPE -- 
					-- USE SurchargeMaterial VALUES - ELSE - USE PARENT TICKET VALUES
					SELECT  @MatlPhase = ISNULL(MatlPhase, @PMatlPhase), @MatlCT = ISNULL(MatlJCCostType, @PMatlCT),
							@HaulPhase = ISNULL(HaulPhase, @PHaulPhase), @HaulCT = ISNULL(HaulJCCostType, @PHaulCT)
					  FROM  bHQMT WITH (NOLOCK)
					 WHERE  MatlGroup = @MatlGroup
					   AND  Material = @SurchargeMaterial					   			   		

					-- REMOVE HAUL VALUES --
					IF @HaulerType = 'N'
						BEGIN
							SET @HaulPhase = NULL
							SET @HaulCT = NULL
						END
				END 
			ELSE
				BEGIN
					-- RESET VALUES --
					SET @MatlPhase = NULL
					SET @MatlCT = NULL
					SET @HaulPhase = NULL
					SET @HaulCT = NULL						
				END	-- IF @SaleType = 'J'			
					
									
			-----------------
			-- BEGIN TRANS --
			-----------------
			BEGIN TRANSACTION
			
				-- NEW BATCH SEQ NUMBER --
				SET @BatchSeq = @StartSeq + @RowCnt		

				--------------------------------
				-- ADD A NEW SURCHARGE RECORD --
				--------------------------------
				IF @BatchTransType = ('A')
					BEGIN				

						-- CREATE SURCHARGE RECORD WITH MOST OF THE ORIGINAL TICKET INFORMATION --
						INSERT INTO bMSTB	 
								(Co, Mth, BatchId, BatchSeq, BatchTransType, MSTrans, SaleDate, FromLoc, Ticket, 
								VendorGroup, MatlVendor, SaleType, CustGroup, Customer, CustJob, CustPO, PaymentType, 
								CheckNo, Hold, JCCo, Job, PhaseGroup, INCo, ToLoc, MatlGroup, Material, UM, MatlPhase, 
								MatlJCCType, GrossWght, TareWght, WghtUM, MatlUnits, UnitPrice, ECM, MatlTotal, MatlCost, 
								HaulerType, HaulVendor, Truck, Driver, EMCo, Equipment, EMGroup, PRCo, Employee, TruckType, 
								StartTime, StopTime, Loads, Miles, Hours, Zone, HaulCode, HaulPhase, HaulJCCType, HaulBasis, 
								HaulRate, HaulTotal, PayCode, PayBasis, PayRate, PayTotal, RevCode, RevBasis, RevRate, RevTotal, 
								TaxGroup, TaxCode, TaxType, TaxBasis, TaxTotal, DiscBasis, 	DiscRate, DiscOff, TaxDisc, Void, 
								OldSaleDate, OldTic, OldFromLoc, OldVendorGroup, OldMatlVendor, OldSaleType, OldCustGroup, 
								OldCustomer, OldCustJob, OldCustPO, OldPaymentType, OldCheckNo, OldHold, OldJCCo, OldJob, 
								OldPhaseGroup, OldINCo, OldToLoc, OldMatlGroup, OldMaterial, OldUM, OldMatlPhase, OldMatlJCCType, 
								OldGrossWght, OldTareWght, OldWghtUM, OldMatlUnits, OldUnitPrice, OldECM, OldMatlTotal, OldMatlCost, 
								OldHaulerType, OldHaulVendor, OldTruck, OldDriver, OldEMCo, OldEquipment, OldEMGroup, OldPRCo, 
								OldEmployee, OldTruckType, OldStartTime, OldStopTime, OldLoads, OldMiles, OldHours, OldZone, 
								OldHaulCode, OldHaulPhase, OldHaulJCCType, OldHaulBasis, OldHaulRate, OldHaulTotal, OldPayCode, 
								OldPayBasis, OldPayRate, OldPayTotal, OldRevCode, OldRevBasis, OldRevRate, OldRevTotal, OldTaxGroup, 
								OldTaxCode, OldTaxType, OldTaxBasis, OldTaxTotal, OldDiscBasis, OldDiscRate, OldDiscOff, OldTaxDisc, 
								OldVoid, OldMSInv, OldAPRef, OldVerifyHaul, Changed, OldReasonCode, ReasonCode, ShipAddress, City, 
								State, Zip, OldShipAddress, OldCity, OldState, OldZip, UniqueAttchID, APCo, APMth, OldAPCo, OldAPMth, 
								MatlAPCo, MatlAPMth, MatlAPRef, OldMatlAPCo, OldMatlAPMth, OldMatlAPRef, OrigMSTrans, Country, OldCountry, 
								SurchargeKeyID, SurchargeCode, SurchargeBasis, SurchargeRate)	
						SELECT		  
								Co, Mth, BatchId, @BatchSeq, @BatchTransType, NULL, SaleDate, FromLoc, Ticket, VendorGroup, 
								NULL, SaleType, CustGroup, Customer, CustJob, CustPO, PaymentType, CheckNo, Hold, JCCo, Job, 
								PhaseGroup, INCo, ToLoc, MatlGroup, @SurchargeMaterial, @SurchargeUM, @MatlPhase, @MatlCT, ISNULL(GrossWght, 0), 
								ISNULL(TareWght, 0), WghtUM, ISNULL(@SurchargeBasis, 0), ISNULL(@SurchargeRate, 0), ECM, ISNULL(@SurchargeTotal, 0), 
								0, HaulerType, @HaulVendor, Truck, Driver, EMCo, Equipment, EMGroup, PRCo, Employee, 
								TruckType, StartTime, StopTime, ISNULL(Loads, 0), ISNULL(Miles, 0), ISNULL(Hours, 0), Zone, HaulCode, 
								@HaulPhase, @HaulCT, 0,0,0,/*ISNULL(HaulBasis, 0), ISNULL(HaulRate, 0), ISNULL(HaulTotal, 0),*/ 
								@PayCode, @PayBasis, @PayRate, @PayTotal, @RevCode, @RevBasis, @RevRate, @RevTotal,
								TaxGroup, TaxCode, TaxType, ISNULL(@TaxBasis, 0), ISNULL(@TaxTotal, 0), ISNULL(@SurchargeBasis, 0), 
								ISNULL(@DiscountRate, 0), ISNULL(@DiscountOffered, 0), ISNULL(@TaxDiscount, 0), Void, 
								OldSaleDate, OldTic, OldFromLoc, OldVendorGroup, OldMatlVendor, OldSaleType, OldCustGroup, OldCustomer, 
								OldCustJob, OldCustPO, OldPaymentType, OldCheckNo, OldHold, OldJCCo, OldJob, OldPhaseGroup, OldINCo, OldToLoc, 
								OldMatlGroup, OldMaterial, OldUM, OldMatlPhase, OldMatlJCCType, OldGrossWght, OldTareWght, OldWghtUM, 
								OldMatlUnits, OldUnitPrice, OldECM, OldMatlTotal, 0, OldHaulerType, OldHaulVendor, OldTruck, 
								OldDriver, OldEMCo, OldEquipment, OldEMGroup, OldPRCo, OldEmployee, OldTruckType, OldStartTime, OldStopTime, 
								OldLoads, OldMiles, OldHours, OldZone, OldHaulCode, OldHaulPhase, OldHaulJCCType, OldHaulBasis, OldHaulRate, 
								OldHaulTotal, OldPayCode, OldPayBasis, OldPayRate, OldPayTotal, OldRevCode, OldRevBasis, OldRevRate, OldRevTotal, 
								OldTaxGroup, OldTaxCode, OldTaxType, OldTaxBasis, OldTaxTotal, OldDiscBasis, OldDiscRate, OldDiscOff, OldTaxDisc, 
								OldVoid, OldMSInv, OldAPRef, OldVerifyHaul, Changed, OldReasonCode, ReasonCode, ShipAddress, City, State, Zip, 
								OldShipAddress, OldCity, OldState, OldZip, NULL, APCo, APMth, OldAPCo, OldAPMth, MatlAPCo, MatlAPMth, 
								MatlAPRef, OldMatlAPCo, OldMatlAPMth, OldMatlAPRef, OrigMSTrans, Country, OldCountry, 
								@MSTBKeyID, @SurchargeCode, ISNULL(@SurchargeBasis, 0), ISNULL(@SurchargeRate, 0)
						FROM	bMSTB WITH (NOLOCK)
						WHERE	KeyID = @MSTBKeyID
					

					END	--IF @BatchTransType = ('A')

				-----------------------------
				-- MODIFY SURCHARGE RECORD --
				-----------------------------
				IF @BatchTransType IN ('C', 'D')
					BEGIN	
						
						-- GET MSTrans NUMBER -- NOT NULL WHEN @BatchTransType = 'C,D' --
						SELECT @MSTrans = MSTrans FROM bMSTD WITH (NOLOCK) WHERE KeyID = @MSTDKeyID

						INSERT INTO bMSTB	 
								(Co, Mth, BatchId, BatchSeq, BatchTransType, MSTrans, SaleDate, FromLoc, Ticket, 
								VendorGroup, MatlVendor, SaleType, CustGroup, Customer, CustJob, CustPO, PaymentType, 
								CheckNo, Hold, JCCo, Job, PhaseGroup, INCo, ToLoc, MatlGroup, Material, UM, MatlPhase, 
								MatlJCCType, GrossWght, TareWght, WghtUM, MatlUnits, UnitPrice, ECM, MatlTotal, MatlCost, 
								HaulerType, HaulVendor, Truck, Driver, EMCo, Equipment, EMGroup, PRCo, Employee, TruckType, 
								StartTime, StopTime, Loads, Miles, Hours, Zone, HaulCode, HaulPhase, HaulJCCType, HaulBasis, 
								HaulRate, HaulTotal, PayCode, PayBasis, PayRate, PayTotal, RevCode, RevBasis, RevRate, RevTotal, 
								TaxGroup, TaxCode, TaxType, TaxBasis, TaxTotal, DiscBasis, 	DiscRate, DiscOff, TaxDisc, Void, 
								OldSaleDate, OldTic, OldFromLoc, OldVendorGroup, OldMatlVendor, OldSaleType, OldCustGroup, 
								OldCustomer, OldCustJob, OldCustPO, OldPaymentType, OldCheckNo, OldHold, OldJCCo, OldJob, 
								OldPhaseGroup, OldINCo, OldToLoc, OldMatlGroup, OldMaterial, OldUM, OldMatlPhase, OldMatlJCCType, 
								OldGrossWght, OldTareWght, OldWghtUM, OldMatlUnits, OldUnitPrice, OldECM, OldMatlTotal, OldMatlCost, 
								OldHaulerType, OldHaulVendor, OldTruck, OldDriver, OldEMCo, OldEquipment, OldEMGroup, OldPRCo, 
								OldEmployee, OldTruckType, OldStartTime, OldStopTime, OldLoads, OldMiles, OldHours, OldZone, 
								OldHaulCode, OldHaulPhase, OldHaulJCCType, OldHaulBasis, OldHaulRate, OldHaulTotal, OldPayCode, 
								OldPayBasis, OldPayRate, OldPayTotal, OldRevCode, OldRevBasis, OldRevRate, OldRevTotal, OldTaxGroup, 
								OldTaxCode, OldTaxType, OldTaxBasis, OldTaxTotal, OldDiscBasis, OldDiscRate, OldDiscOff, OldTaxDisc, 
								OldVoid, OldMSInv, OldAPRef, OldVerifyHaul, Changed, OldReasonCode, ReasonCode, ShipAddress, City, 
								State, Zip, OldShipAddress, OldCity, OldState, OldZip, UniqueAttchID, APCo, APMth, OldAPCo, OldAPMth, 
								MatlAPCo, MatlAPMth, MatlAPRef, OldMatlAPCo, OldMatlAPMth, OldMatlAPRef, OrigMSTrans, Country, OldCountry, 
								SurchargeKeyID, SurchargeCode, SurchargeBasis, SurchargeRate)	
						SELECT		  
								b.Co, b.Mth, b.BatchId, @BatchSeq, @BatchTransType, d.MSTrans, b.SaleDate, b.FromLoc, b.Ticket, b.VendorGroup, 
								NULL, b.SaleType, b.CustGroup, b.Customer, b.CustJob, b.CustPO, b.PaymentType, b.CheckNo, b.Hold, b.JCCo, b.Job, 
								b.PhaseGroup, b.INCo, b.ToLoc, b.MatlGroup, @SurchargeMaterial, @SurchargeUM, @MatlPhase, @MatlCT, ISNULL(b.GrossWght, 0), 
								ISNULL(b.TareWght, 0), b.WghtUM, ISNULL(@SurchargeBasis, 0), ISNULL(@SurchargeRate, 0), b.ECM, ISNULL(@SurchargeTotal, 0), 
								0, b.HaulerType, @HaulVendor, b.Truck, b.Driver, b.EMCo, b.Equipment, b.EMGroup, b.PRCo, b.Employee, 
								b.TruckType, b.StartTime, b.StopTime, ISNULL(b.Loads, 0), ISNULL(b.Miles, 0), ISNULL(b.Hours, 0), b.Zone, b.HaulCode, 
								@HaulPhase, @HaulCT, 0,0,0,/*ISNULL(HaulBasis, 0), ISNULL(HaulRate, 0), ISNULL(HaulTotal, 0),*/ 
								@PayCode, @PayBasis, @PayRate, @PayTotal, @RevCode, @RevBasis, @RevRate, @RevTotal,
								b.TaxGroup, b.TaxCode, b.TaxType, ISNULL(@TaxBasis, 0), ISNULL(@TaxTotal, 0), ISNULL(@SurchargeBasis, 0), 
								ISNULL(@DiscountRate, 0), ISNULL(@DiscountOffered, 0), ISNULL(@TaxDiscount, 0), b.Void, 
								OldSaleDate, OldTic, OldFromLoc, OldVendorGroup, OldMatlVendor, OldSaleType, OldCustGroup, OldCustomer, 
								OldCustJob, OldCustPO, OldPaymentType, OldCheckNo, OldHold, OldJCCo, OldJob, OldPhaseGroup, OldINCo, OldToLoc, 
								OldMatlGroup, d.Material, d.UM, d.MatlPhase, d.MatlJCCType, OldGrossWght, OldTareWght, OldWghtUM, 
								d.MatlUnits, d.UnitPrice, OldECM, d.MatlTotal, 0, OldHaulerType, OldHaulVendor, OldTruck, 
								OldDriver, OldEMCo, OldEquipment, OldEMGroup, OldPRCo, OldEmployee, OldTruckType, OldStartTime, OldStopTime, 
								OldLoads, OldMiles, OldHours, OldZone, OldHaulCode, d.HaulPhase, d. HaulJCCType, 0, 0, 0,  
								d.PayCode, d.PayBasis, d.PayRate, d.PayTotal, d.RevCode, d.RevBasis, d.RevRate, d.RevTotal, 
								OldTaxGroup, OldTaxCode, OldTaxType, d.TaxBasis, d.TaxTotal, d.DiscBasis, d.DiscRate, d.DiscOff, d.TaxDisc, 
								OldVoid, OldMSInv, OldAPRef, OldVerifyHaul, d.Changed, OldReasonCode, d.ReasonCode, d.ShipAddress, d.City, d.State, d.Zip, 
								OldShipAddress, OldCity, OldState, OldZip, NULL, d.APCo, d.APMth, OldAPCo, OldAPMth, d.MatlAPCo, d.MatlAPMth, 
								d.MatlAPRef, OldMatlAPCo, OldMatlAPMth, OldMatlAPRef, OrigMSTrans, b.Country, d.Country,
								@MSTBKeyID, @SurchargeCode, ISNULL(@SurchargeBasis, 0), ISNULL(@SurchargeRate, 0)
						  FROM  bMSTB b WITH (NOLOCK)
						  JOIN	bMSSurcharges s WITH (NOLOCK) ON b.KeyID = s.MSTBKeyID
						  JOIN  bMSTD d WITH (NOLOCK) ON s.MSTDKeyID = d.KeyID
						 WHERE  d.KeyID = @MSTDKeyID											
											
					END --IF @BatchTransType in ('C', 'D')			
			
			------------------
			-- COMMIT TRANS --
			------------------
			COMMIT TRANSACTION
					
					
			-- UPDATE ROW COUNT --
			SET @RowCnt = @RowCnt + 1
			


		END -- WHILE @RowCnt <= @NumRows
		
	-----------------
	-- END ROUTINE --
	-----------------
	vspexit:
		
		IF @rcode <> 0 
			SET @msg = 'Error Posting Surcharges - ' + isnull(@msg,'')
						
		RETURN @rcode
		
		
		
		


GO
GRANT EXECUTE ON  [dbo].[vspMSSurchargePost] TO [public]
GO
