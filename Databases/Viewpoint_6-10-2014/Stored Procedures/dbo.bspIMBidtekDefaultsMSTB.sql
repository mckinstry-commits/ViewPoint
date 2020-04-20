SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[bspIMBidtekDefaultsMSTB]
        /***********************************************************
         * CREATED BY:  Danf
         * MODIFIED BY: danf 01/22/02 Correct min amt default on ticket.
         *              DANF 03/19/02 - Added Record Type
         *              danf 04/11/02 - Issue 16910
         *              DANF 04/16/02 - Added X for Credit card like C for Cash
         *              DANF 04/23/02 - Corrected Paycode and Haul tax basis.
         *              DANF 05/13/02 - Corrected Haul/Revenue Rate, Basis, and Total when based on each other.
         *              DANF 07/01/02 - Issue 17380 - Do not remove Customer Group if Sales Type is J or I.
         *			    GG 08/12/02 = #17811 - old/new template prices, pass @SaleDate to bspMSTicMatlVal
         *			    SR 09/25/02 = #18693 - put isnull around @HaulCode and @TaxCode on calculating @TaxBasis
         *              DANF 10/24/02 = #19110 - Set Void to 'N' if not N or Y along with hold add Hauler Type Default.
         *              DANF 12/31/02 = onhand parameter missing from bspMSTicMatlVal Added... 
         *              bc   02/06/03 - fix to issue #18693
         *			    DANF 02/12/03 - 20367 - Add isnull around Material, Truck, HaulVandor, and Equipment
         * 		        DANF 02/14/03 - Added removal of truck and driver when haul vendor is null or empty.
         *              DANF 03/10/03 - 20609 USE Metric flag from MS Quotes for UM default
         *			    DANF 03/27/03 - Correct tax discount amount when tax code is null.
         *			    DANF 04/04/03 - 20918 Correct Hauler Type default.
         * 		        DANF 05/12/03 - 20376 Remove use metric um default
         *			    RBT  07/07/03 - 21738 Fix UnitPrice and UM not defaulting, send 'Y' to bspMSTicMatlVal parm #2.
         *			    RBT  07/08/03 - 21286 Correct Haul Total inclusion/exclusion for TaxBasis. Also added "with (nolock)"
         *								to multiple select statements.
         *			    RBT  07/29/03 - 21256 Check metric flag and convert units if needed.
         * 		        DANF 08/04/03 - 21996 Correct Vendor used for returning correct pay rate by haul vendor.
         *			    RBT  08/05/03 - 22050 Correct decimal conversion for GrossWght,TareWght,MatlUnits,UnitPrice,MatlTotal.
         *			    RBT  09/09/03 - 21346 Default Haul Phase to Matl Phase for Viewpoint Default if no haul phase.
         *				GF   11/05/03 - 18762 - added output param to bspMSTicTemplate
         *				RBT  01/09/04 - 23460 Change metric conversion to divide by factor instead of multiplying.
         *				RBT  06/07/04 - 24724 Move UnitPrice, UM, and MatlTotal metric conversion inside default check.
         *				RBT  07/09/04 - 25074 Fix metric conversion for UnitPrice.
         *				RBT  07/15/04 - 25084 Fix for haul rate override by phase, restore Gil's code from #21141.
         *				RBT  07/16/04 - 25139 Re-link UM and UnitPrice for metric conversion. Only default UM if blank.
         *				RBT  07/19/04 - 25079 Get haul code from quote if exists, add variable @quotehaulcode.
         *				RBT  02/21/05 - 27204 Clear RevBasis, RevRate, RevTotal defaults before sp call, fix "if" statement.
     	 *				RBT  03/28/05 - 27490 Don't calc Hours if StartTime or StopTime is null.
    	 *				RBT  05/02/05 - 28429 Fix UnitPrice default when phase set on quote but not in HQMT.
   		 *				RBT  07/18/05 - 29217 Reset @quotepaycode = null at end of each record.
		 *				DANF 04/10/07 - 122102 Recalculate PayBasis and Pay Total after Haul if Pay basis is based on the Haul total
	     *				DANF 08/06/08 - 125178 Correct Viewpoint defaultfor Hauler type of E.
		 *				GF 03/03/2008 - issue #127261 - added output parameter HQPT.DiscOpt
		 *				CC	 04/14/08 - 127776 Retrieve EM Group only for Equipment records 
		 *				CC	 04/28/08 - 128019 Retrieve default price for material only if Material Vendor is null
		 *				GP	 04/29/08 - 127970 Added output parameter @returnvendor where calling bspMSTicTruckVal
		 *				DAN SO 05/22/08 - 28688 - Added @payminamt to bspMSTicPayCodeVal call
		 *				GP	 06/17/2008 - 127986 - Added @MatlVendor and @VendorGroup to bspMSTicMatlPriceGet call
		 *				GF 07/14/2008 - issue #128290 international GST/PST tax
		 *				DAN SO 10/29/08 - 130789 - Added output parameter @UpdateVendor where calling bspMSTicTruckVal
		 *				DAN SO 11/21/08 - 131171 - Removed IF statement and moved 'end' to include -> If @ynRevTotal ='Y'
		 *				CC	02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
		 *				DAN SO 05/25/09 - Issue #133679 - - Added input parameter @CurrentMode where calling bspMSTicTruckVal
		 *				CC  05/29/09 - Issue #133516 - Correct defaulting of Company
		 *				DAN SO 06/26/09 - Issue #134524 - Corrected DEFAULT FOR EMGroup
		 *				DAN SO 07/22/09 - Issue #133864 - IF MinAmt = 0 - then allow negative values
		 *				DAN SO 01/21/2010 - Issue #129350 - bspMSTicMatlVal has an added output parameter
		 *				GF 09/14/2010 - issue #141031 change TO USE FUNCTION vfDateOnly
		 *				AMR 01/12/11 - Issue #142350, making case sensitive by removing unused vars and renaming same named variables
		 *				GF 08/21/2012 TK-17302 IF sale = 'J' AND hauling AND no DEFAULT haul cost TYPE SET TO material costtype		
		 *				GF 08/22/2012 TK-17308 tax code DEFAULT incorrect WHEN tax OPTION 4 - delivery
		 *	
         *
         * Usage:
         *	Used by Imports to create values for needed or missing
         *      data based upon Bidtek default rules.
         *
         * Input params:
         *	@ImportId	Import Identifier
         *	@ImportTemplate	Import ImportTemplate
         *
         * Output params:
         *	@msg		error message
         *
         * Return code:
         *	0 = success, 1 = failure
         ************************************************************/
        
         (@Company bCompany, @ImportId varchar(20), @ImportTemplate varchar(20), @Form varchar(20), @rectype varchar(30), @msg varchar(120) output)
        
        as
        
        set nocount on
        
        declare @rcode int, @recode int, @desc varchar(120),
                @ynCo bYN, @ynMth bYN, @ynBatchId bYN, @ynBatchSeq bYN, @ynBatchTransType bYN, @ynSaleDate bYN, @ynFromLoc bYN, @ynTicket bYN,
                @ynVoid bYN, @ynVendorGroup bYN, @ynMatlVendor bYN, @ynSaleType bYN, @ynCustGroup bYN, @ynCustomer bYN, @ynCustJob bYN,
                @ynCustPO bYN, @ynPaymentType bYN, @ynCheckNo bYN, @ynHold bYN, @ynJCCo bYN, @ynPhaseGroup bYN, @ynJob bYN, @ynINCo bYN,
                @ynToLoc bYN, @ynMatlGroup bYN, @ynMaterial bYN, @ynUM bYN, @ynMatlPhase bYN, @ynMatlJCCType bYN, @ynHaulerType bYN, @ynEMCo bYN,
                @ynEMGroup bYN, @ynEquipment bYN, @ynPRCo bYN, @ynEmployee bYN, @ynHaulVendor bYN, @ynTruck bYN, @ynDriver bYN, @ynGrossWght bYN,
                @ynTareWght bYN, @ynWghtUM bYN, @ynMatlUnits bYN, @ynUnitPrice bYN, @ynECM bYN, @ynMatlTotal bYN, @ynTruckType bYN,
                @ynStartTime bYN, @ynStopTime bYN, @ynLoads bYN, @ynMiles bYN, @ynHours bYN, @ynZone bYN, @ynHaulCode bYN, @ynHaulPhase bYN,
                @ynHaulJCCType bYN, @ynHaulBasis bYN, @ynHaulRate bYN, @ynHaulTotal bYN, @ynRevCode bYN, @ynRevRate bYN, @ynRevBasis bYN,
                @ynRevTotal bYN, @ynPayCode bYN, @ynPayRate bYN, @ynPayBasis bYN, @ynPayTotal bYN, @ynTaxGroup bYN, @ynTaxCode bYN,
                @ynTaxType bYN, @ynTaxBasis bYN, @ynTaxTotal bYN, @ynDiscBasis bYN, @ynDiscRate bYN, @ynDiscOff bYN, @ynTaxDisc bYN,
        		@ynUMMetric bYN
        
        declare @CoID int, @MthID int, @BatchIdID int, @BatchSeqID int, @BatchTransTypeID int, @SaleDateID int, @FromLocID int, @TicketID int,
                @VoidID int, @VendorGroupID int, @MatlVendorID int, @SaleTypeID int, @CustGroupID int, @CustomerID int, @CustJobID int,
                @CustPOID int, @PaymentTypeID int, @CheckNoID int, @HoldID int, @JCCoID int, @PhaseGroupID int, @JobID int, @INCoID int,
                @ToLocID int, @MatlGroupID int, @MaterialID int, @UMID int, @MatlPhaseID int, @MatlJCCTypeID int, @HaulerTypeID int, @EMCoID int,
                @EMGroupID int, @EquipmentID int, @PRCoID int, @EmployeeID int, @HaulVendorID int, @TruckID int, @DriverID int, @GrossWghtID int,
                @TareWghtID int, @WghtUMID int, @MatlUnitsID int, @UnitPriceID int, @ECMID int, @MatlTotalID int, @TruckTypeID int,
                @StartTimeID int, @StopTimeID int, @LoadsID int, @MilesID int, @HoursID int, @ZoneID int, @HaulCodeID int, @HaulPhaseID int,
                @HaulJCCTypeID int, @HaulBasisID int, @HaulRateID int, @HaulTotalID int, @RevCodeID int, @RevRateID int, @RevBasisID int,
                @RevTotalID int, @PayCodeID int, @PayRateID int, @PayBasisID int, @PayTotalID int, @TaxGroupID int, @TaxCodeID int,
                @TaxTypeID int, @TaxBasisID int, @TaxTotalID int, @DiscBasisID int, @DiscRateID int, @DiscOffID int, @TaxDiscID int,
                @CompanyID int
        
        declare @salesum bUM, @paydisctype char(1), @paydiscrate bUnitCost, @matlphase bPhase, @matlct bJCCType,
                @haulphase bPhase, @haulct bJCCType, @netumconv bUnitCost, @matlumconv bUnitCost, @taxable bYN,
                @unitprice bUnitCost, @ecm bECM, @minamt bDollar, @haulcode bHaulCode,
                @quote varchar(10), @disctemplate smallint, @pricetemplate smallint, @netum bUM, @locgroup bGroup,
                @taxcode bTaxCode,@zone varchar(10), @haultaxopt tinyint, @ECMFact int, @defaultvalue varchar(20),
                @truckprco bCompany, @truckemployee bEmployee, @trucktype varchar(10), @trucktare bUnits, @truckrevcode bRevCode,
                @category bCat, @umconv bUnitCost, @revrate bUnitCost, @revbasisyn bYN, @revbasis bUnits, @taxrate bRate, @disctax bYN,
                @haulbasis tinyint, @haulrate bUnitCost,  @haulminamt bDollar, @payrate bUnitCost, @paybasis tinyint, @paycodeminamt bDollar,
                @quotepaycode bPayCode, @paycode bPayCode, @opencursor int, @Minutes bHrs, @HaulBased bYN, @RevBased bYN,
       		    @uploadum bUM, @matlcategory varchar(10), @quotehaulcode bHaulCode, @custpriceopt tinyint, @jobpriceopt tinyint, 
    			@invpriceopt tinyint, @priceopt tinyint, @tojcco bCompany, @country varchar(2)
        
        select @ynCo = 'N', @ynMth = 'N', @ynBatchId = 'N', @ynBatchSeq = 'N', @ynBatchTransType = 'N', @ynSaleDate = 'N', @ynFromLoc = 'N',
               @ynTicket = 'N', @ynVoid = 'N', @ynVendorGroup = 'N', @ynMatlVendor = 'N', @ynSaleType = 'N', @ynCustGroup = 'N',
               @ynCustomer = 'N', @ynCustJob = 'N', @ynCustPO = 'N', @ynPaymentType = 'N', @ynCheckNo = 'N', @ynHold = 'N', @ynJCCo = 'N',
               @ynPhaseGroup = 'N', @ynJob = 'N', @ynINCo = 'N', @ynToLoc = 'N', @ynMatlGroup = 'N', @ynMaterial = 'N', @ynUM = 'N',
               @ynMatlPhase = 'N', @ynMatlJCCType = 'N', @ynHaulerType = 'N', @ynEMCo = 'N', @ynEMGroup = 'N', @ynEquipment = 'N',
               @ynPRCo = 'N', @ynEmployee = 'N', @ynHaulVendor = 'N', @ynTruck = 'N', @ynDriver = 'N', @ynGrossWght = 'N', @ynTareWght = 'N',
               @ynWghtUM = 'N', @ynMatlUnits = 'N', @ynUnitPrice = 'N', @ynECM = 'N', @ynMatlTotal = 'N', @ynTruckType = 'N', @ynStartTime = 'N',
               @ynStopTime = 'N', @ynLoads = 'N', @ynMiles = 'N', @ynHours = 'N', @ynZone = 'N', @ynHaulCode = 'N', @ynHaulPhase = 'N',
               @ynHaulJCCType = 'N', @ynHaulBasis = 'N', @ynHaulRate = 'N', @ynHaulTotal = 'N', @ynRevCode = 'N', @ynRevRate = 'N',
               @ynRevBasis = 'N', @ynRevTotal = 'N', @ynPayCode = 'N', @ynPayRate = 'N', @ynPayBasis = 'N', @ynPayTotal = 'N', @ynTaxGroup = 'N',
               @ynTaxCode = 'N', @ynTaxType = 'N', @ynTaxBasis = 'N', @ynTaxTotal = 'N', @ynDiscBasis = 'N', @ynDiscRate = 'N', @ynDiscOff = 'N',
               @ynTaxDisc = 'N', @ynUMMetric = 'N', @ynECM = 'N'
        
        select @rcode = 0
        
        
        /* check required input params */
        
        if @ImportId is null
          begin
          select @desc = 'Missing ImportId.', @rcode = 1
          goto bspexit
        
          end
        if @ImportTemplate is null
          begin
          select @desc = 'Missing ImportTemplate.', @rcode = 1
          goto bspexit
          end
        
        if @Form is null
          begin
          select @desc = 'Missing Form.', @rcode = 1
          goto bspexit
         end
        
        -- Check ImportTemplate detail for columns to set Bidtek Defaults
        select top 1 1
        From IMTD with (nolock)
        Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
        
  if @@rowcount = 0
          begin
          select @desc='No Bidtek Defaults set up for ImportTemplate ' + @ImportTemplate +'.', @rcode=1
          goto bspexit
          end
        
        DECLARE 
			  @OverwriteBatchTransType 	 	bYN
			, @OverwriteCo 	 				bYN
			, @OverwriteSaleDate 	 		bYN
			, @OverwriteVoid 	 			bYN
			, @OverwriteHold 	 			bYN
			, @OverwriteECM 	 			bYN
			, @OverwriteSaleType 	 		bYN
			, @OverwriteVendorGroup 	 	bYN
			, @OverwriteCustGroup 	 		bYN
			, @OverwriteJCCo 	 			bYN
			, @OverwritePhaseGroup 	 		bYN
			, @OverwriteINCo 	 			bYN
			, @OverwriteMatlGroup 	 		bYN
			, @OverwriteUM 	 				bYN
			, @OverwriteMatlPhase 	 		bYN
			, @OverwriteMatlJCCType 	 	bYN
			, @OverwriteWghtUM 	 			bYN
			, @OverwriteMatlUnits 	 	 	bYN
			, @OverwriteEMGroup 	 	 	bYN
			, @OverwritePRCo 	 		 	bYN
			, @OverwriteUnitPrice 	 	 	bYN
			, @OverwriteMatlTotal 	 	 	bYN
			, @OverwriteZone 	 		 	bYN
			, @OverwriteTareWght 	 	 	bYN
			, @OverwriteEmployee 	 	 	bYN
			, @OverwriteTruckType 	 	 	bYN
			, @OverwriteHaulCode 	 	 	bYN
			, @OverwriteHaulPhase 	 	 	bYN
			, @OverwriteHaulJCCType 	 	bYN
			, @OverwriteRevCode 	 	 	bYN
			, @OverwriteEMCo 	 		 	bYN
			, @OverwriteTaxType 	 	 	bYN
			, @OverwriteTaxCode 	 	 	bYN
			, @OverwriteTaxGroup 	 	 	bYN
			, @OverwriteLoads 	 		 	bYN
			, @OverwriteMiles 	 		 	bYN
			, @OverwriteHours 	 		 	bYN
			, @OverwriteHaulBasis 	 	 	bYN
			, @OverwriteHaulRate 	 	 	bYN
			, @OverwriteHaulTotal 	 	 	bYN
			, @OverwritePayBasis 	 	 	bYN
			, @OverwritePayRate 	 	 	bYN
			, @OverwritePayTotal 	 	 	bYN
			, @OverwriteRevBasis 	 	 	bYN
			, @OverwriteRevRate 	 	 	bYN
			, @OverwriteRevTotal 	 	 	bYN
			, @OverwriteTaxBasis 	 	 	bYN
			, @OverwriteTaxTotal 	 	 	bYN
			, @OverwriteDiscBasis 	 	 	bYN
			, @OverwriteDiscRate 	 	 	bYN
			, @OverwriteDiscOff 	 	 	bYN
			, @OverwriteTaxDisc 	 	 	bYN
			, @OverwriteDriver 	 		 	bYN
			, @OverwriteHaulerType 	 	 	bYN
			, @OverwritePayCode 	 	 	bYN
			,	@IsCoEmpty 				 bYN
			,	@IsMthEmpty 			 bYN
			,	@IsBatchIdEmpty 		 bYN
			,	@IsBatchSeqEmpty 		 bYN
			,	@IsBatchTransTypeEmpty 	 bYN
			,	@IsSaleDateEmpty 		 bYN
			,	@IsFromLocEmpty 		 bYN
			,	@IsTicketEmpty 			 bYN
			,	@IsVoidEmpty 			 bYN
			,	@IsVendorGroupEmpty 	 bYN
			,	@IsMatlVendorEmpty 		 bYN
			,	@IsSaleTypeEmpty 		 bYN
			,	@IsCustGroupEmpty 		 bYN
			,	@IsCustomerEmpty 		 bYN
			,	@IsCustJobEmpty 		 bYN
			,	@IsCustPOEmpty 			 bYN
			,	@IsPaymentTypeEmpty 	 bYN
			,	@IsCheckNoEmpty 		 bYN
			,	@IsHoldEmpty 			 bYN
			,	@IsJCCoEmpty 			 bYN
			,	@IsPhaseGroupEmpty 		 bYN
			,	@IsJobEmpty 			 bYN
			,	@IsINCoEmpty 			 bYN
			,	@IsToLocEmpty 			 bYN
			,	@IsMatlGroupEmpty 		 bYN
			,	@IsMaterialEmpty 		 bYN
			,	@IsUMEmpty 				 bYN
			,	@IsMatlPhaseEmpty 		 bYN
			,	@IsMatlJCCTypeEmpty 	 bYN
			,	@IsHaulerTypeEmpty 		 bYN
			,	@IsEMCoEmpty 			 bYN
			,	@IsEMGroupEmpty 		 bYN
			,	@IsEquipmentEmpty 		 bYN
			,	@IsPRCoEmpty 			 bYN
			,	@IsEmployeeEmpty 		 bYN
			,	@IsHaulVendorEmpty 		 bYN
			,	@IsTruckEmpty 			 bYN
			,	@IsDriverEmpty 			 bYN
			,	@IsGrossWghtEmpty 		 bYN
			,	@IsTareWghtEmpty 		 bYN
			,	@IsWghtUMEmpty 			 bYN
			,	@IsMatlUnitsEmpty 		 bYN
			,	@IsUnitPriceEmpty 		 bYN
			,	@IsECMEmpty 			 bYN
			,	@IsMatlTotalEmpty 		 bYN
			,	@IsTruckTypeEmpty 		 bYN
			,	@IsStartTimeEmpty 		 bYN
			,	@IsStopTimeEmpty 		 bYN
			,	@IsLoadsEmpty 			 bYN
			,	@IsMilesEmpty 			 bYN
			,	@IsHoursEmpty 			 bYN
			,	@IsZoneEmpty 			 bYN
			,	@IsHaulCodeEmpty 		 bYN
			,	@IsHaulPhaseEmpty 		 bYN
			,	@IsHaulJCCTypeEmpty 	 bYN
			,	@IsHaulBasisEmpty 		 bYN
			,	@IsHaulRateEmpty 		 bYN
			,	@IsHaulTotalEmpty 		 bYN
			,	@IsRevCodeEmpty 		 bYN
			,	@IsRevRateEmpty 		 bYN
			,	@IsRevBasisEmpty 		 bYN
			,	@IsRevTotalEmpty 		 bYN
			,	@IsPayCodeEmpty 		 bYN
			,	@IsPayRateEmpty 		 bYN
			,	@IsPayBasisEmpty 		 bYN
			,	@IsPayTotalEmpty 		 bYN
			,	@IsTaxGroupEmpty 		 bYN
			,	@IsTaxCodeEmpty 		 bYN
			,	@IsTaxTypeEmpty 		 bYN
			,	@IsTaxBasisEmpty 		 bYN
			,	@IsTaxTotalEmpty 		 bYN
			,	@IsDiscBasisEmpty 		 bYN
			,	@IsDiscRateEmpty 		 bYN
			,	@IsDiscOffEmpty 		 bYN
			,	@IsTaxDiscEmpty 		 bYN
			,	@IsReasonCodeEmpty 		 bYN
			,	@IsShipAddressEmpty 	 bYN
			,	@IsCityEmpty 			 bYN
			,	@IsStateEmpty 			 bYN
			,	@IsCountryEmpty 		 bYN
			,	@IsZipEmpty 			 bYN			
			
			
		SELECT @OverwriteBatchTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BatchTransType', @rectype);
		SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Co', @rectype);
		SELECT @OverwriteSaleDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SaleDate', @rectype);
		SELECT @OverwriteVoid = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Void', @rectype);
		SELECT @OverwriteHold = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Hold', @rectype);
		SELECT @OverwriteECM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ECM', @rectype);
		SELECT @OverwriteSaleType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SaleType', @rectype);
		SELECT @OverwriteVendorGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'VendorGroup', @rectype);
		SELECT @OverwriteCustGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CustGroup', @rectype);
		SELECT @OverwriteJCCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JCCo', @rectype);
		SELECT @OverwritePhaseGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PhaseGroup', @rectype);
		SELECT @OverwriteINCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'INCo', @rectype);
		SELECT @OverwriteMatlGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MatlGroup', @rectype);
		SELECT @OverwriteUM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UM', @rectype);
		SELECT @OverwriteMatlPhase = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MatlPhase', @rectype);
		SELECT @OverwriteMatlJCCType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MatlJCCType', @rectype);
		SELECT @OverwriteWghtUM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'WghtUM', @rectype);
		SELECT @OverwriteMatlUnits = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MatlUnits', @rectype);
		SELECT @OverwriteEMGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EMGroup', @rectype);
		SELECT @OverwritePRCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PRCo', @rectype);
		SELECT @OverwriteINCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'INCo', @rectype);
		SELECT @OverwriteUnitPrice = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UnitPrice', @rectype);
		SELECT @OverwriteMatlTotal = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MatlTotal', @rectype);
		SELECT @OverwriteMatlGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MatlGroup', @rectype);
		SELECT @OverwriteZone = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Zone', @rectype);
		SELECT @OverwriteTareWght = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TareWght', @rectype);
		SELECT @OverwriteEmployee = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Employee', @rectype);
		SELECT @OverwriteTruckType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TruckType', @rectype);
		SELECT @OverwriteHaulCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'HaulCode', @rectype);
		SELECT @OverwriteHaulPhase = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'HaulPhase', @rectype);
		SELECT @OverwriteHaulJCCType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'HaulJCCType', @rectype);
		SELECT @OverwriteRevCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RevCode', @rectype);
		SELECT @OverwriteEMCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EMCo', @rectype);
		SELECT @OverwriteTaxType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxType', @rectype);
		SELECT @OverwriteTaxCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxCode', @rectype);
		SELECT @OverwriteTaxGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxGroup', @rectype);
		SELECT @OverwriteLoads = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Loads', @rectype);
		SELECT @OverwriteMiles = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Miles', @rectype);
		SELECT @OverwriteHours = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Hours', @rectype);
		SELECT @OverwriteHaulBasis = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'HaulBasis', @rectype);
		SELECT @OverwriteHaulRate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'HaulRate', @rectype);
		SELECT @OverwriteHaulTotal = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'HaulTotal', @rectype);
		SELECT @OverwritePayBasis = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PayBasis', @rectype);
		SELECT @OverwritePayRate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PayRate', @rectype);
		SELECT @OverwritePayTotal = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PayTotal', @rectype);
		SELECT @OverwriteRevBasis = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RevBasis', @rectype);
		SELECT @OverwriteRevRate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RevRate', @rectype);
		SELECT @OverwriteRevTotal = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RevTotal', @rectype);
		SELECT @OverwriteTaxBasis = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxBasis', @rectype);
		SELECT @OverwriteTaxTotal = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxTotal', @rectype);
		SELECT @OverwriteDiscBasis = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'DiscBasis', @rectype);
		SELECT @OverwriteDiscRate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'DiscRate', @rectype);
		SELECT @OverwriteDiscOff = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'DiscOff', @rectype);
		SELECT @OverwriteTaxDisc = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxDisc', @rectype);
		SELECT @OverwriteDriver = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Driver', @rectype);
		SELECT @OverwriteHaulerType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'HaulerType', @rectype);
		SELECT @OverwritePayCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PayCode', @rectype);
        

        select @BatchTransTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'BatchTransType'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteBatchTransType, 'Y') = 'Y')
         begin
           UPDATE IMWE
           SET IMWE.UploadVal = 'A'
           where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @BatchTransTypeID
         end
        --
        select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'Y') 
         begin
           UPDATE IMWE
           SET IMWE.UploadVal = @Company
           where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
         end
        
        --
        
        select @SaleDateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SaleDate'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteSaleDate, 'Y') = 'Y')
         begin
          UPDATE IMWE
          ----#141031
          SET IMWE.UploadVal = convert(varchar(20), dbo.vfDateOnly(),101)
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @SaleDateID
         end
        
        select @VoidID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Void'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteVoid, 'Y') = 'Y')
         begin
          UPDATE IMWE
          SET IMWE.UploadVal = 'N'
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @VoidID
         end
        
        select @HoldID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Hold'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteHold, 'Y') = 'Y')
         begin
          UPDATE IMWE
          SET IMWE.UploadVal = 'N'
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @HoldID
         end
        
        
        ------------------------------------
        
        select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'N') 
         begin
           UPDATE IMWE
           SET IMWE.UploadVal = @Company
           where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
         end
        
		select @BatchTransTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'BatchTransType'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteBatchTransType, 'Y') = 'N')
         begin
           UPDATE IMWE
           SET IMWE.UploadVal = 'A'
           where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @BatchTransTypeID
           AND IMWE.UploadVal IS NULL
         end
        
        select @SaleDateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SaleDate'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteSaleDate, 'Y') = 'N')
         begin
          UPDATE IMWE
          ----#141031
          SET IMWE.UploadVal = convert(varchar(20), dbo.vfDateOnly(),101)
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @SaleDateID
          AND IMWE.UploadVal IS NULL
         end
        
        select @VoidID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Void'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteVoid, 'Y') = 'N')
         begin
          UPDATE IMWE
          SET IMWE.UploadVal = 'N'
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @VoidID
          AND IMWE.UploadVal IS NULL
         end
        
        select @HoldID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Hold'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteHold, 'Y') = 'N')
         begin
          UPDATE IMWE
          SET IMWE.UploadVal = 'N'
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @HoldID
          AND IMWE.UploadVal IS NULL
         end
        
        
        
        
    /*    select @ECMID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ECM'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'
         begin
          UPDATE IMWE
          SET IMWE.UploadVal = 'E'
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @ECMID
         end
        */
    	--issue #28429
        select @ECMID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ECM'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynECM ='Y'
    
        select @SaleTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SaleType'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynSaleType ='Y'
        
        select @VendorGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'VendorGroup'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynVendorGroup ='Y'
        
        select @CustGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CustGroup'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynCustGroup ='Y'
        
        select @CustomerID = DDUD.Identifier From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Customer'
        
        select @CustJobID = DDUD.Identifier From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CustJob'
        
        select @CustPOID = DDUD.Identifier From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CustPO'
        
        select @PaymentTypeID = DDUD.Identifier From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PaymentType'
        
        select @CheckNoID = DDUD.Identifier From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CheckNo'
        
        select @ToLocID = DDUD.Identifier From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ToLoc'
        
        select @JobID = DDUD.Identifier From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Job'
        
        select @JCCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JCCo'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynJCCo ='Y'
        
        select @PhaseGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PhaseGroup'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynPhaseGroup ='Y'
        
        select @INCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'INCo'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynINCo ='Y'
        
        select @MatlGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MatlGroup'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynMatlGroup ='Y'
        
        select @UMID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'UM'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynUM ='Y'
        
        select @MatlPhaseID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MatlPhase'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynMatlPhase ='Y'
        
        select @MatlJCCTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MatlJCCType'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynMatlJCCType ='Y'
        
        select @WghtUMID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'WghtUM'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynWghtUM ='Y'
        
        select @MatlUnitsID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MatlUnits'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynMatlUnits ='Y'
        
        select @EMGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EMGroup'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynEMGroup ='Y'
        
        select @EquipmentID = DDUD.Identifier From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Equipment'
        
        select @PRCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PRCo'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynPRCo ='Y'
        
        select @INCoID =  DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'INCo'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynINCo ='Y'
        
        select @UnitPriceID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'UnitPrice'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynUnitPrice ='Y'
   
        select @MatlTotalID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MatlTotal'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynMatlTotal ='Y'
        
        select @MatlGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MatlGroup'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynMatlGroup ='Y'
        
        select @ZoneID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Zone'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynZone ='Y'
        
        select @TruckID = DDUD.Identifier From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Truck'
        
        select @GrossWghtID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'GrossWght'
        
        select @TareWghtID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TareWght'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynTareWght ='Y'
        
        select @EmployeeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Employee'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynEmployee ='Y'
        
        select @TruckTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TruckType'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynTruckType ='Y'
   
        select @HaulVendorID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'HaulVendor'
        
        select @HaulCodeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'HaulCode'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynHaulCode ='Y'
        
        select @HaulPhaseID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'HaulPhase'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynHaulPhase ='Y'
        
        select @HaulJCCTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'HaulJCCType'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynHaulJCCType ='Y'
        
        select @RevCodeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'RevCode'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynRevCode ='Y'
        
        select @EMCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EMCo'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynEMCo ='Y'
        
        select @StartTimeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'StartTime'
  
        select @StopTimeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'StopTime'
        
        select @TaxTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TaxType'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynTaxType ='Y'
        
        select @TaxCodeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TaxCode'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynTaxCode ='Y'
        
        select @TaxGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TaxGroup'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynTaxGroup ='Y'
        
        select @LoadsID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Loads'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynLoads ='Y'
        
        select @MilesID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Miles'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynMiles ='Y'
        
        select @HoursID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Hours'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynHours ='Y'
        
        select @HaulBasisID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'HaulBasis'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynHaulBasis ='Y'
        
        select @HaulRateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'HaulRate'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynHaulRate ='Y'
        
        select @HaulTotalID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'HaulTotal'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynHaulTotal ='Y'
        
        select @PayCodeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PayCode'
        
        select @PayBasisID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PayBasis'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynPayBasis ='Y'
        
        
        select @PayRateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PayRate'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynPayRate ='Y'
        
        select @PayTotalID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PayTotal'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynPayTotal ='Y'
        
        select @RevBasisID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'RevBasis'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynRevBasis ='Y'
      
        select @RevRateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'RevRate'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynRevRate ='Y'
        
        select @RevTotalID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'RevTotal'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynRevTotal ='Y'
        
        select @TaxBasisID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TaxBasis'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynTaxBasis ='Y'
        
        select @TaxTotalID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TaxTotal'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynTaxTotal ='Y'
        
        select @DiscBasisID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'DiscBasis'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynDiscBasis ='Y'
        
        select @DiscRateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'DiscRate'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynDiscRate ='Y'
        
        select @DiscOffID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
      Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'DiscOff'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynDiscOff ='Y'
        
        select @TaxDiscID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TaxDisc'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynTaxDisc ='Y'
        
        select @DriverID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Driver'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynDriver ='Y'
        
        select @HaulerTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'HaulerType'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynHaulerType ='Y'
        
        select @PayCodeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PayCode'
        if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynPayCode ='Y'
        
		 --#142350 change @MatlPhase,@UnitPrice,@ECM,@TruckType,@Zone,@HaulCode,@HaulPhase,
		 --@HaulBasis,@HaulRate,@RevRate,@RevBasis,@PayCode,@PayRate,@PayBasis,@TaxCode
        declare
         @Co bCompany, @Mth bMonth, @BatchId bBatchID, @BatchSeq int, @BatchTransType char(1), @SaleDate bDate, @FromLoc bLoc,
         @Ticket varchar(10), @Void bYN, @VendorGroup bGroup, @MatlVendor bVendor, @SaleType char(1), @CustGroup bGroup, @Customer bCustomer, @CustJob varchar(20),
         @CustPO varchar(20), @PaymentType char(1), @CheckNo varchar(10), @Hold bYN, @JCCo bCompany, @PhaseGroup bGroup, @Job bJob, @INCo bCompany,
         @ToLoc bLoc, @MatlGroup bGroup, @Material bMatl, @UM bUM, @MaterialPhaseCur bPhase, @MatlJCCType bJCCType, @HaulerType char(1),
         @EMCo bCompany, @EMGroup bGroup, @Equipment bEquip, @PRCo bCompany, @Employee bEmployee, @HaulVendor bVendor, @Truck varchar(10), @Driver bDesc,
         @GrossWght bUnits, @TareWght bUnits, @WghtUM bUM, @MatlUnits bUnits, @UnitPriceCur bUnitCost, @ECMCur bECM, @MatlTotal bDollar,
         @TruckTyp varchar(10), @StartTime smalldatetime, @StopTime smalldatetime, @Loads smallint, @Miles bUnits, @Hours bHrs, @ZoneCur varchar(10),
         @HaulCodeCur bHaulCode, @HaulPhaseCur bPhase, @HaulJCCType bJCCType, @HaulBasisCur bUnits, @HaulRateCur bUnitCost, @HaulTotal bDollar,
         @RevCode bRevCode, @RevRateCur bUnitCost, @RevBasisCur bUnits, @RevTotal bDollar, @PayCodeCur bPayCode, @PayRateCur bUnitCost, @PayBasisCur bUnits,
         @PayTotal bDollar, @TaxGroup bGroup, @TaxCodeCur bTaxCode, @TaxType tinyint, @TaxBasis bUnits, @TaxTotal bDollar, @DiscBasis bUnits,
         @DiscRate bUnitCost, @DiscOff bDollar, @TaxDisc bDollar, @loctaxcode bTaxCode, @taxopt tinyint, @payterms bPayTerms,
         @matldisc bYN, @hqptdiscrate bUnitCost, @HCTaxable bYN, @metricUM bUM, @returnvendor bVendor, @UpdateVendor CHAR(1), @CurrentMode VARCHAR(10)
        
        declare WorkEditCursor cursor LOCAL FAST_FORWARD for
        select IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
            from IMWE with (nolock)
                inner join DDUD with (nolock) on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
            where IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form
            Order by IMWE.RecordSeq, IMWE.Identifier
        
        open WorkEditCursor
        -- set open cursor flag
        select @opencursor = 1
        --#142350 removing unused @importid, @seq, @Identifier
        DECLARE @Recseq int,
            @Tablename varchar(20),
            @Column varchar(30),
            @Uploadval varchar(60),
            @Ident int,
            @SUploadval varchar(60)
        
        declare @currrecseq int, @allownull int, @error int, @tsql varchar(255), @valuelist varchar(255),
                @columnlist varchar(255), @complete int, @counter int, @records int, @oldrecseq int
        
        declare @costtypeout bEMCType, @Wghtopt tinyint, @WghtConv bUnitCost, @MatConv bUnitCost,
                @fil varchar(60), @filonhand numeric(12,3)
        
        fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
        
        select @currrecseq = @Recseq, @complete = 0, @counter = 1
        
        -- while cursor is not empty
        while @complete = 0
        
        begin
        
          if @@fetch_status <> 0
            select @Recseq = -1
        
            --if rec sequence = current rec sequence flag
          if @Recseq = @currrecseq
            begin
           --select @Uploadval = LTRIM(@Uploadval) do not add back in.
           select @Uploadval = RTRIM(@Uploadval)
            If @Column='Co' and isnumeric(@Uploadval) =1 select @Co = Convert( int, @Uploadval)
        	If @Column='Mth' and isdate(@Uploadval) =1 select @Mth = Convert( smalldatetime, @Uploadval)
        	If @Column='BatchSeq' and  isnumeric(@Uploadval) =1 select @BatchSeq = @Uploadval
        	If @Column='BatchTransType' select @BatchTransType = @Uploadval
        	If @Column='SaleDate' and isdate(@Uploadval) =1 select @SaleDate = Convert( smalldatetime, @Uploadval)
        	If @Column='FromLoc' select @FromLoc = @Uploadval
        	If @Column='Ticket' select @Ticket = @Uploadval
        	If @Column='Void' select @Void = @Uploadval
        	If @Column='VendorGroup' and isnumeric(@Uploadval) =1 select @VendorGroup = @Uploadval
        	If @Column='MatlVendor' and isnumeric(@Uploadval) =1 select @MatlVendor = @Uploadval
        	If @Column='SaleType' select @SaleType = @Uploadval
        	If @Column='CustGroup' and isnumeric(@Uploadval) =1 select @CustGroup = @Uploadval
        	If @Column='Customer' and isnumeric(@Uploadval) =1 select @Customer = Convert( int, @Uploadval)
        	If @Column='CustJob' select @CustJob = @Uploadval
         	If @Column='CustPO'  select @CustPO = @Uploadval
        	If @Column='PaymentType' select @PaymentType = @Uploadval
        	If @Column='CheckNo' select @CheckNo = @Uploadval
        	If @Column='Hold' select @Hold = @Uploadval
        	If @Column='JCCo' and isnumeric(@Uploadval) =1 select @JCCo = Convert( int, @Uploadval)
        	If @Column='PhaseGroup' and isnumeric(@Uploadval) =1 select @PhaseGroup = Convert( int, @Uploadval)
         	If @Column='Job' select @Job = @Uploadval
            If @Column='INCo' and  isnumeric(@Uploadval) =1 select @INCo = convert(numeric,@Uploadval)
        	If @Column='ToLoc' select @ToLoc = @Uploadval
        	If @Column='MatlGroup' and  isnumeric(@Uploadval) =1 select @MatlGroup = convert(numeric,@Uploadval)
        	If @Column='Material' select @Material = @Uploadval
        	If @Column='UM' select @UM = @Uploadval
        	If @Column='MatlPhase' select @MaterialPhaseCur = @Uploadval
        	If @Column='MatlJCCType' and  isnumeric(@Uploadval) =1 select @MatlJCCType = convert(numeric,@Uploadval)
        	If @Column='HaulerType' select @HaulerType = @Uploadval
        	If @Column='EMCo' and  isnumeric(@Uploadval) =1 select @EMCo = convert(int,@Uploadval)
        	If @Column='EMGroup' and isnumeric(@Uploadval) =1 select @EMGroup = Convert( int, @Uploadval)
        	If @Column='Equipment' select @Equipment = @Uploadval
        	If @Column='PRCo' and isnumeric(@Uploadval) =1 select @PRCo = Convert( int, @Uploadval)
         	If @Column='Employee' and isnumeric(@Uploadval) =1 select @Employee = Convert( int, @Uploadval)
        	If @Column='HaulVendor' and isnumeric(@Uploadval) =1 select @HaulVendor = Convert( int, @Uploadval)
        	If @Column='Truck' select @Truck = @Uploadval
        	If @Column='Driver' select @Driver = @Uploadval
          	If @Column='GrossWght' and isnumeric(@Uploadval) =1 select @GrossWght = convert(decimal(12,3),@Uploadval)
         	If @Column='TareWght' and isnumeric(@Uploadval) =1 select @TareWght = convert(decimal(12,3),@Uploadval)
         	If @Column='WghtUM' select @WghtUM = @Uploadval
         	If @Column='MatlUnits' and isnumeric(@Uploadval) =1 select @MatlUnits = convert(decimal(12,3),@Uploadval)
         	If @Column='UnitPrice' and isnumeric(@Uploadval) =1 select @UnitPriceCur = convert(decimal(16,5),@Uploadval)
        	If @Column='ECM' select @ECMCur = @Uploadval
        	If @Column='MatlTotal' and isnumeric(@Uploadval) =1 select @MatlTotal = convert(decimal(12,2),@Uploadval)
        	If @Column='TruckType' select @TruckTyp = @Uploadval
        
         	If @Column='StartTime' or @Column='StopTime'
               begin
        
                 IF Len(@Uploadval) = 5  and isdate(@Uploadval) =1
                  begin
                  select @Uploadval = @SaleDate + @Uploadval
                 end
        
                 IF Len(@Uploadval) = 4 and isnumeric(@Uploadval) =1
                  begin
                   select @Uploadval = substring(@Uploadval,1,2) + ':' + substring(@Uploadval,3,2)
                   select @Uploadval = @SaleDate + @Uploadval
  end
        
                 if @Column='StartTime'
                   begin
                     UPDATE IMWE
                     SET IMWE.UploadVal = @Uploadval
                     where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
                     and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @StartTimeID
                   end
                 if @Column='StopTime'
                   begin
                     UPDATE IMWE
                     SET IMWE.UploadVal = @Uploadval
        
                     where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
                     and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @StopTimeID
                   end
        
               end
        
        
         	If @Column='StartTime' and isdate(@Uploadval) =1 select @StartTime = Convert( smalldatetime, @Uploadval)
        	If @Column='StopTime' and isdate(@Uploadval) =1 select @StopTime = Convert( smalldatetime, @Uploadval)
        	If @Column='Loads' and isnumeric(@Uploadval) =1 select @Loads = Convert( decimal(10,0), @Uploadval)
        	If @Column='Miles' and isnumeric(@Uploadval) =1 select @Miles = convert(decimal(10,5),@Uploadval)
        	If @Column='Hours' and isnumeric(@Uploadval) =1 select @Hours = convert(decimal(10,5),@Uploadval)
        	If @Column='Zone' select @ZoneCur = @Uploadval
         	If @Column='HaulCode' select @HaulCodeCur = @Uploadval
        	If @Column='HaulPhase' select @HaulPhaseCur = @Uploadval
        	If @Column='HaulJCCType' and isnumeric(@Uploadval) =1 select @HaulJCCType = convert(int,@Uploadval)
            If @Column='HaulBasis' and isnumeric(@Uploadval) =1 select @HaulBasisCur = convert(decimal(10,2),@Uploadval)
        	If @Column='HaulRate' and isnumeric(@Uploadval) =1 select @HaulRateCur = convert(decimal(10,5),@Uploadval)
         	If @Column='HaulTotal' and isnumeric(@Uploadval) =1 select @HaulTotal = convert(decimal(10,2),@Uploadval)
        	If @Column='RevCode' select @RevCode = @Uploadval
        	If @Column='RevRate' and isnumeric(@Uploadval) =1 select @RevRateCur = convert(decimal(10,5),@Uploadval)
        	If @Column='RevBasis' and isnumeric(@Uploadval) =1 select @RevBasisCur = convert(decimal(10,2),@Uploadval)
        	If @Column='RevTotal' and isnumeric(@Uploadval) =1 select @RevTotal = convert(decimal(10,2),@Uploadval)
        	If @Column='PayCode' select @PayCodeCur = @Uploadval
        	If @Column='PayRate' and isnumeric(@Uploadval) =1 select @PayRateCur = convert(decimal(10,5),@Uploadval)
        	If @Column='PayBasis' and isnumeric(@Uploadval) =1 select @PayBasisCur = convert(decimal(10,2),@Uploadval)
        	If @Column='PayTotal' and isnumeric(@Uploadval) =1 select @PayTotal = convert(decimal(10,2),@Uploadval)
            If @Column='TaxGroup' and isnumeric(@Uploadval) =1 select @TaxGroup = convert(int,@Uploadval)
        	If @Column='TaxCode' select @TaxCodeCur = @Uploadval
         	If @Column='TaxType' and isnumeric(@Uploadval) =1 select @TaxType = convert(int,@Uploadval)
        	If @Column='TaxBasis' and isnumeric(@Uploadval) =1 select @TaxBasis = convert(decimal(10,2),@Uploadval)
        	If @Column='TaxTotal' and isnumeric(@Uploadval) =1 select @TaxTotal = convert(decimal(10,2),@Uploadval)
        	If @Column='DiscBasis' and isnumeric(@Uploadval) =1 select @DiscBasis = convert(decimal(10,2),@Uploadval)
        	If @Column='DiscRate' and isnumeric(@Uploadval) =1 select @DiscRate = convert(decimal(10,5),@Uploadval)
        	If @Column='DiscOff' and isnumeric(@Uploadval) =1 select @DiscOff = Convert( decimal(10,2), @Uploadval)
        	If @Column='TaxDisc' and isnumeric(@Uploadval) =1 select @TaxDisc = Convert( decimal(10,2), @Uploadval)

			IF @Column='Co' 
				IF @Uploadval IS NULL
					SET @IsCoEmpty = 'Y'
				ELSE
					SET @IsCoEmpty = 'N'
			IF @Column='Mth' 
				IF @Uploadval IS NULL
					SET @IsMthEmpty = 'Y'
				ELSE
					SET @IsMthEmpty = 'N'
			IF @Column='BatchId' 
				IF @Uploadval IS NULL
					SET @IsBatchIdEmpty = 'Y'
				ELSE
					SET @IsBatchIdEmpty = 'N'
			IF @Column='BatchSeq' 
				IF @Uploadval IS NULL
					SET @IsBatchSeqEmpty = 'Y'
				ELSE
					SET @IsBatchSeqEmpty = 'N'
			IF @Column='BatchTransType' 
				IF @Uploadval IS NULL
					SET @IsBatchTransTypeEmpty = 'Y'
				ELSE
					SET @IsBatchTransTypeEmpty = 'N'
			IF @Column='SaleDate' 
				IF @Uploadval IS NULL
					SET @IsSaleDateEmpty = 'Y'
				ELSE
					SET @IsSaleDateEmpty = 'N'
			IF @Column='FromLoc' 
				IF @Uploadval IS NULL
					SET @IsFromLocEmpty = 'Y'
				ELSE
					SET @IsFromLocEmpty = 'N'
			IF @Column='Ticket' 
				IF @Uploadval IS NULL
					SET @IsTicketEmpty = 'Y'
				ELSE
					SET @IsTicketEmpty = 'N'
			IF @Column='Void' 
				IF @Uploadval IS NULL
					SET @IsVoidEmpty = 'Y'
				ELSE
					SET @IsVoidEmpty = 'N'
			IF @Column='VendorGroup' 
				IF @Uploadval IS NULL
					SET @IsVendorGroupEmpty = 'Y'
				ELSE
					SET @IsVendorGroupEmpty = 'N'
			IF @Column='MatlVendor' 
				IF @Uploadval IS NULL
					SET @IsMatlVendorEmpty = 'Y'
				ELSE
					SET @IsMatlVendorEmpty = 'N'
			IF @Column='SaleType' 
				IF @Uploadval IS NULL
					SET @IsSaleTypeEmpty = 'Y'
				ELSE
					SET @IsSaleTypeEmpty = 'N'
			IF @Column='CustGroup' 
				IF @Uploadval IS NULL
					SET @IsCustGroupEmpty = 'Y'
				ELSE
					SET @IsCustGroupEmpty = 'N'
			IF @Column='Customer' 
				IF @Uploadval IS NULL
					SET @IsCustomerEmpty = 'Y'
				ELSE
					SET @IsCustomerEmpty = 'N'
			IF @Column='CustJob' 
				IF @Uploadval IS NULL
					SET @IsCustJobEmpty = 'Y'
				ELSE
					SET @IsCustJobEmpty = 'N'
			IF @Column='CustPO' 
				IF @Uploadval IS NULL
					SET @IsCustPOEmpty = 'Y'
				ELSE
					SET @IsCustPOEmpty = 'N'
			IF @Column='PaymentType' 
				IF @Uploadval IS NULL
					SET @IsPaymentTypeEmpty = 'Y'
				ELSE
					SET @IsPaymentTypeEmpty = 'N'
			IF @Column='CheckNo' 
				IF @Uploadval IS NULL
					SET @IsCheckNoEmpty = 'Y'
				ELSE
					SET @IsCheckNoEmpty = 'N'
			IF @Column='Hold' 
				IF @Uploadval IS NULL
					SET @IsHoldEmpty = 'Y'
				ELSE
					SET @IsHoldEmpty = 'N'
			IF @Column='JCCo' 
				IF @Uploadval IS NULL
					SET @IsJCCoEmpty = 'Y'
				ELSE
					SET @IsJCCoEmpty = 'N'
			IF @Column='PhaseGroup' 
				IF @Uploadval IS NULL
					SET @IsPhaseGroupEmpty = 'Y'
				ELSE
					SET @IsPhaseGroupEmpty = 'N'
			IF @Column='Job' 
				IF @Uploadval IS NULL
					SET @IsJobEmpty = 'Y'
				ELSE
					SET @IsJobEmpty = 'N'
			IF @Column='INCo' 
				IF @Uploadval IS NULL
					SET @IsINCoEmpty = 'Y'
				ELSE
					SET @IsINCoEmpty = 'N'
			IF @Column='ToLoc' 
				IF @Uploadval IS NULL
					SET @IsToLocEmpty = 'Y'
				ELSE
					SET @IsToLocEmpty = 'N'
			IF @Column='MatlGroup' 
				IF @Uploadval IS NULL
					SET @IsMatlGroupEmpty = 'Y'
				ELSE
					SET @IsMatlGroupEmpty = 'N'
			IF @Column='Material' 
				IF @Uploadval IS NULL
					SET @IsMaterialEmpty = 'Y'
				ELSE
					SET @IsMaterialEmpty = 'N'
			IF @Column='UM' 
				IF @Uploadval IS NULL
					SET @IsUMEmpty = 'Y'
				ELSE
					SET @IsUMEmpty = 'N'
			IF @Column='MatlPhase' 
				IF @Uploadval IS NULL
					SET @IsMatlPhaseEmpty = 'Y'
				ELSE
					SET @IsMatlPhaseEmpty = 'N'
			IF @Column='MatlJCCType' 
				IF @Uploadval IS NULL
					SET @IsMatlJCCTypeEmpty = 'Y'
				ELSE
					SET @IsMatlJCCTypeEmpty = 'N'
			IF @Column='HaulerType' 
				IF @Uploadval IS NULL
					SET @IsHaulerTypeEmpty = 'Y'
				ELSE
					SET @IsHaulerTypeEmpty = 'N'
			IF @Column='EMCo' 
				IF @Uploadval IS NULL
					SET @IsEMCoEmpty = 'Y'
				ELSE
					SET @IsEMCoEmpty = 'N'
			IF @Column='EMGroup' 
				IF @Uploadval IS NULL
					SET @IsEMGroupEmpty = 'Y'
				ELSE
					SET @IsEMGroupEmpty = 'N'
			IF @Column='Equipment' 
				IF @Uploadval IS NULL
					SET @IsEquipmentEmpty = 'Y'
				ELSE
					SET @IsEquipmentEmpty = 'N'
			IF @Column='PRCo' 
				IF @Uploadval IS NULL
					SET @IsPRCoEmpty = 'Y'
				ELSE
					SET @IsPRCoEmpty = 'N'
			IF @Column='Employee' 
				IF @Uploadval IS NULL
					SET @IsEmployeeEmpty = 'Y'
				ELSE
					SET @IsEmployeeEmpty = 'N'
			IF @Column='HaulVendor' 
				IF @Uploadval IS NULL
					SET @IsHaulVendorEmpty = 'Y'
				ELSE
					SET @IsHaulVendorEmpty = 'N'
			IF @Column='Truck' 
				IF @Uploadval IS NULL
					SET @IsTruckEmpty = 'Y'
				ELSE
					SET @IsTruckEmpty = 'N'
			IF @Column='Driver' 
				IF @Uploadval IS NULL
					SET @IsDriverEmpty = 'Y'
				ELSE
					SET @IsDriverEmpty = 'N'
			IF @Column='GrossWght' 
				IF @Uploadval IS NULL
					SET @IsGrossWghtEmpty = 'Y'
				ELSE
					SET @IsGrossWghtEmpty = 'N'
			IF @Column='TareWght' 
				IF @Uploadval IS NULL
					SET @IsTareWghtEmpty = 'Y'
				ELSE
					SET @IsTareWghtEmpty = 'N'
			IF @Column='WghtUM' 
				IF @Uploadval IS NULL
					SET @IsWghtUMEmpty = 'Y'
				ELSE
					SET @IsWghtUMEmpty = 'N'
			IF @Column='MatlUnits' 
				IF @Uploadval IS NULL
					SET @IsMatlUnitsEmpty = 'Y'
				ELSE
					SET @IsMatlUnitsEmpty = 'N'
			IF @Column='UnitPrice' 
				IF @Uploadval IS NULL
					SET @IsUnitPriceEmpty = 'Y'
				ELSE
					SET @IsUnitPriceEmpty = 'N'
			IF @Column='ECM' 
				IF @Uploadval IS NULL
					SET @IsECMEmpty = 'Y'
				ELSE
					SET @IsECMEmpty = 'N'
			IF @Column='MatlTotal' 
				IF @Uploadval IS NULL
					SET @IsMatlTotalEmpty = 'Y'
				ELSE
					SET @IsMatlTotalEmpty = 'N'
			IF @Column='TruckType' 
				IF @Uploadval IS NULL
					SET @IsTruckTypeEmpty = 'Y'
				ELSE
					SET @IsTruckTypeEmpty = 'N'
			IF @Column='StartTime' 
				IF @Uploadval IS NULL
					SET @IsStartTimeEmpty = 'Y'
				ELSE
					SET @IsStartTimeEmpty = 'N'
			IF @Column='StopTime' 
				IF @Uploadval IS NULL
					SET @IsStopTimeEmpty = 'Y'
				ELSE
					SET @IsStopTimeEmpty = 'N'
			IF @Column='Loads' 
				IF @Uploadval IS NULL
					SET @IsLoadsEmpty = 'Y'
				ELSE
					SET @IsLoadsEmpty = 'N'
			IF @Column='Miles' 
				IF @Uploadval IS NULL
					SET @IsMilesEmpty = 'Y'
				ELSE
					SET @IsMilesEmpty = 'N'
			IF @Column='Hours' 
				IF @Uploadval IS NULL
					SET @IsHoursEmpty = 'Y'
				ELSE
					SET @IsHoursEmpty = 'N'
			IF @Column='Zone' 
				IF @Uploadval IS NULL
					SET @IsZoneEmpty = 'Y'
				ELSE
					SET @IsZoneEmpty = 'N'
			IF @Column='HaulCode' 
				IF @Uploadval IS NULL
					SET @IsHaulCodeEmpty = 'Y'
				ELSE
					SET @IsHaulCodeEmpty = 'N'
			IF @Column='HaulPhase' 
				IF @Uploadval IS NULL
					SET @IsHaulPhaseEmpty = 'Y'
				ELSE
					SET @IsHaulPhaseEmpty = 'N'
			IF @Column='HaulJCCType' 
				IF @Uploadval IS NULL
					SET @IsHaulJCCTypeEmpty = 'Y'
				ELSE
					SET @IsHaulJCCTypeEmpty = 'N'
			IF @Column='HaulBasis' 
				IF @Uploadval IS NULL
					SET @IsHaulBasisEmpty = 'Y'
				ELSE
					SET @IsHaulBasisEmpty = 'N'
			IF @Column='HaulRate' 
				IF @Uploadval IS NULL
					SET @IsHaulRateEmpty = 'Y'
				ELSE
					SET @IsHaulRateEmpty = 'N'
			IF @Column='HaulTotal' 
				IF @Uploadval IS NULL
					SET @IsHaulTotalEmpty = 'Y'
				ELSE
					SET @IsHaulTotalEmpty = 'N'
			IF @Column='RevCode' 
				IF @Uploadval IS NULL
					SET @IsRevCodeEmpty = 'Y'
				ELSE
					SET @IsRevCodeEmpty = 'N'
			IF @Column='RevRate' 
				IF @Uploadval IS NULL
					SET @IsRevRateEmpty = 'Y'
				ELSE
					SET @IsRevRateEmpty = 'N'
			IF @Column='RevBasis' 
				IF @Uploadval IS NULL
					SET @IsRevBasisEmpty = 'Y'
				ELSE
					SET @IsRevBasisEmpty = 'N'
			IF @Column='RevTotal' 
				IF @Uploadval IS NULL
					SET @IsRevTotalEmpty = 'Y'
				ELSE
					SET @IsRevTotalEmpty = 'N'
			IF @Column='PayCode' 
				IF @Uploadval IS NULL
					SET @IsPayCodeEmpty = 'Y'
				ELSE
					SET @IsPayCodeEmpty = 'N'
			IF @Column='PayRate' 
				IF @Uploadval IS NULL
					SET @IsPayRateEmpty = 'Y'
				ELSE
					SET @IsPayRateEmpty = 'N'
			IF @Column='PayBasis' 
				IF @Uploadval IS NULL
					SET @IsPayBasisEmpty = 'Y'
				ELSE
					SET @IsPayBasisEmpty = 'N'
			IF @Column='PayTotal' 
				IF @Uploadval IS NULL
					SET @IsPayTotalEmpty = 'Y'
				ELSE
					SET @IsPayTotalEmpty = 'N'
			IF @Column='TaxGroup' 
				IF @Uploadval IS NULL
					SET @IsTaxGroupEmpty = 'Y'
				ELSE
					SET @IsTaxGroupEmpty = 'N'
			IF @Column='TaxCode' 
				IF @Uploadval IS NULL
					SET @IsTaxCodeEmpty = 'Y'
				ELSE
					SET @IsTaxCodeEmpty = 'N'
			IF @Column='TaxType' 
				IF @Uploadval IS NULL
					SET @IsTaxTypeEmpty = 'Y'
				ELSE
					SET @IsTaxTypeEmpty = 'N'
			IF @Column='TaxBasis' 
				IF @Uploadval IS NULL
					SET @IsTaxBasisEmpty = 'Y'
				ELSE
					SET @IsTaxBasisEmpty = 'N'
			IF @Column='TaxTotal' 
				IF @Uploadval IS NULL
					SET @IsTaxTotalEmpty = 'Y'
				ELSE
					SET @IsTaxTotalEmpty = 'N'
			IF @Column='DiscBasis' 
				IF @Uploadval IS NULL
					SET @IsDiscBasisEmpty = 'Y'
				ELSE
					SET @IsDiscBasisEmpty = 'N'
			IF @Column='DiscRate' 
				IF @Uploadval IS NULL
					SET @IsDiscRateEmpty = 'Y'
				ELSE
					SET @IsDiscRateEmpty = 'N'
			IF @Column='DiscOff' 
				IF @Uploadval IS NULL
					SET @IsDiscOffEmpty = 'Y'
				ELSE
					SET @IsDiscOffEmpty = 'N'
			IF @Column='TaxDisc' 
				IF @Uploadval IS NULL
					SET @IsTaxDiscEmpty = 'Y'
				ELSE
					SET @IsTaxDiscEmpty = 'N'
			IF @Column='ReasonCode' 
				IF @Uploadval IS NULL
					SET @IsReasonCodeEmpty = 'Y'
				ELSE
					SET @IsReasonCodeEmpty = 'N'
			IF @Column='ShipAddress' 
				IF @Uploadval IS NULL
					SET @IsShipAddressEmpty = 'Y'
				ELSE
					SET @IsShipAddressEmpty = 'N'
			IF @Column='City' 
				IF @Uploadval IS NULL
					SET @IsCityEmpty = 'Y'
				ELSE
					SET @IsCityEmpty = 'N'
			IF @Column='State' 
				IF @Uploadval IS NULL
					SET @IsStateEmpty = 'Y'
				ELSE
					SET @IsStateEmpty = 'N'
			IF @Column='Country' 
				IF @Uploadval IS NULL
					SET @IsCountryEmpty = 'Y'
				ELSE
					SET @IsCountryEmpty = 'N'
			IF @Column='Zip' 
				IF @Uploadval IS NULL
					SET @IsZipEmpty = 'Y'
				ELSE
					SET @IsZipEmpty = 'N'        
        
        
                   --fetch next record
        
                if @@fetch_status <> 0
                  select @complete = 1
        
                select @oldrecseq = @Recseq
        
                fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
        
            end
        
          else
        
            begin
        
			---- get country code from HQCo
			select @country = isnull(Country,DefaultCountry)
			from bHQCO with (nolock) where HQCo=@Co
			if @@rowcount = 0 select @country = 'US'

       	  -- Issue #23460, use to make sure we're not already using metric UM.
       	  select @uploadum = @UM
       
       
             if @ynSaleType ='Y' AND (ISNULL(@OverwriteSaleType, 'Y') = 'Y' OR ISNULL(@IsSaleTypeEmpty, 'Y') = 'Y')
         	  begin
               select @SaleType = 'C'
        
               If isnull(@ToLoc,'') <> '' select @SaleType = 'I'
               If isnull(@Job,'') <> '' select @SaleType = 'J'
               If isnull(@Customer,'') <> '' select @SaleType = 'C'
        
               UPDATE IMWE
               SET IMWE.UploadVal = @SaleType
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @SaleTypeID
              end
        
        
        	if @ynVendorGroup ='Y' and isnull(@Co,'') <> ''  AND (ISNULL(@OverwriteVendorGroup, 'Y') = 'Y' OR ISNULL(@IsVendorGroupEmpty, 'Y') = 'Y')
         	  begin
        
           select @VendorGroup = h.VendorGroup
               from bHQCO h with (nolock)
               join bMSCO m with (nolock) on m.APCo = h.HQCo
               where m.MSCo = @Co
        
               UPDATE IMWE
               SET IMWE.UploadVal = @VendorGroup
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @VendorGroupID
              end
        
        	if @ynCustGroup ='Y' and isnull(@Co,'') <> ''  AND (ISNULL(@OverwriteCustGroup, 'Y') = 'Y' OR ISNULL(@IsCustGroupEmpty, 'Y') = 'Y')
         	  begin
        
                   select @CustGroup = h.CustGroup
                   from bHQCO h with (nolock)
                   join bMSCO m with (nolock) on m.ARCo = h.HQCo
                   where m.MSCo = @Co
        
        
               UPDATE IMWE
               SET IMWE.UploadVal = @CustGroup
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @CustGroupID
              end
        
        	if @ynJCCo ='Y' and isnull(@Co,'') <> ''  AND (ISNULL(@OverwriteJCCo, 'Y') = 'Y' OR ISNULL(@IsJCCoEmpty, 'Y') = 'Y')
         	  begin
        
               If @SaleType = 'J'
                   select @JCCo = @Co
               else
                   select @JCCo = null
        
               UPDATE IMWE
               SET IMWE.UploadVal = @JCCo
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @JCCoID
              end
        
        	if @ynPhaseGroup ='Y'  AND (ISNULL(@OverwritePhaseGroup, 'Y') = 'Y' OR ISNULL(@IsPhaseGroupEmpty, 'Y') = 'Y')-- and isnull(@JCCo,'') <> '' 
         	  begin
        
               select @defaultvalue = null
               /*If @SaleType = 'J'
                 begin*/
                  select @PhaseGroup = PhaseGroup
                  from bHQCO with (nolock)
                  where HQCo = @JCCo
        
                  select @defaultvalue = @PhaseGroup
                /* end
               else
                  select @defaultvalue = null, @PhaseGroup = null*/
        
               UPDATE IMWE
               SET IMWE.UploadVal = @defaultvalue
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @PhaseGroupID
              end
        
        	if @ynINCo ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteINCo, 'Y') = 'Y' OR ISNULL(@IsINCoEmpty, 'Y') = 'Y')
         	  begin
        
               If @SaleType = 'I'
                 select @defaultvalue = @Co
               else
                 select @defaultvalue = null
        
       		select @INCo = @defaultvalue	-- Issue #23460, fix for inventory metric conversion.
        
               UPDATE IMWE
               SET IMWE.UploadVal = @defaultvalue
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @INCoID
              end
        
        	if @ynMatlGroup ='Y' and isnull(@Co,'') <> ''  AND (ISNULL(@OverwriteMatlGroup, 'Y') = 'Y' OR ISNULL(@IsMatlGroupEmpty, 'Y') = 'Y')
         	  begin
               select @MatlGroup = MatlGroup
               from bHQCO with (nolock)
               Where HQCo = @Co
        
               UPDATE IMWE
               SET IMWE.UploadVal = @MatlGroup
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @MatlGroupID
              end
        
        
        	if @ynWghtUM ='Y' and isnull(@MatlGroup,'') <> ''  AND (ISNULL(@OverwriteWghtUM, 'Y') = 'Y' OR ISNULL(@IsWghtUMEmpty, 'Y') = 'Y') 
         	  begin
               select @Wghtopt = WghtOpt
               from bINLM with (nolock)
               Where INCo = @Co and Loc = @FromLoc
        
               select @WghtUM =  CASE @Wghtopt WHEN 1 then  'LBS'
                                               WHEN 2 then  'TON'
                                               WHEN 3 then 'kg'
                                               else  null end
               UPDATE IMWE
               SET IMWE.UploadVal = @WghtUM
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @WghtUMID
              end
        
        	if @ynEMCo ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteEMCo, 'Y') = 'Y' OR ISNULL(@IsEMCoEmpty, 'Y') = 'Y')
         	  begin
               select @EMCo = @Co
               UPDATE IMWE
               SET IMWE.UploadVal = @Co
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @EMCoID
              end
        --Issue #127776 added AND @HaulerType = 'E'
        -- Issue #134524 - Corrected MatlUnits to EMGroup 
        	if @ynEMGroup ='Y' and isnull(@EMCo,'') <> '' AND @HaulerType = 'E'  AND (ISNULL(@OverwriteEMGroup, 'Y') = 'Y' OR ISNULL(@IsEMGroupEmpty, 'Y') = 'Y') 
        
         	  begin
               exec @rcode = dbo.bspEMGroupGet @EMCo, @EMGroup output, @desc output
        
               UPDATE IMWE
               SET IMWE.UploadVal = @EMGroup
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @EMGroupID
              end
        
        	if @ynHaulerType ='Y' AND (ISNULL(@OverwriteHaulerType, 'Y') = 'Y' OR ISNULL(@IsHaulerTypeEmpty, 'Y') = 'Y')
         	  begin -- @HaulVendor
               select @HaulerType = 'N'
               If isnull(@Truck,'')<>'' or isnull(@HaulVendor,'')<>'' select @HaulerType = 'H'
               If isnull(@Equipment,'')<>'' and isnull(@HaulVendor,'')='' select @HaulerType = 'E'
        
        
               UPDATE IMWE
               SET IMWE.UploadVal = @HaulerType
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @HaulerTypeID
              end
        
        
         	if @ynUM ='Y' and isnull(@UM,'') = ''  AND (ISNULL(@OverwriteUM, 'Y') = 'Y' OR ISNULL(@IsUMEmpty, 'Y') = 'Y')	--IsNull added for #25139
         	begin
       
    	   		--Issue #21738 Get @salesum first...
    	   		select @salesum = SalesUM 
    	   		from bHQMT with (nolock) where MatlGroup = @MatlGroup and Material = @Material
    	   		--end Issue #21738
    	   
    	   		select @UM = @salesum		
    	   				
    	   		UPDATE IMWE
    	   		SET IMWE.UploadVal = @UM
    	   		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    	   	         and IMWE.Identifier = @UMID
    	   	end
        
        
        /* get defaults for later use from bsp*/
        
         select @taxopt = TaxOpt -- 0 - No Tax, 1 - Sales Location, 2 - SaleType/Purchaser, 3 - SaleType/Purchaser/Sales Location, 4 - Delivery
         from bMSCO with (nolock) where MSCo=@Co
        
         -- initialize variable on every cycle
         select @loctaxcode = null
        
         select @locgroup = LocGroup, @loctaxcode = TaxCode
         from bINLM with (nolock) where INCo = @Co and Loc = @FromLoc
        
         select @quote = null, @disctemplate = null, @pricetemplate = null, @zone = null, @haultaxopt = null, @taxcode = null,
                @salesum = null, @paydisctype = null, @paydiscrate = null, @matlphase = null, @matlct = null, @haulphase = null,
                @haulct = null, @netumconv = null, @matlumconv = null, @taxable = null, @unitprice = null, @ecm = null,
                @minamt = null, @haulcode = null, @payterms = null
        
         exec @recode = dbo.bspMSTicTemplateGet @Co, @SaleType, @CustGroup, @Customer, @CustJob, @CustPO,
                      @JCCo, @Job, @INCo, @ToLoc, @FromLoc, @quote output, @disctemplate output,
                      @pricetemplate output, @zone output, @haultaxopt output, @taxcode output, @payterms output, null, null,
					  null, @msg output        
        
         -- Issue 21256, get Use Metric setting....
         if isnull(@quote,'') <> ''
        	select @ynUMMetric = UseUMMetricYN FROM bMSQH with (nolock) where MSCo = @Co and Quote = @quote
         else
        	set @ynUMMetric = 'N'
        
        
         exec @recode = dbo.bspMSTicMatlVal @Co, 'Y', @MatlGroup, @Material,  @MatlVendor, @FromLoc, @SaleType,
        	  @INCo, @ToLoc, @locgroup, @PhaseGroup, @quote, @disctemplate, @pricetemplate,
        	  @WghtUM, @UM, @CustGroup, @Customer, @JCCo, @Job, @SaleDate, @salesum output, @paydisctype output,
        	  @paydiscrate output, @matlphase output, @matlct output, @haulphase output, @haulct output,
        	  @netumconv output, @matlumconv output, @taxable output, @unitprice output, @ecm output,
        	  @minamt output, @haulcode output, @fil, @fil, @filonhand, @fil, @msg output --Issue: #129350
        
 if @recode <> 0 
         begin
    	   	select @rcode = 1
    	   
    	   	insert into IMWM(ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier)
    	   	values(@ImportId, @ImportTemplate, @Form, @currrecseq, null, @msg, null)
         end
       
         -- issue #21256, convert to metric UM.
         if @ynUMMetric = 'Y' and not (@SaleType = 'C' and (@PaymentType='C' or @PaymentType='X')) 
         begin
        	select @metricUM = @salesum		--should be metric already
       
        	--call validation again to get conversion factor (@matlumconv).
         	exec @recode = dbo.bspMSTicMatlVal @Co, 'Y', @MatlGroup, @Material,  @MatlVendor, @FromLoc, @SaleType,
        	  @INCo, @ToLoc, @locgroup, @PhaseGroup, @quote, @disctemplate, @pricetemplate,
        	  @WghtUM, @metricUM, @CustGroup, @Customer, @JCCo, @Job, @SaleDate, @salesum output, @paydisctype output,
        	  @paydiscrate output, @matlphase output, @matlct output, @haulphase output, @haulct output,
        	  @netumconv output, @matlumconv output, @taxable output, @unitprice output, @ecm output,
        	  @minamt output, @haulcode output, @fil, @fil, @filonhand, @fil, @msg output	--Issue: #129350
        
    	   	if @recode <> 0 
    	   	begin
    	   		select @rcode = 1
    	   
    	   		insert into IMWM(ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier)
    	   		values(@ImportId, @ImportTemplate, @Form, @currrecseq, null, @msg, null)
    	   	end
    	   
    	   	if @ynUM = 'Y' AND (ISNULL(@OverwriteUM, 'Y') = 'Y' OR ISNULL(@IsUMEmpty, 'Y') = 'Y')
    	   	begin
    	   
    	   		select @UM = @metricUM
    	   
    	   	 	update IMWE
    	   	 	set UploadVal = @UM
    	   	    where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    	   	          and IMWE.Identifier = @UMID
    	   
    	   		-- #25139 moved here so having Units selected for default is not necessary.
    	   		-- issue #21256, convert to metric units, unit price, and material total.
    	    		-- issue #23460, divide instead of multiplying.  Factor tells how many of the
    	   		-- standard unit is in the metric unit.
    	    		select @MatlUnits = @MatlUnits / @matlumconv	--convert to metric
    	   
    	           UPDATE IMWE
    	           SET IMWE.UploadVal = @MatlUnits
    	           where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    	                 and IMWE.Identifier = @MatlUnitsID
    	   
        	end
       
         end
        
         If @HaulerType = 'H'
          begin
          	select @trucktype = TruckType
          	from bMSVT with (nolock)
          	where VendorGroup = @VendorGroup and Vendor = @HaulVendor and  Truck = @Truck
          end
        
         If @HaulerType = 'E'
          begin
           exec @recode =  dbo.bspMSTicEquipVal @EMCo, @Equipment, @prco = @truckprco output, @operator = @truckemployee output,
                           @tare = @trucktare output, @trucktype = @trucktype output, @revcode = @truckrevcode output
          end
        
        	if @ynTareWght ='Y' -- and @HaulerType = 'E' and isnull(@trucktare,'') <> ''
         	  begin
               If  @HaulerType = 'E' select @TareWght = @trucktare else select @TareWght = 0
        
               UPDATE IMWE
               SET IMWE.UploadVal = @TareWght
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @TareWghtID
              end
        
        	if @ynMatlUnits ='Y' and isnull(@MatlUnits,0) = 0 AND (ISNULL(@OverwriteMatlUnits, 'Y') = 'Y' OR ISNULL(@IsMatlUnitsEmpty, 'Y') = 'Y')
         	  begin
       	    if isnull(@GrossWght,0)<>0 select @MatlUnits = isnull(@GrossWght,0) - isnull(@TareWght,0)
       
               if @UM<>@WghtUM
               begin
        
                 	select @WghtConv=Conversion from bINMU with (nolock)
                   	where MatlGroup=@MatlGroup and INCo=@Co and Material=@Material and Loc=@FromLoc and UM=@WghtUM
                    if @@rowcount = 0
                     begin
                       exec @rcode = dbo.bspHQStdUMGet @MatlGroup,@Material,@WghtUM,@WghtConv output,@fil output,@fil output
                     end
        
           			select @MatConv=Conversion from bINMU with (nolock)
                   	where MatlGroup=@MatlGroup and INCo=@Co and Material=@Material and Loc=@FromLoc and UM=@UM
           			if @@rowcount = 0
                      begin
                       exec @rcode = dbo.bspHQStdUMGet @MatlGroup,@Material,@UM,@MatConv output,@fil output,@fil output
                      end
                    if isnull(@WghtConv,0) <>0 and isnull(@MatConv,0) <> 0  select @MatlUnits = @MatlUnits * @WghtConv / @MatConv
        
                  end
       
       
               UPDATE IMWE
               SET IMWE.UploadVal = @MatlUnits
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @MatlUnitsID
              end
        
    
        	if @ynPRCo ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwritePRCo, 'Y') = 'Y' OR ISNULL(@IsPRCoEmpty, 'Y') = 'Y')
         	  begin
               select @PRCo = @Co
               IF @HaulerType = 'E' and @truckprco is not null select @PRCo = @truckprco
               UPDATE IMWE
               SET IMWE.UploadVal = @Co
              where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @PRCoID
              end
        
        	if @ynEmployee ='Y' AND (ISNULL(@OverwriteEmployee, 'Y') = 'Y' OR ISNULL(@IsEmployeeEmpty, 'Y') = 'Y') --and @HaulerType = 'E' and isnull(@truckemployee,'') <> ''
         	  begin
            If @HaulerType = 'E'  select @Employee = @truckemployee else Select @Employee = Null
               UPDATE IMWE
               SET IMWE.UploadVal = @Employee
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @EmployeeID
              end
        
        	if @ynDriver ='Y' AND (ISNULL(@OverwriteDriver, 'Y') = 'Y' OR ISNULL(@IsDriverEmpty, 'Y') = 'Y') --and @HaulerType = 'H' and isnull(@HaulVendor,'') <> '' and isnull(@Truck,'') <> ''
         	  begin
               select @Driver = Null
               If @HaulerType = 'H'
                 Begin
                  select @Driver = Driver
                  From bMSVT with (nolock)
                  where VendorGroup = @VendorGroup and Vendor=@HaulVendor and Truck=@Truck
                 End
        
               UPDATE IMWE
 SET IMWE.UploadVal = @Driver
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @DriverID
              end
        
        	if @ynTruckType ='Y' AND (ISNULL(@OverwriteTruckType, 'Y') = 'Y' OR ISNULL(@IsTruckTypeEmpty, 'Y') = 'Y')
         	  begin
               if @HaulerType = 'E' and isnull(@trucktype,'') <> '' select @TruckTyp = @trucktype
         	   if @HaulerType = 'H' and isnull(@trucktype,'') <> '' select @TruckTyp = @trucktype
               if @HaulerType = 'N'select @TruckTyp = null
        
               UPDATE IMWE
               SET IMWE.UploadVal = @TruckTyp
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
               and IMWE.Identifier = @TruckTypeID
              end
        
        	if @ynRevCode ='Y' AND (ISNULL(@OverwriteRevCode, 'Y') = 'Y' OR ISNULL(@IsRevCodeEmpty, 'Y') = 'Y')
         	  begin
               If @HaulerType = 'E' and isnull(@Equipment,'') <> ''
                 select @RevCode = @truckrevcode
               else
        select @RevCode = null
        
       
            UPDATE IMWE
               SET IMWE.UploadVal = @RevCode
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @RevCodeID
              end
        
        	if @ynHours ='Y' and @StartTime is not null and @StopTime is not null AND (ISNULL(@OverwriteHours, 'Y') = 'Y' OR ISNULL(@IsHoursEmpty, 'Y') = 'Y') --#27490, null check.
         	  begin
               select @Hours=0
             If isdate(@StartTime)= 1 and isdate (@StopTime)=1
                  Begin
                   select @Minutes = DATEDIFF(minute,@StartTime,@StopTime)
                   If @Minutes<0 select @Minutes = @Minutes + 1440
                     select @Hours = @Minutes/60
                  End
        
               UPDATE IMWE
               SET IMWE.UploadVal = @Hours
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @HoursID
              end
        
         --issue #27204, group or conditions together to fix IF statement.
         If @HaulerType = 'E' and (@ynRevRate ='Y' or @ynRevBasis ='Y' or @ynRevTotal ='Y') --and isnull(@Equipment,'') <> ''
            begin
			-- ISSUE: #131171 --
				 select @category = Category
				 from bEMEM with (nolock)
				 where EMCo = @EMCo and Equipment = @Equipment
        
				 select @umconv = 0

				 If isnull(@RevCode,'') <> ''
					begin
  					  --issue #27204, clear out values.
    					select @RevRateCur = null, @RevBasisCur = null, @RevTotal = null
	      
						exec @recode = dbo.bspHQStdUMGet @MatlGroup,@Material,@UM, @umconv output,@fil output,@fil output
	        
						exec @recode = dbo.bspMSTicRevCodeVal @Co, @EMCo, @EMGroup, @RevCode, @Equipment, @category, @JCCo, @Job,
							@MatlGroup, @Material, @FromLoc, @MatlUnits, @umconv, @Hours,
							@revbasisamt = @revbasis output, @rate = @revrate output, @basis = @revbasisyn output
        
  					   --#27204, Move default code to be within "isnull(@RevCode,'')<>''" block.
  					   If @ynRevRate ='Y'
  						  begin
  							select @RevRateCur = @revrate
	      	  
  							UPDATE IMWE
  							SET IMWE.UploadVal = @RevRateCur
  							where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
  								  and IMWE.Identifier = @RevRateID

  						  end --If @ynRevRate ='Y'
      	  
  					   If @ynRevBasis ='Y'
  						  begin
	      	  
  							select @RevBasisCur = @revbasis
	      	  
  							UPDATE IMWE
  	        				  SET IMWE.UploadVal = @RevBasisCur
  							where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
  								  and IMWE.Identifier = @RevBasisID
	      	  
  						  end --If @ynRevBasis ='Y'
						
						-- ISSUE: #131171 --
  						If @ynRevTotal ='Y'
  						  begin
  							select @RevTotal = @revbasis * @revrate
	      	  
  							UPDATE IMWE
  							SET IMWE.UploadVal = @RevTotal
  							where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
  								  and IMWE.Identifier = @RevTotalID
	      	  
  						  end --If @ynRevTotal ='Y'

					end --If isnull(@RevCode,'') <> ''

            end --If @HaulerType = 'E' and .....
        
        	if @ynMatlPhase ='Y' AND (ISNULL(@OverwriteMatlPhase, 'Y') = 'Y' OR ISNULL(@IsMatlPhaseEmpty, 'Y') = 'Y')  --and isnull(@MatlGroup,'') <> ''
         	  begin
                If @SaleType = 'J'
                 select @MaterialPhaseCur = @matlphase
                else
                 select @MaterialPhaseCur = null
        
               UPDATE IMWE
               SET IMWE.UploadVal = @MaterialPhaseCur
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @MatlPhaseID
         end
        
        	if @ynMatlJCCType ='Y' AND (ISNULL(@OverwriteMatlJCCType, 'Y') = 'Y' OR ISNULL(@IsMatlJCCTypeEmpty, 'Y') = 'Y') --and isnull(@MatlGroup,'') <> ''
         	  begin
        
                If @SaleType = 'J'
                 select @MatlJCCType = @matlct
                else
                 select @MatlJCCType = null
        
               UPDATE IMWE
               SET IMWE.UploadVal = @MatlJCCType
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @MatlJCCTypeID
              end
     
    --issue #28429
    		--NEW CODE
    
    		-- get IN company pricing options
    		select @priceopt = null
    		select @priceopt = 
    			case @SaleType
    				when 'C' then CustPriceOpt 
    				when 'J' then JobPriceOpt
    				when 'I' then InvPriceOpt
    			end
    		from bINCO with (nolock) where INCo=@Co
    		if @@rowcount = 0
    		begin
    			select @msg = 'Unable to get IN Company parameters'
    		   	select @rcode = 1
    		   
    		   	insert into IMWM(ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier)
    		   	values(@ImportId, @ImportTemplate, @Form, @currrecseq, @recode, @msg, @UnitPriceID)
    		end
			--Issue #128019, do not get default prices unless the material vendor is null.
    		IF @MatlVendor IS NULL
			BEGIN
    	 		-- get material unit price defaults.
    			exec @recode = dbo.bspMSTicMatlPriceGet @Co,@MatlGroup,@Material,@locgroup,@FromLoc,@UM,
    			@quote,@pricetemplate,@SaleDate,@JCCo,@Job,@CustGroup,@Customer,@INCo,@ToLoc,@priceopt, 
    			@SaleType, @PhaseGroup, @MaterialPhaseCur, @MatlVendor, @VendorGroup, 
				@unitprice output, @ecm output, @minamt output, @msg output
    
    			if @recode <> 0
    			begin
    		   		select @rcode = 1
    		   
    		   		insert into IMWM(ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier)
    		   		values(@ImportId, @ImportTemplate, @Form, @currrecseq, @recode, @msg, @UnitPriceID)
    			end
			END

    		if @ynECM = 'Y' AND (ISNULL(@OverwriteECM, 'Y') = 'Y' OR ISNULL(@IsECMEmpty, 'Y') = 'Y')
    		begin
    			select @ECMCur = isnull(@ecm, 'E')
    
    			UPDATE IMWE
    			SET IMWE.UploadVal = @ECMCur
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			     and IMWE.Identifier = @ECMID
    		end
    
    		--MOVED CODE
    
    		if @ynUnitPrice = 'Y' and isnull(@Co,'') <> '' and isnull(@Material,'') <> '' AND (ISNULL(@OverwriteUnitPrice, 'Y') = 'Y' OR ISNULL(@IsUnitPriceEmpty, 'Y') = 'Y')
    		begin
    			if (@SaleType = 'C' and (@PaymentType='C' or @PaymentType='X')) --If Cash sale use imported value
    			 begin
    				  select @SUploadval = IMWE.ImportedVal from IMWE with (nolock)
    			     where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			     and IMWE.Identifier = @UnitPriceID
    			
    			     select @UnitPriceCur = 0
    			
    			     if isnumeric(@SUploadval) = 1 select @UnitPriceCur = convert(decimal(10,5), @SUploadval)
    			 end
    			else
    				 select @UnitPriceCur = @unitprice
    			
    			UPDATE IMWE
    			SET IMWE.UploadVal = @UnitPriceCur
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			     and IMWE.Identifier = @UnitPriceID
    		end
    		
    		
    		if @ynMatlTotal ='Y' AND (ISNULL(@OverwriteMatlTotal, 'Y') = 'Y' OR ISNULL(@IsMatlTotalEmpty, 'Y') = 'Y')
    		begin
    			select @ECMFact = CASE @ECMCur WHEN 'M' then  1000
    			                            WHEN 'C' then  100
    			                            else  1 end
    			
    			if (@SaleType = 'C' and (@PaymentType='C' or @PaymentType='X'))
    			begin
    			     select @SUploadval = IMWE.ImportedVal from IMWE with (nolock)
    			     where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			     and IMWE.Identifier = @MatlTotalID
    			
    			     select @MatlTotal = 0
    			
    			     if isnumeric(@SUploadval) =1 select @MatlTotal = convert(decimal(10,5),@SUploadval)
    			end
    			else
    			begin
    			  if @UnitPriceCur is not null and @MatlUnits is not null select @MatlTotal = ( @MatlUnits / @ECMFact)* @UnitPriceCur
    			  If isnull(@minamt,0)<>0 and isnull(@MatlUnits,0) <> 0 and isnull(@MatlTotal,0)<isnull(@minamt,0) select @MatlTotal = @minamt
    			end
    			
    			UPDATE IMWE
    			SET IMWE.UploadVal = @MatlTotal
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			     and IMWE.Identifier = @MatlTotalID
    		end
        
    --end issue #28429
    
             if @ynZone ='Y' AND (ISNULL(@OverwriteZone, 'Y') = 'Y' OR ISNULL(@IsZoneEmpty, 'Y') = 'Y')
         	  begin
               	select @ZoneCur = @zone
        
    	           UPDATE IMWE
    	           SET IMWE.UploadVal = @ZoneCur
    	           where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    		       and IMWE.Identifier = @ZoneID
              end
        
        	if @ynHaulCode ='Y' AND (ISNULL(@OverwriteHaulCode, 'Y') = 'Y' OR ISNULL(@IsHaulCodeEmpty, 'Y') = 'Y')
         	  begin
        
               if (@SaleType = 'C' and (@PaymentType='C' or @PaymentType='X'))
                  begin
                     select @SUploadval = IMWE.ImportedVal from IMWE with (nolock)
                     where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @HaulCodeID
                     select @HaulCodeCur = @SUploadval
                  end
               else
                  begin
               		If isnull(@HaulerType,'') = 'H' or isnull(@HaulerType,'') = 'E'		--#25079
       				begin
       					select @quotehaulcode = null
       
       		            exec @recode = dbo.bspMSTicTruckTypeVal @Co, @TruckTyp, @quote, @locgroup, @FromLoc, @MatlGroup,
                                 @Material, @UM, @VendorGroup, @HaulVendor, @Truck, @HaulerType, @quotehaulcode output, @paycode = @quotepaycode output, @msg = @msg output
       
       					if @recode <> 0 
       					begin
       						select @rcode = 1
       					
       						insert into IMWM(ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier)
       						values(@ImportId, @ImportTemplate, @Form, @currrecseq, null, @msg, @HaulCodeID)
       					end
       
       					if isnull(@quotehaulcode,'') <> ''
       						select @HaulCodeCur = @quotehaulcode
       					else
       						select @HaulCodeCur = @haulcode
       
       				end

               		else
               			select @HaulCodeCur = Null
                  end
        
               UPDATE IMWE
               SET IMWE.UploadVal = @HaulCodeCur
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @HaulCodeID
          end
        
        	if @ynHaulPhase ='Y' and isnull(@HaulCodeCur,'') <> '' AND (ISNULL(@OverwriteHaulPhase, 'Y') = 'Y' OR ISNULL(@IsHaulPhaseEmpty, 'Y') = 'Y')
         	  begin
               if @SaleType = 'J'
       		begin
       			--Issue #21346
               	if isnull(@haulphase,'') <> '' 
       				select @HaulPhaseCur = @haulphase
       			else
       				select @HaulPhaseCur = @MaterialPhaseCur
       		end
               else
                select @HaulPhaseCur = null
        
               UPDATE IMWE
               SET IMWE.UploadVal = @HaulPhaseCur
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @HaulPhaseID
              end
        
        	if @ynHaulJCCType ='Y' and isnull(@HaulCodeCur,'') <> '' AND (ISNULL(@OverwriteHaulJCCType, 'Y') = 'Y' OR ISNULL(@IsHaulJCCTypeEmpty, 'Y') = 'Y')
         	  BEGIN
				----TK-17302
				IF @SaleType = 'J' 
					BEGIN
					IF @haulct IS NOT NULL
						BEGIN
						SET @HaulJCCType = @haulct
						END
					ELSE
						BEGIN
						SET @HaulJCCType = @MatlJCCType
						END
					END
				ELSE
					BEGIN
					SELECT  @HaulJCCType = NULL
					END
        
               UPDATE IMWE
               SET IMWE.UploadVal = @HaulJCCType
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @HaulJCCTypeID
              end
 
        
        	if @ynPayCode ='Y' AND (ISNULL(@OverwritePayCode, 'Y') = 'Y' OR ISNULL(@IsPayCodeEmpty, 'Y') = 'Y') -- and @HaulerType = 'H'
         	  begin
                  if @HaulerType = 'H'
                    begin
                    exec @recode = dbo.bspMSTicTruckTypeVal @Co, @TruckTyp, @quote, @locgroup, @FromLoc, @MatlGroup,
                                         @Material, @UM, @VendorGroup, @HaulVendor, @Truck, @HaulerType, @haulcode output, @paycode = @quotepaycode output, @msg = @msg output
        
                      exec @recode = dbo.bspMSTicTruckVal @VendorGroup, @HaulVendor, @Truck, @CurrentMode, @paycode = @paycode output, @returnvendor = @returnvendor output, @UpdateVendor = @UpdateVendor OUTPUT, @msg = @msg output
        
                     If isnull(@quotepaycode,'')<>''
                       select @PayCodeCur = @quotepaycode
                	else
              		select @PayCodeCur = @paycode
                	end
        		else
                     select @PayCodeCur = null
        
        
               UPDATE IMWE
               SET IMWE.UploadVal = @PayCodeCur
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @PayCodeID
       
        	end
        
             If isnull(@PayCodeCur,'') <>'' and @HaulerType = 'H' and (@ynPayBasis ='Y' or @ynPayRate ='Y' or @ynPayTotal ='Y' )
              begin
        
                 exec @recode = dbo.bspMSTicPayCodeVal @Co, @PayCodeCur, @MatlGroup, @Material, @locgroup, @FromLoc, @quote,
                               @TruckTyp, @VendorGroup, @HaulVendor, @Truck, @UM, @ZoneCur,
                               @rate = @payrate output, @basis = @paybasis output, @payminamt = @paycodeminamt output, @msg = @msg output
        
        
               if @ynPayBasis ='Y' AND (ISNULL(@OverwritePayBasis, 'Y') = 'Y' OR ISNULL(@IsPayBasisEmpty, 'Y') = 'Y')
         	    begin
                   select @PayBasisCur =  CASE @paybasis WHEN 1 then  @MatlUnits
													  WHEN 2 then  @Hours
                                                      WHEN 3 then  @Loads
                                                      WHEN 4 then  @MatlUnits
                                                      WHEN 5 then  @MatlUnits
                                                      WHEN 6 then  @HaulTotal
                                                      else 0 end
                 UPDATE IMWE
                 SET IMWE.UploadVal = @PayBasisCur
                 where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                       and IMWE.Identifier = @PayBasisID
                end
         		if @ynPayRate ='Y' AND (ISNULL(@OverwritePayRate, 'Y') = 'Y' OR ISNULL(@IsPayRateEmpty, 'Y') = 'Y')
         	    begin
                 select @PayRateCur = @payrate
        
                 UPDATE IMWE
                 SET IMWE.UploadVal = @PayRateCur
                 where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                       and IMWE.Identifier = @PayRateID
                end
        
    
               if @ynPayTotal ='Y' AND (ISNULL(@OverwritePayTotal, 'Y') = 'Y' OR ISNULL(@IsPayTotalEmpty, 'Y') = 'Y')
            	  begin

					set @PayTotal = isnull(@PayBasisCur,0) * isnull(@PayRateCur,0)
                 
					-- ISSUE: #133864 --
					IF ISNULL(@paycodeminamt, 0) <> 0     
						If @PayTotal < @paycodeminamt set @PayTotal = @paycodeminamt
        
					 UPDATE IMWE
					 SET IMWE.UploadVal = @PayTotal
					 where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
						   and IMWE.Identifier = @PayTotalID
                end
             end
        
        	 If isnull(@HaulCodeCur,'') <> ''
        	 begin
        		 		--RT 21286 - Added HCTaxable variable.
                 -- Rates and amounts are based on Pay amounts or Revenue amounts
         		select @RevBased = RevBased, @HCTaxable = Taxable
         		from bMSHC with (nolock)
         		where MSCo = @Co and HaulCode = @HaulCodeCur
        	 end
        
            If isnull(@HaulCodeCur,'') <>'' and (@ynHaulBasis ='Y' or @ynHaulRate ='Y' or @ynHaulTotal ='Y' )
              begin

                 exec @recode = dbo.bspMSTicHaulCodeVal @Co, @HaulCodeCur, @MatlGroup, @Material, @locgroup, @FromLoc, @quote, @UM,
                              @TruckTyp, @ZoneCur, @basis = @haulbasis output, @rate = @haulrate output, @minamt = @haulminamt output,
                              @msg = @msg output
        		
       		if @SaleType = 'J'	--issue #21141, restored by issue #25084.
       			begin
       			select @matlcategory = Category from bHQMT where MatlGroup=@MatlGroup and Material=@Material
       			exec @recode = dbo.bspMSTicHaulRateGet @Co, @HaulCodeCur, @MatlGroup, @Material, @matlcategory, @locgroup, 
       					@FromLoc, @TruckTyp, @UM, @quote, @ZoneCur, @haulbasis, @JCCo, @PhaseGroup, @HaulPhaseCur,
       					@rate = @haulrate output, @minamt = @haulminamt output, @msg = @msg output
        			end
       
               if @ynHaulBasis ='Y' AND (ISNULL(@OverwriteHaulBasis, 'Y') = 'Y' OR ISNULL(@IsHaulBasisEmpty, 'Y') = 'Y')
         	    begin
        
        			select @HaulBasisCur =  CASE @haulbasis WHEN 1 then  @MatlUnits
                                                          WHEN 2 then  @Hours
                                                          WHEN 3 then  @Loads
                                                          WHEN 4 then  @MatlUnits
                                                          WHEN 5 then  @MatlUnits
                                                          else  0 end
        
        			if isnull(@RevBased,'N') = 'Y' and @HaulerType = 'H' and isnull(@PayCodeCur,'') <>'' select @HaulBasisCur = @PayBasisCur
        			if isnull(@RevBased,'N') = 'Y' and @HaulerType = 'E' and isnull(@RevCode,'') <>'' select @HaulBasisCur = @RevBasisCur
        
             if (@SaleType = 'C' and (@PaymentType='C' or @PaymentType='X'))
                     begin
                       select @SUploadval = IMWE.ImportedVal from IMWE with (nolock)
                       where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                       and IMWE.Identifier = @HaulBasisID
        
                       select @HaulBasisCur = 0
                       if  isnumeric(@SUploadval) =1 select @HaulBasisCur = convert(decimal(10,5),@SUploadval)
               end
        
                 UPDATE IMWE
                 SET IMWE.UploadVal = @HaulBasisCur
                 where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                       and IMWE.Identifier = @HaulBasisID
                end
        --mark 6/20
               if @ynHaulRate ='Y' AND (ISNULL(@OverwriteHaulRate, 'Y') = 'Y' OR ISNULL(@IsHaulRateEmpty, 'Y') = 'Y')
         	    begin
       			
        			select @HaulRateCur = @haulrate
        
        			if isnull(@RevBased,'N') = 'Y' and @HaulerType = 'H' and isnull(@PayCodeCur,'') <>'' select @HaulRateCur = @PayRateCur
        			if isnull(@RevBased,'N') = 'Y' and @HaulerType = 'E' and isnull(@RevCode,'') <>'' select @HaulRateCur = @RevRateCur
        
                 if (@SaleType = 'C' and (@PaymentType='C' or @PaymentType='X'))
                   begin
                       select @SUploadval = IMWE.ImportedVal from IMWE with (nolock)
                       where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                       and IMWE.Identifier = @HaulRateID
        
                       select @HaulRateCur = 0
        
                       if isnumeric(@SUploadval) = 1 select @HaulRateCur = convert(decimal(10,5),@SUploadval)
                   end
        
                 UPDATE IMWE
                 SET IMWE.UploadVal = @HaulRateCur
                 where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                       and IMWE.Identifier = @HaulRateID
                end
        
               if @ynHaulTotal ='Y' AND (ISNULL(@OverwriteHaulTotal, 'Y') = 'Y' OR ISNULL(@IsHaulTotalEmpty, 'Y') = 'Y')
            	  begin

        			set @HaulTotal = isnull(@HaulBasisCur,0) * isnull(@HaulRateCur,0)
        			
        			-- ISSUE: #133864 --
        			IF ISNULL(@haulminamt, 0) <> 0          			
        				If @HaulTotal < @haulminamt set @HaulTotal = @haulminamt
        
        			if isnull(@RevBased,'N') = 'Y' and @HaulerType = 'H' and isnull(@PayCodeCur,'') <>'' select @HaulTotal = @PayTotal
        			if isnull(@RevBased,'N') = 'Y' and @HaulerType = 'E' and isnull(@RevCode,'') <>'' select @HaulTotal = @RevTotal
        
                   if (@SaleType = 'C' and (@PaymentType='C' or @PaymentType='X'))
                     begin
                       select @SUploadval = IMWE.ImportedVal from IMWE with (nolock)
                       where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                       and IMWE.Identifier = @HaulTotalID
        
                       select @HaulTotal = 0
        
                       if isnumeric(@SUploadval) =1 select @HaulTotal = convert(decimal(10,5),@SUploadval)
                     end
        
                 UPDATE IMWE
                 SET IMWE.UploadVal = @HaulTotal
                 where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                       and IMWE.Identifier = @HaulTotalID
                end
             end

			-- Issue 122102 If Pay basis is based on Haul then set Pay basis and Pay total based on Haul.
			 if @ynPayBasis ='Y' and @paybasis = 6 AND (ISNULL(@OverwritePayBasis, 'Y') = 'Y' OR ISNULL(@IsPayBasisEmpty, 'Y') = 'Y')
         			begin

					   select @PayBasisCur =  @HaulTotal

					   UPDATE IMWE
					   SET IMWE.UploadVal = @PayBasisCur
					   where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
						   and IMWE.Identifier = @PayBasisID
	        
	    
					   if @ynPayTotal ='Y'
            			  begin
        
		        			set @PayTotal = isnull(@PayBasisCur,0) * isnull(@PayRateCur,0)
                 
							-- ISSUE: #133864 --
							IF ISNULL(@paycodeminamt, 0) <> 0     
								If @PayTotal < @paycodeminamt set @PayTotal = @paycodeminamt
		              
							UPDATE IMWE
							SET IMWE.UploadVal = @PayTotal
							where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
								and IMWE.Identifier = @PayTotalID
						end
					end

             if @ynTaxGroup ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteTaxGroup, 'Y') = 'Y' OR ISNULL(@IsTaxGroupEmpty, 'Y') = 'Y')
         	  begin
               select @TaxGroup = TaxGroup
               from bHQCO
               Where HQCo = @Co
        
               UPDATE IMWE
               SET IMWE.UploadVal = @TaxGroup
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @TaxGroupID
              end
        
             if @ynTaxType ='Y'  AND (ISNULL(@OverwriteTaxType, 'Y') = 'Y' OR ISNULL(@IsTaxTypeEmpty, 'Y') = 'Y')
         	  begin
				select @TaxType = 1
				---- issue #128290
				if @SaleType in ('J','I')
					begin
					select @TaxType = 2
					end
				---- issue #128290
				if @TaxType = 1 and @country in ('AU','CA')
					begin
					select @TaxType = 3
					end

               UPDATE IMWE
               SET IMWE.UploadVal = @TaxType
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @TaxTypeID
         end
         
             if @ynTaxCode ='Y' AND (ISNULL(@OverwriteTaxCode, 'Y') = 'Y' OR ISNULL(@IsTaxCodeEmpty, 'Y') = 'Y')
         	  BEGIN    	  
              select @taxcode =  CASE when @taxopt = 0 then null
                                      when @taxopt = 1 then @loctaxcode
                                      when @taxopt = 2 then @taxcode
                                      when @taxopt = 3 then isnull(@taxcode,@loctaxcode)
                                      ----TK-17308
									  WHEN @taxopt = 4 AND @HaulerType = 'E' AND ISNULL(@Equipment,'') = ''	   THEN @loctaxcode
									  WHEN @taxopt = 4 AND @HaulerType = 'E' AND ISNULL(@Equipment,'') <> ''   THEN @taxcode
                                      WHEN @taxopt = 4 AND @HaulerType = 'H' AND isnull(@HaulCodeCur,'') = ''  THEN @loctaxcode
                                      WHEN @taxopt = 4 AND @HaulerType = 'H' AND isnull(@HaulCodeCur,'') <> '' THEN @taxcode
                                      WHEN @taxopt = 4 AND @HaulerType = 'N' THEN @loctaxcode
                                      ELSE null END
        
        
               select @TaxCodeCur = @taxcode
                      
               UPDATE IMWE
               SET IMWE.UploadVal = @TaxCodeCur
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @TaxCodeID
              end
        
             if @ynTaxBasis ='Y' AND (ISNULL(@OverwriteTaxBasis, 'Y') = 'Y' OR ISNULL(@IsTaxBasisEmpty, 'Y') = 'Y')
         	  begin
           		   if (@SaleType = 'C' and (@PaymentType='C' or @PaymentType='X'))
                     begin
                       select @SUploadval = IMWE.ImportedVal from IMWE with (nolock)
                       where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                       and IMWE.Identifier = @TaxBasisID
        
                       select @TaxBasis = 0
        
                       if isnumeric(@SUploadval) =1 select @TaxBasis = convert(decimal(10,5),@SUploadval)
                     end
                   else
                     begin
                        select @TaxBasis = 0
        
                        If isnull(@Material,'')<>'' and @taxable <> 'N' and isnull(@TaxCodeCur,'')<>'' select @TaxBasis = @MatlTotal
        
        --RBT 21286
        				if @HCTaxable = 'Y' and @HaulerType <> 'N' and isnull(@HaulCodeCur,'')<>'' and isnull(@TaxCodeCur,'')<>'' 
        				begin
        					if (@haultaxopt = 1 and @HaulerType = 'H' and isnull(@HaulVendor,'')<>'') OR (@haultaxopt = 2)
        						select @TaxBasis = @TaxBasis + @HaulTotal
        				end
        
        				if @HaulerType = 'N'
        				begin
        					select @HaulTotal = 0, @HaulCodeCur = null
        				end
        --end RBT 21286
        /*
                        If (@haultaxopt = 2  or (@haultaxopt = 1 and @HaulerType = 'H')) and 
                           		isnull(@HaulCodeCur,'')<>'' and isnull(@TaxCodeCur,'')<>'' 
        					select @TaxBasis = @TaxBasis + @HaulTotal
        */
                     end
        
        
               UPDATE IMWE
               SET IMWE.UploadVal = @TaxBasis
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @TaxBasisID
              end
        
             if @ynTaxTotal='Y' or @ynTaxDisc='Y'
             exec @recode = dbo.bspHQTaxRateGet @TaxGroup, @TaxCodeCur, @SaleDate, @taxrate = @taxrate output, @msg = @msg output
        
        
             if @ynTaxTotal='Y' AND (ISNULL(@OverwriteTaxTotal, 'Y') = 'Y' OR ISNULL(@IsTaxTotalEmpty, 'Y') = 'Y')
         	  begin
                   if (@SaleType = 'C' and (@PaymentType='C' or @PaymentType='X'))
      
                     begin
                       select @SUploadval = IMWE.ImportedVal from IMWE with (nolock)
                       where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    and IMWE.Identifier = @TaxTotalID
        
                       select @TaxTotal = 0
        
                       if isnumeric(@SUploadval) =1 select @TaxTotal = convert(decimal(10,5),@SUploadval)
                     end
                   else
                     begin
                        select @TaxTotal = isnull(@TaxBasis,0) * isnull(@taxrate,0)
                     end
        
        
               UPDATE IMWE
               SET IMWE.UploadVal = @TaxTotal
               where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                     and IMWE.Identifier = @TaxTotalID
              end
        
              If @SaleType = 'C'
                 Begin
                   -- get customer pay terms issue 18762 @payterms 
                   -- select @payterms=PayTerms from bARCM where CustGroup=@CustGroup and Customer=@Customer
                   -- get matldisc flag from HQPT
                   select @hqptdiscrate=DiscRate, @matldisc=MatlDisc from bHQPT where PayTerms=@payterms
                   if @matldisc = 'N' select @paydiscrate = @hqptdiscrate
        
                  if @ynDiscBasis='Y'
                    begin
                      select @DiscBasis = 0
                      If @paydisctype = 'U' and @matldisc = 'Y' select @DiscBasis = @MatlUnits
                   If @paydisctype = 'R' and @matldisc = 'Y' select @DiscBasis = @MatlTotal
                      If @matldisc = 'N' select @DiscBasis = isnull(@MatlTotal,0) + isnull(@HaulTotal,0)
        
                      UPDATE IMWE
                      SET IMWE.UploadVal = @DiscBasis
                      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                            and IMWE.Identifier = @DiscBasisID
                    end
                  if @ynDiscRate='Y'
                    begin
                      select @DiscRate =  @paydiscrate
        
                      UPDATE IMWE
                      SET IMWE.UploadVal = @DiscRate
                      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                   and IMWE.Identifier = @DiscRateID
        
                    end
        
                  if @ynDiscOff='Y'
                       begin
                       select @DiscOff = @DiscRate * @DiscBasis
        
                       UPDATE IMWE
                       SET IMWE.UploadVal = @DiscOff
                       where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                             and IMWE.Identifier = @DiscOffID
                     end
        
                  if @ynTaxDisc='Y'  --and @TaxCodeCur is not null
                     begin
                       select @disctax = DiscTax
                       from bARCO with (nolock)
                       where @Co = ARCo
        
                        If @disctax = 'Y' select @TaxDisc = isnull(@DiscOff,0) * isnull(@taxrate,0)
                   		IF isnull(@TaxCodeCur,'')='' or @TaxTotal = 0 select @TaxDisc = 0
        
                       UPDATE IMWE
            		   SET IMWE.UploadVal = @TaxDisc
                       where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                             and IMWE.Identifier = @TaxDiscID
                     end
        
                 end
        
                  select @HaulBased = null, @RevBased = null
                  If isnull(@HaulCodeCur,'') <>'' and isnull(@RevCode,'') <>''
                     begin
        
                     select @HaulBased = HaulBased
                     from bEMRC with (nolock)
             		where EMGroup = @EMGroup and RevCode=@RevCode
        
                      if @HaulBased = 'Y'
                        begin
                      UPDATE IMWE
                          SET IMWE.UploadVal = @HaulRateCur
                          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                          and IMWE.Identifier = @RevRateID
        
                          UPDATE IMWE
                          SET IMWE.UploadVal = @HaulBasisCur
                          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                          and IMWE.Identifier = @RevBasisID
        
                          UPDATE IMWE
                          SET IMWE.UploadVal = @HaulTotal
                          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
           				  and IMWE.Identifier = @RevTotalID
        
           				end
        
               end
        
                    -- clean up data fields
        
                    IF @SaleType = 'J'
                       begin
                       -- null out @CustomerID, @CustJobID, @CustPOID, @PaymentTypeID, @CheckNoID, @INCoID, @ToLocID
                         UPDATE IMWE
                         SET IMWE.UploadVal = null
                       where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and
                         (IMWE.Identifier = @CustomerID or IMWE.Identifier = @CustJobID or IMWE.Identifier = @CustPOID
                          or IMWE.Identifier = @PaymentTypeID or IMWE.Identifier = @CheckNoID or IMWE.Identifier = @HoldID
                          or IMWE.Identifier = @INCoID or IMWE.Identifier = @ToLocID or IMWE.Identifier = @TaxDiscID
                          or IMWE.Identifier = @DiscOffID or IMWE.Identifier = @DiscRateID or IMWE.Identifier = @DiscBasisID)
                       end
        
                    IF @SaleType = 'I'
                       begin
                       -- null out @CustomerID, @CustJobID, @CustPOID, @PaymentTypeID, @CheckNoID, @JCCoID, @JobID
                         UPDATE IMWE
                         SET IMWE.UploadVal = null
                         where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and
                         (IMWE.Identifier = @CustomerID or IMWE.Identifier = @CustJobID or IMWE.Identifier = @CustPOID
                          or IMWE.Identifier = @PaymentTypeID or IMWE.Identifier = @CheckNoID or IMWE.Identifier = @HoldID
                          or IMWE.Identifier = @JCCoID or IMWE.Identifier = @JobID or IMWE.Identifier = @HaulPhaseID or IMWE.Identifier = @HaulJCCTypeID
                          or IMWE.Identifier = @MatlPhaseID or IMWE.Identifier = @MatlJCCTypeID or IMWE.Identifier = @TaxDiscID
             			  or IMWE.Identifier = @DiscOffID or IMWE.Identifier = @DiscRateID or IMWE.Identifier = @DiscBasisID)
                       end
        
                    IF @SaleType = 'C'
                       begin
                       -- null out  @JCCoID, @JobID, @INCoID, @ToLocID
                         UPDATE IMWE
                         SET IMWE.UploadVal = null
                         where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and
                         (IMWE.Identifier = @JCCoID or IMWE.Identifier = @JobID or IMWE.Identifier = @INCoID
        
                         or IMWE.Identifier = @ToLocID or IMWE.Identifier = @HaulPhaseID or IMWE.Identifier = @HaulJCCTypeID
                       or IMWE.Identifier = @MatlPhaseID or IMWE.Identifier = @MatlJCCTypeID)
                       end
        
                    IF @PaymentType <> 'C'
                     begin
                       -- null out  @CheckNoID
                         UPDATE IMWE
                         SET IMWE.UploadVal = null
                         where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and
                         (IMWE.Identifier = @CheckNoID)
                       end
        
                       IF @HaulerType = 'N'
                       begin
                       -- null out    @EMCoID, @EquipmentID, @PRCoID, @EmployeeID,  @RevCodeID, @RevBasisID, @RevRateID, @RevTotalID
                       -- @TruckTypeID, @StartTimeID, @StopTimeID, @LoadsID, @MilesID, @HoursID, @ZoneID, @GrossWghtID, @TareWghtID, @HaulCodeID,
                       -- @HaulVendorID, @TruckID, @DriverID, @PayCodeID, @PayBasisID, @PayRateID, @PayTotalID,
                       -- @HaulBasisID, @HaulRateID, @HaulTotalID,
                       -- @HaulPhaseID, @HaulJCCTypeID
        
                         UPDATE IMWE
                         SET IMWE.UploadVal = null
                         where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and
                         (IMWE.Identifier = @EMCoID or IMWE.Identifier = @EquipmentID or IMWE.Identifier = @PRCoID or IMWE.Identifier = @EmployeeID
                         or IMWE.Identifier = @RevCodeID or IMWE.Identifier = @RevBasisID or IMWE.Identifier = @RevRateID or IMWE.Identifier = @RevTotalID
                         or IMWE.Identifier = @TruckTypeID or IMWE.Identifier = @StartTimeID or IMWE.Identifier = @StopTimeID or IMWE.Identifier = @LoadsID
                         or IMWE.Identifier = @MilesID or IMWE.Identifier = @HoursID or IMWE.Identifier = @ZoneID
                         or IMWE.Identifier = @GrossWghtID or IMWE.Identifier = @TareWghtID or IMWE.Identifier = @HaulCodeID
                         or IMWE.Identifier = @HaulVendorID or IMWE.Identifier = @TruckID or IMWE.Identifier = @DriverID or IMWE.Identifier = @PayCodeID
                         or IMWE.Identifier = @PayBasisID or IMWE.Identifier = @PayRateID or IMWE.Identifier = @PayTotalID
                         or IMWE.Identifier = @HaulBasisID or IMWE.Identifier = @HaulRateID or IMWE.Identifier = @HaulTotalID
                         or IMWE.Identifier = @HaulPhaseID or IMWE.Identifier = @HaulJCCTypeID)
                       end
        
                       IF @HaulerType = 'E'
                       begin
              -- Haul Vendor, Truck #, Driver, Pay Code, Pay Basis, PayRate, PayTotal,
            UPDATE IMWE
                         SET IMWE.UploadVal = null
                         where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and
                         (IMWE.Identifier = @HaulVendorID or IMWE.Identifier = @TruckID or IMWE.Identifier = @DriverID or IMWE.Identifier = @PayCodeID
                         or IMWE.Identifier = @PayBasisID or IMWE.Identifier = @PayRateID or IMWE.Identifier = @PayTotalID)
                       end
        
    
                       IF @HaulerType = 'H'
                       begin
                          --  EMCo, Equipment, PRCo, Employee,  Rev Code, Rev Basis, Rev Rate, Rev Total
                         UPDATE IMWE
                         SET IMWE.UploadVal = null
                         where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and
                         (IMWE.Identifier = @EMCoID or IMWE.Identifier = @EquipmentID or IMWE.Identifier = @PRCoID or IMWE.Identifier = @EmployeeID
                         or IMWE.Identifier = @RevCodeID or IMWE.Identifier = @RevBasisID or IMWE.Identifier = @RevRateID or IMWE.Identifier = @RevTotalID)
                       end
        		-- Need to remove truck & driver when HaulType='H' and no haulvendor
                       IF @HaulerType = 'H' and isnull(@HaulVendor,'')=''
                       begin
                          --  Truck #, Driver
                         UPDATE IMWE
                         SET IMWE.UploadVal = null
                         where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and
                         (IMWE.Identifier = @TruckID or IMWE.Identifier = @DriverID)
                       end
        
                       IF isnull(@HaulCodeCur,'') =''
                       begin
                          --     Haul Basis, Haul Rate, Haul Charge,
                          --     Haul Phase, Haul Cost Type
                         UPDATE IMWE
                         SET IMWE.UploadVal = null
                         where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and
                 		 (IMWE.Identifier = @HaulBasisID or IMWE.Identifier = @HaulRateID or IMWE.Identifier = @HaulTotalID
                 		 or IMWE.Identifier = @HaulPhaseID or IMWE.Identifier = @HaulJCCTypeID)
                       end
        
       
                    select @currrecseq = @Recseq
                    select @counter = @counter + 1
                    select @Co = null, @Mth = null, @BatchSeq = null, @BatchTransType = null, @SaleDate = null, @FromLoc = null,
                           @Ticket = null, @Void = null, @VendorGroup = null, @MatlVendor = null, @SaleType = null,
                           @CustGroup = null, @Customer = null, @CustJob = null, @CustPO = null, @PaymentType = null,
                           @CheckNo = null, @Hold = null, @JCCo = null, @PhaseGroup = null, @Job = null, @INCo = null,
                           @ToLoc = null, @MatlGroup = null, @Material = null, @UM = null, @MaterialPhaseCur = null, @MatlJCCType = null,
                           @HaulerType = null, @EMCo = null, @EMGroup = null, @Equipment = null, @PRCo = null, @Employee = null,
                           @HaulVendor = null, @Truck = null, @Driver = null, @GrossWght = null, @TareWght = null, @WghtUM = null,
                           @MatlUnits = null, @UnitPriceCur = null, @ECMCur = null, @MatlTotal = null, @TruckTyp = null, @StartTime = null,
                           @StopTime = null, @Loads = null, @Miles = null, @Hours = null, @ZoneCur = null,  @HaulCodeCur = null,
                           @HaulPhaseCur = null, @HaulJCCType = null, @HaulBasisCur = null, @HaulRateCur = null, @HaulTotal = null,
                           @RevCode = null, @RevRateCur = null, @RevBasisCur = null, @RevTotal = null, @PayCodeCur = null, @PayRateCur = null,
                           @PayBasisCur = null, @PayTotal = null, @TaxGroup = null, @TaxCodeCur = null, @TaxType = null, @TaxBasis = null,
                           @TaxTotal = null, @DiscBasis = null, @DiscRate = null, @DiscOff = null, @TaxDisc = null, @quotepaycode = null
        
                end
        
        end
        
        
        UPDATE IMWE
        SET IMWE.UploadVal = 0
        where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.UploadVal is null and
        (IMWE.Identifier = @GrossWghtID or IMWE.Identifier = @TareWghtID or IMWE.Identifier = @MatlUnitsID
         or IMWE.Identifier = @UnitPriceID or IMWE.Identifier = @MatlTotalID or IMWE.Identifier = @TaxDiscID
         or IMWE.Identifier = @TaxDiscID or IMWE.Identifier = @DiscOffID or IMWE.Identifier = @DiscRateID
         or IMWE.Identifier = @DiscBasisID or IMWE.Identifier = @TaxTotalID or IMWE.Identifier = @TaxBasisID
         or IMWE.Identifier = @RevTotalID or IMWE.Identifier = @RevRateID or IMWE.Identifier = @RevBasisID
         or IMWE.Identifier = @PayTotalID or IMWE.Identifier = @PayRateID or IMWE.Identifier = @PayBasisID
         or IMWE.Identifier = @HaulTotalID or IMWE.Identifier = @HaulRateID or IMWE.Identifier = @HaulBasisID
         or IMWE.Identifier = @HoursID or IMWE.Identifier = @MilesID or IMWE.Identifier = @LoadsID)
        
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'
        where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and isnull(IMWE.UploadVal,'') not in ('N','Y') and
        (IMWE.Identifier = @HoldID or IMWE.Identifier = @VoidID)
        
        bspexit:
        If @opencursor = 1
           begin
          close WorkEditCursor
           deallocate WorkEditCursor
           end
        
            select @msg = isnull(@desc,'Material Sales') + char(13) + char(10) + '[bspBidtekDefaultMSTB]'
        
            return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspIMBidtekDefaultsMSTB] TO [public]
GO
