SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vspIMBidtekDefaultsMSTB]
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
		 *				AMR 09/09/11 - Refactoring FOR performance issues experience WITH larger customers
         *				AMR 10/13/11 - TK-09062 Adding PaymentType Default IN FOR A
						AMR 11/17/11 - TK-10092 fixing the sales type selection and adding ticket to the update
						AMR 11/22/11 - TK-10181 fixing PRCo and letting the hauler rate over rides.
						AMR 1/4/12 - TK-11476 making just the columns that we deal with NULL
						AMR 1/19/12 - TK-11938 - Adding the filter @ImportId to update STATEMENT
						JayR 6/29/2012 - TK-16090 - Change the logic so company defaults correctly.
		 *				GF 08/21/2012 TK-17295 missing COLUMNS TO UPDATE FOR DEFAULTS	
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
BEGIN
        set nocount on
        
        declare @rcode int, @recode int, @desc varchar(120), @ynCo bYN,  @ynVoid bYN, @ynBatchTransType bYN,
                @ynVendorGroup bYN, @ynMatlVendor bYN, @ynSaleType bYN, @ynCustGroup bYN, @ynCustomer bYN, @ynCustJob bYN,
                @ynCustPO bYN, @ynPaymentType bYN, @ynCheckNo bYN, @ynHold bYN, @ynJCCo bYN, @ynPhaseGroup bYN, @ynJob bYN, @ynINCo bYN,
                @ynToLoc bYN, @ynMatlGroup bYN, @ynMaterial bYN, @ynUM bYN, @ynMatlPhase bYN, @ynMatlJCCType bYN, @ynHaulerType bYN, @ynEMCo bYN,
                @ynEMGroup bYN, @ynEquipment bYN, @ynPRCo bYN, @ynEmployee bYN, @ynHaulVendor bYN, @ynTruck bYN, @ynDriver bYN, @ynGrossWght bYN,
                @ynTareWght bYN, @ynWghtUM bYN, @ynMatlUnits bYN, @ynUnitPrice bYN, @ynECM bYN, @ynMatlTotal bYN, @ynTruckType bYN,
                @ynStartTime bYN, @ynStopTime bYN, @ynLoads bYN, @ynMiles bYN, @ynHours bYN, @ynZone bYN, @ynHaulCode bYN, @ynHaulPhase bYN,
                @ynHaulJCCType bYN, @ynHaulBasis bYN, @ynHaulRate bYN, @ynHaulTotal bYN, @ynRevCode bYN, @ynRevRate bYN, @ynRevBasis bYN,
                @ynRevTotal bYN, @ynPayCode bYN, @ynPayRate bYN, @ynPayBasis bYN, @ynPayTotal bYN, @ynTaxGroup bYN, @ynTaxCode bYN,
                @ynTaxType bYN, @ynTaxBasis bYN, @ynTaxTotal bYN, @ynDiscBasis bYN, @ynDiscRate bYN, @ynDiscOff bYN, @ynTaxDisc bYN,
        		@ynUMMetric bYN, @ynCountry bYN, @ynSaleDate bYN, @ynPayType bYN,
        		----TK-17295
        		@ynTicket bYN
        
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
        
        -- setting these in the pivot
        SELECT  @ynECM = 'N'
        
        SELECT @rcode = 0
        
        /* check required input params */
		-- hate gotos will knock these out later when I can see the bottom
        IF @ImportId IS NULL 
            BEGIN
                SELECT  @desc = 'Missing ImportId.',
                        @rcode = 1
                GOTO bspexit
            END
        IF @ImportTemplate IS NULL 
            BEGIN
                SELECT  @desc = 'Missing ImportTemplate.',
                        @rcode = 1
                GOTO bspexit
            END
        
        IF @Form IS NULL 
            BEGIN
                SELECT  @desc = 'Missing Form.',
                        @rcode = 1
                GOTO bspexit
            END
        
        -- Check ImportTemplate detail for columns to set Bidtek Defaults
        -- ahh the love of the @@rowcount, lets not use this
        IF NOT EXISTS (SELECT 1
		FROM			IMTD WITH ( NOLOCK )
		WHERE			IMTD.ImportTemplate = @ImportTemplate
						AND IMTD.DefaultValue = '[Bidtek]'	)
        BEGIN 
			SELECT  @desc = 'No Bidtek Defaults set up for ImportTemplate '
                        + @ImportTemplate + '.',
                        @rcode = 1
                GOTO bspexit
            END
        
        -- keeping the vars so I don't have to dump them to a temp table and do queries again
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
			, @OverwritePayType				bYN
			----TK-17295
			, @OverwriteCustomer			bYN
			, @OverwriteCustJob				bYN
			, @OverwriteCustPO				bYN
			, @OverwriteGrossWght			bYN
			, @OverwriteCheckNo				bYN
			, @OverwriteMatlVendor			bYN
			, @OverwriteTicket				bYN
			
		-- okay first let's make a list of columns we want to work with
		DECLARE @ColList varchar(MAX)
		SET @ColList = 'BatchTransType,Co,SaleDate,Void,Hold,ECM,SaleType,VendorGroup,CustGroup,'+
						'JCCo,PhaseGroup,INCo,MatlGroup,UM,MatlPhase,MatlJCCType,WghtUM,MatlUnits,'+
						'EMGroup,PRCo,UnitPrice,MatlTotal,Zone,TareWght,Employee,'+
						'TruckType,HaulCode,HaulPhase,HaulJCCType,RevCode,EMCo,TaxType,TaxCode,'+
						'TaxGroup,Loads,Miles,[Hours],HaulBasis,HaulRate,HaulTotal,PayBasis,PayRate,'+
						'PayTotal,RevBasis,RevRate,RevTotal,TaxBasis,TaxTotal,DiscBasis,DiscRate,'+
						'DiscOff,TaxDisc,Driver,HaulerType,PayCode,StartTime,StopTime,ToLoc,Job,'+
						----TK-17295
						'FromLoc,HaulVendor,Equipment,Truck,Material,Customer,CustJob,CustPO,'+
						'GrossWght,PaymentType,CheckNo,MatlVendor,Ticket'		
		
		-- lets build a table of tables to update, someday ill improve the vfTableFromArray to run better
		CREATE TABLE #tblCols (ColumnName varchar(30))
		
		INSERT INTO #tblCols ( ColumnName )
		SELECT RTRIM(LTRIM([Names])) -- just in case someone puts white space into the list
		FROM dbo.vfTableFromArray(@ColList)
		
		-- replaces the	 vfIMTemplateOverwrite function, one shot all defaults
		SELECT @OverwriteBatchTransType = piv.BatchTransType
			, @OverwriteCo  = piv.Co
			, @OverwriteSaleDate  = piv.SaleDate
			, @OverwriteVoid  = piv.Void
			, @OverwriteHold  = piv.Hold
			, @OverwriteECM	 = piv.ECM
			, @OverwriteSaleType  = piv.SaleType
			, @OverwriteVendorGroup	 = piv.VendorGroup
			, @OverwriteCustGroup   = piv.CustGroup
			, @OverwriteJCCo  = piv.JCCo
			, @OverwritePhaseGroup    = piv.PhaseGroup
			, @OverwriteINCo  = piv.INCo
			, @OverwriteMatlGroup   = piv.MatlGroup
			, @OverwriteUM = piv.UM
			, @OverwriteMatlPhase = piv.MatlPhase
			, @OverwriteMatlJCCType = piv.MatlJCCType
			, @OverwriteWghtUM = piv.WghtUM
			, @OverwriteMatlUnits = piv.MatlUnits
			, @OverwriteEMGroup = piv.EMGroup
			, @OverwritePRCo = piv.PRCo
			, @OverwriteUnitPrice   = piv.UnitPrice
			, @OverwriteMatlTotal = piv.MatlTotal
			, @OverwriteZone = piv.Zone
			, @OverwriteTareWght = piv.TareWght
			, @OverwriteEmployee = piv.Employee
			, @OverwriteTruckType = piv.TruckType
			, @OverwriteHaulCode = piv.HaulCode
			, @OverwriteHaulPhase = piv.HaulPhase
			, @OverwriteHaulJCCType = piv.HaulJCCType
			, @OverwriteRevCode = piv.RevCode
			, @OverwriteEMCo = piv.EMCo
			, @OverwriteTaxType = piv.TaxType
			, @OverwriteTaxCode = piv.TaxCode
			, @OverwriteTaxGroup = piv.TaxGroup
			, @OverwriteLoads = piv.Loads
			, @OverwriteMiles = piv.Miles
			, @OverwriteHours = piv.[Hours]
			, @OverwriteHaulBasis = piv.HaulBasis
			, @OverwriteHaulRate = piv.HaulRate
			, @OverwriteHaulTotal = piv.HaulTotal
			, @OverwritePayBasis = piv.PayBasis
			, @OverwritePayRate = piv.PayRate
			, @OverwritePayTotal = piv.PayTotal
			, @OverwriteRevBasis = piv.RevBasis
			, @OverwriteRevRate = piv.RevRate
			, @OverwriteRevTotal = piv.RevTotal
			, @OverwriteTaxBasis = piv.TaxBasis
			, @OverwriteTaxTotal = piv.TaxTotal
			, @OverwriteDiscBasis = piv.DiscBasis
			, @OverwriteDiscRate = piv.DiscRate
			, @OverwriteDiscOff = piv.DiscOff
			, @OverwriteTaxDisc = piv.TaxDisc
			, @OverwriteDriver = piv.Driver
			, @OverwriteHaulerType = piv.HaulerType
			, @OverwritePayCode = piv.PayCode
			, @OverwritePayType	= piv.PaymentType
			----TK-17295
			, @OverwriteCustomer = piv.Customer
			, @OverwriteCustJob = piv.CustJob
			, @OverwriteCustPO	= piv.CustPO
			, @OverwriteGrossWght = piv.GrossWght	
			, @OverwriteCheckNo	= piv.CheckNo
			, @OverwriteMatlVendor = piv.MatlVendor
			, @OverwriteTicket = piv.Ticket
			
		FROM (
			   SELECT	d.ColumnName,
						CASE WHEN ISNULL(@rectype,'')='' THEN 'N' ELSE i.OverrideYN END AS OverwriteValue
			   FROM dbo.bDDUD d
					JOIN #tblCols c ON d.ColumnName = c.ColumnName
					LEFT JOIN 	dbo.IMTD i WITH (NOLOCK) ON i.Identifier = d.Identifier 
											AND i.ImportTemplate= @ImportTemplate
											AND i.DefaultValue = '[Bidtek]'
											AND i.RecordType = @rectype
											AND d.Form = @Form
			)   a
		PIVOT (MAX(a.OverwriteValue) 
				FOR a.ColumnName IN (	BatchTransType,Co,SaleDate,Void,Hold,ECM,SaleType,VendorGroup,CustGroup,
										JCCo,PhaseGroup,INCo,MatlGroup,UM,MatlPhase,MatlJCCType,WghtUM,MatlUnits,
										EMGroup,PRCo,UnitPrice,MatlTotal,Zone,TareWght,Employee,
										TruckType,HaulCode,HaulPhase,HaulJCCType,RevCode,EMCo,TaxType,TaxCode,
										TaxGroup,Loads,Miles,[Hours],HaulBasis,HaulRate,HaulTotal,PayBasis,PayRate,
										PayTotal,RevBasis,RevRate,RevTotal,TaxBasis,TaxTotal,DiscBasis,DiscRate,
										DiscOff,TaxDisc,Driver,HaulerType,PayCode,StartTime,StopTime,ToLoc,Job,
										FromLoc,HaulVendor,Equipment,Truck,Material,Customer,CustJob,CustPO,
										GrossWght,PaymentType,CheckNo,MatlVendor,Ticket)
									) piv
		-- in talking with DAN this might not be needed, we should always have a rectype, therefore
		-- we will alway have an overwrite or we won't, so instead of assigning N for nulls to the overwrite
		-- leave it null and that means N for the yn vars.
		SELECT 
				@ynHold = ISNULL(piv.Hold,'N'), 
				@ynBatchTransType = ISNULL(piv.BatchTransType,'N'), 
				@ynVoid =  ISNULL(piv.Void,'N'),
				@ynCo  = ISNULL(piv.Co,'N'), 
                @ynVendorGroup = ISNULL(piv.VendorGroup,'N'),
                @ynSaleType = ISNULL(piv.SaleType,'N'),
                @ynCustGroup = ISNULL(piv.CustGroup,'N'),
                @ynJCCo = ISNULL(piv.JCCo,'N'),
                @ynPhaseGroup = ISNULL(piv.PhaseGroup,'N'),
                @ynJob = ISNULL(piv.Job,'N'),
                @ynINCo = ISNULL(piv.INCo,'N'),
                @ynToLoc = ISNULL(piv.ToLoc,'N'),
                @ynMatlGroup = ISNULL(piv.MatlGroup,'N'),
                @ynMaterial = ISNULL(piv.Material,'N'),
                @ynUM = ISNULL(piv.UM,'N'),
                @ynMatlPhase = ISNULL(piv.MatlPhase,'N'),
                @ynMatlJCCType = ISNULL(piv.MatlJCCType,'N'),
                @ynHaulerType = ISNULL(piv.HaulerType,'N'),
                @ynEMCo = ISNULL(piv.EMCo,'N'),
                @ynEMGroup = ISNULL(piv.EMGroup,'N'),
                @ynEquipment = ISNULL(piv.Equipment,'N'),
                @ynPRCo = ISNULL(piv.PRCo,'N'),
                @ynEmployee = ISNULL(piv.Employee,'N'),
                @ynHaulVendor = ISNULL(piv.HaulVendor,'N'),
                @ynTruck = ISNULL(piv.Truck,'N'),
                @ynDriver = ISNULL(piv.Driver,'N'),
                @ynTareWght = ISNULL(piv.TareWght,'N'),
                @ynWghtUM = ISNULL(piv.WghtUM,'N'),
                @ynMatlUnits = ISNULL(piv.MatlUnits,'N'),
                @ynUnitPrice = ISNULL(piv.UnitPrice,'N'),
                @ynECM = ISNULL(piv.ECM,'N'),
                @ynMatlTotal = ISNULL(piv.MatlTotal,'N'),
                @ynTruckType = ISNULL(piv.TruckType,'N'),
                @ynStartTime = ISNULL(piv.StartTime,'N'),
                @ynStopTime = ISNULL(piv.StopTime,'N'),
                @ynLoads = ISNULL(piv.Loads,'N'),
                @ynMiles = ISNULL(piv.Miles,'N'),
                @ynHours = ISNULL(piv.[Hours],'N'),
                @ynZone = ISNULL(piv.[Zone],'N'),
                @ynHaulCode = ISNULL(piv.HaulCode,'N'),
                @ynHaulPhase = ISNULL(piv.HaulPhase,'N'),
                @ynHaulJCCType = ISNULL(piv.HaulJCCType,'N'),
                @ynHaulBasis = ISNULL(piv.HaulBasis,'N'),
                @ynHaulRate = ISNULL(piv.HaulRate,'N'),
                @ynHaulTotal = ISNULL(piv.HaulTotal,'N'),
                @ynRevCode = ISNULL(piv.RevCode,'N'),
                @ynRevRate = ISNULL(piv.RevRate,'N'),
                @ynRevBasis = ISNULL(piv.RevBasis,'N'),
                @ynRevTotal = ISNULL(piv.RevTotal,'N'),
                @ynPayCode = ISNULL(piv.PayCode,'N'),
                @ynPayRate = ISNULL(piv.PayRate,'N'),
                @ynPayBasis = ISNULL(piv.PayBasis,'N'),
                @ynPayTotal = ISNULL(piv.PayTotal,'N'),
                @ynTaxGroup = ISNULL(piv.TaxGroup,'N'),
                @ynTaxCode = ISNULL(piv.TaxCode,'N'),
                @ynTaxType = ISNULL(piv.TaxType,'N'),
                @ynTaxBasis = ISNULL(piv.TaxBasis,'N'),
                @ynTaxTotal = ISNULL(piv.TaxTotal,'N'),
                @ynDiscBasis = ISNULL(piv.DiscBasis,'N'),
                @ynDiscRate = ISNULL(piv.DiscRate,'N'),
                @ynDiscOff = ISNULL(piv.DiscOff,'N'),
                @ynTaxDisc = ISNULL(piv.TaxDisc,'N'),
                @ynECM = ISNULL(piv.ECM,'N'),
                @ynPayType = ISNULL(piv.PaymentType,'N'),
                ----TK-17295
                @ynCustomer = ISNULL(piv.Customer,'N'),
                @ynCustJob = ISNULL(piv.CustJob,'N'),
                @ynCustPO = ISNULL(piv.CustPO,'N'),
                @ynGrossWght = ISNULL(piv.GrossWght,'N'),
                @ynCheckNo = ISNULL(piv.CheckNo,'N'),
                @ynMatlVendor = ISNULL(piv.MatlVendor,'N'),
                @ynTicket = ISNULL(piv.Ticket,'N')
	   FROM (
			   SELECT	d.ColumnName,
						CASE WHEN i.Identifier IS NULL THEN 'N' ELSE 'Y' END AS OverrideValue
			   FROM dbo.bDDUD d
					JOIN #tblCols c ON d.ColumnName = c.ColumnName
					LEFT JOIN 	dbo.IMTD i WITH (NOLOCK) ON i.Identifier = d.Identifier 
											AND i.ImportTemplate= @ImportTemplate
											AND i.DefaultValue = '[Bidtek]'
			   WHERE d.Form = @Form
			)   a
		PIVOT (MAX(a.OverrideValue) 
				FOR a.ColumnName IN (	Co,BatchTransType,Void,Hold,ECM,SaleType,VendorGroup,CustGroup,
										JCCo,PhaseGroup,INCo,MatlGroup,UM,MatlPhase,MatlJCCType,WghtUM,MatlUnits,
										EMGroup,PRCo,UnitPrice,MatlTotal,Zone,TareWght,Employee,
										TruckType,HaulCode,HaulPhase,HaulJCCType,RevCode,EMCo,TaxType,TaxCode,
										TaxGroup,Loads,Miles,[Hours],HaulBasis,HaulRate,HaulTotal,PayBasis,PayRate,
										PayTotal,RevBasis,RevRate,RevTotal,TaxBasis,TaxTotal,DiscBasis,DiscRate,
										DiscOff,TaxDisc,Driver,HaulerType,PayCode,StartTime,StopTime,ToLoc,Job,
										FromLoc,HaulVendor,Equipment,Truck,Material,Customer,CustJob,CustPO,
										GrossWght,PaymentType,CheckNo,MatlVendor,Ticket)
										) piv
	
		
	    -- let's see how to process the cursor
        -- here is the cursor set, pivoted out        
		SELECT
			ROW_NUMBER() OVER (ORDER BY RecordSeq) AS tmpID, -- I need a primary key, when I deal with joining
			piv.*
		INTO #tmpPivIMWE
		FROM (
			SELECT  IMWE.RecordSeq,
					DDUD.TableName,
					DDUD.ColumnName,
					IMWE.UploadVal,
					CONVERT(char(2),'US') AS Country -- make this column for later updates
			FROM    dbo.IMWE
					INNER JOIN dbo.DDUD ON IMWE.Identifier = DDUD.Identifier
													   AND DDUD.Form = IMWE.Form
			WHERE   IMWE.ImportId = @ImportId
					AND IMWE.ImportTemplate = @ImportTemplate
					AND IMWE.Form LIKE @Form
		) AS a											 
		PIVOT  (
				-- use the upload value instead of the imported value
				-- this catches cross references and keyed in defaults
				-- I'm breaking this from the old version where we would intermix upload and imported
				-- I'm going to drive from the upload
					MAX(a.UploadVal)
					FOR a.ColumnName IN (BatchTransType,Co,SaleDate,Void,Hold,ECM,SaleType,VendorGroup,CustGroup,
										JCCo,PhaseGroup,INCo,MatlGroup,UM,MatlPhase,MatlJCCType,WghtUM,MatlUnits,
										EMGroup,PRCo,UnitPrice,MatlTotal,Zone,TareWght,Employee,
										TruckType,HaulCode,HaulPhase,HaulJCCType,RevCode,EMCo,TaxType,TaxCode,
										TaxGroup,Loads,Miles,[Hours],HaulBasis,HaulRate,HaulTotal,PayBasis,PayRate,
										PayTotal,RevBasis,RevRate,RevTotal,TaxBasis,TaxTotal,DiscBasis,DiscRate,
										DiscOff,TaxDisc,Driver,HaulerType,PayCode,StartTime,StopTime,ToLoc,Job,
										FromLoc,HaulVendor,Equipment,Truck,Material,Customer,CustJob,CustPO,
										GrossWght,PaymentType,CheckNo,Mth,BatchSeq,MatlVendor,Ticket)
				)			
				   AS piv
	
		
        --let's add a cluster index on tmpID since we are going to use it everywhere
		CREATE UNIQUE CLUSTERED INDEX IX_tmpPivIMWE ON #tmpPivIMWE (tmpID)
		
		-- we are going to work off the temp table which for problem loads should provide performance
		-- this is because we have a smaller data set in the temp table than IMWE
		-- and we will hit all the rows at once per column
		-- for 100 imported rows in the past we loop 100 x 56 columns or 5600 times to update values and other selects
		-- now this should be just 56 times one for each column to a smaller 100 row temp table versus 
		-- a 1 million row IMWE table
		-- then the plan is to write back to IMWE in one shot   

		IF @ynBatchTransType = 'Y'
		BEGIN
			UPDATE piv
			SET BatchTransType = 'A'
			FROM #tmpPivIMWE piv
			WHERE piv.BatchTransType IS NULL
				OR ( ISNULL(@OverwriteBatchTransType, 'Y') = 'Y' ) 
		END
		
		--JayR The old procedure that starts with a 'b' updates the company wrong and then later updates the company correctly.
		IF @ynCo = 'Y' OR ISNULL(@OverwriteCo, 'Y') = 'N'
		BEGIN
		
			UPDATE piv
			SET Co = @Company
			FROM #tmpPivIMWE piv
		END

		--update the country field now
		IF @ynCountry = 'Y'
		BEGIN
			UPDATE piv
			SET Country = 
				COALESCE(h.Country, h.DefaultCountry,'US')
			FROM  #tmpPivIMWE piv
					JOIN dbo.bHQCO h ON h.HQCo = piv.Co
		END
		                        
		IF @ynSaleDate = 'Y'
		BEGIN
			UPDATE piv
			SET SaleDate = CONVERT(varchar(60), dbo.vfDateOnly(), 101)
			FROM #tmpPivIMWE piv
			WHERE piv.SaleDate IS NULL
				OR ( ISNULL(@OverwriteSaleDate, 'Y') = 'Y' ) 
		END
		
		--check issues with data and then update to null if bad
		UPDATE #tmpPivIMWE
		SET SaleDate = CASE WHEN ISDATE(SaleDate) = 1 THEN SaleDate ELSE NULL END, -- don't covert date, never written back
			Customer = CASE WHEN ISNUMERIC(Customer) = 1 THEN CONVERT(int,Customer) ELSE NULL END,
			Co = CASE WHEN ISNUMERIC(Co) = 1 THEN CONVERT(int,Co) ELSE NULL END,
			Mth = CASE WHEN ISDATE(Mth) = 1 THEN Mth ELSE NULL END,
			BatchSeq = CASE WHEN ISNUMERIC(BatchSeq) = 1 THEN BatchSeq ELSE NULL END,
			VendorGroup = CASE WHEN ISNUMERIC(VendorGroup) = 1 THEN VendorGroup ELSE NULL END,
			MatlVendor = CASE WHEN ISNUMERIC(MatlVendor) = 1 THEN MatlVendor ELSE NULL END,	
			CustGroup = CASE WHEN ISNUMERIC(CustGroup) = 1 THEN CustGroup ELSE NULL END,			
			JCCo = CASE WHEN ISNUMERIC(JCCo) = 1 THEN CONVERT(int,JCCo) ELSE NULL END,	
			PhaseGroup = CASE WHEN ISNUMERIC(PhaseGroup) = 1 THEN CONVERT(int,PhaseGroup) ELSE NULL END,	
			INCo = CASE WHEN ISNUMERIC(INCo) = 1 THEN CONVERT(numeric,INCo) ELSE NULL END,	
			MatlGroup = CASE WHEN ISNUMERIC(MatlGroup) = 1 THEN CONVERT(numeric,MatlGroup) ELSE NULL END,	
			MatlJCCType = CASE WHEN ISNUMERIC(MatlJCCType) = 1 THEN CONVERT(numeric,MatlJCCType) ELSE NULL END,	
			EMCo = CASE WHEN ISNUMERIC(EMCo) = 1 THEN CONVERT(int,EMCo) ELSE NULL END,	
			EMGroup = CASE WHEN ISNUMERIC(EMGroup) = 1 THEN CONVERT(int,EMGroup) ELSE NULL END,	
			PRCo = CASE WHEN ISNUMERIC(PRCo) = 1 THEN CONVERT(int,PRCo) ELSE NULL END,	
			Employee = CASE WHEN ISNUMERIC(Employee) = 1 THEN CONVERT(int,Employee) ELSE NULL END,
			HaulVendor = CASE WHEN ISNUMERIC(HaulVendor) = 1 THEN CONVERT(int,HaulVendor) ELSE NULL END,
			GrossWght = CASE WHEN ISNUMERIC(GrossWght) = 1 THEN CONVERT(decimal(12,3),GrossWght) ELSE NULL END,
			TareWght = CASE WHEN ISNUMERIC(TareWght) = 1 THEN CONVERT(decimal(12,3),TareWght) ELSE NULL END,
			MatlUnits = CASE WHEN ISNUMERIC(MatlUnits) = 1 THEN MatlUnits ELSE NULL END,
			UnitPrice = CASE WHEN ISNUMERIC(UnitPrice) = 1 THEN UnitPrice ELSE NULL END,
			MatlTotal = CASE WHEN ISNUMERIC(MatlTotal) = 1 THEN MatlTotal ELSE NULL END

		IF @ynVoid = 'Y'
		BEGIN
			UPDATE piv
			SET Void = 'N'
			FROM #tmpPivIMWE piv
			WHERE piv.Void IS NULL
				OR ( ISNULL(@OverwriteVoid, 'Y') = 'Y' ) 
		END

		IF @ynHold = 'Y'
		BEGIN
			UPDATE piv
			SET Hold = 'N'
			FROM #tmpPivIMWE piv
			WHERE piv.Hold IS NULL
				OR ( ISNULL(@OverwriteHold, 'Y') = 'Y' ) 
		END 
		
		-- let's do the work on the temp table
		-- start with the start and end times
		-- we can move this up later possibly
		UPDATE #tmpPivIMWE
		SET StartTime =	 CASE WHEN LEN(StartTime) = 5
                                    AND ISDATE(StartTime) = 1 
								 THEN SaleDate + ' ' + StartTime 
							  WHEN LEN(StartTime) = 4
									AND ISNUMERIC(StartTime) = 1 
								THEN  SaleDate + (SUBSTRING(StartTime,1, 2) + ':'
                                                + SUBSTRING(StartTime, 3, 2))
                             ELSE StartTime
                           END,
            StopTime =   CASE WHEN LEN(StopTime) = 5
                                    AND ISDATE(StopTime) = 1 
								 THEN SaleDate + ' ' + StopTime 
							  WHEN LEN(StopTime) = 4
									AND ISNUMERIC(StopTime) = 1 
								THEN  StopTime + (SUBSTRING(StopTime,1, 2) + ':'
                                                + SUBSTRING(StopTime, 3, 2))
                             ELSE StopTime
                           END
        
                           
		IF @ynVendorGroup = 'Y'
		BEGIN 
			UPDATE piv
			SET VendorGroup = h.VendorGroup
			FROM #tmpPivIMWE piv
				JOIN dbo.bMSCO m ON m.MSCo = piv.Co	
				JOIN dbo.bHQCO h ON m.APCo = h.HQCo
			WHERE piv.VendorGroup IS NULL
				OR ISNULL(@OverwriteVendorGroup, 'Y') = 'Y'
		END
		    
        SELECT  @SaleTypeID = DDUD.Identifier,
                @defaultvalue = IMTD.DefaultValue
        FROM    IMTD WITH ( NOLOCK )
                INNER JOIN DDUD WITH ( NOLOCK ) ON IMTD.Identifier = DDUD.Identifier
                                                   AND DDUD.Form = @Form
        WHERE   IMTD.ImportTemplate = @ImportTemplate
                AND DDUD.ColumnName = 'SaleType'
        IF @@rowcount <> 0
            AND @defaultvalue = '[Bidtek]' 
            SELECT  @ynSaleType = 'Y'
		
		IF @ynSaleType = 'Y'
		BEGIN
            UPDATE piv
			SET SaleType = CASE WHEN ISNULL(piv.Customer,'') <> '' THEN 'C' -- customer overrides all
								WHEN ISNULL(piv.Job,'') <> '' THEN 'J' -- then job
								WHEN ISNULL(piv.ToLoc,'') <> '' THEN 'I' -- then location
								ELSE 'C' -- if all else, make C
							END
			FROM #tmpPivIMWE piv
			WHERE piv.SaleType IS NULL
				OR ISNULL(@OverwriteSaleType, 'Y') = 'Y'
		END
        
       	IF @ynCustGroup = 'Y'
		BEGIN 
			UPDATE piv
			SET CustGroup = h.CustGroup
			FROM #tmpPivIMWE piv
				JOIN bMSCO m ON m.MSCo = piv.Co	
				JOIN bHQCO h ON m.ARCo = h.HQCo
			WHERE piv.CustGroup IS NULL
				OR ISNULL(@OverwriteCustGroup, 'Y') = 'Y'
		END 
		
		IF @ynJCCo = 'Y' 
		BEGIN 
			UPDATE piv
			SET JCCo = CASE WHEN piv.SaleType = 'J' THEN piv.Co
							ELSE NULL
						END
			FROM #tmpPivIMWE piv
			WHERE piv.JCCo IS NULL
				OR ISNULL(@OverwriteJCCo, 'Y') = 'Y'
		END 
		
		IF @ynPhaseGroup = 'Y'
		BEGIN 
			UPDATE piv
			SET PhaseGroup = h.PhaseGroup 
			FROM #tmpPivIMWE piv
				JOIN dbo.bHQCO h ON h.HQCo = piv.JCCo
			WHERE piv.PhaseGroup IS NULL
				OR ISNULL(@OverwritePhaseGroup, 'Y') = 'Y'
		END 
		
		IF @ynINCo = 'Y'
		BEGIN
			UPDATE piv
			SET INCo =	CASE WHEN piv.SaleType = 'I' THEN piv.Co
							ELSE NULL
						END 
			FROM #tmpPivIMWE piv
			WHERE piv.Co IS NOT NULL
				AND (piv.INCo IS NULL
					OR ISNULL(@OverwriteINCo, 'Y') = 'Y')
		END
				
		IF @ynMatlGroup = 'Y'
		BEGIN
			UPDATE piv
			SET MatlGroup =	h.MatlGroup
			FROM #tmpPivIMWE piv
				JOIN dbo.bHQCO h ON h.HQCo = piv.Co
			WHERE piv.Co IS NOT NULL
				AND (piv.MatlGroup IS NULL
					OR ISNULL(@OverwriteMatlGroup, 'Y') = 'Y')
		END
		
		IF @ynWghtUM = 'Y'
		BEGIN
			UPDATE piv
			SET WghtUM = CASE i.WghtOpt
							WHEN 1 THEN 'LBS'
                            WHEN 2 THEN 'TON'
                            WHEN 3 THEN 'kg'
                            ELSE NULL
                         END
			FROM #tmpPivIMWE piv
				 JOIN bINLM i ON i.INCo = piv.Co AND i.Loc = piv.FromLoc
			WHERE piv.MatlGroup IS NOT NULL
				AND (piv.WghtUM IS NULL
					OR ISNULL(@OverwriteWghtUM, 'Y') = 'Y')
		END
		
		IF @ynEMCo = 'Y'
		BEGIN
			UPDATE piv
			SET EMCo = piv.Co
			FROM #tmpPivIMWE piv
			WHERE piv.Co IS NOT NULL
				AND (piv.MatlGroup IS NULL
					OR ISNULL(@OverwriteEMCo, 'Y') = 'Y')
		END
		
		IF @ynEMGroup = 'Y' 
		BEGIN
			UPDATE piv
			SET EMGroup = h.EMGroup
			FROM #tmpPivIMWE piv
				JOIN dbo.bHQCO h ON h.HQCo = piv.EMCo
			WHERE piv.EMCo IS NOT NULL
				AND (piv.EMGroup IS NULL
					OR ISNULL(@OverwriteEMGroup, 'Y') = 'Y')
				AND piv.HaulerType = 'E'
		END

        IF @ynHaulerType = 'Y'
		BEGIN
			UPDATE piv
			SET HaulerType = CASE WHEN ISNULL(piv.Truck,'') <> ''
										OR ISNULL(piv.HaulVendor, '') <> '' THEN 'H'
									WHEN ISNULL(piv.Equipment, '') <> ''
											AND ISNULL(piv.HaulVendor,'') = '' THEN 'E'
									ELSE piv.HaulerType
								END 
			FROM #tmpPivIMWE piv
			WHERE (piv.HaulerType IS NULL
					OR ISNULL(@OverwriteHaulerType, 'Y') = 'Y')
				AND piv.HaulerType = 'E'
		END    
	
		IF @ynUM = 'Y'
		BEGIN
			UPDATE piv
			SET UM = h.SalesUM
			FROM #tmpPivIMWE piv
				JOIN dbo.bHQMT h ON piv.MatlGroup = h.MatlGroup
									AND piv.Material = h.Material
			WHERE (piv.UM IS NULL
					OR ISNULL(@OverwriteUM, 'Y') = 'Y')
		END    
	
		IF @ynPayType = 'Y'
		BEGIN
			UPDATE piv
			SET PaymentType = 'A'
			FROM #tmpPivIMWE piv
			WHERE piv.PaymentType IS NULL
					OR ISNULL(@OverwritePayType, 'Y') = 'Y'
		END    
		
		-- okay so here is where I'm going to cutoff refactoring for the most part
		-- before going down the rabbit hole of refactoring other procs, I'm just going to take our pivoted set
		-- and loop over the validation procs for it.  This cuts complexity, but we are still looping :(
		BEGIN -- block the cursor for rollups	
				
			DECLARE curDefaultMSTB CURSOR LOCAL FAST_FORWARD FOR
			SELECT  tmpID,
					RecordSeq,
					BatchTransType,
					Co,
					SaleDate,
					Void,
					Hold,
					ECM,
					SaleType,
					VendorGroup,
					CustGroup,
					JCCo,
					PhaseGroup,
					INCo,
					MatlGroup,
					UM,
					MatlPhase,
					MatlJCCType,
					WghtUM,
					MatlUnits,
					EMGroup,
					PRCo,
					UnitPrice,
					MatlTotal,
					Zone,
					TareWght,
					Employee,
					TruckType,
					HaulCode,
					HaulPhase,
					HaulJCCType,
					RevCode,
					EMCo,
					TaxType,
					TaxCode,
					TaxGroup,
					Loads,
					Miles,
					[Hours],
					HaulBasis,
					HaulRate,
					HaulTotal,
					PayBasis,
					PayRate,
					PayTotal,
					RevBasis,
					RevRate,
					RevTotal,
					TaxBasis,
					TaxTotal,
					DiscBasis,
					DiscRate,
					DiscOff,
					TaxDisc,
					Driver,
					HaulerType,
					PayCode,
					StartTime,
					StopTime,
					ToLoc,
					Job,
					FromLoc,
					HaulVendor,
					Equipment,
					Truck,
					Material,
					Customer,
					CustJob,
					CustPO,
					GrossWght
			FROM    #tmpPivIMWE
			
			
			DECLARE	@currrecseq int,
					@allownull int,
					@error int,
					@tsql varchar(255),
					@valuelist varchar(255),
					@columnlist varchar(255),
					@complete int,
					@counter int,
					@records int,
					@oldrecseq int
					
			DECLARE @Co bCompany,
				@Mth bMonth,
				@BatchId bBatchID,
				@BatchSeq int,
				@BatchTransType char(1),
				@SaleDate bDate,
				@FromLoc bLoc,
				@Ticket varchar(10),
				@Void bYN,
				@VendorGroup bGroup,
				@MatlVendor bVendor,
				@SaleType char(1),
				@CustGroup bGroup,
				@Customer bCustomer,
				@CustJob varchar(20),
				@CustPO varchar(20),
				@PaymentType char(1),
				@CheckNo varchar(10),
				@Hold bYN,
				@JCCo bCompany,
				@PhaseGroup bGroup,
				@Job bJob,
				@INCo bCompany,
				@ToLoc bLoc,
				@MatlGroup bGroup,
				@Material bMatl,
				@UM bUM,
				@MaterialPhaseCur bPhase,
				@MatlJCCType bJCCType,
				@HaulerType char(1),
				@EMCo bCompany,
				@EMGroup bGroup,
				@Equipment bEquip,
				@PRCo bCompany,
				@Employee bEmployee,
				@HaulVendor bVendor,
				@Truck varchar(10),
				@Driver bDesc,
				@GrossWght bUnits,
				@TareWght bUnits,
				@WghtUM bUM,
				@MatlUnits bUnits,
				@UnitPriceCur bUnitCost,
				@ECMCur bECM,
				@MatlTotal bDollar,
				@TruckTyp varchar(10),
				@StartTime smalldatetime,
				@StopTime smalldatetime,
				@Loads smallint,
				@Miles bUnits,
				@Hours bHrs,
				@ZoneCur varchar(10),
				@HaulCodeCur bHaulCode,
				@HaulPhaseCur bPhase,
				@HaulJCCType bJCCType,
				@HaulBasisCur bUnits,
				@HaulRateCur bUnitCost,
				@HaulTotal bDollar,
				@RevCode bRevCode,
				@RevRateCur bUnitCost,
				@RevBasisCur bUnits,
				@RevTotal bDollar,
				@PayCodeCur bPayCode,
				@PayRateCur bUnitCost,
				@PayBasisCur bUnits,
				@PayTotal bDollar,
				@TaxGroup bGroup,
				@TaxCodeCur bTaxCode,
				@TaxType tinyint,
				@TaxBasis bUnits,
				@TaxTotal bDollar,
				@DiscBasis bUnits,
				@DiscRate bUnitCost,
				@DiscOff bDollar,
				@TaxDisc bDollar,
				@loctaxcode bTaxCode,
				@taxopt tinyint,
				@payterms bPayTerms,
				@matldisc bYN,
				@hqptdiscrate bUnitCost,
				@HCTaxable bYN,
				@metricUM bUM,
				@returnvendor bVendor,
				@UpdateVendor char(1),
				@CurrentMode varchar(10),
				@tmpID int,
				@SUploadval varchar(60),
				@Recseq int
			    
			DECLARE @costtypeout bEMCType,
					@Wghtopt tinyint,
					@WghtConv bUnitCost,
					@MatConv bUnitCost,
					@fil varchar(60),
					@filonhand numeric(12, 3)
	            
			OPEN curDefaultMSTB	
			FETCH NEXT FROM curDefaultMSTB INTO 
											@tmpID,
											@currrecseq,
											@BatchTransType,
											@Co,
											@SaleDate,
											@Void,
											@Hold,
											@ECMCur,
											@SaleType,
											@VendorGroup,
											@CustGroup,
											@JCCo,
											@PhaseGroup,
											@INCo,
											@MatlGroup,
											@UM,
											@MaterialPhaseCur,
											@MatlJCCType,
											@WghtUM,
											@MatlUnits,
											@EMGroup,
											@PRCo,
											@UnitPriceCur,
											@MatlTotal,
											@ZoneCur,
											@TareWght,
											@Employee,
											@TruckTyp,
											@HaulCodeCur,
											@HaulPhaseCur,
											@HaulJCCType,
											@RevCode,
											@EMCo,
											@TaxType,
											@TaxCodeCur,
											@TaxGroup,
											@Loads,
											@Miles,
											@Hours,
											@HaulBasisCur,
											@HaulRateCur,
											@HaulTotal,
											@PayBasisCur,
											@PayRateCur,
											@PayTotal,
											@RevBasisCur,
											@RevRateCur,
											@RevTotal,
											@TaxBasis,
											@TaxTotal,
											@DiscBasis,
											@DiscRate,
											@DiscOff,
											@TaxDisc,
											@Driver,
											@HaulerType,
											@PayCodeCur,
											@StartTime,
											@StopTime,
											@ToLoc,
											@Job,
											@FromLoc,
											@HaulVendor,
											@Equipment,
											@Truck,
											@Material,
											@Customer,
											@CustJob,
											@CustPO,
											@GrossWght
			
			WHILE @@FETCH_STATUS = 0
			BEGIN
					
			   -- notice we are starting at setting defaults for now
			   -- we have to make these procs support temp tables or make functions before we can go further
			   /* get defaults for later use from bsp*/
				SELECT  @taxopt = TaxOpt -- 0 - No Tax, 1 - Sales Location, 2 - SaleType/Purchaser, 3 - SaleType/Purchaser/Sales Location, 4 - Delivery
				FROM    dbo.bMSCO WITH ( NOLOCK )
				WHERE   MSCo = @Co
	        
				-- initialize variable on every cycle
				SELECT  @loctaxcode = NULL

				SELECT  @locgroup = LocGroup,
						@loctaxcode = TaxCode
				FROM    dbo.bINLM WITH ( NOLOCK )
				WHERE   INCo = @Co
						AND Loc = @FromLoc
	        
				SELECT  @quote = NULL,
						@disctemplate = NULL,
						@pricetemplate = NULL,
						@zone = NULL,
						@haultaxopt = NULL,
						@taxcode = NULL,
						@salesum = NULL,
						@paydisctype = NULL,
						@paydiscrate = NULL,
						@matlphase = NULL,
						@matlct = NULL,
						@haulphase = NULL,
						@haulct = NULL,
						@netumconv = NULL,
						@matlumconv = NULL,
						@taxable = NULL,
						@unitprice = NULL,
						@ecm = NULL,
						@minamt = NULL,
						@haulcode = NULL,
						@payterms = NULL
	        
				EXEC @recode = dbo.bspMSTicTemplateGet 
								@Co,
								@SaleType,
								@CustGroup,
								@Customer,
								@CustJob,
								@CustPO,
								@JCCo,
								@Job,
								@INCo,
								@ToLoc,
								@FromLoc,
								@quote OUTPUT,
								@disctemplate OUTPUT,
								@pricetemplate OUTPUT,
								@zone OUTPUT,
								@haultaxopt OUTPUT,
								@taxcode OUTPUT,
								@payterms OUTPUT,
								NULL,
								NULL,
								NULL,
								@msg OUTPUT        

		  
			-- Issue 21256, get Use Metric setting....
				IF ISNULL(@quote, '') <> '' 
					SELECT  @ynUMMetric = UseUMMetricYN
					FROM    dbo.bMSQH WITH ( NOLOCK )
					WHERE   MSCo = @Co
							AND Quote = @quote
				ELSE 
					SET @ynUMMetric = 'N'
					
	 	        
				EXEC @recode = dbo.bspMSTicMatlVal 
					@Co,
					'Y',
					@MatlGroup,
					@Material,
					@MatlVendor,
					@FromLoc,
					@SaleType,
					@INCo,
					@ToLoc,
					@locgroup,
					@PhaseGroup,
					@quote,
					@disctemplate,
					@pricetemplate,
					@WghtUM,
					@UM,
					@CustGroup,
					@Customer,
					@JCCo,
					@Job,
					@SaleDate,
					@salesum OUTPUT,
					@paydisctype OUTPUT,
					@paydiscrate OUTPUT,
					@matlphase OUTPUT,
					@matlct OUTPUT,
					@haulphase OUTPUT,
					@haulct OUTPUT,
					@netumconv OUTPUT,
					@matlumconv OUTPUT,
					@taxable OUTPUT,
					@unitprice OUTPUT,
					@ecm OUTPUT,
					@minamt OUTPUT,
					@haulcode OUTPUT,
					@fil,
					@fil,
					@filonhand,
					@fil,
					@msg OUTPUT --Issue: #129350
	        
				IF @recode <> 0 
				BEGIN
						SELECT  @rcode = 1

						INSERT  INTO dbo.bIMWM
								( ImportId,
								  ImportTemplate,
								  Form,
								  RecordSeq,
								  Error,
								  [Message],
								  Identifier
								)
						VALUES  ( @ImportId,
								  @ImportTemplate,
								  @Form,
								  @currrecseq,
								  NULL,
								  @msg,
								  NULL
								)
					 END
	                            
			 -- issue #21256, convert to metric UM.
				IF @ynUMMetric = 'Y'
				 AND NOT ( @SaleType = 'C'
							AND ( @PaymentType = 'C'
									OR @PaymentType = 'X'
								 )
						) 
				BEGIN
					SELECT  @metricUM = @salesum		--should be metric already

				--call validation again to get conversion factor (@matlumconv).
					EXEC @recode = dbo.bspMSTicMatlVal 
						@Co,
						'Y',
						@MatlGroup,
						@Material,
						@MatlVendor,
						@FromLoc,
						@SaleType,
						@INCo,
						@ToLoc,
						@locgroup,
						@PhaseGroup,
						@quote,
						@disctemplate,
						@pricetemplate,
						@WghtUM,
						@metricUM,
						@CustGroup,
						@Customer,
						@JCCo,
						@Job,
						@SaleDate,
						@salesum OUTPUT,
						@paydisctype OUTPUT,
						@paydiscrate OUTPUT,
						@matlphase OUTPUT,
						@matlct OUTPUT,
						@haulphase OUTPUT,
						@haulct OUTPUT,
						@netumconv OUTPUT,
						@matlumconv OUTPUT,
						@taxable OUTPUT,
						@unitprice OUTPUT,
						@ecm OUTPUT,
						@minamt OUTPUT,
						@haulcode OUTPUT,
						@fil,
						@fil,
						@filonhand,
						@fil,
						@msg OUTPUT	--Issue: #129350

					IF @recode <> 0 
					BEGIN
						SELECT  @rcode = 1

						INSERT  INTO dbo.bIMWM
								( ImportId,
								  ImportTemplate,
								  Form,
								  RecordSeq,
								  Error,
								  Message,
								  Identifier
								)
						VALUES  ( @ImportId,
								  @ImportTemplate,
								  @Form,
								  @currrecseq,
								  NULL,
								  @msg,
								  NULL
								)
					END

					IF @ynUM = 'Y'
						AND ( ISNULL(@OverwriteUM, 'Y') = 'Y'
							  OR @UM IS NULL
							) 
					BEGIN
						-- instead of IMWE update the temp table
						UPDATE #tmpPivIMWE
						SET  UM = @metricUM
						WHERE tmpID = @tmpID

					-- #25139 moved here so having Units selected for default is not necessary.
					-- issue #21256, convert to metric units, unit price, and material total.
					-- issue #23460, divide instead of multiplying.  Factor tells how many of the
					-- standard unit is in the metric unit.
						SELECT  @MatlUnits = @MatlUnits / @matlumconv	--convert to metric

						UPDATE  #tmpPivIMWE
						SET     MatlUnits = @MatlUnits
						WHERE   tmpID = @tmpID
					END

				END
	                            
				IF @HaulerType = 'H' 
				BEGIN
					SELECT  @trucktype = TruckType
					FROM    dbo.bMSVT WITH ( NOLOCK )
					WHERE   VendorGroup = @VendorGroup
							AND Vendor = @HaulVendor
							AND Truck = @Truck
				END

				IF @HaulerType = 'E' 
				BEGIN
					EXEC @recode = dbo.bspMSTicEquipVal 
						@EMCo,
						@Equipment,
						@prco = @truckprco OUTPUT,
						@operator = @truckemployee OUTPUT,
						@tare = @trucktare OUTPUT,
						@trucktype = @trucktype OUTPUT,
						@revcode = @truckrevcode OUTPUT
				END
	                             
				IF @ynTareWght = 'Y' -- and @HaulerType = 'E' and isnull(@trucktare,'') <> ''
				BEGIN
						IF @HaulerType = 'E' 
							SELECT  @TareWght = @trucktare
						ELSE 
							SELECT  @TareWght = 0

						UPDATE  #tmpPivIMWE
						SET     TareWght = @TareWght
						WHERE   tmpID = @tmpID
				END 
		    
				IF @ynMatlUnits = 'Y'
					AND ISNULL(@MatlUnits, 0) = 0
					AND ( ISNULL(@OverwriteMatlUnits, 'Y') = 'Y'
							OR @MatlUnits IS NULL
						) 
				BEGIN
					IF ISNULL(@GrossWght, 0) <> 0 
						SELECT  @MatlUnits = ISNULL(@GrossWght, 0)
								- ISNULL(@TareWght, 0)

					IF @UM <> @WghtUM 
					BEGIN
	  					SELECT  @WghtConv = Conversion
						FROM    dbo.bINMU WITH ( NOLOCK )
						WHERE   MatlGroup = @MatlGroup
								AND INCo = @Co
								AND Material = @Material
								AND Loc = @FromLoc
								AND UM = @WghtUM
						IF @@rowcount = 0 
							BEGIN
								EXEC @rcode = dbo.bspHQStdUMGet 
									@MatlGroup,
									@Material,
									@WghtUM,
									@WghtConv OUTPUT,
									@fil OUTPUT,
									@fil OUTPUT
							END

						SELECT  @MatConv = Conversion
						FROM    bINMU WITH ( NOLOCK )
						WHERE   MatlGroup = @MatlGroup
								AND INCo = @Co
								AND Material = @Material
								AND Loc = @FromLoc
								AND UM = @UM
						IF @@rowcount = 0 
							BEGIN
								EXEC @rcode = dbo.bspHQStdUMGet 
									@MatlGroup,
									@Material,
									@UM,
									@MatConv OUTPUT,
									@fil OUTPUT,
									@fil OUTPUT
							END
						IF ISNULL(@WghtConv, 0) <> 0
							AND ISNULL(@MatConv, 0) <> 0 
							SELECT  @MatlUnits = @MatlUnits
									* @WghtConv / @MatConv
					END

					UPDATE  #tmpPivIMWE
					SET     MatlUnits = @MatlUnits
					WHERE   tmpID = @tmpID
				END
				IF @ynPRCo = 'Y'
					AND ISNULL(@Co, '') <> ''
					AND ( ISNULL(@OverwritePRCo, 'Y') = 'Y'
						  OR @PRCo IS NULL
						) 
				BEGIN
					SELECT  @PRCo = @Co
					IF @HaulerType = 'E'
						AND @truckprco IS NOT NULL 
						SELECT  @PRCo = @truckprco
						
					UPDATE  #tmpPivIMWE
					SET     PRCo = @Co
					WHERE   tmpID = @tmpID
				END
	            SELECT @Employee                    
				IF @ynEmployee = 'Y'
						AND ( ISNULL(@OverwriteEmployee, 'Y') = 'Y'
						  OR @Employee IS NULL
						) --and @HaulerType = 'E' and isnull(@truckemployee,'') <> ''
				BEGIN
					IF @HaulerType = 'E' 
						SELECT  @Employee = @truckemployee
					ELSE 
						SELECT  @Employee = NULL
				
					UPDATE  #tmpPivIMWE
					SET     Employee = @Employee
					WHERE   tmpID = @tmpID
				END
	                         
	                             
				IF @ynDriver = 'Y'
					AND ( ISNULL(@OverwriteDriver, 'Y') = 'Y'
					  OR @Driver IS NULL
					) --and @HaulerType = 'H' and isnull(@HaulVendor,'') <> '' and isnull(@Truck,'') <> ''
				BEGIN
					SELECT  @Driver = NULL
					
					IF @HaulerType = 'H' 
					BEGIN
						SELECT  @Driver = Driver
						FROM    bMSVT WITH ( NOLOCK )
						WHERE   VendorGroup = @VendorGroup
								AND Vendor = @HaulVendor
								AND Truck = @Truck
					END

					UPDATE  #tmpPivIMWE
					SET     Driver = @Driver
					WHERE   tmpID = @tmpID
				END
	        
				IF @ynTruckType = 'Y'
					AND ( ISNULL(@OverwriteTruckType, 'Y') = 'Y'
					  OR @TruckTyp IS NULL
					) 
				BEGIN
					IF @HaulerType = 'E'
						AND ISNULL(@trucktype, '') <> '' 
						SELECT  @TruckTyp = @trucktype
					IF @HaulerType = 'H'
						AND ISNULL(@trucktype, '') <> '' 
						SELECT  @TruckTyp = @trucktype
					IF @HaulerType = 'N' SELECT @TruckTyp = NULL
					
					UPDATE  #tmpPivIMWE
					SET     TruckType = @TruckTyp
					WHERE   tmpID = @tmpID
				END
	                            
				IF @ynRevCode = 'Y'
					AND ( ISNULL(@OverwriteRevCode, 'Y') = 'Y'
					  OR @RevCode IS NULL
					) 
				BEGIN
					IF @HaulerType = 'E'
						AND ISNULL(@Equipment, '') <> '' 
						SELECT  @RevCode = @truckrevcode
					ELSE 
						SELECT  @RevCode = NULL

					UPDATE  #tmpPivIMWE
					SET     RevCode = @RevCode
					WHERE   tmpID = @tmpID
				END

				IF @ynHours = 'Y'
					AND @StartTime IS NOT NULL
					AND @StopTime IS NOT NULL
					AND ( ISNULL(@OverwriteHours, 'Y') = 'Y'
						  OR @Hours IS NULL
						) --#27490, null check.
				BEGIN
					SELECT  @Hours = 0
					IF ISDATE(@StartTime) = 1
						AND ISDATE(@StopTime) = 1 
					BEGIN
						SELECT  @Minutes = DATEDIFF(minute,
											  @StartTime,
											  @StopTime)
						IF @Minutes < 0 
							SELECT  @Minutes = @Minutes + 1440
						SELECT  @Hours = @Minutes / 60
					END
						
					UPDATE  #tmpPivIMWE
					SET     [Hours] = @Hours
					WHERE   tmpID = @tmpID
				END
				
			--issue #27204, group or conditions together to fix IF statement.
				IF @HaulerType = 'E'
					AND ( @ynRevRate = 'Y'
						  OR @ynRevBasis = 'Y'
						  OR @ynRevTotal = 'Y'
						) --and isnull(@Equipment,'') <> ''
				BEGIN
				-- ISSUE: #131171 --
					SELECT  @category = Category
					FROM    bEMEM WITH ( NOLOCK )
					WHERE   EMCo = @EMCo
							AND Equipment = @Equipment

					SELECT  @umconv = 0

					IF ISNULL(@RevCode, '') <> '' 
					BEGIN
					 --issue #27204, clear out values.
						SELECT  @RevRateCur = NULL,
								@RevBasisCur = NULL,
								@RevTotal = NULL

						EXEC @recode = dbo.bspHQStdUMGet 
							@MatlGroup,
							@Material,
							@UM,
							@umconv OUTPUT,
							@fil OUTPUT,
							@fil OUTPUT

						EXEC @recode = dbo.bspMSTicRevCodeVal 
							@Co,
							@EMCo,
							@EMGroup,
							@RevCode,
							@Equipment,
							@category,
							@JCCo,
							@Job,
							@MatlGroup,
							@Material,
							@FromLoc,
							@MatlUnits,
							@umconv,
							@Hours,
							@revbasisamt = @revbasis OUTPUT,
							@rate = @revrate OUTPUT,
							@basis = @revbasisyn OUTPUT
	    
					  --#27204, Move default code to be within "isnull(@RevCode,'')<>''" block.
						IF @ynRevRate = 'Y' 
							BEGIN
								SELECT  @RevRateCur = @revrate
	                            
                    			UPDATE  #tmpPivIMWE
								SET     RevRate = @RevRateCur
								WHERE   tmpID = @tmpID
							END --If @ynRevRate ='Y'
	  	  
						IF @ynRevBasis = 'Y' 
							BEGIN
								SELECT  @RevBasisCur = @revbasis
	                            
								UPDATE  #tmpPivIMWE
								SET     RevBasis = @RevBasisCur
								WHERE   tmpID = @tmpID
							END --If @ynRevBasis ='Y'
						
						-- ISSUE: #131171 --
						IF @ynRevTotal = 'Y' 
							BEGIN
								SELECT  @RevTotal = @revbasis
										* @revrate

								UPDATE  #tmpPivIMWE
								SET     RevTotal = @RevTotal
								WHERE   tmpID = @tmpID
							END --If @ynRevTotal ='Y'

					END --If isnull(@RevCode,'') <> ''

				END --If @HaulerType = 'E' and .....
	                            
				IF @ynMatlPhase = 'Y'
					AND ( ISNULL(@OverwriteMatlPhase, 'Y') = 'Y'
						  OR @MaterialPhaseCur IS NULL
						)  --and isnull(@MatlGroup,'') <> ''
				BEGIN
					IF @SaleType = 'J' 
						SELECT  @MaterialPhaseCur = @matlphase
					ELSE 
						SELECT  @MaterialPhaseCur = NULL
	                    
        			UPDATE  #tmpPivIMWE
					SET     MatlPhase = @MaterialPhaseCur
					WHERE   tmpID = @tmpID
				END
		
				IF @ynMatlJCCType = 'Y'
					AND ( ISNULL(@OverwriteMatlJCCType, 'Y') = 'Y'
						  OR @MatlJCCType IS NULL
						) --and isnull(@MatlGroup,'') <> ''
				BEGIN
					IF @SaleType = 'J' 
						SELECT  @MatlJCCType = @matlct
					ELSE 
						SELECT  @MatlJCCType = NULL
	                    
					UPDATE  #tmpPivIMWE
					SET     MatlJCCType = @MatlJCCType
					WHERE   tmpID = @tmpID
				END
	            
				--issue #28429
				--NEW CODE
	    
				-- get IN company pricing options
				SELECT  @priceopt = NULL
				SELECT  @priceopt = CASE @SaleType
									  WHEN 'C' THEN CustPriceOpt
									  WHEN 'J' THEN JobPriceOpt
									  WHEN 'I' THEN InvPriceOpt
									END
				FROM    bINCO WITH ( NOLOCK )
				WHERE   INCo = @Co
				
				IF @@rowcount = 0 
				BEGIN
					SELECT  @msg = 'Unable to get IN Company parameters'
					SELECT  @rcode = 1

					INSERT  INTO dbo.IMWM
							( ImportId,
							  ImportTemplate,
							  Form,
							  RecordSeq,
							  Error,
							  [Message],
							  Identifier
							)
					VALUES  ( @ImportId,
							  @ImportTemplate,
							  @Form,
							  @currrecseq,
							  @recode,
							  @msg,
							  @UnitPriceID
							)
				END
				
				--Issue #128019, do not get default prices unless the material vendor is null.
				IF @MatlVendor IS NULL 
				BEGIN
				-- get material unit price defaults.
					EXEC @recode = dbo.bspMSTicMatlPriceGet 
						@Co,
						@MatlGroup,
						@Material,
						@locgroup,
						@FromLoc,
						@UM,
						@quote,
						@pricetemplate,
						@SaleDate,
						@JCCo,
						@Job,
						@CustGroup,
						@Customer,
						@INCo,
						@ToLoc,
						@priceopt,
						@SaleType,
						@PhaseGroup,
						@MaterialPhaseCur,
						@MatlVendor,
						@VendorGroup,
						@unitprice OUTPUT,
						@ecm OUTPUT,
						@minamt OUTPUT,
						@msg OUTPUT
	    
					IF @recode <> 0 
					BEGIN
						SELECT  @rcode = 1

						INSERT  INTO dbo.IMWM
								( ImportId,
								  ImportTemplate,
								  Form,
								  RecordSeq,
								  Error,
								  [Message],
								  Identifier
								)
						VALUES  ( @ImportId,
								  @ImportTemplate,
								  @Form,
								  @currrecseq,
								  @recode,
								  @msg,
								  @UnitPriceID
								)
					END
				END
	            
				IF @ynECM = 'Y'
					AND ( ISNULL(@OverwriteECM, 'Y') = 'Y'
						  OR @ECMCur IS NULL
						) 
				BEGIN
					SELECT  @ECMCur = ISNULL(@ecm, 'E')

					UPDATE  #tmpPivIMWE
					SET     ECM = @ECMCur
					WHERE   tmpID = @tmpID
				END
	            
				--MOVED CODE
				IF @ynUnitPrice = 'Y'
					AND ISNULL(@Co, '') <> ''
					AND ISNULL(@Material, '') <> ''
					AND ( ISNULL(@OverwriteUnitPrice, 'Y') = 'Y'
						  OR @UnitPriceCur IS NULL
						) 
				BEGIN
					IF ( @SaleType = 'C'
						 AND ( @PaymentType = 'C'
							   OR @PaymentType = 'X'
							 )
					   ) --If Cash sale use imported value
					BEGIN
						SELECT  @SUploadval = UnitPrice
						FROM    #tmpPivIMWE
						WHERE   tmpID = @tmpID

						SELECT  @UnitPriceCur = 0

						IF ISNUMERIC(@SUploadval) = 1 
							SELECT  @UnitPriceCur = CONVERT(decimal(10,
											  5), @SUploadval)
					END
					ELSE 
						SELECT  @UnitPriceCur = @unitprice
						
					UPDATE  #tmpPivIMWE
					SET     UnitPrice = @UnitPriceCur
					WHERE   tmpID = @tmpID
				END
				
				IF @ynMatlTotal = 'Y'
					AND ( ISNULL(@OverwriteMatlTotal, 'Y') = 'Y'
						  OR @MatlTotal IS NULL
						) 
				BEGIN
					SELECT  @ECMFact = CASE @ECMCur
										 WHEN 'M' THEN 1000
										 WHEN 'C' THEN 100
										 ELSE 1
									   END

					IF ( @SaleType = 'C'
						 AND ( @PaymentType = 'C'
							   OR @PaymentType = 'X'
							 )
					   ) 
						BEGIN
							SELECT  @SUploadval = MatlTotal
							FROM    #tmpPivIMWE
							WHERE   tmpID = @tmpID
						
							SELECT  @MatlTotal = 0

							IF ISNUMERIC(@SUploadval) = 1 
								SELECT  @MatlTotal = CONVERT(decimal(10,
												  5), @SUploadval)
						END
						ELSE 
						BEGIN
							IF @UnitPriceCur IS NOT NULL
								AND @MatlUnits IS NOT NULL 
								SELECT  @MatlTotal = ( @MatlUnits
												  / @ECMFact )
										* @UnitPriceCur
							IF ISNULL(@minamt, 0) <> 0
								AND ISNULL(@MatlUnits, 0) <> 0
								AND ISNULL(@MatlTotal, 0) < ISNULL(@minamt,
												  0) 
								SELECT  @MatlTotal = @minamt
						END
					
					UPDATE  #tmpPivIMWE
					SET     MatlTotal = @MatlTotal
					WHERE   tmpID = @tmpID
				END
	            
				--end issue #28429
				IF @ynZone = 'Y'
					AND ( ISNULL(@OverwriteZone, 'Y') = 'Y'
						  OR @ZoneCur IS NULL
						) 
				BEGIN
					SELECT  @ZoneCur = @zone
					
					UPDATE  #tmpPivIMWE
					SET     Zone = @ZoneCur
					WHERE   tmpID = @tmpID
				END
				
				IF @ynHaulCode = 'Y'
					AND ( ISNULL(@OverwriteHaulCode, 'Y') = 'Y'
						  OR @HaulCodeCur IS NULL
						) 
				BEGIN
					IF ( @SaleType = 'C'
						 AND ( @PaymentType = 'C'
							   OR @PaymentType = 'X'
							 )
					   ) 
					BEGIN
						SELECT  @SUploadval = @HaulCodeCur
						FROM    #tmpPivIMWE
						WHERE   tmpID = @tmpID
						
						SELECT  @HaulCodeCur = @SUploadval
					END
					ELSE 
					BEGIN
						IF ISNULL(@HaulerType, '') = 'H'
							OR @HaulerType IS NULL		--#25079
						BEGIN
							SELECT  @quotehaulcode = NULL

							EXEC @recode = dbo.bspMSTicTruckTypeVal 
								@Co,
								@TruckTyp,
								@quote,
								@locgroup,
								@FromLoc,
								@MatlGroup,
								@Material,
								@UM,
								@VendorGroup,
								@HaulVendor,
								@Truck,
								@HaulerType,
								@quotehaulcode OUTPUT,
								@paycode = @quotepaycode OUTPUT,
								@msg = @msg OUTPUT

							IF @recode <> 0 
							BEGIN
								SELECT
									  @rcode = 1

								INSERT
									  INTO dbo.IMWM
									  (		ImportId,
											ImportTemplate,
											Form,
											RecordSeq,
											Error,
											Message,
											Identifier
									  )
								VALUES
									  ( @ImportId,
										@ImportTemplate,
										@Form,
										@currrecseq,
										NULL,
										@msg,
										@HaulCodeID
									  )
							END

							IF ISNULL(@quotehaulcode, '') <> '' 
								SELECT  @HaulCodeCur = @quotehaulcode
							ELSE 
								SELECT  @HaulCodeCur = @haulcode

						END

					ELSE 
						SELECT  @HaulCodeCur = NULL
					END
						   
					UPDATE  #tmpPivIMWE
					SET     HaulCode = @HaulCodeCur
					WHERE   tmpID = @tmpID
				END	

				IF @ynHaulPhase = 'Y'
					AND ISNULL(@HaulCodeCur, '') <> ''
					AND ( ISNULL(@OverwriteHaulPhase, 'Y') = 'Y'
						  OR @HaulPhaseCur IS NULL
						) 
				BEGIN
					IF @SaleType = 'J' 
					BEGIN
					--Issue #21346
						IF ISNULL(@haulphase, '') <> '' 
							SELECT  @HaulPhaseCur = @haulphase
						ELSE 
							SELECT  @HaulPhaseCur = @MaterialPhaseCur
					END
					ELSE 
						SELECT  @HaulPhaseCur = NULL
						
					UPDATE  #tmpPivIMWE
					SET     HaulPhase = @HaulPhaseCur
					WHERE   tmpID = @tmpID
				END

				IF @ynHaulJCCType = 'Y'
						AND ISNULL(@HaulCodeCur, '') <> ''
						AND ( ISNULL(@OverwriteHaulJCCType, 'Y') = 'Y'
							  OR @HaulJCCType IS NULL
							) 
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
						
					UPDATE  #tmpPivIMWE
					SET     HaulJCCType = @HaulJCCType
					WHERE   tmpID = @tmpID
					END
				
				IF @ynPayCode = 'Y'
					AND ( ISNULL(@OverwritePayCode, 'Y') = 'Y'
						  OR @PayCodeCur IS NULL
						) -- and @HaulerType = 'H'
				BEGIN
					IF @HaulerType = 'H' 
					BEGIN
						EXEC @recode = dbo.bspMSTicTruckTypeVal 
							@Co,
							@TruckTyp,
							@quote,
							@locgroup,
							@FromLoc,
							@MatlGroup,
							@Material,
							@UM,
							@VendorGroup,
							@HaulVendor,
							@Truck,
							@HaulerType,
							@haulcode OUTPUT,
							@paycode = @quotepaycode OUTPUT,
							@msg = @msg OUTPUT

						EXEC @recode = dbo.bspMSTicTruckVal 
							@VendorGroup,
							@HaulVendor,
							@Truck,
							@CurrentMode,
							@paycode = @paycode OUTPUT,
							@returnvendor = @returnvendor OUTPUT,
							@UpdateVendor = @UpdateVendor OUTPUT,
							@msg = @msg OUTPUT

						IF ISNULL(@quotepaycode, '') <> '' 
							SELECT  @PayCodeCur = @quotepaycode
						ELSE 
							SELECT  @PayCodeCur = @paycode
					END
					ELSE 
						SELECT  @PayCodeCur = NULL
						
					UPDATE  #tmpPivIMWE
					SET     PayCode = @PayCodeCur
					WHERE   tmpID = @tmpID
				END
				
				IF ISNULL(@PayCodeCur, '') <> ''
						AND @HaulerType = 'H'
						AND ( @ynPayBasis = 'Y'
							  OR @ynPayRate = 'Y'
							  OR @ynPayTotal = 'Y'
							) 
				BEGIN
					EXEC @recode = dbo.bspMSTicPayCodeVal 
						@Co,
						@PayCodeCur,
						@MatlGroup,
						@Material,
						@locgroup,
						@FromLoc,
						@quote,
						@TruckTyp,
						@VendorGroup,
						@HaulVendor,
						@Truck,
						@UM,
						@ZoneCur,
						@rate = @payrate OUTPUT,
						@basis = @paybasis OUTPUT,
						@payminamt = @paycodeminamt OUTPUT,
						@msg = @msg OUTPUT
	                                
					IF @ynPayBasis = 'Y'
						AND ( ISNULL(@OverwritePayBasis, 'Y') = 'Y'
							  OR @PayBasisCur IS NULL
							) 
					BEGIN
						SELECT  @PayBasisCur = CASE @paybasis
											  WHEN 1
											  THEN @MatlUnits
											  WHEN 2
											  THEN @Hours
											  WHEN 3
											  THEN @Loads
											  WHEN 4
											  THEN @MatlUnits
											  WHEN 5
											  THEN @MatlUnits
											  WHEN 6
											  THEN @HaulTotal
											  ELSE 0
											  END
								
						UPDATE  #tmpPivIMWE
						SET     PayBasis = @PayBasisCur
						WHERE   tmpID = @tmpID
					END
					
					IF @ynPayRate = 'Y'
						AND ( ISNULL(@OverwritePayRate, 'Y') = 'Y'
							  OR @PayRateCur IS NULL
							) 
					BEGIN
						SELECT  @PayRateCur = @payrate
						
						UPDATE  #tmpPivIMWE
						SET     PayRate = @PayRateCur
						WHERE   tmpID = @tmpID
					END
	    
					IF @ynPayTotal = 'Y'
						AND ( ISNULL(@OverwritePayTotal, 'Y') = 'Y'
							  OR @PayTotal IS NULL
							) 
					BEGIN

						SET @PayTotal = ISNULL(@PayBasisCur, 0)
							* ISNULL(@PayRateCur, 0)

				-- ISSUE: #133864 --
						IF ISNULL(@paycodeminamt, 0) <> 0 
							IF @PayTotal < @paycodeminamt 
								SET @PayTotal = @paycodeminamt
								
						UPDATE  #tmpPivIMWE
						SET     PayTotal = @PayTotal
						WHERE   tmpID = @tmpID
					END
				END
			    
				IF ISNULL(@HaulCodeCur, '') <> '' 
				BEGIN
				--RT 21286 - Added HCTaxable variable.
				-- Rates and amounts are based on Pay amounts or Revenue amounts
					SELECT  @RevBased = RevBased,
							@HCTaxable = Taxable
					FROM    bMSHC WITH ( NOLOCK )
					WHERE   MSCo = @Co
							AND HaulCode = @HaulCodeCur
				END
				
				IF ISNULL(@HaulCodeCur, '') <> ''
							AND ( @ynHaulBasis = 'Y'
								  OR @ynHaulRate = 'Y'
								  OR @ynHaulTotal = 'Y'
								) 
				BEGIN
					EXEC @recode = dbo.bspMSTicHaulCodeVal 
							@Co,
							@HaulCodeCur,
							@MatlGroup,
							@Material,
							@locgroup,
							@FromLoc,
							@quote,
							@UM,
							@TruckTyp,
							@ZoneCur,
							@basis = @haulbasis OUTPUT,
							@rate = @haulrate OUTPUT,
							@minamt = @haulminamt OUTPUT,
							@msg = @msg OUTPUT
	        		
					IF @SaleType = 'J'	--issue #21141, restored by issue #25084.
					BEGIN
						SELECT  @matlcategory = Category
						FROM    bHQMT
						WHERE   MatlGroup = @MatlGroup
								AND Material = @Material
						EXEC @recode = dbo.bspMSTicHaulRateGet 
							@Co,
							@HaulCodeCur,
							@MatlGroup,
							@Material,
							@matlcategory,
							@locgroup,
							@FromLoc,
							@TruckTyp,
							@UM,
							@quote,
							@ZoneCur,
							@haulbasis,
							@JCCo,
							@PhaseGroup,
							@HaulPhaseCur,
							@rate = @haulrate OUTPUT,
							@minamt = @haulminamt OUTPUT,
							@msg = @msg OUTPUT
					END
	                
					IF @ynHaulBasis = 'Y'
							AND ( ISNULL(@OverwriteHaulBasis, 'Y') = 'Y'
								  OR @HaulBasisCur IS NULL
								) 
					BEGIN
						SELECT  @HaulBasisCur = CASE @haulbasis
											  WHEN 1
												THEN @MatlUnits
											  WHEN 2
												THEN @Hours
											  WHEN 3
												THEN @Loads
											  WHEN 4
												THEN @MatlUnits
											  WHEN 5
												THEN @MatlUnits
											  ELSE 0
											END

						IF ISNULL(@RevBased, 'N') = 'Y'
							AND @HaulerType = 'H'
							AND ISNULL(@PayCodeCur, '') <> '' 
							SET  @HaulBasisCur = @PayBasisCur
						IF ISNULL(@RevBased, 'N') = 'Y'
							AND @HaulerType = 'E'
							AND ISNULL(@RevCode, '') <> '' 
							SET  @HaulBasisCur = @RevBasisCur
						IF ( @SaleType = 'C'
							 AND ( @PaymentType = 'C'
								   OR @PaymentType = 'X'
								 )
						   ) 
						BEGIN
							
							SELECT  @SUploadval = HaulBasis
							FROM  #tmpPivIMWE
							WHERE   tmpID = @tmpID
	             
							SELECT  @HaulBasisCur = 0
							IF ISNUMERIC(@SUploadval) = 1 
								SELECT  @HaulBasisCur = CONVERT(decimal(10,
										  5), @SUploadval)
						END
	                   
						UPDATE  #tmpPivIMWE
						SET     HaulBasis = @HaulBasisCur
						WHERE   tmpID = @tmpID
					END
	                
					IF @ynHaulRate = 'Y'
						AND ( ISNULL(@OverwriteHaulRate, 'Y') = 'Y'
							  OR @HaulRateCur IS NULL
							) 
					BEGIN
						SELECT  @HaulRateCur = @haulrate

						IF ISNULL(@RevBased, 'N') = 'Y'
							AND @HaulerType = 'H'
							AND ISNULL(@PayCodeCur, '') <> '' 
							SELECT  @HaulRateCur = @PayRateCur
						IF ISNULL(@RevBased, 'N') = 'Y'
							AND @HaulerType = 'E'
							AND ISNULL(@RevCode, '') <> '' 
							SELECT  @HaulRateCur = @RevRateCur

						IF ( @SaleType = 'C'
							 AND ( @PaymentType = 'C'
								   OR @PaymentType = 'X'
								 )
						   ) 
						BEGIN
	                                  
							SELECT  @SUploadval = HaulRate
							FROM  #tmpPivIMWE	
							WHERE   tmpID = @tmpID
	                        
							SELECT  @HaulRateCur = 0

							IF ISNUMERIC(@SUploadval) = 1 
								SELECT  @HaulRateCur = CONVERT(decimal(10,
										  5), @SUploadval)
						END
	                    
						UPDATE  #tmpPivIMWE
						SET     HaulRate = @HaulRateCur
						WHERE   tmpID = @tmpID
					END  
	                
					IF @ynHaulTotal = 'Y'
						AND ( ISNULL(@OverwriteHaulTotal, 'Y') = 'Y'
							  OR @HaulTotal IS NULL
							) 
					BEGIN
						SET @HaulTotal = ISNULL(@HaulBasisCur,0)
											* ISNULL(@HaulRateCur, 0)

						-- ISSUE: #133864 --
						IF ISNULL(@haulminamt, 0) <> 0 
							IF @HaulTotal < @haulminamt 
								SET @HaulTotal = @haulminamt

						IF ISNULL(@RevBased, 'N') = 'Y'
							AND @HaulerType = 'H'
							AND ISNULL(@PayCodeCur, '') <> '' 
							SELECT  @HaulTotal = @PayTotal
						IF ISNULL(@RevBased, 'N') = 'Y'
							AND @HaulerType = 'E'
							AND ISNULL(@RevCode, '') <> '' 
							SELECT  @HaulTotal = @RevTotal

						IF ( @SaleType = 'C'
							 AND ( @PaymentType = 'C'
								   OR @PaymentType = 'X'
								 )
							) 
						BEGIN
							SELECT  @SUploadval = @HaulTotal       
							FROM  #tmpPivIMWE
							WHERE   tmpID = @tmpID

							SELECT  @HaulTotal = 0

							IF ISNUMERIC(@SUploadval) = 1 
								SELECT  @HaulTotal = CONVERT(decimal(10,
										  5), @SUploadval)
						END

						UPDATE  #tmpPivIMWE
						SET     HaulTotal = @HaulTotal
						WHERE   tmpID = @tmpID
					END
				END  
				
				-- Issue 122102 If Pay basis is based on Haul then set Pay basis and Pay total based on Haul.
				IF @ynPayBasis = 'Y'
					AND @paybasis = 6
					AND ( ISNULL(@OverwritePayBasis, 'Y') = 'Y'
						  OR @PayBasisCur IS NULL
						) 
					BEGIN

						SELECT  @PayBasisCur = @HaulTotal
	                    
						UPDATE  #tmpPivIMWE
						SET     PayBasis = @PayBasisCur
						WHERE   tmpID = @tmpID

						IF @ynPayTotal = 'Y' 
						BEGIN
							SET @PayTotal = ISNULL(@PayBasisCur, 0) * ISNULL(@PayRateCur, 0)
	 
							-- ISSUE: #133864 --
							IF ISNULL(@paycodeminamt, 0) <> 0 
								IF @PayTotal < @paycodeminamt 
									SET @PayTotal = @paycodeminamt
	                                
							UPDATE  #tmpPivIMWE
							SET     PayTotal = @PayTotal
							WHERE   tmpID = @tmpID
						END
					END 
	                
					IF @ynTaxGroup = 'Y'
							AND ISNULL(@Co, '') <> ''
							AND ( ISNULL(@OverwriteTaxGroup, 'Y') = 'Y'
								  OR @TaxGroup IS NULL
								) 
					BEGIN
						SELECT  @TaxGroup = TaxGroup
						FROM    bHQCO
						WHERE   HQCo = @Co
	                    
						UPDATE  #tmpPivIMWE
						SET     TaxGroup = @TaxGroup
						WHERE   tmpID = @tmpID
					END 
	    
					IF @ynTaxType = 'Y'
								AND ( ISNULL(@OverwriteTaxType, 'Y') = 'Y'
									  OR @TaxType IS NULL
									) 
					BEGIN
						SELECT  @TaxType = 1
				---- issue #128290
						IF @SaleType IN ( 'J', 'I' ) 
						BEGIN
							SELECT  @TaxType = 2
						END
				---- issue #128290
						IF @TaxType = 1
							AND @country IN ( 'AU', 'CA' ) 
						BEGIN
							SELECT  @TaxType = 3
						END
	                        
						UPDATE  #tmpPivIMWE
						SET     TaxType = @TaxType
						WHERE   tmpID = @tmpID
					END
	                
					IF @ynTaxCode = 'Y'
					AND ( ISNULL(@OverwriteTaxCode, 'Y') = 'Y'
						  OR @TaxCodeCur IS NULL
						) 
					BEGIN
						SELECT  @taxcode = CASE WHEN @taxopt = 0
												THEN NULL
												WHEN @taxopt = 1
												THEN @loctaxcode
												WHEN @taxopt = 2
												THEN @taxcode
												WHEN @taxopt = 3
												THEN ISNULL(@taxcode,
													  @loctaxcode)
												----TK-17308
												WHEN @taxopt = 4
													AND @HaulerType = 'E'
													AND ISNULL(@Equipment,'') = ''
													THEN @loctaxcode
												WHEN @taxopt = 4
													AND @HaulerType = 'E'
													AND ISNULL(@Equipment,'') <> ''
													THEN  @taxcode
												WHEN @taxopt = 4
													AND @HaulerType = 'H'
													AND ISNULL(@HaulCodeCur,'') = ''
													THEN @loctaxcode
												WHEN @taxopt = 4
													AND @HaulerType = 'H'
													AND ISNULL(@HaulCodeCur,'') <> ''
													THEN @taxcode
												WHEN @taxopt = 4
													AND @HaulerType = 'N'
													THEN @loctaxcode
												ELSE NULL
											END

						SELECT  @TaxCodeCur = @taxcode
	                    
						UPDATE  #tmpPivIMWE
						SET     TaxCode = @TaxCodeCur
						WHERE   tmpID = @tmpID	
					END
					
					IF @ynTaxBasis = 'Y'
						AND ( ISNULL(@OverwriteTaxBasis, 'Y') = 'Y'
							  OR @TaxBasis IS NULL
							) 
					BEGIN
						IF ( @SaleType = 'C'
							 AND ( @PaymentType = 'C'
								   OR @PaymentType = 'X'
								 )
						   ) 
						BEGIN
							SELECT  @SUploadval = TaxBasis
							FROM    #tmpPivIMWE 
							WHERE   tmpID = @tmpID
	        
							SELECT  @TaxBasis = 0
	        
							IF ISNUMERIC(@SUploadval) = 1 
								SELECT  @TaxBasis = CONVERT(decimal(10,
												  5), @SUploadval)
						END
						ELSE 
						BEGIN
							SELECT  @TaxBasis = 0

							IF ISNULL(@Material, '') <> ''
								AND @taxable <> 'N'
								AND ISNULL(@TaxCodeCur, '') <> '' 
								SELECT  @TaxBasis = @MatlTotal

							--RBT 21286
							IF @HCTaxable = 'Y'
								AND @HaulerType <> 'N'
								AND ISNULL(@HaulCodeCur, '') <> ''
								AND ISNULL(@TaxCodeCur, '') <> '' 
							BEGIN
								IF ( @haultaxopt = 1
									 AND @HaulerType = 'H'
									 AND ISNULL(@HaulVendor,
											  '') <> ''
								   )
									OR ( @haultaxopt = 2 ) 
									SELECT  @TaxBasis = @TaxBasis
											+ @HaulTotal
							END
	    
							IF @HaulerType = 'N' 
							BEGIN
								SELECT  @HaulTotal = 0,
										@HaulCodeCur = NULL
							END
						--end RBT 21286
						/*
										If (@haultaxopt = 2  or (@haultaxopt = 1 and @HaulerType = 'H')) and 
                       							isnull(@HaulCodeCur,'')<>'' and isnull(@TaxCodeCur,'')<>'' 
    										select @TaxBasis = @TaxBasis + @HaulTotal
						*/
						END

						UPDATE  #tmpPivIMWE
						SET     TaxBasis = @TaxBasis
						WHERE   tmpID = @tmpID
					END		
					
					IF @ynTaxTotal = 'Y'
							OR @ynTaxDisc = 'Y' 
						EXEC @recode = dbo.bspHQTaxRateGet 
							@TaxGroup,
							@TaxCodeCur,
							@SaleDate,
							@taxrate = @taxrate OUTPUT,
							@msg = @msg OUTPUT	
							
					IF @ynTaxTotal = 'Y'
						AND ( ISNULL(@OverwriteTaxTotal, 'Y') = 'Y'
							  OR @TaxTotal IS NULL
							) 
					BEGIN
						IF ( @SaleType = 'C'
							 AND ( @PaymentType = 'C'
								   OR @PaymentType = 'X'
								 )
						   ) 
						BEGIN
							SELECT  @SUploadval = TaxTotal
							FROM    #tmpPivIMWE
							WHERE   tmpID = @tmpID

							SELECT  @TaxTotal = 0

							IF ISNUMERIC(@SUploadval) = 1 
								SELECT  @TaxTotal = CONVERT(decimal(10,
												  5), @SUploadval)
						END
						ELSE 
						BEGIN
							SELECT  @TaxTotal = ISNULL(@TaxBasis,0) * ISNULL(@taxrate, 0)
						END

						UPDATE  #tmpPivIMWE
						SET     TaxTotal = @TaxTotal
						WHERE   tmpID = @tmpID
				END
				
				IF @SaleType = 'C' 
				BEGIN
			   -- get customer pay terms issue 18762 @payterms 
			   -- select @payterms=PayTerms from bARCM where CustGroup=@CustGroup and Customer=@Customer
			   -- get matldisc flag from HQPT
					SELECT  @hqptdiscrate = DiscRate,
							@matldisc = MatlDisc
					FROM    dbo.bHQPT
					WHERE   PayTerms = @payterms
					
					IF @matldisc = 'N' 
						SELECT  @paydiscrate = @hqptdiscrate

					IF @ynDiscBasis = 'Y' 
					BEGIN
						SELECT  @DiscBasis = 0
						IF @paydisctype = 'U'
							AND @matldisc = 'Y' 
							SELECT  @DiscBasis = @MatlUnits
						IF @paydisctype = 'R'
							AND @matldisc = 'Y' 
							SELECT  @DiscBasis = @MatlTotal
						IF @matldisc = 'N' 
							SELECT  @DiscBasis = ISNULL(@MatlTotal,0)+ ISNULL(@HaulTotal, 0)

						UPDATE  #tmpPivIMWE
						SET     DiscBasis = @DiscBasis
						WHERE   tmpID = @tmpID
					END
	                                
					IF @ynDiscRate = 'Y' 
					BEGIN
						SELECT  @DiscRate = @paydiscrate
						
						UPDATE  #tmpPivIMWE
						SET     DiscRate = @DiscRate
						WHERE   tmpID = @tmpID
					END
	    
					IF @ynDiscOff = 'Y' 
					BEGIN
						SELECT  @DiscOff = @DiscRate * @DiscBasis
	                    
						UPDATE  #tmpPivIMWE
						SET     DiscOff = @DiscOff
						WHERE   tmpID = @tmpID
					END
	        
					IF @ynTaxDisc = 'Y'  --and @TaxCodeCur is not null
					BEGIN
						SELECT  @disctax = DiscTax
						FROM    dbo.bARCO WITH ( NOLOCK )
						WHERE   @Co = ARCo

						IF @disctax = 'Y' 
							SELECT  @TaxDisc = ISNULL(@DiscOff,0)* ISNULL(@taxrate, 0)
						IF ISNULL(@TaxCodeCur, '') = ''
							OR @TaxTotal = 0 
							SELECT  @TaxDisc = 0
	                        
						UPDATE  #tmpPivIMWE
						SET     TaxDisc = @TaxDisc
						WHERE   tmpID = @tmpID
					END
				END
				
				SELECT  @HaulBased = NULL,
									@RevBased = NULL
				IF ISNULL(@HaulCodeCur, '') <> ''
						AND ISNULL(@RevCode, '') <> '' 
				BEGIN
					SELECT  @HaulBased = HaulBased
					FROM    dbo.bEMRC WITH ( NOLOCK )
					WHERE   EMGroup = @EMGroup
							AND RevCode = @RevCode
	        
					IF @HaulBased = 'Y' 
					BEGIN
						UPDATE  #tmpPivIMWE
						SET     RevRate = @HaulRateCur
						WHERE   tmpID = @tmpID
						
						UPDATE  #tmpPivIMWE
						SET     RevBasis = @HaulBasisCur
						WHERE   tmpID = @tmpID
						
						UPDATE  #tmpPivIMWE
						SET     RevTotal = @HaulTotal
						WHERE   tmpID = @tmpID
					END
				END		
          
			SELECT  @currrecseq = @Recseq,
					@counter = @counter + 1,
					@Co = NULL,
					@Mth = NULL,
					@BatchSeq = NULL,
					@BatchTransType = NULL,
					@SaleDate = NULL,
					@FromLoc = NULL,
					@Ticket = NULL,
					@Void = NULL,
					@VendorGroup = NULL,
					@MatlVendor = NULL,
					@SaleType = NULL,
					@CustGroup = NULL,
					@Customer = NULL,
					@CustJob = NULL,
					@CustPO = NULL,
					@PaymentType = NULL,
					@CheckNo = NULL,
					@Hold = NULL,
					@JCCo = NULL,
					@PhaseGroup = NULL,
					@Job = NULL,
					@INCo = NULL,
					@ToLoc = NULL,
					@MatlGroup = NULL,
					@Material = NULL,
					@UM = NULL,
					@MaterialPhaseCur = NULL,
					@MatlJCCType = NULL,
					@HaulerType = NULL,
					@EMCo = NULL,
					@EMGroup = NULL,
					@Equipment = NULL,
					@PRCo = NULL,
					@Employee = NULL,
					@HaulVendor = NULL,
					@Truck = NULL,
					@Driver = NULL,
					@GrossWght = NULL,
					@TareWght = NULL,
					@WghtUM = NULL,
					@MatlUnits = NULL,
					@UnitPriceCur = NULL,
					@ECMCur = NULL,
					@MatlTotal = NULL,
					@TruckTyp = NULL,
					@StartTime = NULL,
					@StopTime = NULL,
					@Loads = NULL,
					@Miles = NULL,
					@Hours = NULL,
					@ZoneCur = NULL,
					@HaulCodeCur = NULL,
					@HaulPhaseCur = NULL,
					@HaulJCCType = NULL,
					@HaulBasisCur = NULL,
					@HaulRateCur = NULL,
					@HaulTotal = NULL,
					@RevCode = NULL,
					@RevRateCur = NULL,
					@RevBasisCur = NULL,
					@RevTotal = NULL,
					@PayCodeCur = NULL,
					@PayRateCur = NULL,
					@PayBasisCur = NULL,
					@PayTotal = NULL,
					@TaxGroup = NULL,
					@TaxCodeCur = NULL,
					@TaxType = NULL,
					@TaxBasis = NULL,
					@TaxTotal = NULL,
					@DiscBasis = NULL,
					@DiscRate = NULL,
					@DiscOff = NULL,
					@TaxDisc = NULL,
					@quotepaycode = NULL
					
			FETCH NEXT FROM curDefaultMSTB INTO 
											@tmpID,
											@currrecseq,
											@BatchTransType,
											@Co,
											@SaleDate,
											@Void,
											@Hold,
											@ECMCur,
											@SaleType,
											@VendorGroup,
											@CustGroup,
											@JCCo,
											@PhaseGroup,
											@INCo,
											@MatlGroup,
											@UM,
											@MaterialPhaseCur,
											@MatlJCCType,
											@WghtUM,
											@MatlUnits,
											@EMGroup,
											@PRCo,
											@UnitPriceCur,
											@MatlTotal,
											@ZoneCur,
											@TareWght,
											@Employee,
											@TruckTyp,
											@HaulCodeCur,
											@HaulPhaseCur,
											@HaulJCCType,
											@RevCode,
											@EMCo,
											@TaxType,
											@TaxCodeCur,
											@TaxGroup,
											@Loads,
											@Miles,
											@Hours,
											@HaulBasisCur,
											@HaulRateCur,
											@HaulTotal,
											@PayBasisCur,
											@PayRateCur,
											@PayTotal,
											@RevBasisCur,
											@RevRateCur,
											@RevTotal,
											@TaxBasis,
											@TaxTotal,
											@DiscBasis,
											@DiscRate,
											@DiscOff,
											@TaxDisc,
											@Driver,
											@HaulerType,
											@PayCodeCur,
											@StartTime,
											@StopTime,
											@ToLoc,
											@Job,
											@FromLoc,
											@HaulVendor,
											@Equipment,
											@Truck,
											@Material,
											@Customer,
											@CustJob,
											@CustPO,
											@GrossWght
						
		END
	
		CLOSE curDefaultMSTB
		DEALLOCATE curDefaultMSTB
	END -- end the cursor

	-- null out @CustomerID, @CustJobID, @CustPOID, @PaymentTypeID, @CheckNoID, @INCoID, @ToLocID
	UPDATE  #tmpPivIMWE
	SET Customer = CASE WHEN SaleType IN ('I','J') THEN NULL ELSE Customer END,    
		CustJob = CASE WHEN SaleType IN ('I','J') THEN NULL ELSE CustJob END,
		CustPO = CASE WHEN SaleType IN ('I','J') THEN NULL ELSE CustPO END,
		PaymentType = CASE WHEN SaleType IN ('I','J') THEN NULL ELSE PaymentType END,
		CheckNo = CASE WHEN SaleType IN ('I','J') OR PaymentType <> 'C' THEN NULL ELSE CheckNo END,
		Hold = CASE WHEN SaleType IN ('I','J') THEN NULL ELSE Hold END,
		
		INCo = CASE WHEN SaleType IN ('J','C') THEN NULL ELSE INCo END,
		ToLoc = CASE WHEN SaleType IN ('J','C') THEN NULL ELSE ToLoc END,
		
		TaxDisc = CASE WHEN SaleType IN ('I','J') THEN NULL ELSE TaxDisc END,
		DiscOff = CASE WHEN SaleType IN ('I','J') THEN NULL ELSE DiscOff END,
		DiscRate = CASE WHEN SaleType IN ('I','J') THEN NULL ELSE DiscRate END,
		DiscBasis = CASE WHEN SaleType IN ('I','J') THEN NULL ELSE DiscBasis END,
		
		JCCo = CASE WHEN SaleType IN ('I','C') THEN NULL ELSE JCCo END,
		Job = CASE WHEN SaleType IN ('I','C') THEN NULL ELSE Job END,
		HaulPhase = CASE WHEN SaleType IN ('I','C') OR HaulerType = 'N' OR ISNULL(HaulCode, '') = '' 
				THEN NULL ELSE HaulPhase END,
		HaulJCCType = CASE WHEN SaleType IN ('I','C')  OR HaulerType = 'N'  OR ISNULL(HaulCode, '') = ''
				THEN NULL ELSE HaulJCCType END,
		MatlPhase = CASE WHEN SaleType IN ('I','C') THEN NULL ELSE MatlPhase END,
		MatlJCCType = CASE WHEN SaleType IN ('I','C') THEN NULL ELSE MatlJCCType END,
		
		-- Haul Vendor, Truck #, Driver, Pay Code, Pay Basis, PayRate, PayTotal,
		EMCo = CASE WHEN HaulerType IN ('N','H') THEN NULL ELSE EMCo END,
		Equipment = CASE WHEN HaulerType IN ('N','H') THEN NULL ELSE Equipment END,
		PRCo = CASE WHEN HaulerType IN ('N','H') THEN NULL ELSE PRCo END, 
		Employee = CASE WHEN HaulerType IN ('N','H') THEN NULL ELSE Employee END, 
		RevCode = CASE WHEN HaulerType IN ('N','H') THEN NULL ELSE RevCode END,
		RevBasis = CASE WHEN HaulerType IN ('N','H') THEN NULL ELSE RevBasis END,
		RevRate = CASE WHEN HaulerType IN ('N','H') THEN NULL ELSE RevRate END,
		RevTotal = CASE WHEN HaulerType IN ('N','H') THEN NULL ELSE RevTotal END,
		TruckType = CASE WHEN HaulerType = 'N' THEN NULL ELSE TruckType END,
		StartTime = CASE WHEN HaulerType = 'N' THEN NULL ELSE StartTime END,
		StopTime = CASE WHEN HaulerType = 'N' THEN NULL ELSE StopTime END,
		Loads = CASE WHEN HaulerType = 'N' THEN NULL ELSE Loads END,
		Miles = CASE WHEN HaulerType = 'N' THEN NULL ELSE Miles END,
		[Hours] = CASE WHEN HaulerType = 'N' THEN NULL ELSE [Hours] END,
		Zone = CASE WHEN HaulerType = 'N' THEN NULL ELSE Zone END,
		GrossWght = CASE WHEN HaulerType = 'N' THEN NULL ELSE GrossWght END,
		TareWght = CASE WHEN HaulerType = 'N' THEN NULL ELSE TareWght END,
		HaulCode = CASE WHEN HaulerType = 'N' THEN NULL ELSE HaulCode END,
		HaulVendor = CASE WHEN HaulerType IN ('N','E') THEN NULL ELSE HaulVendor END,
		-- Need to remove truck & driver when HaulType='H' and no haulvendor
		Truck = CASE WHEN HaulerType IN ('N','E')  OR (HaulerType = 'H' AND ISNULL(HaulVendor, '') = '')
				THEN NULL ELSE Truck END,
		Driver = CASE WHEN HaulerType IN ('N','E') OR (HaulerType = 'H' AND ISNULL(HaulVendor, '') = '')
				 THEN NULL ELSE Driver END,
		PayCode = CASE WHEN HaulerType IN ('N','E') THEN NULL ELSE PayCode END,
		PayBasis = CASE WHEN HaulerType IN ('N','E') THEN NULL ELSE PayBasis END,
		PayRate = CASE WHEN HaulerType IN ('N','E') THEN NULL ELSE PayRate END,
		PayTotal = CASE WHEN HaulerType IN ('N','E') THEN NULL ELSE PayTotal END,
		
		HaulBasis = CASE WHEN HaulerType = 'N' OR ISNULL(HaulCode, '') = '' THEN NULL ELSE HaulBasis END,
		HaulRate = CASE WHEN HaulerType = 'N' OR ISNULL(HaulCode, '') = '' THEN NULL ELSE HaulRate END,
		HaulTotal = CASE WHEN HaulerType = 'N' OR ISNULL(HaulCode, '') = '' THEN NULL ELSE HaulTotal END
	

	UPDATE  #tmpPivIMWE
	SET	  GrossWght = ISNULL(GrossWght,0),
		  TareWght = ISNULL(TareWght,0),
		  MatlUnits = ISNULL(MatlUnits,0),
		  UnitPrice = ISNULL(UnitPrice,0),
		  MatlTotal = ISNULL(MatlTotal,0),
		  TaxDisc = ISNULL(TaxDisc,0),
		  DiscOff = ISNULL(DiscOff,0),
		  DiscRate = ISNULL(DiscRate,0),
		  DiscBasis = ISNULL(DiscBasis,0),
		  TaxTotal = ISNULL(TaxTotal,0),
		  TaxBasis = ISNULL(TaxBasis,0),
		  RevTotal = ISNULL(RevTotal,0),
		  RevRate = ISNULL(RevRate,0),
		  RevBasis = ISNULL(RevBasis,0),
		  PayTotal = ISNULL(PayTotal,0),
		  PayRate = ISNULL(PayRate,0),
		  PayBasis = ISNULL(PayBasis,0),
		  HaulTotal = ISNULL(HaulTotal,0),
		  HaulRate = ISNULL(HaulRate,0),
		  HaulBasis = ISNULL(HaulBasis,0),
		  [Hours] = ISNULL([Hours],0),
		  Miles = ISNULL(Miles,0),
		  Loads = ISNULL(Loads,0),
		  Hold = ISNULL(NULLIF(Hold,''),'N'),
		  Void = ISNULL(NULLIF(Void,''),'N')
		  
	-- write the temp table back to IMWE
	-- we need to depivot the temp table here to get it in the right format to write it back
	-- because unpivot removes null rows, I'm going to update IMWE to null first
	UPDATE i
	SET UploadVal = NULL
	FROM  dbo.bIMWE i
		JOIN dbo.bDDUD b ON b.Identifier = i.Identifier
							AND b.Form = i.Form
		JOIN #tblCols c ON c.ColumnName = b.ColumnName 
	WHERE i.ImportId = @ImportId
					AND i.ImportTemplate = @ImportTemplate
					AND i.Form = @Form
	
	UPDATE dbo.bIMWE
	SET UploadVal = unpiv.UploadVal
	FROM 
	(SELECT 
			RecordSeq,
			TableName,
			BatchTransType,
			Co,
			SaleDate,
			Void,
			Hold,
			ECM,
			SaleType,
			VendorGroup,
			CustGroup,
			JCCo,
			PhaseGroup,
			INCo,
			MatlGroup,
			UM,
			MatlPhase,
			MatlJCCType,
			WghtUM,
			MatlUnits,
			EMGroup,
			PRCo,
			UnitPrice,
			MatlTotal,
			Zone,
			TareWght,
			Employee,
			TruckType,
			HaulCode,
			HaulPhase,
			HaulJCCType,
			RevCode,
			EMCo,
			TaxType,
			TaxCode,
			TaxGroup,
			Loads,
			Miles,
			[Hours],
			HaulBasis,
			HaulRate,
			HaulTotal,
			PayBasis,
			PayRate,
			PayTotal,
			RevBasis,
			RevRate,
			RevTotal,
			TaxBasis,
			TaxTotal,
			DiscBasis,
			DiscRate,
			DiscOff,
			TaxDisc,
			Driver,
			HaulerType,
			PayCode,
			StartTime,
			StopTime,
			ToLoc,
			Job,
			FromLoc,
			HaulVendor,
			Equipment,
			Truck,
			Material,
			Customer,
			CustJob,
			CustPO,
			GrossWght,
			PaymentType,
			CheckNo,
			Mth,
			BatchSeq,
			MatlVendor,
			Ticket
		FROM #tmpPivIMWE ) piv
		UNPIVOT 
			(UploadVal FOR ColumnName IN (
											BatchTransType,
											Co,
											SaleDate,
											Void,
											Hold,
											ECM,
											SaleType,
											VendorGroup,
											CustGroup,
											JCCo,
											PhaseGroup,
											INCo,
											MatlGroup,
											UM,
											MatlPhase,
											MatlJCCType,
											WghtUM,
											MatlUnits,
											EMGroup,
											PRCo,
											UnitPrice,
											MatlTotal,
											Zone,
											TareWght,
											Employee,
											TruckType,
											HaulCode,
											HaulPhase,
											HaulJCCType,
											RevCode,
											EMCo,
											TaxType,
											TaxCode,
											TaxGroup,
											Loads,
											Miles,
											[Hours],
											HaulBasis,
											HaulRate,
											HaulTotal,
											PayBasis,
											PayRate,
											PayTotal,
											RevBasis,
											RevRate,
											RevTotal,
											TaxBasis,
											TaxTotal,
											DiscBasis,
											DiscRate,
											DiscOff,
											TaxDisc,
											Driver,
											HaulerType,
											PayCode,
											StartTime,
											StopTime,
											ToLoc,
											Job,
											FromLoc,
											HaulVendor,
											Equipment,
											Truck,
											Material,
											Customer,
											CustJob,
											CustPO,
											GrossWght,
											PaymentType,
											CheckNo,
											Mth,
											BatchSeq,
											MatlVendor,
											Ticket
											)
	) unpiv
	JOIN dbo.bDDUD b ON b.TableName = unpiv.TableName
						AND b.ColumnName = unpiv.ColumnName
						AND b.Form = @Form
	JOIN dbo.bIMWE i ON b.Form = i.Form
						AND b.Identifier = i.Identifier
						AND i.ImportTemplate = @ImportTemplate
						AND i.RecordSeq = unpiv.RecordSeq
						AND i.ImportId = @ImportId
											
    --clean up our temp table      			
	DROP TABLE #tmpPivIMWE
	DROP TABLE #tblCols

        bspexit:
        IF @opencursor = 1 
            BEGIN
                CLOSE WorkEditCursor
                DEALLOCATE WorkEditCursor
            END
        
        SELECT  @msg = ISNULL(@desc, 'Material Sales') + CHAR(13) + CHAR(10)
                + '[vspBidtekDefaultMSTB]'
        
        RETURN @rcode

END


GO
GRANT EXECUTE ON  [dbo].[vspIMBidtekDefaultsMSTB] TO [public]
GO
