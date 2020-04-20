SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vspIMViewpointDefaultsMSLB]
/***********************************************************
* CREATED BY: Dan So 05/04/09 - Issue: #126811
* MODIFIED BY: EricV 06/23/11 - TK-06283 PayRate and PayTotal not defaulting on import.
*				GF 04/12/2013 TFS-47289 144900 haul set to pay when based on Rev/Pay
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
    
(@Co bCompany, @ImportId varchar(20), @ImportTemplate varchar(20), 
 @Form varchar(20), @rectype varchar(30), @msg varchar(120) output)

AS

	SET NOCOUNT ON

	DECLARE
		@rcode int, @recode int, @Temprcode int, @desc varchar(120), @ImportCompleted bYN,
		@TempMinutes int, @TempLocGroup bGroup, @TempQuote varchar(10), @TempHaulBasis int, @TempHaulRate bUnitCost,
		@TempPayCode bPayCode, @TempHoursUM bHrs, @TempPayRate bUnitCost, @TempPayMinAmt bUnitCost, @TempPayBasis int,
		@TempTaxGroup bGroup, @TempCountry char(2), @TempActive bYN, @TempTaxCode bTaxCode, @TempLocTaxCode bTaxCode,
		@TempHaulTaxable bYN, @TempHaulTaxOpt int, @TempTaxRate bRate, @TempPayTerms bPayTerms, @TempMatlDisc bYN, 
		@TempDiscRateHQPT bPct, @TempPayDiscRate bPct,  @TempPayDiscType char(1), @TempDiscOpt int, @TempTaxDisc bYN,
		@TempUploadVal varchar(60), @TempHaulBased bYN,


		-- Header Variables --
		@FormHeader			varchar(20), @HeaderRecKeyID		int,		@HeaderRecType			varchar(10), 
		@HeaderRecSeq		int,		 @HeaderSaleDate		bDate,		@HeaderSaleDateID		int,
		@HeaderHaulerType	CHAR(1),	 @HeaderHaulTypeID		int,		@HeaderEMCo				bCompany,	
		@HeaderEMGroup		bGroup,		 @HeaderEMGroupID		int,		@HeaderEquipment		bEquip,	     
		@HeaderEquipmentID	int,		 @HeaderVendorGroup		bGroup,		@HeaderVendorGroupID	int,
		@HeaderHaulVendor	bVendor,	 @HeaderHaulVendorID	int,		@HeaderTruck			bTruck,		 
		@HeaderTruckID		int,		 @HeaderEquipCat	    bVendor,				

		-- Detail Variables --
		@FormDetail		varchar(20),
		@DetailRecKeyID	int,
		@Mth			bMonth,		@BatchId		bBatchID,	 @BatchSeq		int,
		@HaulLine		int,			@BatchTransType	CHAR(1),	@FromLoc		bLoc,		 @Material		bMatl, 
		@MatlVendor		bVendor,		@MatlGroup		bGroup,		@UM				bUM,		 @SaleType		CHAR(1), 
		@CustGroup		bGroup,			@Customer 		bCustomer,	@CustJob		CHAR(20),	 @CustPO 		CHAR(20), 
		@PaymentType	CHAR(1),		@CheckNo		CHAR(10),	@Hold			bYN,		 @JCCo			bCompany, 
		@Job			bJob,			@PhaseGroup		bGroup,		@HaulPhase		bPhase,		 @HaulJCCType	bJCCType, 
		@INCo			bCompany,		@ToLoc			bLoc,		@TruckType		VARCHAR(10), @StartTime		smalldatetime, 
		@StopTime		smalldatetime,	@Loads			int,		@Miles 			bUnits,		 @Hours			bHrs,
		@Zone			int,			@HaulCode 		bHaulCode,	@HaulBasis		bUnits,		 @HaulRate		bUnitCost, 
		@HaulTotal		bDollar,		@RevCode 		bRevCode,	@RevBasis		bUnits,		 @RevRate		bUnitCost, 
		@RevTotal		bDollar,		@PayCode		bPayCode,	@PayBasis		bUnits,		 @PayRate		bUnitCost, 
		@PayTotal		bDollar,		@TaxGroup		bGroup,		@TaxType 		int,		 @TaxCode		bTaxCode, 
		@TaxBasis		bDollar,		@TaxTotal		bDollar,	@DiscBasis		bUnits,		 @DiscRate		bUnitCost,
		@DiscOff		bDollar,		@TaxDisc 		bDollar,	@VendorGroup	bGroup,		 @MSTrans		bTrans,

		-- ID --
		@CoID			int, @MthID				int, @BatchIdID		int, @BatchSeqID	int, 
		@HaulLineID		int, @BatchTransTypeID	int, @FromLocID		int, @MaterialID	int, 
		@MatlVendorID	int, @MatlGroupID		int, @UMID			int, @SaleTypeID	int, 
		@CustGroupID	int, @CustomerID 		int, @CustJobID		int, @CustPOID 		int, 
		@PaymentTypeID	int, @CheckNoID			int, @HoldID		int, @JCCoID		int, 
		@JobID			int, @PhaseGroupID		int, @HaulPhaseID	int, @HaulJCCTypeID	int, 
		@INCoID			int, @ToLocID			int, @TruckTypeID	int, @StartTimeID	int, 
		@StopTimeID 	int, @LoadsID			int, @MilesID 		int, @HoursID		int,
		@ZoneID 		int, @HaulCodeID 		int, @HaulBasisID	int, @HaulRateID	int, 
		@HaulTotalID	int, @RevCodeID 		int, @RevBasisID	int, @RevRateID		int, 
		@RevTotalID		int, @PayCodeID			int, @PayBasisID	int, @PayRateID		int, 
		@PayTotalID		int, @TaxGroupID		int, @TaxTypeID 	int, @TaxCodeID		int, 
		@TaxBasisID		int, @TaxTotalID		int, @DiscBasisID	int, @DiscRateID 	int,
		@DiscOffID		int, @TaxDiscID 		int, @VendorGroupID int, @MSTransID		int,	

		-- Clear Data ID --
		@cdCoID				int, @cdMthID				int, @cdBatchIdID		int, @cdBatchSeqID		int, 
		@cdHaulLineID		int, @cdBatchTransTypeID	int, @cdFromLocID		int, @cdMaterialID		int, 
		@cdMatlVendorID		int, @cdMatlGroupID			int, @cdUMID			int, @cdSaleTypeID		int, 
		@cdCustGroupID		int, @cdCustomerID 			int, @cdCustJobID		int, @cdCustPOID 		int, 
		@cdPaymentTypeID	int, @cdCheckNoID			int, @cdHoldID			int, @cdJCCoID			int, 
		@cdJobID			int, @cdPhaseGroupID		int, @cdHaulPhaseID		int, @cdHaulJCCTypeID	int, 
		@cdINCoID			int, @cdToLocID				int, @cdTruckTypeID		int, @cdStartTimeID		int, 
		@cdStopTimeID 		int, @cdLoadsID				int, @cdMilesID 		int, @cdHoursID			int,
		@cdZoneID 			int, @cdHaulCodeID 			int, @cdHaulBasisID		int, @cdHaulRateID		int, 
		@cdHaulTotalID		int, @cdRevCodeID 			int, @cdRevBasisID		int, @cdRevRateID		int, 
		@cdRevTotalID		int, @cdPayCodeID			int, @cdPayBasisID		int, @cdPayRateID		int, 
		@cdPayTotalID		int, @cdTaxGroupID			int, @cdTaxTypeID 		int, @cdTaxCodeID		int, 
		@cdTaxBasisID		int, @cdTaxTotalID			int, @cdDiscBasisID		int, @cdDiscRateID 		int,
		@cdDiscOffID		int, @cdTaxDiscID 			int, @cdVendorGroupID	int, @cdMSTransID		int,
		@cdHeaderEmployeeID	int, @cdHeaderEMCoID		int, @cdHeaderPRCoID	int, @cdHeaderDriverID	int,		

		-- Value Exists --
		@ynCo			bYN, @ynMth				bYN, @ynBatchId		bYN, @ynBatchSeq	bYN, 
		@ynHaulLine		bYN, @ynBatchTransType	bYN, @ynFromLoc		bYN, @ynMaterial	bYN, 
		@ynMatlVendor	bYN, @ynMatlGroup		bYN, @ynUM			bYN, @ynSaleType	bYN, 
		@ynCustGroup	bYN, @ynCustomer 		bYN, @ynCustJob		bYN, @ynCustPO 		bYN, 
		@ynPaymentType	bYN, @ynCheckNo			bYN, @ynHold		bYN, @ynJCCo		bYN, 
		@ynJob			bYN, @ynPhaseGroup		bYN, @ynHaulPhase	bYN, @ynHaulJCCType	bYN, 
		@ynINCo			bYN, @ynToLoc			bYN, @ynTruckType	bYN, @ynStartTime	bYN, 
		@ynStopTime 	bYN, @ynLoads			bYN, @ynMiles 		bYN, @ynHours		bYN,
		@ynZone 		bYN, @ynHaulCode 		bYN, @ynHaulBasis	bYN, @ynHaulRate	bYN, 
		@ynHaulTotal	bYN, @ynRevCode 		bYN, @ynRevBasis	bYN, @ynRevRate		bYN, 
		@ynRevTotal		bYN, @ynPayCode			bYN, @ynPayBasis	bYN, @ynPayRate		bYN, 
		@ynPayTotal		bYN, @ynTaxGroup		bYN, @ynTaxType 	bYN, @ynTaxCode		bYN, 
		@ynTaxBasis		bYN, @ynTaxTotal		bYN, @ynDiscBasis	bYN, @ynDiscRate 	bYN,
		@ynDiscOff		bYN, @ynTaxDisc 		bYN, @ynVendorGroup bYN, @ynMSTrans		bYN,	
		
		-- Overwrite --
		@owCo			bYN, @owMth				bYN, @owBatchId		bYN, @owBatchSeq	bYN, 
		@owHaulLine		bYN, @owBatchTransType	bYN, @owFromLoc		bYN, @owMaterial	bYN, 
		@owMatlVendor	bYN, @owMatlGroup		bYN, @owUM			bYN, @owSaleType	bYN, 
		@owCustGroup	bYN, @owCustomer 		bYN, @owCustJob		bYN, @owCustPO 		bYN, 
		@owPaymentType	bYN, @owCheckNo			bYN, @owHold		bYN, @owJCCo		bYN, 
		@owJob			bYN, @owPhaseGroup		bYN, @owHaulPhase	bYN, @owHaulJCCType	bYN, 
		@owINCo			bYN, @owToLoc			bYN, @owTruckType	bYN, @owStartTime	bYN, 
		@owStopTime 	bYN, @owLoads			bYN, @owMiles 		bYN, @owHours		bYN,
		@owZone 		bYN, @owHaulCode 		bYN, @owHaulBasis	bYN, @owHaulRate	bYN, 
		@owHaulTotal	bYN, @owRevCode 		bYN, @owRevBasis	bYN, @owRevRate		bYN, 
		@owRevTotal		bYN, @owPayCode			bYN, @owPayBasis	bYN, @owPayRate		bYN, 
		@owPayTotal		bYN, @owTaxGroup		bYN, @owTaxType 	bYN, @owTaxCode		bYN, 
		@owTaxBasis		bYN, @owTaxTotal		bYN, @owDiscBasis	bYN, @owDiscRate 	bYN,
		@owDiscOff		bYN, @owTaxDisc 		bYN, @owVendorGroup bYN, @owMSTrans		bYN,

		-- IsEmpty --
		@IsEmptyCo			bYN, @IsEmptyMth			bYN, @IsEmptyBatchId		bYN, @IsEmptyBatchSeq		bYN, 
		@IsEmptyHaulLine	bYN, @IsEmptyBatchTransType	bYN, @IsEmptyFromLoc		bYN, @IsEmptyMaterial		bYN, 
		@IsEmptyMatlVendor	bYN, @IsEmptyMatlGroup		bYN, @IsEmptyUM				bYN, @IsEmptySaleType		bYN, 
		@IsEmptyCustGroup	bYN, @IsEmptyCustomer 		bYN, @IsEmptyCustJob		bYN, @IsEmptyCustPO 		bYN, 
		@IsEmptyPaymentType	bYN, @IsEmptyCheckNo		bYN, @IsEmptyHold			bYN, @IsEmptyJCCo			bYN, 
		@IsEmptyJob			bYN, @IsEmptyPhaseGroup		bYN, @IsEmptyHaulPhase		bYN, @IsEmptyHaulJCCType	bYN, 
		@IsEmptyINCo		bYN, @IsEmptyToLoc			bYN, @IsEmptyTruckType		bYN, @IsEmptyStartTime		bYN, 
		@IsEmptyStopTime 	bYN, @IsEmptyLoads			bYN, @IsEmptyMiles 			bYN, @IsEmptyHours			bYN,
		@IsEmptyZone 		bYN, @IsEmptyHaulCode 		bYN, @IsEmptyHaulBasis		bYN, @IsEmptyHaulRate		bYN, 
		@IsEmptyHaulTotal	bYN, @IsEmptyRevCode 		bYN, @IsEmptyRevBasis		bYN, @IsEmptyRevRate		bYN, 
		@IsEmptyRevTotal	bYN, @IsEmptyPayCode		bYN, @IsEmptyPayBasis		bYN, @IsEmptyPayRate		bYN, 
		@IsEmptyPayTotal	bYN, @IsEmptyTaxGroup		bYN, @IsEmptyTaxType 		bYN, @IsEmptyTaxCode		bYN, 
		@IsEmptyTaxBasis	bYN, @IsEmptyTaxTotal		bYN, @IsEmptyDiscBasis		bYN, @IsEmptyDiscRate 		bYN,
		@IsEmptyDiscOff		bYN, @IsEmptyTaxDisc 		bYN, @IsEmptyVendorGroup	bYN, @IsEmptyMSTrans		bYN,

		-- Cusor Variables --
		@curRecSeq	int,		  @curTableName	VARCHAR(20),  @curCol		VARCHAR(30), @curUploadVal	VARCHAR(60),
		@curIdent	int,		  @curImportID	VARCHAR(10),  @curSeq		int,		 @curIdentifier	int,
		@curCurSeq	int,		  @curAllowNull	int,		  @curError		int,		 @curSQL		VARCHAR(255),
		@curValList VARCHAR(255), @curColList	VARCHAR(255), @curComplete  int,		 @curCounter	int, 
		@curRecord	int,		  @curOldRecSeq int,		  @curOpen		int,		 @curRecKey		int

----TFS-47289
DECLARE @BasedOn bYN, @SourceID INT,
		@OvrPayBasisID INT, @OvrPayRateID INT, @OvrPayTotalID INT,
		@OvrRevBasisID INT, @OvrRevRateID INT, @OvrRevTotalID INT,
		@OvrHaulBasisID INT, @OvrHaulRateID INT, @OvrHaulTotalID INT

	---------------------
	-- PRIME VARIABLES --
	---------------------
	SET @rcode = 0
	SET @curOpen = 0
	SET @ImportCompleted = 'N'
	SET @FormHeader = 'MSHaulEntry'
	SET @FormDetail = 'MSHaulEntryLines'


	SELECT	
		@ynCo			= 'N', @ynMth				= 'N', @ynBatchId		= 'N', @ynBatchSeq		= 'N', 
		@ynHaulLine		= 'N', @ynBatchTransType	= 'N', @ynFromLoc		= 'N', @ynMaterial		= 'N', 
		@ynMatlVendor	= 'N', @ynMatlGroup			= 'N', @ynUM			= 'N', @ynSaleType		= 'N', 
		@ynCustGroup	= 'N', @ynCustomer 			= 'N', @ynCustJob		= 'N', @ynCustPO 		= 'N', 
		@ynPaymentType	= 'N', @ynCheckNo			= 'N', @ynHold			= 'N', @ynJCCo			= 'N', 
		@ynJob			= 'N', @ynPhaseGroup		= 'N', @ynHaulPhase		= 'N', @ynHaulJCCType	= 'N', 
		@ynINCo			= 'N', @ynToLoc				= 'N', @ynTruckType		= 'N', @ynStartTime		= 'N', 
		@ynStopTime 	= 'N', @ynLoads				= 'N', @ynMiles 		= 'N', @ynHours			= 'N',
		@ynZone 		= 'N', @ynHaulCode 			= 'N', @ynHaulBasis		= 'N', @ynHaulRate		= 'N', 
		@ynHaulTotal	= 'N', @ynRevCode 			= 'N', @ynRevBasis		= 'N', @ynRevRate		= 'N', 
		@ynRevTotal		= 'N', @ynPayCode			= 'N', @ynPayBasis		= 'N', @ynPayRate		= 'N', 
		@ynPayTotal		= 'N', @ynTaxGroup			= 'N', @ynTaxType 		= 'N', @ynTaxCode		= 'N', 
		@ynTaxBasis		= 'N', @ynTaxTotal			= 'N', @ynDiscBasis		= 'N', @ynDiscRate 		= 'N',
		@ynDiscOff		= 'N', @ynTaxDisc 			= 'N', @ynVendorGroup	= 'N', @ynMSTrans		= 'N'


	SELECT 	
		@IsEmptyCo			= 'N', @IsEmptyMth				= 'N', @IsEmptyBatchId		= 'N', @IsEmptyBatchSeq		= 'N', 
		@IsEmptyHaulLine	= 'N', @IsEmptyBatchTransType	= 'N', @IsEmptyFromLoc		= 'N', @IsEmptyMaterial		= 'N', 
		@IsEmptyMatlVendor	= 'N', @IsEmptyMatlGroup		= 'N', @IsEmptyUM			= 'N', @IsEmptySaleType		= 'N', 
		@IsEmptyCustGroup	= 'N', @IsEmptyCustomer 		= 'N', @IsEmptyCustJob		= 'N', @IsEmptyCustPO 		= 'N', 
		@IsEmptyPaymentType	= 'N', @IsEmptyCheckNo			= 'N', @IsEmptyHold			= 'N', @IsEmptyJCCo			= 'N', 
		@IsEmptyJob			= 'N', @IsEmptyPhaseGroup		= 'N', @IsEmptyHaulPhase	= 'N', @IsEmptyHaulJCCType	= 'N', 
		@IsEmptyINCo		= 'N', @IsEmptyToLoc			= 'N', @IsEmptyTruckType	= 'N', @IsEmptyStartTime	= 'N', 
		@IsEmptyStopTime 	= 'N', @IsEmptyLoads			= 'N', @IsEmptyMiles 		= 'N', @IsEmptyHours		= 'N',
		@IsEmptyZone 		= 'N', @IsEmptyHaulCode 		= 'N', @IsEmptyHaulBasis	= 'N', @IsEmptyHaulRate		= 'N', 
		@IsEmptyHaulTotal	= 'N', @IsEmptyRevCode 			= 'N', @IsEmptyRevBasis		= 'N', @IsEmptyRevRate		= 'N', 
		@IsEmptyRevTotal	= 'N', @IsEmptyPayCode			= 'N', @IsEmptyPayBasis		= 'N', @IsEmptyPayRate		= 'N', 
		@IsEmptyPayTotal	= 'N', @IsEmptyTaxGroup			= 'N', @IsEmptyTaxType 		= 'N', @IsEmptyTaxCode		= 'N', 
		@IsEmptyTaxBasis	= 'N', @IsEmptyTaxTotal			= 'N', @IsEmptyDiscBasis	= 'N', @IsEmptyDiscRate 	= 'N',
		@IsEmptyDiscOff		= 'N', @IsEmptyTaxDisc 			= 'N', @IsEmptyVendorGroup	= 'N', @IsEmptyMSTrans		= 'N'
   

	-------------------------
    -- REQUIRED PARAMETERS --
	-------------------------
	IF @ImportId IS NULL
		BEGIN
			SET @desc = 'Missing ImportId.' 
			SET @rcode = 1
			GOTO vspExit
		END

    IF @ImportTemplate IS NULL
		BEGIN
			SET @desc = 'Missing ImportTemplate.'
			SET @rcode = 1
			GOTO vspExit
		END
    
    IF @Form IS NULL
		BEGIN
			SET @desc = 'Missing Form.'
			SET @rcode = 1
			GOTO vspExit
		END

	----------------------------------
	-- CHECK FOR ANY DEFAULTS EXIST --
	----------------------------------
	SELECT TOP 1 1
	  FROM IMTD	
	 WHERE IMTD.ImportTemplate=@ImportTemplate 
	   AND IMTD.DefaultValue = '[Bidtek]'
	   AND IMTD.RecordType = @rectype

	IF @@ROWCOUNT = 0
		BEGIN
			SET @desc = 'No Bidtek Defaults set up for ImportTemplate ' + @ImportTemplate +'.'
			GOTO vspExit
		END

	----------------------------
	-- GET HEADER RECORD TYPE --
	----------------------------
	SELECT @HeaderRecType = RecordType
	  FROM IMTR
	 WHERE ImportTemplate = @ImportTemplate
	   AND Form = @FormHeader

	----------------------------
	-- GET RECORD IDENTIFIERS --
	----------------------------
	-- HEADER --
	SELECT @HeaderRecKeyID = a.Identifier
      FROM IMTD a join DDUD b 
		ON a.Identifier = b.Identifier
     WHERE a.ImportTemplate = @ImportTemplate 
	   AND b.ColumnName = 'RecKey'
       AND a.RecordType = @rectype 
	   AND b.Form = @FormHeader

	-- DETAIL --
	SELECT @DetailRecKeyID = a.Identifier
      FROM IMTD a join DDUD b 
		ON a.Identifier = b.Identifier
     WHERE a.ImportTemplate = @ImportTemplate 
	   AND b.ColumnName = 'RecKey'
       AND a.RecordType = @rectype 
	   AND b.Form = @FormDetail


	------------------
	-- OVERWRITE YN --
	------------------		
	SET @owCo				= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Co', @rectype)
	SET @owBatchTransType	= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BatchTransType', @rectype) 
	SET @owFromLoc			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'FromLoc', @rectype)
	SET @owMaterial			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Material', @rectype)
	SET @owMatlVendor		= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MatlVendor', @rectype)
	SET @owMatlGroup		= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MatlGroup', @rectype)
	SET @owUM				= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UM', @rectype)
	SET @owSaleType			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SaleType', @rectype)
	SET @owCustGroup		= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CustGroup', @rectype)
	SET @owCustomer			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Customer', @rectype)
	SET @owCustJob			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CustJob', @rectype)
	SET @owCustPO			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CustPO', @rectype)
	SET @owPaymentType		= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PaymentType', @rectype)
	SET @owCheckNo			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CheckNo', @rectype)
	SET @owHold				= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Hold', @rectype)
	SET @owJCCo				= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JCCo', @rectype)
	SET @owJob				= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Job', @rectype)
	SET @owPhaseGroup		= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PhaseGroup', @rectype)
	SET @owHaulPhase		= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'HaulPhase', @rectype)
	SET @owHaulJCCType		= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'HaulJCCType', @rectype)
	SET @owINCo				= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'INCo', @rectype)
	SET @owToLoc			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ToLoc', @rectype)
	SET @owTruckType		= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TruckType', @rectype)
	SET @owStartTime		= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'StartTime', @rectype)
	SET @owStopTime			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'StopTime', @rectype)
	SET @owLoads			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Loads', @rectype)
	SET @owMiles			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Miles', @rectype)
	SET @owHours			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Hours', @rectype)
	SET @owZone				= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Zone', @rectype)
	SET @owHaulCode			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'HaulCode', @rectype)
	SET @owHaulBasis		= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'HaulBasis', @rectype)
	SET @owHaulRate			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'HaulRate', @rectype)
	SET @owHaulTotal		= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'HaulTotal', @rectype)
	SET @owRevCode			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RevCode', @rectype)
	SET @owRevBasis			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RevBasis', @rectype)
	SET @owRevRate			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RevRate', @rectype)
	SET @owRevTotal			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RevTotal', @rectype)
	SET @owPayCode			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PayCode', @rectype)
	SET @owPayBasis			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PayBasis', @rectype)
	SET @owPayRate			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PayRate', @rectype)
	SET @owPayTotal			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PayTotal', @rectype)
	SET @owTaxGroup			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxGroup', @rectype)
	SET @owTaxType			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxType', @rectype)
	SET @owTaxCode			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxCode', @rectype)
	SET @owTaxBasis			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxBasis', @rectype)
	SET @owTaxTotal			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxTotal', @rectype)
	SET @owDiscBasis		= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'DiscBasis', @rectype)
	SET @owDiscRate			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'DiscRate', @rectype)
	SET @owDiscOff			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'DiscOff', @rectype)
	SET @owTaxDisc			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxDisc', @rectype)
	SET @owVendorGroup		= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'VendorGroup', @rectype)
	SET @owMSTrans			= dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MSTrans', @rectype)

----TFS-00000 get id's for haul default based on rev/pay
select @OvrPayBasisID = DDUD.Identifier
From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form and IMTD.RecordType = @rectype
Where IMTD.ImportTemplate='MSHaulTest' AND DDUD.ColumnName = 'PayBasis'
select @OvrPayRateID = DDUD.Identifier
From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form and IMTD.RecordType = @rectype
Where IMTD.ImportTemplate='MSHaulTest' AND DDUD.ColumnName = 'PayRate'
select @OvrPayTotalID = DDUD.Identifier
From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form and IMTD.RecordType = @rectype
Where IMTD.ImportTemplate='MSHaulTest' AND DDUD.ColumnName = 'PayTotal'
select @OvrRevBasisID = DDUD.Identifier
From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form and IMTD.RecordType = @rectype
Where IMTD.ImportTemplate='MSHaulTest' AND DDUD.ColumnName = 'RevBasis'
select @OvrRevRateID = DDUD.Identifier
From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form and IMTD.RecordType = @rectype
Where IMTD.ImportTemplate='MSHaulTest' AND DDUD.ColumnName = 'RevRate'
select @OvrRevTotalID = DDUD.Identifier
From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form and IMTD.RecordType = @rectype
Where IMTD.ImportTemplate='MSHaulTest' AND DDUD.ColumnName = 'RevTotal'
select @OvrHaulBasisID = DDUD.Identifier
From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form and IMTD.RecordType = @rectype
Where IMTD.ImportTemplate='MSHaulTest' AND DDUD.ColumnName = 'HaulBasis'
select @OvrHaulRateID = DDUD.Identifier
From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form and IMTD.RecordType = @rectype
Where IMTD.ImportTemplate='MSHaulTest' AND DDUD.ColumnName = 'HaulRate'
select @OvrHaulTotalID = DDUD.Identifier
From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form and IMTD.RecordType = @rectype
Where IMTD.ImportTemplate='MSHaulTest' AND DDUD.ColumnName = 'HaulTotal'


	-- ************************************************************************************ --
	--																						--
	--			RECORDS ALREADY EXIST IN THE IMWE TABLE FROM THE IMPORTED TEXTFILE			--
	--																						--
	--			All records with the same RecordSeq represent a single import record		--
	--																						--
	-- ************************************************************************************ --

	------------------
	-- SET DEFAULTS -- VALUES DEFAULTED ON NEW RECORD --
	------------------
    -- Co --
	--------	
	SET @CoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Co', @rectype, 'Y')

	-- IS THERE AN ID --
	IF ISNULL(@CoID, 0)<> 0 
		-- OVERWRITE DEFAULT VALUE --
		IF (ISNULL(@owCo, 'Y') = 'Y')
			BEGIN
				UPDATE IMWE
				   SET IMWE.UploadVal = @Co
				 WHERE IMWE.ImportTemplate = @ImportTemplate 
				   AND IMWE.ImportId = @ImportId 
				   AND IMWE.Identifier = @CoID 
				   AND IMWE.RecordType = @rectype
			 END
		ELSE
     		BEGIN
				UPDATE IMWE
				   SET IMWE.UploadVal = @Co
				 WHERE IMWE.ImportTemplate = @ImportTemplate 
				   AND IMWE.ImportId = @ImportId 
				   AND IMWE.Identifier = @CoID 
				   AND IMWE.RecordType = @rectype
				   AND IMWE.UploadVal IS NULL
			 END

	--------------------
    -- BatchTransType --
	--------------------
	SET @BatchTransTypeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'BatchTransType', @rectype, 'Y')

	-- IS THERE AN ID --
	IF ISNULL(@BatchTransTypeID, 0)<> 0 
		-- OVERWRITE DEFAULT VALUE --
		IF ISNULL(@owBatchTransType, 'Y') = 'Y'
			BEGIN
				UPDATE IMWE
				   SET IMWE.UploadVal = 'A'
				 WHERE IMWE.ImportTemplate = @ImportTemplate 
				   AND IMWE.ImportId = @ImportId 
				   AND IMWE.Identifier = @BatchTransTypeID
				   AND IMWE.RecordType = @rectype
			END
		ELSE
			BEGIN
				UPDATE IMWE
				   SET IMWE.UploadVal = 'A'
				 WHERE IMWE.ImportTemplate = @ImportTemplate 
				   AND IMWE.ImportId = @ImportId 
				   AND IMWE.Identifier = @BatchTransTypeID
				   AND IMWE.RecordType = @rectype
				   AND IMWE.UploadVal IS NULL
			END
        
	--------------
	-- SaleType --
	--------------
	SET @SaleTypeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SaleType', @rectype, 'Y')

	-- IS THERE AN ID --
	IF ISNULL(@SaleTypeID, 0)<> 0 
		-- OVERWRITE DEFAULT VALUE --
		IF ISNULL(@owSaleType, 'Y') = 'Y'
			BEGIN
				UPDATE IMWE
				   SET IMWE.UploadVal = 'C'
				 WHERE IMWE.ImportTemplate = @ImportTemplate 
				   AND IMWE.ImportId = @ImportId 
				   AND IMWE.Identifier = @SaleTypeID
				   AND IMWE.RecordType = @rectype
			END
		ELSE
			BEGIN
				UPDATE IMWE
				   SET IMWE.UploadVal = 'C'
				 WHERE IMWE.ImportTemplate = @ImportTemplate 
				   AND IMWE.ImportId = @ImportId 
				   AND IMWE.Identifier = @SaleTypeID
				   AND IMWE.RecordType = @rectype
				   AND IMWE.UploadVal IS NULL
			END
               
	-----------------
	-- PaymentType --
	-----------------
	SET @PaymentTypeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PaymentType', @rectype, 'Y')

	-- IS THERE AN ID --
	IF ISNULL(@PaymentTypeID, 0)<> 0 
		-- OVERWRITE DEFAULT VALUE --
		IF ISNULL(@owPaymentType, 'Y') = 'Y'
			BEGIN
				UPDATE IMWE
				   SET IMWE.UploadVal = 'A'
				 WHERE IMWE.ImportTemplate = @ImportTemplate 
				   AND IMWE.ImportId = @ImportId 
				   AND IMWE.Identifier = @PaymentTypeID
				   AND IMWE.RecordType = @rectype
			END
		ELSE
			BEGIN
				UPDATE IMWE
				   SET IMWE.UploadVal = 'A'
				 WHERE IMWE.ImportTemplate = @ImportTemplate 
				   AND IMWE.ImportId = @ImportId 
				   AND IMWE.Identifier = @PaymentTypeID
				   AND IMWE.RecordType = @rectype
				   AND IMWE.UploadVal IS NULL
			END

	----------
	-- Hold --
	----------
	SET @HoldID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Hold', @rectype, 'Y')

	-- IS THERE AN ID --
	IF ISNULL(@HoldID, 0)<> 0 
		-- OVERWRITE DEFAULT VALUE --
		IF ISNULL(@owHold, 'Y') = 'Y'
			BEGIN
				UPDATE IMWE
				   SET IMWE.UploadVal = 'N'
				 WHERE IMWE.ImportTemplate = @ImportTemplate 
				   AND IMWE.ImportId = @ImportId 
				   AND IMWE.Identifier = @HoldID
				   AND IMWE.RecordType = @rectype
			END
		ELSE
			BEGIN
				UPDATE IMWE
				   SET IMWE.UploadVal = 'N'
				 WHERE IMWE.ImportTemplate = @ImportTemplate 
				   AND IMWE.ImportId = @ImportId 
				   AND IMWE.Identifier = @HoldID
				   AND IMWE.RecordType = @rectype
				   AND IMWE.UploadVal IS NULL
			END


	------------------------------------------------
	-- GET COLUMN IDENTIFIERS FOR THOSE COLUMNS   --
	-- THAT MIGHT BE DEFAULTED BUT WHOSE DEFAULTS --
	-- COULD BE UNIQUE FOR EACH IMPORTED RECORD	  --	 
	------------------------------------------------  
	-- HEADER --
	SET @HeaderSaleDateID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'SaleDate', @HeaderRecType, 'N')
	SET @HeaderHaulTypeID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'HaulerType', @HeaderRecType, 'N')
	SET	@HeaderEMGroupID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'EMGroup', @HeaderRecType, 'N')
	SET	@HeaderEquipmentID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'Equipment', @HeaderRecType, 'N')
	SET	@HeaderVendorGroupID	= dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'VendorGroup', @HeaderRecType, 'N')
	SET	@HeaderHaulVendorID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'HaulVendor', @HeaderRecType, 'N')
	SET	@HeaderTruckID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'Truck', @HeaderRecType, 'N')

	-- DETAIL -- ** SOME ID VALUES HAVE ALREADY BEEN SET ABOVE
	SET @HaulLineID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'HaulLine', @rectype, 'Y')
	SET @FromLocID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'FromLoc', @rectype, 'Y')
	SET @MaterialID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Material', @rectype, 'Y')
	SET @MatlVendorID	= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MatlVendor', @rectype, 'Y')
	SET @MatlGroupID	= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MatlGroup', @rectype, 'Y')
	SET @UMID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UM', @rectype, 'Y')
	SET @CustGroupID	= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CustGroup', @rectype, 'Y')
	SET @CustomerID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Customer', @rectype, 'Y')
	SET @CustJobID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CustJob', @rectype, 'Y')
	SET @CustPOID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CustPO', @rectype, 'Y')
	SET @CheckNoID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CheckNo', @rectype, 'Y')
	SET @JCCoID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'JCCo', @rectype, 'Y')
	SET @JobID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Job', @rectype, 'Y')
	SET @PhaseGroupID	= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PhaseGroup', @rectype, 'Y')
	SET @HaulPhaseID	= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'HaulPhase', @rectype, 'Y')
	SET @HaulJCCTypeID	= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'HaulJCCType', @rectype, 'Y')
	SET @INCoID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'INCo', @rectype, 'Y')
	SET @ToLocID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ToLoc', @rectype, 'Y')
	SET @TruckTypeID	= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TruckType', @rectype, 'Y')
	SET @StartTimeID	= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'StartTime', @rectype, 'Y')
	SET @StopTimeID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'StopTime', @rectype, 'Y')
	SET @LoadsID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Loads', @rectype, 'Y')
	SET @MilesID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Miles', @rectype, 'Y')
	SET @HoursID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Hours', @rectype, 'Y')
	SET @ZoneID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Zone', @rectype, 'Y')
	SET @HaulCodeID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'HaulCode', @rectype, 'Y')
	SET @HaulBasisID	= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'HaulBasis', @rectype, 'Y')
	SET @HaulRateID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'HaulRate', @rectype, 'Y')
	SET @HaulTotalID	= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'HaulTotal', @rectype, 'Y')
	SET @RevCodeID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RevCode', @rectype, 'Y')
	SET @RevBasisID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RevBasis', @rectype, 'Y')
	SET @RevRateID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RevRate', @rectype, 'Y')
	SET @RevTotalID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RevTotal', @rectype, 'Y')
	SET @PayCodeID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PayCode', @rectype, 'Y')
	SET @PayBasisID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PayBasis', @rectype, 'Y')
	SET @PayRateID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PayRate', @rectype, 'Y')
	SET @PayTotalID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PayTotal', @rectype, 'Y')
	SET @TaxGroupID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxGroup', @rectype, 'Y')
	SET @TaxTypeID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxType', @rectype, 'Y')
	SET @TaxCodeID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxCode', @rectype, 'Y')
	SET @TaxBasisID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxBasis', @rectype, 'Y')
	SET @TaxTotalID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxTotal', @rectype, 'Y')
	SET @DiscBasisID	= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'DiscBasis', @rectype, 'Y')
	SET @DiscRateID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'DiscRate', @rectype, 'Y')
	SET @DiscOffID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'DiscOff', @rectype, 'Y')
	SET @TaxDiscID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxDisc', @rectype, 'Y')
	SET @VendorGroupID	= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'VendorGroup', @rectype, 'Y')
	SET @MSTransID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MSTrans', @rectype, 'Y')


	--------------------------------------
	-- GET COLUMN IDENTIFIERS TO BE USED TO CLEAR  --
	-- DATA AT THE BOTTOM OF THE ROUTINE - THIS IS --
	-- NEEDED JUST IN CASE DATA WAS UPLOADED AND   --
	-- NEEDS TO BE CLEARED IN CERTAIN CASES - I    --
	-- INCLUDED ALL OF THE DETAIL IDs JUST IN CASE --
	-- THEY ARE NEEDED IN THE FUTUREFOR EASE       --
	-------------------------------------------------  
	-- HEADER --
	SET @cdHeaderEmployeeID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'Employee', @HeaderRecType, 'N')
	SET @cdHeaderEMCoID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'EMCo', @HeaderRecType, 'N')
	SET @cdHeaderPRCoID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'PRCo', @HeaderRecType, 'N')
	SET @cdHeaderDriverID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'Driver', @HeaderRecType, 'N')

	-- DETAIL --
	SET @cdCoID				= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Co', @rectype, 'N')
	SET @cdBatchTransTypeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'BatchTransType', @rectype, 'N')
	SET @cdSaleTypeID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SaleType', @rectype, 'N')
	SET @cdPaymentTypeID	= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PaymentType', @rectype, 'N')
	SET @cdHoldID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Hold', @rectype, 'N')
	SET @cdFromLocID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'FromLoc', @rectype, 'N')
	SET @cdMaterialID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Material', @rectype, 'N')
	SET @cdMatlVendorID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MatlVendor', @rectype, 'N')
	SET @cdMatlGroupID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MatlGroup', @rectype, 'N')
	SET @cdUMID				= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UM', @rectype, 'N')
	SET @cdCustGroupID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CustGroup', @rectype, 'N')
	SET @cdCustomerID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Customer', @rectype, 'N')
	SET @cdCustJobID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CustJob', @rectype, 'N')
	SET @cdCustPOID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CustPO', @rectype, 'N')
	SET @cdCheckNoID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CheckNo', @rectype, 'N')
	SET @cdJCCoID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'JCCo', @rectype, 'N')
	SET @cdJobID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Job', @rectype, 'N')
	SET @cdPhaseGroupID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PhaseGroup', @rectype, 'N')
	SET @cdHaulPhaseID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'HaulPhase', @rectype, 'N')
	SET @cdHaulJCCTypeID	= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'HaulJCCType', @rectype, 'N')
	SET @cdINCoID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'INCo', @rectype, 'N')
	SET @cdToLocID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ToLoc', @rectype, 'N')
	SET @cdTruckTypeID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TruckType', @rectype, 'N')
	SET @cdStartTimeID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'StartTime', @rectype, 'N')
	SET @cdStopTimeID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'StopTime', @rectype, 'N')
	SET @cdLoadsID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Loads', @rectype, 'N')
	SET @cdMilesID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Miles', @rectype, 'N')
	SET @cdHoursID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Hours', @rectype, 'N')
	SET @cdZoneID			= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Zone', @rectype, 'N')
	SET @cdHaulCodeID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'HaulCode', @rectype, 'N')
	SET @cdHaulBasisID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'HaulBasis', @rectype, 'N')
	SET @cdHaulRateID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'HaulRate', @rectype, 'N')
	SET @cdHaulTotalID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'HaulTotal', @rectype, 'N')
	SET @cdRevCodeID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RevCode', @rectype, 'N')
	SET @cdRevBasisID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RevBasis', @rectype, 'N')
	SET @cdRevRateID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RevRate', @rectype, 'N')
	SET @cdRevTotalID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RevTotal', @rectype, 'N')
	SET @cdPayCodeID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PayCode', @rectype, 'N')
	SET @cdPayBasisID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PayBasis', @rectype, 'N')
	SET @cdPayRateID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PayRate', @rectype, 'N')
	SET @cdPayTotalID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PayTotal', @rectype, 'N')
	SET @cdTaxGroupID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxGroup', @rectype, 'N')
	SET @cdTaxTypeID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxType', @rectype, 'N')
	SET @cdTaxCodeID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxCode', @rectype, 'N')
	SET @cdTaxBasisID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxBasis', @rectype, 'N')
	SET @cdTaxTotalID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxTotal', @rectype, 'N')
	SET @cdDiscBasisID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'DiscBasis', @rectype, 'N')
	SET @cdDiscRateID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'DiscRate', @rectype, 'N')
	SET @cdDiscOffID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'DiscOff', @rectype, 'N')
	SET @cdTaxDiscID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxDisc', @rectype, 'N')
	SET @cdVendorGroupID	= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'VendorGroup', @rectype, 'N')
	SET @cdMSTransID		= dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MSTrans', @rectype, 'N')


	------------------------------------------
	-- BEGIN THE DEFAULT GENERATING PROCESS --
	-- FOR THOSE COLUMNS WHOSE DEFAULT IS	--
	-- UNIQUE FOR EACH IMPORTED RECORD		--
	------------------------------------------
	DECLARE curWorkEdit CURSOR LOCAL FAST_FORWARD FOR
		SELECT IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
		  FROM IMWE INNER JOIN DDUD 
			ON IMWE.Identifier = DDUD.Identifier 
		   AND DDUD.Form = IMWE.Form
		 WHERE IMWE.ImportId = @ImportId 
		   AND IMWE.ImportTemplate = @ImportTemplate 
		   AND IMWE.Form = @Form 
		   AND IMWE.RecordType = @rectype
	  ORDER BY IMWE.RecordSeq, IMWE.Identifier
    
	-- OPEN CUSOR AND GET FIRST RECORD --
	OPEN curWorkEdit
	SET @curOpen = 1

	FETCH NEXT FROM curWorkEdit INTO @curRecSeq, @curIdent, @curTableName, @curCol, @curUploadVal
    
	SELECT @curCurSeq = @curRecSeq, @curComplete = 0, @curCounter = 1

	-------------------------------------------------------------------------------------------------------------
	-- For each imported record:																			   --
	-- (Each imported record has multiple records in the IMWE table representing columns of the import record) --
	-- Cursor will cycle through each column of an imported record and set the imported value into a variable  --
	-- that could be used during the defaulting process later if desired.  It may not be used at all.		   --
	-------------------------------------------------------------------------------------------------------------	

	-- WHILE CURSOR IS NOT EMPTY --
	WHILE @ImportCompleted = 'N'
		BEGIN
    
			-- NEW IMPORT SEQ --
			IF @curCurSeq = @curRecSeq AND @@FETCH_STATUS = 0
				BEGIN
				
					------------------------------------------------
					-- GET UPLOADED VALUES FOR THIS IMPORT RECORD --
					------------------------------------------------
					IF @curCol = 'Co' 
						IF @curUploadVal IS NULL SET @IsEmptyCo = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @Co = CONVERT(int, @curUploadVal)

 					IF @curCol = 'Mth' 
						IF @curUploadVal IS NULL SET @IsEmptyMth = 'Y'
						ELSE IF ISDATE(@curUploadVal) = 1 SET @Mth = CONVERT(smalldatetime, @curUploadVal)

					IF @curCol = 'BatchId' 
						IF @curUploadVal IS NULL SET @IsEmptyCo = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @BatchId = CONVERT(int, @curUploadVal)

					IF @curCol = 'HaulLine' 
						IF @curUploadVal IS NULL SET @IsEmptyHaulLine = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @HaulLine = CONVERT(int, @curUploadVal)

					IF @curCol = 'BatchTransType' 
						IF @curUploadVal IS NULL SET @IsEmptyBatchTransType = 'Y'
						ELSE SET @BatchTransType = @curUploadVal

					IF @curCol = 'FromLoc' 
						IF @curUploadVal IS NULL SET @IsEmptyFromLoc = 'Y'
						ELSE SET @FromLoc = @curUploadVal

					IF @curCol = 'Material' 
						IF @curUploadVal IS NULL SET @IsEmptyMaterial = 'Y'
						ELSE SET @Material = @curUploadVal

					IF @curCol = 'MatlVendor' 
						IF @curUploadVal IS NULL SET @IsEmptyMatlVendor = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @MatlVendor = CONVERT(int, @curUploadVal)

					IF @curCol = 'MatlGroup' 
						IF @curUploadVal IS NULL SET @IsEmptyMatlGroup = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @MatlGroup = CONVERT(int, @curUploadVal)

					IF @curCol = 'UM' 
						IF @curUploadVal IS NULL SET @IsEmptyUM = 'Y'
						ELSE SET @UM = @curUploadVal

					IF @curCol = 'SaleType' 
						IF @curUploadVal IS NULL SET @IsEmptySaleType = 'Y'
						ELSE SET @SaleType = @curUploadVal

					IF @curCol = 'CustGroup' 
						IF @curUploadVal IS NULL SET @IsEmptyCustGroup = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @CustGroup = CONVERT(int, @curUploadVal)

					IF @curCol = 'Customer' 
						IF @curUploadVal IS NULL SET @IsEmptyCustomer = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @Customer = CONVERT(int, @curUploadVal)

					IF @curCol = 'CustJob' 
						IF @curUploadVal IS NULL SET @IsEmptyCustJob = 'Y'
						ELSE SET @CustJob = @curUploadVal

					IF @curCol = 'CustPO' 
						IF @curUploadVal IS NULL SET @IsEmptyCustPO = 'Y'
						ELSE SET @CustPO = @curUploadVal
	
					IF @curCol = 'PaymentType' 
						IF @curUploadVal IS NULL SET @IsEmptyPaymentType = 'Y'
						ELSE SET @PaymentType = @curUploadVal
 
					IF @curCol = 'CheckNo' 
						IF @curUploadVal IS NULL SET @IsEmptyCheckNo = 'Y'
						ELSE SET @CheckNo = @curUploadVal

					IF @curCol = 'Hold' 
						IF @curUploadVal IS NULL SET @IsEmptyHold = 'Y'
						ELSE SET @Hold = @curUploadVal

					IF @curCol = 'JCCo' 
						IF @curUploadVal IS NULL SET @IsEmptyJCCo = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @JCCo = CONVERT(int, @curUploadVal)

					IF @curCol = 'Job' 
						IF @curUploadVal IS NULL SET @IsEmptyJob = 'Y'
						ELSE SET @Job = @curUploadVal

 					IF @curCol = 'PhaseGroup' 
						IF @curUploadVal IS NULL SET @IsEmptyPhaseGroup = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @PhaseGroup = CONVERT(int, @curUploadVal)

					IF @curCol = 'HaulPhase' 
						IF @curUploadVal IS NULL SET @IsEmptyHaulPhase = 'Y'
						ELSE SET @HaulPhase = @curUploadVal
		
 					IF @curCol = 'HaulJCCType' 
						IF @curUploadVal IS NULL SET @IsEmptyHaulJCCType = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @HaulJCCType = CONVERT(int, @curUploadVal)

 					IF @curCol = 'INCo' 
						IF @curUploadVal IS NULL SET @IsEmptyINCo = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @INCo = CONVERT(int, @curUploadVal)
 
					IF @curCol = 'ToLoc' 
						IF @curUploadVal IS NULL SET @IsEmptyToLoc = 'Y'
						ELSE SET @ToLoc = @curUploadVal

					IF @curCol = 'TruckType' 
						IF @curUploadVal IS NULL SET @IsEmptyTruckType = 'Y'
						ELSE SET @TruckType = @curUploadVal

					IF @curCol = 'StartTime' 
						IF @curUploadVal IS NULL SET @IsEmptyStartTime = 'Y'
						ELSE IF ISDATE(@curUploadVal) = 1 SET @StartTime = CONVERT(smalldatetime, @curUploadVal)

 					IF @curCol = 'StopTime' 
						IF @curUploadVal IS NULL SET @IsEmptyStopTime = 'Y'
						ELSE IF ISDATE(@curUploadVal) = 1 SET @StopTime = CONVERT(smalldatetime, @curUploadVal)
 
		 			IF @curCol = 'Loads' 
						IF @curUploadVal IS NULL SET @IsEmptyLoads = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @Loads = CONVERT(int, @curUploadVal)

		 			IF @curCol = 'Miles' 
						IF @curUploadVal IS NULL SET @IsEmptyMiles = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @Miles = CONVERT(numeric, @curUploadVal)

				 	IF @curCol = 'Hours' 
						IF @curUploadVal IS NULL SET @IsEmptyHours = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @Hours = CONVERT(numeric, @curUploadVal)

		 			IF @curCol = 'Zone' 
						IF @curUploadVal IS NULL SET @IsEmptyZone = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @Zone = CONVERT(int, @curUploadVal)

					IF @curCol = 'HaulCode' 
						IF @curUploadVal IS NULL SET @IsEmptyHaulCode = 'Y'
						ELSE SET @HaulCode = @curUploadVal

				 	IF @curCol = 'HaulBasis' 
						IF @curUploadVal IS NULL SET @IsEmptyHaulBasis = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @HaulBasis = CONVERT(numeric, @curUploadVal)

				 	IF @curCol = 'HaulRate' 
						IF @curUploadVal IS NULL SET @IsEmptyHaulRate = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @HaulRate = CONVERT(numeric, @curUploadVal)

				 	IF @curCol = 'HaulTotal' 
						IF @curUploadVal IS NULL SET @IsEmptyHaulTotal = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @HaulTotal = CONVERT(numeric, @curUploadVal)

					IF @curCol = 'RevCode' 
						IF @curUploadVal IS NULL SET @IsEmptyRevCode = 'Y'
						ELSE SET @RevCode = @curUploadVal

				 	IF @curCol = 'RevBasis' 
						IF @curUploadVal IS NULL SET @IsEmptyRevBasis = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @RevBasis = CONVERT(numeric, @curUploadVal)

				 	IF @curCol = 'RevRate' 
						IF @curUploadVal IS NULL SET @IsEmptyRevRate = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @RevRate = CONVERT(numeric, @curUploadVal)

				 	IF @curCol = 'RevTotal' 
						IF @curUploadVal IS NULL SET @IsEmptyRevTotal = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @RevTotal = CONVERT(numeric, @curUploadVal)

					IF @curCol = 'PayCode' 
						IF @curUploadVal IS NULL SET @IsEmptyPayCode = 'Y'
						ELSE SET @PayCode = @curUploadVal

				 	IF @curCol = 'PayBasis' 
						IF @curUploadVal IS NULL SET @IsEmptyPayBasis = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @PayBasis = CONVERT(numeric, @curUploadVal)

				 	IF @curCol = 'PayRate' 
						IF @curUploadVal IS NULL SET @IsEmptyPayRate = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @PayRate = CONVERT(numeric, @curUploadVal)

				 	IF @curCol = 'PayTotal' 
						IF @curUploadVal IS NULL SET @IsEmptyPayTotal = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @PayTotal = CONVERT(numeric, @curUploadVal)

		 			IF @curCol = 'TaxGroup' 
						IF @curUploadVal IS NULL SET @IsEmptyTaxGroup = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @TaxGroup = CONVERT(int, @curUploadVal)

		 			IF @curCol = 'TaxType' 
						IF @curUploadVal IS NULL SET @IsEmptyTaxType = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @TaxType = CONVERT(int, @curUploadVal)

					IF @curCol = 'TaxCode' 
						IF @curUploadVal IS NULL SET @IsEmptyTaxCode = 'Y'
						ELSE SET @TaxCode = @curUploadVal

				 	IF @curCol = 'TaxBasis' 
						IF @curUploadVal IS NULL SET @IsEmptyTaxBasis = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @TaxBasis = CONVERT(numeric, @curUploadVal)

				 	IF @curCol = 'TaxTotal' 
						IF @curUploadVal IS NULL SET @IsEmptyTaxTotal = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @TaxTotal = CONVERT(numeric, @curUploadVal)

				 	IF @curCol = 'DiscBasis' 
						IF @curUploadVal IS NULL SET @IsEmptyDiscBasis = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @DiscBasis = CONVERT(numeric, @curUploadVal)

				 	IF @curCol = 'DiscRate' 
						IF @curUploadVal IS NULL SET @IsEmptyDiscRate = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @DiscRate = CONVERT(numeric, @curUploadVal)

				 	IF @curCol = 'DiscOff' 
						IF @curUploadVal IS NULL SET @IsEmptyDiscOff = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @DiscOff = CONVERT(numeric, @curUploadVal)

				 	IF @curCol = 'TaxDisc' 
						IF @curUploadVal IS NULL SET @IsEmptyTaxDisc = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @TaxDisc = CONVERT(numeric, @curUploadVal)

		 			IF @curCol = 'VendorGroup' 
						IF @curUploadVal IS NULL SET @IsEmptyVendorGroup = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @VendorGroup = CONVERT(int, @curUploadVal)

		 			IF @curCol = 'MSTrans' 
						IF @curUploadVal IS NULL SET @IsEmptyMSTrans = 'Y'
						ELSE IF ISNUMERIC(@curUploadVal) = 1 SET @MSTrans = CONVERT(int, @curUploadVal)


					-- GET NEXT RECORD --
					FETCH NEXT FROM curWorkEdit INTO @curRecSeq, @curIdent, @curTableName, @curCol, @curUploadVal

				END --IF @curRecSeq = @curCurSeq
			ELSE 
				BEGIN 

					-------------------------------
					-- SET UP TO GET HEADER DATA --
					-------------------------------
        			SELECT @curRecKey = IMWE.UploadVal
        			  FROM IMWE
        			 WHERE IMWE.ImportTemplate = @ImportTemplate 
				       AND IMWE.ImportId = @ImportId
        			   AND IMWE.Identifier = @DetailRecKeyID 
					   AND IMWE.RecordType = @rectype 
        			   AND IMWE.RecordSeq = @curCurSeq --@curRecSeq
        
        			SELECT @HeaderRecSeq = IMWE.RecordSeq
        			  FROM IMWE
        			 WHERE IMWE.ImportTemplate = @ImportTemplate 
				       AND IMWE.ImportId = @ImportId
        			   AND IMWE.Identifier = @DetailRecKeyID 
				       AND IMWE.RecordType = @HeaderRecType 
        			   AND IMWE.UploadVal = @curRecKey
        
					----------------------------
					-- GET HEADER INFORMATION --
					----------------------------
					-- HeaderHaulerType --
        			SELECT @HeaderHaulerType = IMWE.UploadVal
        			  FROM IMWE
        			 WHERE IMWE.ImportTemplate = @ImportTemplate 
				       AND IMWE.ImportId = @ImportId
        			   AND IMWE.Identifier = @HeaderHaulTypeID 
					   AND IMWE.RecordType = @HeaderRecType 
        			   AND IMWE.RecordSeq = @HeaderRecSeq

					-- HeaderSaleDate --
					SELECT @HeaderSaleDate = IMWE.UploadVal
        			  FROM IMWE
        			 WHERE IMWE.ImportTemplate = @ImportTemplate 
				       AND IMWE.ImportId = @ImportId
        			   AND IMWE.Identifier = @HeaderSaleDateID 
					   AND IMWE.RecordType = @HeaderRecType 
        			   AND IMWE.RecordSeq = @HeaderRecSeq	

					-- HeaderEMGroup --
					SELECT @HeaderEMGroup = IMWE.UploadVal
        			  FROM IMWE
        			 WHERE IMWE.ImportTemplate = @ImportTemplate 
				       AND IMWE.ImportId = @ImportId
        			   AND IMWE.Identifier = @HeaderEMGroupID 
					   AND IMWE.RecordType = @HeaderRecType 
        			   AND IMWE.RecordSeq = @HeaderRecSeq

					-- HeaderEquipment --	
					SELECT @HeaderEquipment = IMWE.UploadVal
        			  FROM IMWE
        			 WHERE IMWE.ImportTemplate = @ImportTemplate 
				       AND IMWE.ImportId = @ImportId
        			   AND IMWE.Identifier = @HeaderEquipmentID 
					   AND IMWE.RecordType = @HeaderRecType 
        			   AND IMWE.RecordSeq = @HeaderRecSeq	

					-- HeadetVendorGroup --	
					SELECT @HeaderVendorGroup = IMWE.UploadVal
        			  FROM IMWE
        			 WHERE IMWE.ImportTemplate = @ImportTemplate 
				       AND IMWE.ImportId = @ImportId
        			   AND IMWE.Identifier = @HeaderVendorGroupID 
					   AND IMWE.RecordType = @HeaderRecType 
        			   AND IMWE.RecordSeq = @HeaderRecSeq

					-- HeaderHaulVendor --
					SELECT @HeaderHaulVendor = IMWE.UploadVal
        			  FROM IMWE
        			 WHERE IMWE.ImportTemplate = @ImportTemplate 
				       AND IMWE.ImportId = @ImportId
        			   AND IMWE.Identifier = @HeaderHaulVendorID 
					   AND IMWE.RecordType = @HeaderRecType 
        			   AND IMWE.RecordSeq = @HeaderRecSeq

					-- HeaderTruck -- 	
					SELECT @HeaderTruck = IMWE.UploadVal
        			  FROM IMWE
        			 WHERE IMWE.ImportTemplate = @ImportTemplate 
				       AND IMWE.ImportId = @ImportId
        			   AND IMWE.Identifier = @HeaderTruckID 
					   AND IMWE.RecordType = @HeaderRecType 
        			   AND IMWE.RecordSeq = @HeaderRecSeq

					-------------------------
					-- SET DETAIL DEFAULTS --
					-------------------------

					-- HaulLine --
        			IF @HaulLineID <> 0 AND (ISNULL(@owHaulLine, 'Y') = 'Y' OR ISNULL(@IsEmptyHaulLine, 'Y') = 'Y')
        				BEGIN
        
						-- GET NEXT HAUL LINE NUMBER/SEQUENCE
						SELECT @HaulLine = ISNULL(MAX(CAST(w.UploadVal as int)), 0) + 1
        				  FROM IMWE w INNER JOIN IMWE e
        				    ON w.ImportTemplate = e.ImportTemplate 
						   AND w.ImportId = e.ImportId
        				   AND w.RecordType = e.RecordType 
						   AND w.RecordSeq = e.RecordSeq
        				 WHERE w.ImportTemplate = @ImportTemplate AND w.ImportId = @ImportId
        				   AND w.RecordType = @rectype 
						   AND w.Identifier = @HaulLineID
						   AND e.Identifier = @HeaderRecKeyID
						   AND e.UploadVal = @HeaderRecSeq 
						   AND ISNUMERIC(w.UploadVal) = 1 
       
						   UPDATE IMWE
						      SET IMWE.UploadVal = @HaulLine
						    WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							  AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq 
							  AND IMWE.Identifier = @HaulLineID
        				END

					--------------------------------
					-- NO DEFAULT FOR: FromLoc	  --
					-- NO DEFAULT FOR: Material   --
					-- NO DEFAULT FOR: MatlVendor --
					--------------------------------
				
					-- MatlGroup --
					IF @MatlGroupID <> 0 AND (@owMatlGroup = 'Y' OR @IsEmptyMatlGroup = 'Y')
						BEGIN
						   SELECT @MatlGroup = MatlGroup
						     FROM bHQCO WITH (NOLOCK)
						    WHERE HQCo = @Co
			        
						   UPDATE IMWE
						      SET IMWE.UploadVal = @MatlGroup
						    WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							  AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq 
							  AND IMWE.Identifier = @MatlGroupID
						END

					-- UM --
        			IF @UMID <> 0 AND (@owUM = 'Y' OR @IsEmptyUM = 'Y')
         				BEGIN

							SELECT @UM = StdUM
							  FROM bHQMT WITH (NOLOCK)
							 WHERE MatlGroup = @MatlGroup
							   AND Material = @Material

						   UPDATE IMWE
						      SET IMWE.UploadVal = @UM
						    WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							  AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							  AND IMWE.Identifier = @UMID
						END

					-- SaleType --
					IF @SaleTypeID <> 0 AND (@owSaleType = 'Y' OR @IsEmptySaleType = 'Y')
						BEGIN

							-- MAKE BEST GUESS --        
							IF @ToLoc IS NOT NULL SET @SaleType = 'I'
							IF @Job IS NOT NULL SET @SaleType = 'J'
							IF @Customer IS NOT NULL SET @SaleType = 'C'

						   UPDATE IMWE
						      SET IMWE.UploadVal = @SaleType
						    WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							  AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							  AND IMWE.Identifier = @SaleTypeID
						END					
				
					-- CustGroup --
					IF @CustGroupID <> 0 AND (@owCustGroup = 'Y' OR @IsEmptyCustGroup = 'Y')
						BEGIN

						   SELECT @CustGroup = h.CustGroup
						     FROM bHQCO h WITH (NOLOCK)
						     JOIN bMSCO m WITH (NOLOCK) 
						       ON m.ARCo = h.HQCo
						    WHERE m.MSCo = @Co

						   UPDATE IMWE
						      SET IMWE.UploadVal = @CustGroup
						    WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							  AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							  AND IMWE.Identifier = @CustGroupID
						END		

					---------------------------------------------------------------------------
					-- NO DEFAULT FOR: Customer												 --
					-- NO DEFAULT FOR: CustJob												 --
					-- NO DEFAULT FOR: CustPO												 --
					-- PaymentType ALREADY DEFAULTED TO 'C' -- ONLY USED WHEN SaleType = 'C' --
					-- NO DEFAULT FOR: CheckNo												 --
					-- Hold ALREADY DEFAULTED TO 'N'										 --
					---------------------------------------------------------------------------

					-- JCCo --
					IF @JCCoID <> 0 AND (@owJCCo = 'Y' OR @IsEmptyJCCo = 'Y')
						BEGIN				

							IF @SaleType = 'J'
								SET @JCCo = @Co
							ELSE
								SET @JCCo = NULL

						   UPDATE IMWE
						      SET IMWE.UploadVal = @JCCo
						    WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							  AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							  AND IMWE.Identifier = @JCCoID

						END

					-------------------------
					-- NO DEFAULT FOR: Job --
					-------------------------

					-- PhaseGroup --
					IF @PhaseGroupID <> 0 AND (@owPhaseGroup = 'Y' OR @IsEmptyPhaseGroup = 'Y')
						BEGIN	

							SELECT @PhaseGroup = PhaseGroup
							  FROM bHQCO with (nolock)
							 WHERE HQCo = @JCCo

							UPDATE IMWE
						       SET IMWE.UploadVal = @PhaseGroup
						     WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @PhaseGroupID

						END

					-- INCo --
					IF @INCoID <> 0 AND @Co IS NOT NULL AND (@owINCo = 'Y' OR @IsEmptyINCo = 'Y')
						BEGIN	

							SET @INCo = NULL -- ONLY NEEDED FOR INVENTORY --

							--IF @SaleType = 'I' -- TK-06283 Needed to lookup default PayRate
							SET @INCo = @Co

							UPDATE IMWE
							   SET IMWE.UploadVal = @INCo
						     WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @INCoID

						END

					---------------------------
					-- NO DEFAULT FOR: ToLoc --
					---------------------------

					-- TruckType --
					IF @TruckTypeID <> 0 AND (@owTruckType = 'Y' OR @IsEmptyTruckType = 'Y')
						BEGIN		

							SET @TruckType = NULL		

							IF @HeaderHaulerType = 'H' 
								BEGIN
									SELECT @TruckType = TruckType
          							  FROM bMSVT WITH (NOLOCK)
          							 WHERE VendorGroup = @HeaderVendorGroup 
								       AND Vendor = @HeaderHaulVendor 
									   AND Truck = @HeaderTruck
								END

							ELSE -- @HeaderHaulerType = 'E' 
								BEGIN
									SELECT @TruckType = MSTruckType
									  FROM bEMEM WITH (NOLOCK) 
									 WHERE EMCo = @HeaderEMCo 
									   AND Equipment = @HeaderEquipment
								END


							UPDATE IMWE
							   SET IMWE.UploadVal = @TruckType
						     WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @TruckTypeID

						END

					---------------------------
					-- NO DEFAULT FOR: Loads --
					-- NO DEFAULT FOR: Miles --
					---------------------------

					-- Hours --
					IF @HoursID <> 0 AND (@StartTime IS NOT NULL AND @StopTime IS NOT NULL) AND (@owHours = 'Y' OR @IsEmptyHours = 'Y')
						BEGIN	
							SET @Hours = 0

							IF ISDATE(@StartTime) = 1 AND ISDATE(@StopTime) = 1
								BEGIN

									-- GET DIFFERENCE IN MINUTES --
									SET @TempMinutes = DATEDIFF(mi, @StartTime, @StopTime)
									
									-- CONVERT MINUTES INTO HOURS --
									IF @TempMinutes > 0 SET @Hours = @TempMinutes/60.0

								END

							UPDATE IMWE
							   SET IMWE.UploadVal = @Hours
						     WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @HoursID
						END

					---------------------------
					-- NO DEFAULTS FOR: Zone --
					---------------------------
					
					--------------------------------
					-- HAUL CODE LINE INFORMATION --
					--------------------------------
					-- HaulCode --
					IF @HaulCodeID <> 0 AND (@owHaulCode = 'Y' OR @IsEmptyHaulCode = 'Y')
						BEGIN		
							SELECT @HaulCode = HaulCode
							  FROM HQMT 
							 WHERE MatlGroup = @MatlGroup 
							   AND Material = @Material

							UPDATE IMWE
							   SET IMWE.UploadVal = @HaulCode
						     WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @HaulCodeID
						END
				
					SELECT @TempLocGroup = LocGroup, @TempLocTaxCode = TaxCode
					  FROM bINLM WITH (NOLOCK)
				     WHERE INCo = @INCo 
					   AND Loc = @FromLoc

					-- NULLS -> @disctemplate, @pricetemplate, @zone,   
					--			@msg
					EXEC @Temprcode = dbo.bspMSTicTemplateGet @Co, @SaleType, @CustGroup, @Customer, @CustJob, 
															  @CustPO, @JCCo, @Job, @INCo, @ToLoc, @FromLoc,
															  @TempQuote OUTPUT, NULL, NULL, NULL, @TempHaulTaxOpt, @TempTaxCode, 
															  @TempPayTerms, @TempMatlDisc, @TempDiscRateHQPT, @TempDiscOpt, NULL

					-- NULLS -> @minamt, @basistooltip, @ratetooltip, @totaltooltip, @msg
					EXEC @Temprcode = dbo.bspMSTicHaulCodeVal @Co, @HaulCode, @MatlGroup, @Material, @TempLocGroup, 
															  @FromLoc, @TempQuote, @UM, @TruckType, @Zone,
															  @TempHaulBasis OUTPUT, @TempHaulTaxable OUTPUT, @TempHaulRate OUTPUT, 
															  NULL, NULL, NULL, NULL, NULL


					-- HaulPhase -- 
					IF @HaulPhaseID <> 0 AND (@owHaulPhase = 'Y' OR @IsEmptyHaulPhase = 'Y')
						BEGIN	

							SET @HaulPhase = NULL -- ONLY NEEDED FOR JOBS --						

							IF @SaleType = 'J'
								BEGIN
									SELECT @HaulPhase = ISNULL(HaulPhase, MatlPhase)
									  FROM HQMT
									 WHERE MatlGroup = @MatlGroup
									   AND Material = @Material
								END
							
							UPDATE IMWE
							   SET IMWE.UploadVal = @HaulPhase
						     WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @HaulPhaseID
						END

					-- HaulJCCType -- 
					IF @HaulJCCTypeID <> 0 AND (@owHaulJCCType = 'Y' OR @IsEmptyHaulJCCType = 'Y')
						BEGIN	

							SET @HaulJCCType = NULL -- ONLY NEEDED FOR JOBS --						

							IF @SaleType = 'J'
								BEGIN
									SELECT @HaulJCCType = HaulJCCostType
									  FROM HQMT
									 WHERE MatlGroup = @MatlGroup
									   AND Material = @Material
								END
							
							UPDATE IMWE
							   SET IMWE.UploadVal = @HaulJCCType
						     WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @HaulJCCTypeID
						END

					-- HaulBasis --
					IF @HaulCode IS NOT NULL AND (@HaulBasisID <> 0 AND (@owHaulBasis = 'Y' OR @IsEmptyHaulBasis = 'Y'))
						BEGIN
							SET @HaulBasis = @TempHaulBasis

							UPDATE IMWE
							   SET IMWE.UploadVal = @HaulBasis
						     WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @HaulBasisID
						END

					-- HaulRate --    
					IF @HaulRateID <> 0 AND (@owHaulRate = 'Y' OR @IsEmptyHaulRate = 'Y')
						BEGIN
							SET @HaulRate = @TempHaulRate

							UPDATE IMWE
							   SET IMWE.UploadVal = @HaulRate
						     WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @HaulRateID
						END

					-- HaulTotal --
					IF @HaulTotalID <> 0 AND (@owHaulTotal = 'Y' OR @IsEmptyHaulTotal = 'Y')
						BEGIN

							SET @HaulTotal = ISNULL(@HaulBasis, 0) * ISNULL(@HaulRate, 0)

							UPDATE IMWE
							   SET IMWE.UploadVal = @HaulTotal
						     WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							   AND IMWE.Identifier = @HaulTotalID	
						END

					-------------------------------
					-- REV CODE LINE INFORMATION --
					-------------------------------
					IF @HeaderHaulerType = 'E' 
						BEGIN

							-- RevCode --
							IF @RevCodeID <> 0 AND (@owRevCode = 'Y' OR @IsEmptyRevCode = 'Y')
								BEGIN
									SELECT @RevCode = RevenueCode
									  FROM bEMEM WITH (NOLOCK)
									 WHERE EMCo = @HeaderEMCo
									   AND Equipment = @HeaderEquipment

									UPDATE IMWE
									   SET IMWE.UploadVal = @RevCode
						             WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
								       AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							           AND IMWE.Identifier = @RevCodeID								
								END

							-- RevBasis --
							IF @RevBasisID <> 0 AND (@owRevBasis = 'Y' OR @IsEmptyRevBasis = 'Y')
								BEGIN

									SET @RevBasis = 0

									-- GET TIME UNIT OF MEASURE --
									SELECT @TempHoursUM = ISNULL(HrsPerTimeUM, 0)
									  FROM bEMRC WITH (NOLOCK)
									 WHERE EMGroup = @HeaderEMGroup
									   AND RevCode = @RevCode

									-- CALCULATE RevBasis --
									IF (@TempHoursUM > 0) AND (ISNULL(@Hours, 0) > 0)
										SET @RevBasis = @Hours/@TempHoursUM

									UPDATE IMWE
									   SET IMWE.UploadVal = @RevBasis
						             WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
									   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							           AND IMWE.Identifier = @RevBasisID		
								END
			
							-- RevRate --
							IF @RevRateID <> 0 AND (@owRevRate = 'Y' OR @IsEmptyRevRate = 'Y')
								BEGIN
									-- GET DEFAULT RevRate -- NULLS -> @time_um, @work_um, @tmpmsg
									EXEC @Temprcode = dbo.bspEMRevRateUMDflt @HeaderEMCo, @HeaderEMGroup, @SaleType, 
																			 @HeaderEquipment, @HeaderEquipCat, @RevCode, 
																			 @JCCo, @Job, 
																			 @RevRate OUTPUT, NULL, NULL, NULL
									SET @RevRate = ISNULL(@RevRate, 0)

									UPDATE IMWE
									   SET IMWE.UploadVal = @RevRate
						             WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
									   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							           AND IMWE.Identifier = @RevRateID	
								END

							-- RevTotal --
							IF @RevTotalID <> 0 AND (@owRevTotal = 'Y' OR @IsEmptyRevTotal = 'Y')
								BEGIN
									
									SET @RevTotal = (ISNULL(@RevBasis, 0) * ISNULL(@RevRate, 0))		

									UPDATE IMWE
									   SET IMWE.UploadVal = @RevTotal
						             WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
									   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							           AND IMWE.Identifier = @RevTotalID	
								END

							------TFS-47289 haul values may be based on revenue values
							--SET @BasedOn = null
							--If @HaulCode IS NOT NULL AND @RevCode IS NOT NULL
							--	BEGIN
							--	SELECT @BasedOn = HaulBased
							--	FROM dbo.bEMRC WITH (NOLOCK)
							--	WHERE EMGroup = @HeaderEMGroup
							--		AND RevCode = @RevCode
        
							--	PRINT 'We are at haul based on revenue. Flag: ' + dbo.vfToString(@HeaderEMGroup) + ',' + dbo.vfToString(@RevCode) + ',' + dbo.vfToString(@HaulBasedOn)

							--	if @BasedOn = 'Y'
							--		BEGIN
							--		---- update haul basis
							--		UPDATE IMWE
							--			SET IMWE.UploadVal = REV.UploadVal
							--		FROM dbo.IMWE IMWE
							--		INNER JOIN dbo.IMWE REV ON REV.ImportTemplate = IMWE.ImportTemplate AND REV.ImportId = IMWE.ImportId AND REV.RecordType = IMWE.RecordType AND REV.RecordSeq = IMWE.RecordSeq AND REV.Identifier = @OvrRevBasisID
						 --            WHERE IMWE.ImportTemplate = @ImportTemplate
							--			AND IMWE.ImportId = @ImportId 
							--			AND IMWE.RecordType = @rectype 
							--			AND IMWE.RecordSeq = @curCurSeq
							--			AND IMWE.Identifier = @HaulBasisID
  
							--		---- update haul rate
							--		UPDATE IMWE
							--			SET IMWE.UploadVal = REV.UploadVal
							--		FROM dbo.IMWE IMWE
							--		INNER JOIN dbo.IMWE REV ON REV.ImportTemplate = IMWE.ImportTemplate AND REV.ImportId = IMWE.ImportId AND REV.RecordType = IMWE.RecordType AND REV.RecordSeq = IMWE.RecordSeq AND REV.Identifier = @OvrRevRateID
						 --            WHERE IMWE.ImportTemplate = @ImportTemplate
							--			AND IMWE.ImportId = @ImportId 
							--			AND IMWE.RecordType = @rectype 
							--			AND IMWE.RecordSeq = @curCurSeq
							--			AND IMWE.Identifier = @HaulRateID
  
  					--				---- update haul total
							--		UPDATE IMWE
							--			SET IMWE.UploadVal = REV.UploadVal
							--		FROM dbo.IMWE IMWE
							--		INNER JOIN dbo.IMWE REV ON REV.ImportTemplate = IMWE.ImportTemplate AND REV.ImportId = IMWE.ImportId AND REV.RecordType = IMWE.RecordType AND REV.RecordSeq = IMWE.RecordSeq AND REV.Identifier = @OvrRevTotalID
						 --            WHERE IMWE.ImportTemplate = @ImportTemplate
							--			AND IMWE.ImportId = @ImportId 
							--			AND IMWE.RecordType = @rectype 
							--			AND IMWE.RecordSeq = @curCurSeq
							--			AND IMWE.Identifier = @HaulTotalID
							--		END
							--	END

						END --IF @HeaderHaulerType = 'E' 


					-------------------------------
					-- PAY CODE LINE INFORMATION --
					-------------------------------
					IF @HeaderHaulerType = 'H'
						BEGIN

							-- PayCode --
							IF @PayCodeID <> 0 AND (@owPayCode = 'Y' OR @IsEmptyPayCode = 'Y')
								BEGIN

									-- GET PayCode FROM QUOTE -- NULLS -> @haulcode, @msg
									EXEC @Temprcode = dbo.bspMSTicTruckTypeVal @Co, @TruckType, @TempQuote, @TempLocGroup, 
														@FromLoc, @MatlGroup, @Material, @UM, @HeaderVendorGroup, @HeaderHaulVendor, 
														@HeaderTruck, @HeaderHaulerType, 
														NULL, @TempPayCode output, NULL
        
									-- GET PayCode -- NULLS -> @driver, @tare, @weighum, @trucktype
												   -- NULLS -> @returnvendor, @UpdateVendor, @msg
									EXEC @Temprcode = dbo.bspMSTicTruckVal @HeaderVendorGroup, @HeaderHaulVendor, @HeaderTruck, 'ADD',
														NULL, NULL, NULL, NULL, 
														@PayCode output, 
														NULL, NULL, NULL

									-- PayCode FROM QUOTE OVERRIDES DEFAULT PayCode --
									SET @PayCode = ISNULL(@TempPayCode, @PayCode)
        
									UPDATE IMWE
									   SET IMWE.UploadVal = @PayCode
						             WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
									   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							           AND IMWE.Identifier = @PayCodeID	
								END

							-- GET PayBasis, PayRate, and PayMinAmt IN ONE CALL -- NULLS -> @basistooltip, @totaltooltip, @msg
							
							EXEC @Temprcode = bspMSTicPayCodeVal @Co, @PayCode, @MatlGroup, @Material, @TempLocGroup, 
												@FromLoc, @TempQuote, @TruckType, @HeaderVendorGroup, @HeaderHaulVendor, 
												@HeaderTruck, @UM, @Zone,
												@TempPayRate output, @TempPayBasis output, NULL, NULL,
												@TempPayMinAmt output, @msg output
												
							-- PayBasis --
							IF @PayBasisID <> 0 AND (@owPayBasis = 'Y' OR @IsEmptyPayBasis = 'Y')
								BEGIN

									-- ONLY 2, 3, 6 ARE SUPPORTED IN HAUL ENTRY --
									SET @PayBasis =  CASE @TempPayBasis 
															WHEN 1 THEN  0					-- @MatlUnits not used
															WHEN 2 THEN  ISNULL(@Hours, 0)
															WHEN 3 THEN  ISNULL(@Loads, 0)
															WHEN 4 THEN  0					-- @MatlUnits not used
															WHEN 5 THEN  0					-- @MatlUnits not used
															WHEN 6 THEN  ISNULL(@HaulTotal, 0)
															ELSE 0 END

									UPDATE IMWE
									   SET IMWE.UploadVal = @PayBasis
						             WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
									   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							           AND IMWE.Identifier = @PayBasisID	
								END

							-- PayRate -- TK-06283
							IF @PayRateID <> 0 AND (@owPayRate = 'Y' OR @IsEmptyPayRate = 'Y')
								BEGIN
										
									SET @PayRate = ISNULL(@TempPayRate, 0)

									UPDATE IMWE
									   SET IMWE.UploadVal = @PayRate
						             WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
								       AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							           AND IMWE.Identifier = @PayRateID
								END


							-- PayTotal -- TK-06283
							IF @PayTotalID <> 0 AND (@owPayTotal = 'Y' OR @IsEmptyPayTotal = 'Y')
								BEGIN

									SET @PayTotal = ISNULL(@PayBasis, 0) * ISNULL(@PayRate, 0)
								
									-- PAY TOTAL MUST BE AT LEAST MIN AMT --
									IF @PayTotal < @TempPayMinAmt SET @PayTotal = @TempPayMinAmt
								
									UPDATE IMWE
									   SET IMWE.UploadVal = @PayTotal
						             WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
									   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
							           AND IMWE.Identifier = @PayTotalID	
								END			

						END --IF @HeaderHaulerType = 'H' --OK


						----TFS-47289 haul Rates and amounts are based on revenue/pay amounts
						SET @BasedOn = NULL
						IF @HaulCode IS NOT NULL
							BEGIN
         					SELECT @BasedOn = RevBased
         					FROM dbo.bMSHC WITH (NOLOCK)
         					where MSCo = @Co
								AND HaulCode = @HaulCode

							if @BasedOn = 'Y'
								BEGIN
           
								---- update haul basis
								SELECT @SourceID = CASE WHEN @HeaderHaulerType = 'H' THEN @OvrPayBasisID ELSE @OvrRevBasisID END
								UPDATE IMWE
									SET IMWE.UploadVal = REV.UploadVal
								FROM dbo.IMWE IMWE
								INNER JOIN dbo.IMWE REV ON REV.ImportTemplate = IMWE.ImportTemplate AND REV.ImportId = IMWE.ImportId AND REV.RecordType = IMWE.RecordType
										AND REV.RecordSeq = IMWE.RecordSeq AND REV.Identifier = @SourceID
						        WHERE IMWE.ImportTemplate = @ImportTemplate
									AND IMWE.ImportId = @ImportId 
									AND IMWE.RecordType = @rectype 
									AND IMWE.RecordSeq = @curCurSeq
									AND IMWE.Identifier = @HaulBasisID    
										                                
								---- update haul rate
								SELECT @SourceID = CASE WHEN @HeaderHaulerType = 'H' THEN @OvrPayRateID ELSE @OvrRevRateID END
								UPDATE IMWE
									SET IMWE.UploadVal = REV.UploadVal
								FROM dbo.IMWE IMWE
								INNER JOIN dbo.IMWE REV ON REV.ImportTemplate = IMWE.ImportTemplate AND REV.ImportId = IMWE.ImportId AND REV.RecordType = IMWE.RecordType
										AND REV.RecordSeq = IMWE.RecordSeq AND REV.Identifier = @SourceID
						            WHERE IMWE.ImportTemplate = @ImportTemplate
									AND IMWE.ImportId = @ImportId 
									AND IMWE.RecordType = @rectype 
									AND IMWE.RecordSeq = @curCurSeq
									AND IMWE.Identifier = @HaulRateID
  
  								---- update haul total
								SELECT @SourceID = CASE WHEN @HeaderHaulerType = 'H' THEN @OvrPayTotalID ELSE @OvrRevTotalID END
								UPDATE IMWE
									SET IMWE.UploadVal = REV.UploadVal
								FROM dbo.IMWE IMWE
								INNER JOIN dbo.IMWE REV ON REV.ImportTemplate = IMWE.ImportTemplate AND REV.ImportId = IMWE.ImportId AND REV.RecordType = IMWE.RecordType
										AND REV.RecordSeq = IMWE.RecordSeq AND REV.Identifier = @SourceID
						        WHERE IMWE.ImportTemplate = @ImportTemplate
									AND IMWE.ImportId = @ImportId 
									AND IMWE.RecordType = @rectype 
									AND IMWE.RecordSeq = @curCurSeq
									AND IMWE.Identifier = @HaulTotalID
								END
							END ----end revenue basis update

					----revenue amounts are based on haul amounts
					SET @BasedOn = NULL
					IF @RevCode IS NOT NULL AND @HaulCode IS NOT NULL
						BEGIN
						SELECT @BasedOn = HaulBased
						FROM dbo.bEMRC WITH (NOLOCK)
						WHERE EMGroup = @HeaderEMGroup
							AND RevCode = @RevCode
						
						IF @BasedOn = 'Y'
							BEGIN
							---- update revenue basis
							UPDATE IMWE
								SET IMWE.UploadVal = HAUL.UploadVal
							FROM dbo.IMWE IMWE
							INNER JOIN dbo.IMWE HAUL ON HAUL.ImportTemplate = IMWE.ImportTemplate AND HAUL.ImportId = IMWE.ImportId AND HAUL.RecordType = IMWE.RecordType
									AND HAUL.RecordSeq = IMWE.RecordSeq AND HAUL.Identifier = @OvrHaulBasisID
						        WHERE IMWE.ImportTemplate = @ImportTemplate
								AND IMWE.ImportId = @ImportId 
								AND IMWE.RecordType = @rectype 
								AND IMWE.RecordSeq = @curCurSeq
								AND IMWE.Identifier = @RevBasisID
						
							---- update revenue rate
							UPDATE IMWE
								SET IMWE.UploadVal = HAUL.UploadVal
							FROM dbo.IMWE IMWE
							INNER JOIN dbo.IMWE HAUL ON HAUL.ImportTemplate = IMWE.ImportTemplate AND HAUL.ImportId = IMWE.ImportId AND HAUL.RecordType = IMWE.RecordType
									AND HAUL.RecordSeq = IMWE.RecordSeq AND HAUL.Identifier = @OvrHaulRateID
						        WHERE IMWE.ImportTemplate = @ImportTemplate
								AND IMWE.ImportId = @ImportId 
								AND IMWE.RecordType = @rectype 
								AND IMWE.RecordSeq = @curCurSeq
								AND IMWE.Identifier = @RevRateID

  							---- update revenue total
							UPDATE IMWE
								SET IMWE.UploadVal = HAUL.UploadVal
							FROM dbo.IMWE IMWE
							INNER JOIN dbo.IMWE HAUL ON HAUL.ImportTemplate = IMWE.ImportTemplate AND HAUL.ImportId = IMWE.ImportId AND HAUL.RecordType = IMWE.RecordType 
									AND HAUL.RecordSeq = IMWE.RecordSeq AND HAUL.Identifier = @OvrHaulTotalID
						        WHERE IMWE.ImportTemplate = @ImportTemplate
								AND IMWE.ImportId = @ImportId 
								AND IMWE.RecordType = @rectype 
								AND IMWE.RecordSeq = @curCurSeq
								AND IMWE.Identifier = @RevTotalID
							END
					
						END ---- if @revcode is not null AND @HaulCode IS NOT NULL              


					--------------------------
					-- TAX LINE INFORMATION --
					--------------------------
					SELECT @TempTaxGroup = TaxGroup, @TempCountry = ISNULL(Country, DefaultCountry)
					  FROM bHQCO
					 WHERE HQCo = @Co

					-- TaxGroup --
					IF @TaxGroupID <> 0 AND (@owTaxGroup = 'Y' OR @IsEmptyTaxGroup = 'Y')					
						BEGIN

							SET @TaxGroup = @TempTaxGroup

							UPDATE IMWE
							   SET IMWE.UploadVal = @TaxGroup
				             WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
					           AND IMWE.Identifier = @TaxGroupID	
						END

					-- TaxType --
					IF @TaxTypeID <> 0 AND (@owTaxType = 'Y' OR @IsEmptyTaxType = 'Y')					
						BEGIN

							SET @TaxType = 1

							IF @SaleType IN ('J', 'I') SET @TaxType = 2

							IF (@TaxType = 1) AND (@TempCountry IN ('AU','CA')) SET @TaxType = 3

							UPDATE IMWE
							   SET IMWE.UploadVal = @TaxType
				             WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
					           AND IMWE.Identifier = @TaxTypeID	
						END

					-- TaxCode --
					IF @TaxCodeID <> 0 AND (@owTaxCode = 'Y' OR @IsEmptyTaxCode = 'Y')					
						BEGIN				

							SELECT @TaxCode = CASE 
													WHEN TaxOpt = 0 THEN NULL
													WHEN TaxOpt = 1 THEN @TempLocTaxCode
													WHEN TaxOpt = 2 THEN @TempTaxCode
													WHEN TaxOpt = 3 THEN ISNULL(@TempTaxCode, @TempLocTaxCode)
													WHEN TaxOpt = 4 AND (@HaulCode IS NULL) THEN @TempLocTaxCode
													WHEN TaxOpt = 4 AND (@HaulCode IS NOT NULL) THEN @TempTaxCode
													ELSE NULL END
							  FROM bMSCO WITH (NOLOCK)
							 WHERE MSCo = @Co

							UPDATE IMWE
							   SET IMWE.UploadVal = @TaxCode
				             WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq					           
							   AND IMWE.Identifier = @TaxCodeID							

						END

					-- TaxBasis --
					IF @TaxBasisID <> 0 AND (@owTaxBasis = 'Y' OR @IsEmptyTaxBasis = 'Y')					
						BEGIN	

							SET @TaxBasis = 0

							-- CUSTOMER SALE WITH CASH OR CREDIT CARD --
							IF @SaleType = 'C' AND (@PaymentType IN ('C', 'X'))
								BEGIN

									SELECT @TempUploadVal = IMWE.ImportedVal
									  FROM IMWE WITH (NOLOCK)
									 WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
									   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
									   AND IMWE.Identifier = @TaxBasisID		
								
									IF ISNUMERIC(@TempUploadVal) = 1 SET @TaxBasis = CONVERT(DECIMAL(10,5), @TempUploadVal)
								END

							ELSE -- IF @SaleType <> 'C' 

								BEGIN
									-- IS HAUL TAXABLE --
									IF (@TempHaulTaxable = 'Y') AND (@HaulCode IS NOT NULL) AND (@TaxCode IS NOT NULL)
										BEGIN
											IF ((@TempHaulTaxOpt = 1) AND (@HeaderHaulerType = 'H') AND (@HeaderHaulVendor IS NOT NULL))
												OR (@TempHaulTaxOpt = 2)
													SET @TaxBasis = @HaulTotal
										END

								END -- IF @SaleType = 'C' AND (@PaymentType IN ('C', 'X'))


							UPDATE IMWE
							   SET IMWE.UploadVal = @TaxBasis
				             WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
					           AND IMWE.Identifier = @TaxBasisID	
						END

					-- GET TAX RATE -- NULLS -> @msg
					IF @ynTaxTotal = 'Y' OR @ynTaxDisc = 'Y'
						EXEC @Temprcode = dbo.bspHQTaxRateGet @TaxGroup, @TaxCode, @HeaderSaleDate, @TempTaxRate output, NULL

					-- TaxTotal --
					IF @TaxTotalID <> 0 AND (@owTaxTotal = 'Y' OR @IsEmptyTaxTotal = 'Y')					
						BEGIN	

							SET @TaxTotal = 0

							-- CUSTOMER SALE WITH CASH OR CREDIT CARD --
							IF @SaleType = 'C' AND (@PaymentType IN ('C', 'X'))
								BEGIN

									SELECT @TempUploadVal = IMWE.ImportedVal
									  FROM IMWE WITH (NOLOCK)
									 WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
									   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
									   AND IMWE.Identifier = @TaxTotalID		
								
									IF ISNUMERIC(@TempUploadVal) = 1 SET @TaxBasis = CONVERT(DECIMAL(10,5), @TempUploadVal)
								END

							ELSE
								BEGIN
									SET @TaxTotal = ISNULL(@TaxBasis, 0) * ISNULL(@TempTaxRate, 0)
								END


							UPDATE IMWE
							   SET IMWE.UploadVal = @TaxTotal
				             WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
					           AND IMWE.Identifier = @TaxTotalID
						END


					-------------------------------
					-- DISCOUNT LINE INFORMATION --
					-------------------------------
					IF @SaleType = 'C'
						BEGIN

							-- GET DISCOUNT TYPE AND RATE --
							SELECT @TempPayDiscType = ISNULL(PayDiscType, 'N'), @TempPayDiscRate = PayDiscRate
							  FROM bHQMT WITH (NOLOCK)
							 WHERE MatlGroup = @MatlGroup
							   AND Material = @Material
							
							-- DiscBasis -- 
							IF @ynDiscBasis = 'Y'
								BEGIN
									IF @TempPayTerms IS NULL SET @TempPayDiscType = 'N'
										ELSE IF @TempMatlDisc = 'N' SET @TempPayDiscType = 'R'
											
									SELECT @DiscBasis = CASE 
															WHEN @TempPayDiscType = 'U' THEN 0
															WHEN @TempPayDiscType = 'R' AND @TempMatlDisc = 'N' THEN ISNULL(@HaulTotal, 0)
															ELSE 0 END

									UPDATE IMWE
									   SET IMWE.UploadVal = @DiscBasis
									 WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
									   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
									   AND IMWE.Identifier = @DiscBasisID							
								END

							-- DiscRate --
							IF @ynDiscRate = 'Y'
								BEGIN
									
									-- SET RATE --									
									SELECT @DiscRate = CASE @TempMatlDisc
															WHEN 'N' THEN @TempDiscRateHQPT
															WHEN 'Y' THEN @TempPayDiscRate
															ELSE 0 END

									UPDATE IMWE
									   SET IMWE.UploadVal = @DiscRate
									 WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
									   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
									   AND IMWE.Identifier = @DiscRateID
								END

							-- DiscOff --
							IF @ynDiscOff = 'Y'
								BEGIN
				
									SET @DiscOff = ISNULL(@DiscRate, 0) * ISNULL(@DiscBasis, 0)

									UPDATE IMWE
									   SET IMWE.UploadVal = @DiscOff
									 WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
									   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
									   AND IMWE.Identifier = @DiscOffID
								END

							-- TaxDisc --
							IF @ynTaxDisc = 'Y'
								BEGIN
								
									SELECT @TempTaxDisc = DiscTax
									  FROM bARCO WITH (NOLOCK)
								     WHERE ARCo = @Co

									SET @TaxDisc = 0

									IF (@TaxCode IS NULL) OR (@TaxTotal = 0) SET @TaxDisc = 0
										ELSE IF @TempTaxDisc = 'Y' SET @TaxDisc = ISNULL(@DiscOff, 0) * ISNULL(@TempTaxRate, 0)


									UPDATE IMWE
									   SET IMWE.UploadVal = @TaxDisc
									 WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
									   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
									   AND IMWE.Identifier = @TaxDiscID	
								END

						END -- IF @SaleType = 'C'

					-- VendorGroup --
					IF @VendorGroupID <> 0 AND (@owVendorGroup = 'Y' OR @IsEmptyVendorGroup = 'Y')
						BEGIN			        
						   UPDATE IMWE
						      SET IMWE.UploadVal = @HeaderVendorGroup
						    WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							  AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq 
							  AND IMWE.Identifier = @VendorGroupID
						END

					------------------------------------
					-- KEEP HAUL AND REV INFO IN SYNC --
					------------------------------------
					IF (@HaulCode IS NOT NULL) AND (@RevCode IS NOT NULL)
						BEGIN

							SELECT @TempHaulBased = HaulBased
							  FROM bEMRC WITH (NOLOCK)
							 WHERE EMGroup = @HeaderEMGroup
							   AND RevCode = @RevCode


							IF @TempHaulBased = 'Y'
								BEGIN

									UPDATE IMWE
									   SET IMWE.UploadVal = @HaulRate
									 WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
									   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
									   AND IMWE.Identifier = @RevRateID	

									UPDATE IMWE
									   SET IMWE.UploadVal = @HaulBasis
									 WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
									   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
									   AND IMWE.Identifier = @RevBasisID	

									UPDATE IMWE
									   SET IMWE.UploadVal = @HaulTotal
									 WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
									   AND IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq
									   AND IMWE.Identifier = @RevTotalID	
								END
						END


					----------------
					-- CLEAR DATA -- 
					----------------
					-- ** ALL CLEARING OF DATA HAPPENS IN THE DETAIL/LINES DEFAULT PROCEDURE SINCE SP vspIMScrubData USED IN THE
					--		"FORMAT DATA" PORTION OF THE PROCESS COPIES IMPORTED VALUES OVER THE TOP OF NULL VALUES IN THE HEADER RECORD
					-- ** BE CAREFUL IF USING HEADER ID's IN WHERE CLAUSE - WILL CAUSE DETAIL INFORMATION TO BE INFORMATION TO BE NULL'ed OUT
					--		NULL OUT ALL DATA NOT ASSOCIATED WITH RECORD *EXCEPT* NOT NULL VALUES FOR THE TABLE

					-- CLEAR HEADER DATA --  ALREADY HAD SOME HEADER IDs, SO NOT ALL VARIABLES BELOW HAVE 'cd' IN ITS NAME
					IF @HeaderHaulerType = 'E'
						BEGIN
							UPDATE IMWE
							   SET IMWE.UploadVal = NULL
						     WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND
									 IMWE.RecordType = @HeaderRecType AND IMWE.RecordSeq = @curCurSeq AND
									(IMWE.Identifier = @HeaderHaulVendorID OR IMWE.Identifier = @HeaderTruckID OR 
									 IMWE.Identifier = @cdHeaderDriverID)
						END
					
					IF @HeaderHaulerType = 'H'
						BEGIN
							UPDATE IMWE
							   SET IMWE.UploadVal = NULL
						     WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND
									 IMWE.RecordType = @HeaderRecType AND IMWE.RecordSeq = @curCurSeq AND
									(IMWE.Identifier = @cdHeaderEMCoID OR IMWE.Identifier = @HeaderEquipmentID OR 
									 IMWE.Identifier = @cdHeaderPRCoID OR IMWE.Identifier = @cdHeaderEmployeeID) 
						END

					-- CLEAR DETAIL DATA --
                    IF @SaleType = 'J'
						BEGIN
							UPDATE IMWE
							   SET IMWE.UploadVal = NULL
						     WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND
									 IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq AND
									(IMWE.Identifier = @cdCustomerID OR IMWE.Identifier = @cdCustJobID OR IMWE.Identifier = @cdCustPOID OR
									 IMWE.Identifier = @cdPaymentTypeID OR IMWE.Identifier = @cdINCoID OR IMWE.Identifier = @cdToLocID OR 
									 IMWE.Identifier = @cdTaxDiscID OR IMWE.Identifier = @cdDiscOffID OR IMWE.Identifier = @cdDiscRateID OR 
									 IMWE.Identifier = @cdDiscBasisID)
						END

                    IF @SaleType = 'I'
						BEGIN
							UPDATE IMWE
							   SET IMWE.UploadVal = NULL
						     WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND
									 IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq AND
									(IMWE.Identifier = @cdCustomerID OR IMWE.Identifier = @cdCustJobID OR IMWE.Identifier = @cdCustPOID OR
									 IMWE.Identifier = @cdPaymentTypeID OR IMWE.Identifier = @cdJCCoID OR IMWE.Identifier = @cdJobID OR 
									 IMWE.Identifier = @cdHaulPhaseID OR IMWE.Identifier = @cdHaulJCCTypeID OR IMWE.Identifier = @cdTaxDiscID OR 
									 IMWE.Identifier = @cdDiscOffID OR IMWE.Identifier = @cdDiscRateID OR IMWE.Identifier = @cdDiscBasisID)
						END

                    IF @SaleType = 'C'
						BEGIN
							UPDATE IMWE
							   SET IMWE.UploadVal = NULL
						     WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND
									 IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq AND
									(IMWE.Identifier = @cdJCCoID OR IMWE.Identifier = @cdJobID OR IMWE.Identifier = @cdHaulPhaseID OR
									 IMWE.Identifier = @cdHaulJCCTypeID OR IMWE.Identifier = @cdINCoID OR IMWE.Identifier = @cdToLocID)
						END

					IF @PaymentType IN ('A', 'X')
							UPDATE IMWE
							   SET IMWE.UploadVal = NULL
						     WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND
									 IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq AND
									 (IMWE.Identifier = @cdCheckNoID)

					IF @HeaderHaulerType = 'E'
						BEGIN
							UPDATE IMWE
							   SET IMWE.UploadVal = NULL
						     WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND
									 IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq AND
									(IMWE.Identifier = @cdPayCodeID OR IMWE.Identifier = @cdPayBasisID OR IMWE.Identifier = @cdPayRateID OR 
									 IMWE.Identifier = @cdPayTotalID)
						END
      
					IF @HeaderHaulerType = 'H'
						BEGIN
							UPDATE IMWE
							   SET IMWE.UploadVal = NULL
						     WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND
									 IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq AND
									(IMWE.Identifier = @cdRevCodeID OR IMWE.Identifier = @cdRevBasisID OR IMWE.Identifier = @cdRevRateID OR 
									 IMWE.Identifier = @cdRevTotalID)
						END

                   IF @HaulCode IS NULL
						BEGIN
							UPDATE IMWE
							   SET IMWE.UploadVal = NULL
						     WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND
									 IMWE.RecordType = @rectype AND IMWE.RecordSeq = @curCurSeq AND
                 					(IMWE.Identifier = @cdHaulBasisID OR IMWE.Identifier = @cdHaulRateID OR IMWE.Identifier = @cdHaulTotalID OR
                 					 IMWE.Identifier = @cdHaulPhaseID OR IMWE.Identifier = @cdHaulJCCTypeID)
						END

				
					---------------------------------------
					-- RESET HEADER AND DETAIL VARIABLES --
					---------------------------------------
					-- Header Variables --
					SELECT
						@HeaderSaleDate		= NULL, @HeaderHaulerType	= NULL, @HeaderEMCo			= NULL,	
						@HeaderEMGroup		= NULL, @HeaderEquipment	= NULL, @HeaderVendorGroup	= NULL,		
						@HeaderHaulVendor	= NULL,	@HeaderTruck		= NULL, @HeaderEquipCat		= NULL	    

					-- Detail Variables -- ** DO NOT NULL FIELDS THAT REQUIRE A VALUE IN THE UPLOAD TABLE
					SELECT	
						@Co				= NULL, @Mth			= NULL, @BatchId		= NULL, @BatchSeq		= NULL, 
						@HaulLine		= NULL, @BatchTransType	= NULL, @FromLoc		= NULL, @Material		= NULL, 
						@MatlVendor		= NULL, @MatlGroup		= NULL, @UM				= NULL, @SaleType		= NULL, 
						@CustGroup		= NULL, @Customer 		= NULL, @CustJob		= NULL, @CustPO 		= NULL, 
						@PaymentType	= NULL, @CheckNo		= NULL, @Hold			= NULL, @JCCo			= NULL, 
						@Job			= NULL, @PhaseGroup		= NULL, @HaulPhase		= NULL, @HaulJCCType	= NULL, 
						@INCo			= NULL, @ToLoc			= NULL, @TruckType		= NULL, @StartTime		= NULL, 
						@StopTime 		= NULL, @Loads			= NULL, @Miles 			= NULL, @Hours			= NULL,
						@Zone 			= NULL, @HaulCode 		= NULL, @HaulBasis		= NULL, @HaulRate		= NULL, 
						@HaulTotal		= NULL, @RevCode 		= NULL, @RevBasis		= NULL, @RevRate		= NULL, 
						@RevTotal		= NULL, @PayCode		= NULL, @PayBasis		= NULL, @PayRate		= NULL, 
						@PayTotal		= NULL, @TaxGroup		= NULL, @TaxType 		= NULL, @TaxCode		= NULL, 
						@TaxBasis		= NULL, @TaxTotal		= NULL, @DiscBasis		= NULL, @DiscRate 		= NULL,
						@DiscOff		= NULL, @TaxDisc 		= NULL, @VendorGroup	= NULL, @MSTrans		= NULL


					-- SET CURRENT SEQUENCE --
					SET @curCurSeq = @curRecSeq

					-- FLAG STOP LOOP --
					IF @@FETCH_STATUS <> 0 SET @ImportCompleted = 'Y'

				END	--IF @curRecSeq = @curCurSeq	

		END --Cursor Loop


	-- CLEAN UP CURSOR --
	CLOSE curWorkEdit
	DEALLOCATE curWorkEdit
	SET @curOpen = 0
    

	-- GIVE VALUES TO NULL VARIABLES --
    UPDATE IMWE
       SET IMWE.UploadVal = 0
     WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND
			 IMWE.RecordType = @rectype AND IMWE.UploadVal IS NULL AND
			(IMWE.Identifier = @cdTaxDiscID OR IMWE.Identifier = @cdTaxDiscID OR IMWE.Identifier = @cdDiscOffID OR 
			 IMWE.Identifier = @cdDiscRateID OR IMWE.Identifier = @cdDiscBasisID OR IMWE.Identifier = @cdTaxTotalID OR 
			 IMWE.Identifier = @cdTaxBasisID OR IMWE.Identifier = @cdRevTotalID OR IMWE.Identifier = @cdRevRateID OR 
			 IMWE.Identifier = @cdRevBasisID OR IMWE.Identifier = @cdPayTotalID OR IMWE.Identifier = @cdPayRateID OR 
			 IMWE.Identifier = @cdPayBasisID OR IMWE.Identifier = @cdHaulTotalID OR IMWE.Identifier = @cdHaulRateID OR 
			 IMWE.Identifier = @cdHaulBasisID OR IMWE.Identifier = @cdHoursID OR IMWE.Identifier = @cdMilesID OR 
			 IMWE.Identifier = @cdLoadsID)

	UPDATE IMWE
       SET IMWE.UploadVal = 'N'
     WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
			AND IMWE.RecordType = @rectype AND ISNULL(IMWE.UploadVal,'') not in ('N','Y') AND
			(IMWE.Identifier = @cdHoldID)

--------------------
-- ERROR HANDLING --
--------------------
vspExit:
	
	-- CLEAN UP CURSOR --
	IF @curOpen = 1
		BEGIN
			CLOSE curWorkEdit
			DEALLOCATE curWorkEdit
		END

	-- SET ERROR MESSAGE AND RETURN --
    SET @msg = ISNULL(@desc, 'Lines ') + char(13) + char(13) + '[vspIMViewpointDefaultsMSLB]'

    RETURN @rcode



GO
GRANT EXECUTE ON  [dbo].[vspIMViewpointDefaultsMSLB] TO [public]
GO
