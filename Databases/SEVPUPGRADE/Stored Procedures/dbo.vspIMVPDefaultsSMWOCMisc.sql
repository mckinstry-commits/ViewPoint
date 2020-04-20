SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspIMVPDefaultsSMWOCMisc]

   /***********************************************************
    * CREATED BY:   Jim Emery  11/27/2012 TK-19175
    *
    * Usage:
    *	Used BY Imports to create values for needed or missing
    *      data based upon Viewpoint default rules.
    *
    * Input params:
    *	@ImportId	 Import Identifier
    *	@ImportTemplate	 Import Template
    *
    * Output params:
    *	@msg		error message
    *
    * RETURN code:
    *	0 = success, 1 = failure
    ************************************************************/
/*
USE AgreementRates ONLY IF Coverage IS 'T'
IF Coverage='A' THEN USE PROCEDURE TO calculate Billable

ADD the 'No Charge Field' TO this ; DEFAULT NO Charge TO 'N'
IF UseDefaulT Rate='Y' the calculate totals??
Provisional - need more notes what this does

*/    
   
	(   @Company bCompany, @ImportId varchar(20), @ImportTemplate varchar(20), 
   		@Form varchar(20), @rectype varchar(30), @msg varchar(60) output
    )
    WITH Recompile
	AS
   
    SET NOCOUNT ON;
   
    DECLARE @rcode        int;
    DECLARE @desc         varchar(60);
    DECLARE @status       int;
    DECLARE @defaultvalue varchar(30);
    DECLARE @rc			  INT;
	DECLARE @varSMCostType smallint
 
  
IF @ImportId IS NULL
    BEGIN
	SELECT @desc = 'Missing ImportId.', @rcode = 1;
	GOTO vspexit;
	END;
IF @ImportTemplate IS NULL
	BEGIN
	SELECT @desc = 'Missing ImportTemplate.', @rcode = 1;
	GOTO vspexit;
	END;
IF @Form IS NULL
	BEGIN
	SELECT @desc = 'Missing Form.', @rcode = 1;
	GOTO vspexit;
	END;

/* Working Variables */
    DECLARE @SMCo                bCompany;
    DECLARE @WorkOrder           int;
    DECLARE @WorkCompleted       int;
    DECLARE @Scope               int;
    DECLARE @ServiceSite         varchar(20);
    DECLARE @Status              varchar(11);
    DECLARE @Type                tinyint;
    DECLARE @OriginalType        tinyint;    
    DECLARE @PRCo                bCompany;
    DECLARE @Technician          varchar(15);
    DECLARE @Date                bDate;
    DECLARE @MonthToPostCost     bMonth;
    DECLARE @Agreement           varchar(15);
    DECLARE @Revision            int;
    DECLARE @Coverage            char(10);
    DECLARE @ReferenceNo         varchar(60);
    DECLARE @StandardItem        varchar(20);
    DECLARE @Description         varchar(60);
    DECLARE @ServiceItem         varchar(20);
    DECLARE @SMCostType          smallint;
    DECLARE @PhaseGroup          bGroup;
    DECLARE @JCCo                bCompany;
    DECLARE @JCCostType          bJCCType;
    DECLARE @GLCo                bCompany;
    DECLARE @CostAccount         bGLAcct;
    DECLARE @RevenueAccount      bGLAcct;
    DECLARE @CostWIPAccount      bGLAcct;
    DECLARE @RevenueWIPAccount   bGLAcct;
    DECLARE @CostQuantity        bUnits;
    DECLARE @CostRate            bUnitCost;
    DECLARE @CostTotal           bDollar;
    DECLARE @PriceQuantity       bUnits;
    DECLARE @PriceRate           bUnitCost;
    DECLARE @PriceTotal          bDollar;
    DECLARE @TaxType             tinyint;
    DECLARE @TaxGroup            bGroup;
    DECLARE @TaxCode             bTaxCode;
    DECLARE @TaxBasis            bDollar;
    DECLARE @TaxAmount           bDollar;
    DECLARE @NoCharge            bYN;
    DECLARE @NonBillable		         bYN;
    DECLARE @ActualCost          bDollar;
    DECLARE @ActualUnits         bUnits;
    DECLARE @SMInvoiceID         bigint;

	DECLARE @RateSource			INT;
	DECLARE @RateTemplate		VARCHAR(10);
	DECLARE @RateTemplateSource INT; 

	DECLARE @MaxWorkCompleted        int;
	DECLARE @MaxIMWorkCompleted      int;
    DECLARE @defaultSMCostType       smallint;
    DECLARE @defaultCostRate         bUnitCost;
    DECLARE @defaultTechnician       varchar(15);   
    DECLARE @defaultPRCo             bCompany ;   
    DECLARE @defaultRate             bUnitCost;
    DECLARE @defaultCostAccount      bGLAcct;   
    DECLARE @defaultRevenueAccount   bGLAcct;   
    DECLARE @defaultCostWIPAccount   bGLAcct;  
    DECLARE @defaultRevWIPAccount    bGLAcct;  
    DECLARE @defaultTaxType          int;   
    DECLARE @defaultTaxCode          bTaxCode; 
    DECLARE @defaultTaxable          bYN;   
    DECLARE @defaultServiceSite      varchar(20);   
    DECLARE @defaultSMGLCo           bCompany;   
    DECLARE @defaultIsTrackingWIP    bYN;  
    DECLARE @defaultIsScopeCompleted bYN;
    DECLARE @defaultJCCo             bCompany;   
    DECLARE @defaultJob              bJob;  
    DECLARE @defaultJCCostType       bJCCType; 
    DECLARE @defaultPhase            bPhase;  
    DECLARE @defaultPhaseGroup       bGroup;  
    DECLARE @defaultAgreement        varchar(15);  
    DECLARE @defaultRevision         int;  
    DECLARE @defaultCoverage         char(1);  
    DECLARE @defaultIsAgreement      bYN;  
    DECLARE @defaultProvisional      bit; 
    DECLARE @defaultTaxRate          bRate;

/* Cursor variables */
    DECLARE @Recseq        int; 
    DECLARE @Tablename     varchar(20);
    DECLARE @Column        varchar(30);
    DECLARE @Uploadval     varchar(60);
    DECLARE @Ident         int;
    DECLARE @valuelist     varchar(255);
    DECLARE @complete      int;
    DECLARE @counter       int;
    DECLARE @oldrecseq     int;
    DECLARE @currrecseq    int;
 
--Identifiers
    DECLARE @SMCoID                int;
    DECLARE @WorkOrderID           int;
    DECLARE @WorkCompletedID       int;
    DECLARE @ScopeID               int;
    DECLARE @ServiceSiteID         int;
    DECLARE @StatusID              int;
    DECLARE @TypeID                int;
    DECLARE @PRCoID                int;
    DECLARE @TechnicianID          int;
    DECLARE @DateID                int;
    DECLARE @MonthToPostCostID     int;
    DECLARE @AgreementID           int;
    DECLARE @RevisionID            int;
    DECLARE @CoverageID            int;
    DECLARE @ReferenceNoID         int;
    DECLARE @StandardItemID        int;
    DECLARE @DescriptionID         int;
    DECLARE @ServiceItemID         int;
    DECLARE @SMCostTypeID          int;
    DECLARE @SourceID              int;
    DECLARE @PhaseGroupID          int;
    DECLARE @JCCoID                int;
    DECLARE @JCCostTypeID          int;
    DECLARE @GLCoID                int;
    DECLARE @CostAccountID         int;
    DECLARE @RevenueAccountID      int;
    DECLARE @CostWIPAccountID      int;
    DECLARE @RevenueWIPAccountID   int;
    DECLARE @CostQuantityID        int;
    DECLARE @CostRateID            int;
    DECLARE @CostTotalID           int;
    DECLARE @PriceQuantityID       int;
    DECLARE @PriceRateID           int;
    DECLARE @PriceTotalID          int;
    DECLARE @TaxTypeID             int;
    DECLARE @TaxGroupID            int;
    DECLARE @TaxCodeID             int;
    DECLARE @TaxBasisID            int;
    DECLARE @TaxAmountID           int;
    DECLARE @NoChargeID            int;
    DECLARE @NonBillableID              int;    
	DECLARE @ActualCostID          int;
	DECLARE @ActualUnitsID         int;
	DECLARE @SMInvoiceIDID         int;	
	 
 
 
/* Empty flags */ 
    DECLARE @IsEmptySMCo                bYN;
    DECLARE @IsEmptyWorkOrder           bYN;
    DECLARE @IsEmptyWorkCompleted       bYN;
    DECLARE @IsEmptyScope               bYN;
    DECLARE @IsEmptyServiceSite         bYN;
    DECLARE @IsEmptyStatus              bYN;
    DECLARE @IsEmptyType                bYN;
    DECLARE @IsEmptyPRCo                bYN;
    DECLARE @IsEmptyTechnician          bYN;
    DECLARE @IsEmptyDate                bYN;
    DECLARE @IsEmptyMonthToPostCost     bYN;
    DECLARE @IsEmptyAgreement           bYN;
    DECLARE @IsEmptyRevision            bYN;
    DECLARE @IsEmptyCoverage            bYN;
    DECLARE @IsEmptyReferenceNo         bYN;
    DECLARE @IsEmptyStandardItem        bYN;
    DECLARE @IsEmptyDescription         bYN;
    DECLARE @IsEmptyServiceItem         bYN;
    DECLARE @IsEmptySMCostType          bYN;
    DECLARE @IsEmptySource              bYN;
    DECLARE @IsEmptyPhaseGroup          bYN;
    DECLARE @IsEmptyJCCo                bYN;
    DECLARE @IsEmptyJCCostType          bYN;
    DECLARE @IsEmptyGLCo                bYN;
    DECLARE @IsEmptyCostAccount         bYN;
    DECLARE @IsEmptyRevenueAccount      bYN;
    DECLARE @IsEmptyCostWIPAccount      bYN;
    DECLARE @IsEmptyRevenueWIPAccount   bYN;
    DECLARE @IsEmptyQuantity            bYN;
    DECLARE @IsEmptyCostQuantity        bYN;
    DECLARE @IsEmptyCostRate            bYN;
    DECLARE @IsEmptyCostTotal           bYN;
    DECLARE @IsEmptyPriceQuantity       bYN;
    DECLARE @IsEmptyPriceRate           bYN;
    DECLARE @IsEmptyPriceTotal          bYN;
    DECLARE @IsEmptyTaxType             bYN;
    DECLARE @IsEmptyTaxGroup            bYN;
    DECLARE @IsEmptyTaxCode             bYN;
    DECLARE @IsEmptyTaxBasis            bYN;
    DECLARE @IsEmptyTaxAmount           bYN;
    DECLARE @IsEmptyNoCharge            bYN;
    DECLARE @IsEmptyNonBillable              bYN;
    DECLARE @IsEmptyActualCost          bYN;
    DECLARE @IsEmptyActualUnits         bYN;
    DECLARE @IsEmptySMInvoiceID         bYN;    
   
 
/* Overwrite flags */ 
    DECLARE @OverwriteSMCo                     bYN;
    DECLARE @OverwriteWorkOrder                bYN;
    DECLARE @OverwriteWorkCompleted            bYN;
    DECLARE @OverwriteScope                    bYN;
    DECLARE @OverwriteServiceSite              bYN;
    DECLARE @OverwriteStatus                   bYN;
    DECLARE @OverwriteType                     bYN;
    DECLARE @OverwritePRCo                     bYN;
    DECLARE @OverwriteTechnician               bYN;
    DECLARE @OverwriteDate                     bYN;
    DECLARE @OverwriteMonthToPostCost          bYN;
    DECLARE @OverwriteAgreement                bYN;
    DECLARE @OverwriteRevision                 bYN;
    DECLARE @OverwriteCoverage                 bYN;
    DECLARE @OverwriteReferenceNo              bYN;
    DECLARE @OverwriteStandardItem             bYN;
    DECLARE @OverwriteDescription              bYN;
    DECLARE @OverwriteServiceItem              bYN;
    DECLARE @OverwriteSMCostType               bYN;
    DECLARE @OverwriteSource                   bYN;
    DECLARE @OverwritePhaseGroup               bYN;
    DECLARE @OverwriteJCCo                     bYN;
    DECLARE @OverwriteJCCostType               bYN;
    DECLARE @OverwriteGLCo                     bYN;
    DECLARE @OverwriteCostAccount              bYN;
    DECLARE @OverwriteRevenueAccount           bYN;
    DECLARE @OverwriteCostWIPAccount           bYN;
    DECLARE @OverwriteRevenueWIPAccount        bYN;
    DECLARE @OverwriteQuantity                 bYN;
    DECLARE @OverwriteCostQuantity             bYN;
    DECLARE @OverwriteCostRate                 bYN;
    DECLARE @OverwriteCostTotal                bYN;
    DECLARE @OverwritePriceQuantity            bYN;
    DECLARE @OverwritePriceRate                bYN;
    DECLARE @OverwritePriceTotal               bYN;
    DECLARE @OverwriteTaxType                  bYN;
    DECLARE @OverwriteTaxGroup                 bYN;
    DECLARE @OverwriteTaxCode                  bYN;
    DECLARE @OverwriteTaxBasis                 bYN;
    DECLARE @OverwriteTaxAmount                bYN;
    DECLARE @OverwriteNoCharge                 bYN;
    DECLARE @OverwriteNonBillable                   bYN;    
    DECLARE @OverwriteActualCost               bYN;
    DECLARE @OverwriteActualUnits              bYN;
	DECLARE @OverwriteSMInvoiceID			   bYN;
;
/* Set Overwrite flags */ 
    SELECT @OverwriteSMCo =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SMCo', @rectype);
    SELECT @OverwriteWorkOrder =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'WorkOrder', @rectype);
    SELECT @OverwriteWorkCompleted =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'WorkCompleted', @rectype);
    SELECT @OverwriteScope =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Scope', @rectype);
    SELECT @OverwriteServiceSite =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ServiceSite', @rectype);
    SELECT @OverwriteStatus =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Status', @rectype);
    SELECT @OverwriteType =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Type', @rectype);
    SELECT @OverwritePRCo =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PRCo', @rectype);
    SELECT @OverwriteTechnician =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Technician', @rectype);
    SELECT @OverwriteDate =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Date', @rectype);
    SELECT @OverwriteMonthToPostCost =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MonthToPostCost', @rectype);
    SELECT @OverwriteAgreement =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Agreement', @rectype);
    SELECT @OverwriteRevision =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Revision', @rectype);
    SELECT @OverwriteCoverage =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Coverage', @rectype);
    SELECT @OverwriteReferenceNo =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ReferenceNo', @rectype);
    SELECT @OverwriteStandardItem =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'StandardItem', @rectype);
    SELECT @OverwriteDescription =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Description', @rectype);
    SELECT @OverwriteServiceItem =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ServiceItem', @rectype);
    SELECT @OverwriteSMCostType =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SMCostType', @rectype);
    SELECT @OverwritePhaseGroup =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PhaseGroup', @rectype);
    SELECT @OverwriteJCCo =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JCCo', @rectype);
    SELECT @OverwriteJCCostType =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JCCostType', @rectype);
    SELECT @OverwriteGLCo =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLCo', @rectype);
    SELECT @OverwriteCostAccount =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CostAccount', @rectype);
    SELECT @OverwriteRevenueAccount =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RevenueAccount', @rectype);
    SELECT @OverwriteCostWIPAccount =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CostWIPAccount', @rectype);
    SELECT @OverwriteRevenueWIPAccount =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RevenueWIPAccount', @rectype);
    SELECT @OverwriteQuantity =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Quantity', @rectype);
    SELECT @OverwriteCostQuantity =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CostQuantity', @rectype);
    SELECT @OverwriteCostRate =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CostRate', @rectype);
    SELECT @OverwriteCostTotal =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CostTotal', @rectype);
    SELECT @OverwritePriceQuantity =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PriceQuantity', @rectype);
    SELECT @OverwritePriceRate =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PriceRate', @rectype);
    SELECT @OverwritePriceTotal =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PriceTotal', @rectype);
    SELECT @OverwriteTaxType =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxType', @rectype);
    SELECT @OverwriteTaxGroup =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxGroup', @rectype);
    SELECT @OverwriteTaxCode =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxCode', @rectype);
    SELECT @OverwriteTaxBasis =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxBasis', @rectype);
    SELECT @OverwriteTaxAmount =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxAmount', @rectype);
    SELECT @OverwriteNoCharge =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'NoCharge', @rectype);
	SELECT @OverwriteNonBillable =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'NonBillable', @rectype);        
    SELECT @OverwriteActualCost =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ActualCost', @rectype);
    SELECT @OverwriteActualUnits =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ActualUnits', @rectype);
    SELECT @OverwriteActualUnits =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SMInvoiceID', @rectype);  

 
/***** GET COLUMN IDENTIFIERS -  YN field: 
  Y means ONLY when [Use Viewpoint Default] IS set.
  N means RETURN Identifier regardless of [Use Viewpoint Default] IS set 
*******/ 
    SELECT @SMCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SMCo', @rectype, 'N');
    SELECT @WorkOrderID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'WorkOrder', @rectype, 'N');
    SELECT @WorkCompletedID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'WorkCompleted', @rectype, 'N');
    SELECT @ScopeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Scope', @rectype, 'N');
    SELECT @ServiceSiteID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ServiceSite', @rectype, 'N');
    SELECT @StatusID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Status', @rectype, 'N');
    SELECT @TypeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Type', @rectype, 'N');
    SELECT @PRCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PRCo', @rectype, 'N');
    SELECT @TechnicianID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Technician', @rectype, 'N');
    SELECT @DateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Date', @rectype, 'N');
    SELECT @MonthToPostCostID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MonthToPostCost', @rectype, 'N');
    SELECT @AgreementID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Agreement', @rectype, 'N');
    SELECT @RevisionID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Revision', @rectype, 'N');
    SELECT @CoverageID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Coverage', @rectype, 'N');
    SELECT @ReferenceNoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ReferenceNo', @rectype, 'N');
    SELECT @StandardItemID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'StandardItem', @rectype, 'N');
    SELECT @DescriptionID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Description', @rectype, 'N');
    SELECT @ServiceItemID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ServiceItem', @rectype, 'N');
    SELECT @SMCostTypeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SMCostType', @rectype, 'N');
    SELECT @PhaseGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PhaseGroup', @rectype, 'N');
    SELECT @JCCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'JCCo', @rectype, 'N');
    SELECT @JCCostTypeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'JCCostType', @rectype, 'N');
    SELECT @GLCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'GLCo', @rectype, 'N');
    SELECT @CostAccountID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CostAccount', @rectype, 'N');
    SELECT @RevenueAccountID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RevenueAccount', @rectype, 'N');
    SELECT @CostWIPAccountID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CostWIPAccount', @rectype, 'N');
    SELECT @RevenueWIPAccountID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RevenueWIPAccount', @rectype, 'N');
    SELECT @CostQuantityID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CostQuantity', @rectype, 'N');
    SELECT @CostRateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CostRate', @rectype, 'N');
    SELECT @CostTotalID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CostTotal', @rectype, 'N');
    SELECT @PriceQuantityID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PriceQuantity', @rectype, 'N');
    SELECT @PriceRateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PriceRate', @rectype, 'N');
    SELECT @PriceTotalID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PriceTotal', @rectype, 'N');
    SELECT @TaxTypeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxType', @rectype, 'N');
    SELECT @TaxGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxGroup', @rectype, 'N');
    SELECT @TaxCodeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxCode', @rectype, 'N');
    SELECT @TaxBasisID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxBasis', @rectype, 'N');
    SELECT @TaxAmountID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxAmount', @rectype, 'N');
    SELECT @NoChargeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'NoCharge', @rectype, 'N');
    SELECT @NonBillableID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'NonBillable', @rectype, 'N');    
    SELECT @ActualCostID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ActualCost', @rectype, 'N');
    SELECT @ActualUnitsID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ActualUnits', @rectype, 'N');
    SELECT @SMInvoiceIDID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SMInvoiceID', @rectype, 'N');
 

/* Columns that can be updated to ALL imported records as a set.
   The value IS NOT unique to the individual imported record. */
 

/********** SMCo ****** Required ******/
    IF ISNULL(@SMCoID,0)<>0 
	    BEGIN
	    UPDATE IMWE
	    SET IMWE.UploadVal = @Company
	    FROM IMWE
		    WHERE IMWE.ImportTemplate=@ImportTemplate 
			AND IMWE.ImportId=@ImportId 
			AND IMWE.Identifier = @SMCoID 
			AND IMWE.RecordType = @rectype
			AND ( ISNULL(@OverwriteSMCo, 'Y') = 'Y'
				  OR (ISNULL(@OverwriteSMCo, 'Y') = 'N' and IMWE.UploadVal IS NULL))
			;
  	    END;

/********** Validate SMCo  ******* Required ******/  
    IF ISNULL(@SMCoID,0)<>0  
	    BEGIN
            UPDATE dbo.IMWE
            SET IMWE.UploadVal = '** Invalid - must be numeric'
            FROM dbo.IMWE
            WHERE IMWE.ImportTemplate=@ImportTemplate 
                AND IMWE.ImportId=@ImportId 
                AND IMWE.RecordType = @rectype
                AND IMWE.Identifier = @SMCoID
                AND ISNUMERIC(dbo.IMWE.UploadVal)=0 ;
                			
            UPDATE dbo.IMWE
            SET IMWE.UploadVal = '** Invalid - SMCO does not exist'
            FROM dbo.IMWE
            WHERE IMWE.ImportTemplate=@ImportTemplate 
                AND IMWE.ImportId=@ImportId 
                AND IMWE.RecordType = @rectype
                AND IMWE.Identifier = @SMCoID
                 AND ISNUMERIC(dbo.IMWE.UploadVal)=1
                AND NOT EXISTS (select SMCo from dbo.vSMCO
                                WHERE vSMCO.SMCo = IMWE.UploadVal);
            
            IF EXISTS (
				SELECT UploadVal FROM  dbo.IMWE
				WHERE IMWE.ImportTemplate=@ImportTemplate 
                AND IMWE.ImportId=@ImportId 
                AND IMWE.RecordType = @rectype
                AND IMWE.Identifier = @SMCoID
                AND (ISNUMERIC(dbo.IMWE.UploadVal)=0 OR UploadVal IS null)
                )
            GOTO vspexit ;          
        END;

/********** Type ****** Required ******/
    IF ISNULL(@TypeID,0)<>0  
	    BEGIN
	    UPDATE IMWE
	    SET IMWE.UploadVal = '3'  --- miscellaneous is type 3
	    FROM IMWE
	    WHERE IMWE.ImportTemplate=@ImportTemplate 
			AND IMWE.ImportId=@ImportId 
			AND IMWE.Identifier = @TypeID 
			AND IMWE.RecordType = @rectype
			AND ( ISNULL(@OverwriteType, 'Y') = 'Y'
				  OR (ISNULL(@OverwriteType, 'Y') = 'N' and IMWE.UploadVal IS NULL))
			;
  	    END;

/********** Validate Type  ******* Required ******/  
    IF ISNULL(@TypeID,0)<>0
	    BEGIN
            UPDATE dbo.IMWE
            SET IMWE.UploadVal = '** Invalid - must be 3'
            FROM dbo.IMWE
			WHERE IMWE.ImportTemplate=@ImportTemplate 
                AND IMWE.ImportId=@ImportId 
                AND IMWE.RecordType = @rectype
                AND IMWE.Identifier = @TypeID
                AND ISNULL(IMWE.UploadVal,'')<>'3';
        END;

/********** Date ************/
    IF ISNULL(@DateID,0)<>0
        AND (ISNULL(@OverwriteDate, 'Y') = 'Y' 
             OR ISNULL(@IsEmptyDate, 'Y') = 'Y')
        BEGIN
            SELECT @Date = convert (VARCHAR(10),GETDATE(),101)
            UPDATE IMWE
                SET IMWE.UploadVal = @Date
                WHERE IMWE.ImportTemplate=@ImportTemplate 
                    AND IMWE.ImportId=@ImportId 
                    AND IMWE.RecordType = @rectype
                    AND IMWE.Identifier = @DateID
                    AND ( ISNULL(@OverwriteDate, 'Y') = 'Y'
						OR (ISNULL(@OverwriteDate, 'Y') = 'N' and IMWE.UploadVal IS NULL));
        END;
      
/********** NoCharge ************/
    IF ISNULL(@NoChargeID,0)<>0
        AND (ISNULL(@OverwriteNoCharge, 'Y') = 'Y' 
             OR ISNULL(@IsEmptyNoCharge, 'Y') = 'Y')
        BEGIN
            UPDATE IMWE
                SET IMWE.UploadVal = 'N'
                WHERE IMWE.ImportTemplate=@ImportTemplate 
                    AND IMWE.ImportId=@ImportId 
                    AND IMWE.RecordType = @rectype
                    AND IMWE.Identifier = @NoChargeID
                    AND ( ISNULL(@OverwriteNoCharge, 'Y') = 'Y'
						OR (ISNULL(@OverwriteNoCharge, 'Y') = 'N' and IMWE.UploadVal IS NULL));
        END;        

/********** NonBillable ************/
    IF ISNULL(@NonBillableID,0)<>0
        AND (ISNULL(@OverwriteNonBillable, 'Y') = 'Y' 
             OR ISNULL(@IsEmptyNonBillable, 'Y') = 'Y')
        BEGIN
            UPDATE IMWE
                SET IMWE.UploadVal = 'N'
                WHERE IMWE.ImportTemplate=@ImportTemplate 
                    AND IMWE.ImportId=@ImportId 
                    AND IMWE.RecordType = @rectype
                    AND IMWE.Identifier = @NonBillableID
                    AND ( ISNULL(@OverwriteNonBillable, 'Y') = 'Y'
						OR (ISNULL(@OverwriteNonBillable, 'Y') = 'N' and IMWE.UploadVal IS NULL));
        END;
        
        
/********** TaxGroup ************/
-- default from HQCO
    IF ISNULL(@TaxGroupID,0)<>0
	    BEGIN
	    UPDATE IMWE
	    SET IMWE.UploadVal = dbo.bHQCO.TaxGroup
	    FROM IMWE
	    JOIN (select SMCo=UploadVal, SMCORecSeq=RecordSeq
				from dbo.IMWE
				where IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @SMCoID) as SMCO
              on SMCO.SMCORecSeq=IMWE.RecordSeq
		JOIN bHQCO on bHQCO.HQCo=SMCO.SMCo
	    WHERE IMWE.ImportTemplate=@ImportTemplate 
			AND IMWE.ImportId=@ImportId 
			AND IMWE.Identifier = @TaxGroupID 
			AND IMWE.RecordType = @rectype
			AND ( ISNULL(@OverwriteTaxGroup, 'Y') = 'Y'
				  OR (ISNULL(@OverwriteTaxGroup, 'Y') = 'N' and IMWE.UploadVal IS NULL))
			;
  	    END;

/********** Validate TaxGroup  *************/  
-- validate with Tax Code


 
/********* Begin default process. *******
 Multiple cursor records make up a single Import record
 determined BY a change in the RecSeq value.
 New RecSeq signals the beginning of the NEXT Import record. 
*/

DECLARE WorkEditCursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
    FROM IMWE WITH (nolock)
    INNER JOIN DDUD WITH (nolock) on IMWE.Identifier = DDUD.Identifier AND DDUD.Form = IMWE.Form
    WHERE IMWE.ImportId = @ImportId AND IMWE.ImportTemplate = @ImportTemplate 
	    AND IMWE.Form = @Form AND IMWE.RecordType = @rectype
    ORDER BY IMWE.RecordSeq, IMWE.Identifier;
    
OPEN WorkEditCursor;

FETCH NEXT FROM WorkEditCursor INTO @Recseq, @Ident, @Tablename, @Column, @Uploadval;
    
SELECT @currrecseq = @Recseq, @complete = 0, @counter = 1;

-- WHILE cursor IS not empty
WHILE @complete = 0
    BEGIN
    
	IF @@fetch_status <> 0 SELECT @Recseq = -1;

	IF @Recseq = @currrecseq	--Moves on to defaulting process when the first record of a DIFFERENT import RecordSeq IS detected
        BEGIN
		/***** GET UPLOADED VALUES FOR THIS IMPORT RECORD ********/
		/* For each imported record:  (Each imported record has multiple records
		   in the IMWE table representing columns of the import record)
	       Cursor will cycle through each column of an imported record 
		   AND set the imported value INTO a variable that could be used 
		   during the defaulting process later IF desired.  
		   
		   The imported value here IS only needed IF the value will be 
		   used to help determine another default value in some way. */
 	   
        IF @Column='SMCo' AND ISNUMERIC(@Uploadval)=1 SELECT @SMCo=CONVERT(tinyint, @Uploadval);
        IF @Column='WorkOrder' AND ISNUMERIC(@Uploadval)=1 SELECT @WorkOrder=CONVERT(int, @Uploadval);
        IF @Column='WorkCompleted' AND ISNUMERIC(@Uploadval)=1 SELECT @WorkCompleted=CONVERT(int, @Uploadval);
        IF @Column='Scope' AND ISNUMERIC(@Uploadval)=1 SELECT @Scope=CONVERT(int, @Uploadval);
        IF @Column='Type' AND ISNUMERIC(@Uploadval)=1 SELECT @Type=CONVERT(tinyint, @Uploadval);
        IF @Column='PRCo' AND ISNUMERIC(@Uploadval)=1 SELECT @PRCo=CONVERT(tinyint, @Uploadval);
        IF @Column='Revision' AND ISNUMERIC(@Uploadval)=1 SELECT @Revision=CONVERT(int, @Uploadval);
        IF @Column='SMCostType' AND ISNUMERIC(@Uploadval)=1 SELECT @SMCostType=CONVERT(smallint, @Uploadval);
        IF @Column='PhaseGroup' AND ISNUMERIC(@Uploadval)=1 SELECT @PhaseGroup=CONVERT(tinyint, @Uploadval);
        IF @Column='JCCo' AND ISNUMERIC(@Uploadval)=1 SELECT @JCCo=CONVERT(tinyint, @Uploadval);
        IF @Column='JCCostType' AND ISNUMERIC(@Uploadval)=1 SELECT @JCCostType=CONVERT(tinyint, @Uploadval);
        IF @Column='GLCo' AND ISNUMERIC(@Uploadval)=1 SELECT @GLCo=CONVERT(tinyint, @Uploadval);
        IF @Column='CostQuantity' AND ISNUMERIC(@Uploadval)=1 SELECT @CostQuantity=CONVERT(NUMERIC(12,3), @Uploadval);
        IF @Column='CostRate' AND ISNUMERIC(@Uploadval)=1 SELECT @CostRate=CONVERT(NUMERIC(16,5), @Uploadval);
        IF @Column='CostTotal' AND ISNUMERIC(@Uploadval)=1 SELECT @CostTotal=CONVERT(NUMERIC(12,2), @Uploadval);
        IF @Column='PriceQuantity' AND ISNUMERIC(@Uploadval)=1 SELECT @PriceQuantity=CONVERT(NUMERIC(12,3), @Uploadval);
        IF @Column='PriceRate' AND ISNUMERIC(@Uploadval)=1 SELECT @PriceRate=CONVERT(NUMERIC(16,5), @Uploadval);
        IF @Column='PriceTotal' AND ISNUMERIC(@Uploadval)=1 SELECT @PriceTotal=CONVERT(NUMERIC(12,2), @Uploadval);
        IF @Column='TaxType' AND ISNUMERIC(@Uploadval)=1 SELECT @TaxType=CONVERT(tinyint, @Uploadval);
        IF @Column='TaxGroup' AND ISNUMERIC(@Uploadval)=1 SELECT @TaxGroup=CONVERT(tinyint, @Uploadval);
        IF @Column='TaxBasis' AND ISNUMERIC(@Uploadval)=1 SELECT @TaxBasis=CONVERT(NUMERIC(12,2), @Uploadval);
        IF @Column='TaxAmount' AND ISNUMERIC(@Uploadval)=1 SELECT @TaxAmount=CONVERT(NUMERIC(12,2), @Uploadval);
        IF @Column='ActualCost' AND ISNUMERIC(@Uploadval)=1 SELECT @ActualCost=CONVERT(NUMERIC(12,2), @Uploadval);
        IF @Column='ActualUnits' AND ISNUMERIC(@Uploadval)=1 SELECT @ActualUnits=CONVERT(NUMERIC(12,3), @Uploadval);
        
         IF @Column='SMInvoiceID' AND ISNUMERIC(@Uploadval)=1 SELECT @SMInvoiceID=CONVERT(bigint, @Uploadval);
       
        IF @Column='Date' AND ISDATE(@Uploadval)=1 SELECT @Date=CONVERT(smalldatetime, @Uploadval);
        IF @Column='MonthToPostCost' AND ISDATE(@Uploadval)=1 SELECT @MonthToPostCost=CONVERT(smalldatetime, @Uploadval);

--        IF @Column='ServiceSite' SELECT @ServiceSite=@Uploadval; - Cannot supply.
        IF @Column='Status' SELECT @Status=@Uploadval;
        IF @Column='Technician' SELECT @Technician=@Uploadval;
        IF @Column='Agreement' SELECT @Agreement=@Uploadval;
        IF @Column='Coverage' SELECT @Coverage=@Uploadval;
        IF @Column='ReferenceNo' SELECT @ReferenceNo=@Uploadval;
        IF @Column='StandardItem' SELECT @StandardItem= 
			CASE WHEN RTRIM(@Uploadval)='' THEN NULL 
				 WHEN @Uploadval IS NULL THEN NULL 
				 ELSE @Uploadval END;
        IF @Column='Description' SELECT @Description=@Uploadval;
        IF @Column='ServiceItem' SELECT @ServiceItem=@Uploadval;
        IF @Column='CostAccount' SELECT @CostAccount=@Uploadval;
        IF @Column='RevenueAccount' SELECT @RevenueAccount=@Uploadval;
        IF @Column='CostWIPAccount' SELECT @CostWIPAccount=@Uploadval;
        IF @Column='RevenueWIPAccount' SELECT @RevenueWIPAccount=@Uploadval;
        IF @Column='TaxCode' SELECT @TaxCode=@Uploadval;
        IF @Column='NoCharge' SELECT @NoCharge=@Uploadval;
        IF @Column='NonBillable' SELECT @NonBillable=@Uploadval;
        IF @Column='SMCo'
            SET @IsEmptySMCo = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='WorkOrder'
            SET @IsEmptyWorkOrder = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='WorkCompleted'
            SET @IsEmptyWorkCompleted = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='Scope'
            SET @IsEmptyScope = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='ServiceSite'
            SET @IsEmptyServiceSite = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='Status'
            SET @IsEmptyStatus = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='Type'
            SET @IsEmptyType = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='PRCo'
            SET @IsEmptyPRCo = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='Technician'
            SET @IsEmptyTechnician = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='Date'
            SET @IsEmptyDate = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='MonthToPostCost'
            SET @IsEmptyMonthToPostCost = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='Agreement'
            SET @IsEmptyAgreement = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='Revision'
            SET @IsEmptyRevision = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='Coverage'
            SET @IsEmptyCoverage = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='ReferenceNo'
            SET @IsEmptyReferenceNo = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='StandardItem'
            SET @IsEmptyStandardItem = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;

        IF @Column='Description'
            SET @IsEmptyDescription = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='ServiceItem'
            SET @IsEmptyServiceItem = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='SMCostType'
            SET @IsEmptySMCostType = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='PhaseGroup'
            SET @IsEmptyPhaseGroup = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='JCCo'
            SET @IsEmptyJCCo = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='JCCostType'
            SET @IsEmptyJCCostType = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='GLCo'
            SET @IsEmptyGLCo = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='CostAccount'
            SET @IsEmptyCostAccount = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='RevenueAccount'
            SET @IsEmptyRevenueAccount = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='CostWIPAccount'
            SET @IsEmptyCostWIPAccount = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='RevenueWIPAccount'
            SET @IsEmptyRevenueWIPAccount = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='Quantity'
            SET @IsEmptyQuantity = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='CostQuantity'
            SET @IsEmptyCostQuantity = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='CostRate'
            SET @IsEmptyCostRate = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='CostTotal'
            SET @IsEmptyCostTotal = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='PriceQuantity'
            SET @IsEmptyPriceQuantity = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='PriceRate'
            SET @IsEmptyPriceRate = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='PriceTotal'
            SET @IsEmptyPriceTotal = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='TaxType'
            SET @IsEmptyTaxType = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='TaxGroup'
            SET @IsEmptyTaxGroup = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='TaxCode'
            SET @IsEmptyTaxCode = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='TaxBasis'
            SET @IsEmptyTaxBasis = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='TaxAmount'
            SET @IsEmptyTaxAmount = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='NoCharge'
            SET @IsEmptyNoCharge = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='NonBillable'
            SET @IsEmptyNonBillable = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;            
        IF @Column='ActualCost'
            SET @IsEmptyActualCost = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='ActualUnits'
            SET @IsEmptyActualUnits = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='SMInvoiceID '
            SET @IsEmptySMInvoiceID = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;            
          

        IF @@fetch_status <> 0 SELECT @complete = 1;	--set only after ALL records in IMWE have been processed

        SELECT @oldrecseq = @Recseq;

		FETCH NEXT FROM WorkEditCursor 
			INTO @Recseq, @Ident, @Tablename, @Column, @Uploadval;
		END;
	ELSE
        BEGIN
		/* A DIFFERENT import RecordSeq has been detected.  
		   Before moving on, set the default values for our previous Import Record. */
 
/********* SET DEFAULT VALUES ************************/
		/* At this moment, all columns of a single imported record have been
		   processed above.  The defaults for this single imported record 
		   will be set below before the cursor moves on to the columns of the NEXT
		   imported record.  */
		   

/********** Validate SMCo  ******* Required ******/  
-- See above
                    
/**********WorkOrder  ******* Required ******/  
-- no work order default

/********** Validate WorkOrder  ******* Required ******/ 
 
-- Clear Default Values
		SELECT @ServiceSite = NULL, @defaultJCCo=NULL, @defaultJob=NULL
-- validate		
		IF @WorkOrderID <> 0 
			BEGIN;
				EXEC @rc =vspSMWorkCompletedWorkOrderVal @SMCo,@WorkOrder
					,@IsCancelledOK='N' -- per review meeting SET IS CancelledOK='N'
					,@ServiceSite = @ServiceSite OUTPUT 
					,@JCCo =@defaultJCCo OUTPUT
					,@Job =@defaultJob OUTPUT
					,@msg = @msg OUTPUT;
				IF @rc<>0 
					BEGIN;
					UPDATE IMWE
						SET IMWE.UploadVal = CAST ('**' + ISNULL(@msg,'Invalid') AS VARCHAR(60))
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.RecordType = @rectype
							AND IMWE.Identifier = @WorkOrderID;
					 END;
			 END;		
				
/**********WorkCompleted  ******* Required ******/ 
-- check to make sure the Original Type is also a three				              
		SELECT @OriginalType=null  ;
 		IF @WorkCompletedID <> 0 AND ISNULL(@IsEmptyWorkCompleted, 'Y') = 'N'  -- updating an existing WorkCompleted
 			BEGIN;
 				SELECT @OriginalType=[Type] FROM dbo.vSMWorkCompleted
 				WHERE SMCo=@SMCo AND WorkOrder=@WorkOrder  AND @WorkCompleted=@WorkCompleted;
 				IF ISNULL(@OriginalType,3)<>'3'
 					BEGIN
 						UPDATE IMWE
						SET IMWE.UploadVal = '** Invalid - Original Type<>3'
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.Identifier = @WorkCompletedID
							AND IMWE.RecordType = @rectype	
						GOTO FinishCheck;
					END;			
 			END; 
 
 		IF @WorkCompletedID <> 0 AND ISNULL(@IsEmptyWorkCompleted, 'Y') = 'N' AND @WorkCompleted IS NULL -- updating an existing WorkCompleted
 			BEGIN;
				UPDATE IMWE
				SET IMWE.UploadVal = '** Invalid - Work Completed must be empty or numeric'
				WHERE IMWE.ImportTemplate=@ImportTemplate 
					AND IMWE.ImportId=@ImportId 
					AND IMWE.RecordSeq=@currrecseq
					AND IMWE.Identifier = @WorkCompletedID
					AND IMWE.RecordType = @rectype	
				GOTO FinishCheck
 			END; 
 			

  			
		SELECT @MaxWorkCompleted=0, @MaxIMWorkCompleted=0;	 
		IF @WorkCompletedID <> 0  AND ISNULL(@IsEmptyWorkCompleted, 'Y') = 'Y'
			BEGIN;		
				SELECT @MaxWorkCompleted =MAX(WorkCompleted)+1
					FROM dbo.SMWorkCompleted WITH (nolock) 
					WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND Scope = @Scope;

				IF ISNULL(@MaxWorkCompleted,0)=0 
					SELECT @MaxWorkCompleted=1;

		-- get the maximum WorkCompleted from inside the imports
                SELECT  @MaxIMWorkCompleted = MAX(CONVERT(INT,UploadVal)) + 1
                FROM    dbo.IMWE 
                JOIN ( SELECT    RecordSeq
                          FROM      IMWE  -- get the max WorkCompleted for a work order
                          WHERE     IMWE.ImportTemplate = @ImportTemplate
                                    AND dbo.IMWE.ImportId = @ImportId
                                    AND dbo.IMWE.Identifier = @SMCoID
                                    AND dbo.IMWE.RecordType = @rectype
                                    AND dbo.IMWE.UploadVal = @SMCo
                        ) AS CO
                        ON CO.RecordSeq = dbo.IMWE.RecordSeq
                JOIN    ( SELECT    RecordSeq
                          FROM      IMWE  -- get the max WorkCompleted for a work order
                          WHERE     IMWE.ImportTemplate = @ImportTemplate
                                    AND dbo.IMWE.ImportId = @ImportId
                                    AND dbo.IMWE.Identifier = @WorkOrderID
                                    AND dbo.IMWE.RecordType = @rectype
                                    AND dbo.IMWE.UploadVal = @WorkOrder
                        ) AS WO
                        ON WO.RecordSeq = dbo.IMWE.RecordSeq 
                           AND WO.RecordSeq = CO.RecordSeq 
                 JOIN    ( SELECT    RecordSeq
                          FROM      IMWE  -- get the max WorkCompleted for a work order
                          WHERE     IMWE.ImportTemplate = @ImportTemplate
                                    AND dbo.IMWE.ImportId = @ImportId
                                    AND dbo.IMWE.Identifier = @ScopeID
                                    AND dbo.IMWE.RecordType = @rectype
                                    AND dbo.IMWE.UploadVal = @Scope
                        ) AS SO
                        ON SO.RecordSeq = dbo.IMWE.RecordSeq 
                           AND SO.RecordSeq = CO.RecordSeq 
                                  
                 WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
                        AND dbo.IMWE.ImportId = @ImportId
                        AND dbo.IMWE.Identifier = @WorkCompletedID
                        AND dbo.IMWE.RecordType = @rectype
                        AND dbo.IMWE.UploadVal IS NOT null
						AND ISNUMERIC(dbo.IMWE.UploadVal)=1;
						
                IF ISNULL(@MaxIMWorkCompleted, 0) = 0 
                    SELECT  @MaxIMWorkCompleted = 1;
                    
                SELECT  @WorkCompleted = CASE WHEN @MaxWorkCompleted >= @MaxIMWorkCompleted
                                     THEN @MaxWorkCompleted
                                     ELSE @MaxIMWorkCompleted 
                                     END;				
				UPDATE IMWE
				SET IMWE.UploadVal = @WorkCompleted
				WHERE IMWE.ImportTemplate=@ImportTemplate 
					AND IMWE.ImportId=@ImportId 
					AND IMWE.RecordSeq=@currrecseq
					AND IMWE.Identifier = @WorkCompletedID
					AND IMWE.RecordType = @rectype
				SET @IsEmptyWorkCompleted=CASE WHEN @WorkCompleted IS NULL THEN 'Y' ELSE 'N' END;
			END;	
           
/**********StandardItem  *************/ 
        IF @StandardItemID <> 0 
            AND (ISNULL(@OverwriteStandardItem, 'Y') = 'Y' 
                 OR ISNULL(@IsEmptyStandardItem, 'Y') = 'Y')
            BEGIN
                SELECT @StandardItem = null
                UPDATE IMWE
                    SET IMWE.UploadVal = @StandardItem
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordSeq=@currrecseq
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @StandardItemID
                        AND  ISNULL(dbo.IMWE.UploadVal,'')<>ISNULL(@StandardItem,'');
               SET @IsEmptyStandardItem= CASE WHEN @StandardItem IS NULL THEN 'Y' ELSE 'N' END;
            END;
    
/********** Validate StandardItem  *************/ 

		SELECT @defaultCostRate=NULL, @defaultSMCostType=NULL, @msg=null
		IF @StandardItemID<>0 AND @IsEmptyStandardItem='N'  -- sp_helptext vspSMWorkCompletedStandardItemVal
			BEGIN;
				EXEC @rc = dbo.vspSMWorkCompletedStandardItemVal @SMCo = @SMCo, -- bCompany
				    @StandardItem = @StandardItem, -- varchar(20)
				    @CostRate = @defaultCostRate OUTPUT, -- bUnitCost
				    @SMCostType = @defaultSMCostType OUTPUT, -- smallint
				    @msg = @msg OUTPUT -- varchar(100)
				IF @rc<>0
				BEGIN
					UPDATE IMWE
						SET IMWE.UploadVal = CAST('*** '+ISNULL(@msg,'Invalid') AS varchar(60))
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.RecordType = @rectype
							AND IMWE.Identifier = @StandardItemID;
				END
            END;
          
/**********SMCostType  *************/  

        IF @SMCostTypeID <> 0 
            AND (ISNULL(@OverwriteSMCostType, 'Y') = 'Y' 
                 OR ISNULL(@IsEmptySMCostType, 'Y') = 'Y')
            BEGIN;
                SELECT @SMCostType = @defaultSMCostType;
                UPDATE IMWE
                    SET IMWE.UploadVal = @SMCostType
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordSeq=@currrecseq
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @SMCostTypeID;
               SET @IsEmptySMCostType = CASE WHEN @SMCostType IS NULL THEN 'Y' ELSE 'N' END;
            END;

/********** Validate SMCostType  **** sp_helptext vspSMCostTypeVal *********/  
-- clear variables
		SELECT @defaultJCCostType=NULL, @defaultTaxable=NULL, @msg= NULL
		IF @SMCostTypeID<>0 
				BEGIN;
					IF @SMCostType IS NULL AND @IsEmptySMCostType='Y'
						UPDATE IMWE
								SET IMWE.UploadVal = '** Invalid CostType must be numeric'
								WHERE IMWE.ImportTemplate=@ImportTemplate 
									AND IMWE.ImportId=@ImportId 
									AND IMWE.RecordSeq=@currrecseq
									AND IMWE.RecordType = @rectype
									AND IMWE.Identifier = @SMCostTypeID
									AND ISNULL(dbo.IMWE.UploadVal,@msg)<>ISNULL(@msg,'');
									
					IF @SMCostType IS NOT NULL
						BEGIN; 
							EXEC @rc = dbo.vspSMCostTypeVal @SMCo = @SMCo, -- bCompany
								@SMCostType = @SMCostType, -- smallint
								@LineType = @Type, -- tinyint
								@MustExist = 'Y', -- bYN
								@Job = @defaultJob, -- bJob
								@LaborCode = null, -- varchar(15)
								@PayType = null, -- varchar(10)
								@Equipment = NULL, -- bEquip
								@MatlGroup = NULL, -- bGroup
								@Material = NULL, -- bMatl
								@Taxable = @defaultTaxable OUTPUT, -- bYN
								@JCCostType = @defaultJCCostType OUTPUT, -- bJCCType
								@msg = @msg OUTPUT -- varchar(255)
							IF @rc<>0  
							UPDATE IMWE
								SET IMWE.UploadVal = '** Invalid '+ISNULL(@msg,'SMCostType')
								WHERE IMWE.ImportTemplate=@ImportTemplate 
									AND IMWE.ImportId=@ImportId 
									AND IMWE.RecordSeq=@currrecseq
									AND IMWE.RecordType = @rectype
									AND IMWE.Identifier = @SMCostTypeID
									AND ISNULL(dbo.IMWE.UploadVal,@msg)<>ISNULL(@msg,'');
						END;
				END;
 
                                    
/**********Scope  ******* Required ******/  
-- no default
           
            
/********** Validate Scope  ******* Required  sp_helptext vspSMWorkCompletedScopeVal *****/ 
-- clear default values
			 SELECT @defaultCostAccount = NULL,  @defaultRevenueAccount  = NULL,  @defaultCostWIPAccount = NULL
					 ,@defaultRevWIPAccount = NULL, @defaultTaxType = NULL, @defaultTaxCode = NULL
					 ,@defaultServiceSite = NULL, @defaultSMGLCo = NULL, @defaultIsTrackingWIP = NULL
					 ,@defaultIsScopeCompleted = NULL, @defaultJob = NULL, @defaultPhase = NULL, @defaultPhaseGroup = NULL
					 ,@defaultAgreement = NULL,  @defaultRevision = NULL, @defaultCoverage = NULL
					 ,@defaultIsAgreement = NULL, @defaultProvisional = NULL, @msg = NULL   
-- validate
			IF @ScopeID <> 0 
				BEGIN
				
				SET @varSMCostType= @SMCostType;  
				EXEC @rc = vspSMWorkCompletedScopeVal @SMCo, @WorkOrder, @Scope, @LineType =@Type
					 ,@AllowProvisional= 'Y',  @WorkCompleted=@WorkCompleted, @SMCostType=@varSMCostType
					 ,@DefaultCostAcct=@defaultCostAccount OUTPUT
					 ,@DefaultRevenueAcct=@defaultRevenueAccount  OUTPUT
					 ,@DefaultCostWIPAcct=@defaultCostWIPAccount OUTPUT
					 ,@DefaultRevWIPAcct=@defaultRevWIPAccount OUTPUT
					 ,@DefaultTaxType=@defaultTaxType OUTPUT 
					 ,@DefaultTaxCode=@defaultTaxCode OUTPUT
					 ,@ServiceSite=@defaultServiceSite OUTPUT
					 ,@SMGLCo=@defaultSMGLCo OUTPUT
					 ,@IsTrackingWIP = @defaultIsTrackingWIP OUTPUT
					 ,@IsScopeCompleted = @defaultIsScopeCompleted OUTPUT
					 ,@Job=@defaultJob OUTPUT
					 ,@Phase=@defaultPhase OUTPUT
					 ,@PhaseGroup=@defaultPhaseGroup OUTPUT
					 ,@Agreement=@defaultAgreement OUTPUT
					 ,@Revision=@defaultRevision OUTPUT
					 ,@Coverage=@defaultCoverage OUTPUT
					 ,@IsAgreement=@defaultIsAgreement OUTPUT
					 ,@Provisional=@defaultProvisional OUTPUT
					 ,@msg=@msg OUTPUT
					 
					
				IF @rc<>0  
					BEGIN;			
						UPDATE IMWE
						SET IMWE.UploadVal = CAST('** '+ISNULL(@msg,'Invalid') AS VARCHAR(60))
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.RecordType = @rectype
							AND IMWE.Identifier = @ScopeID
							AND ISNULL(UploadVal,'')<>@msg;
						GOTO FinishCheck
					END;
				END;
				
 --SELECT @defaultCostAccount ,  @defaultRevenueAccount  ,  @defaultCostWIPAccount 
	--				 ,@defaultRevWIPAccount , @defaultTaxType , @defaultTaxCode 
	--				 ,@defaultServiceSite , @defaultSMGLCo , @defaultIsTrackingWIP 
	--				 ,@defaultIsScopeCompleted , @defaultJob AS Job , @defaultPhase , @defaultPhaseGroup 
	--				 ,@defaultAgreement ,  @defaultRevision , @defaultCoverage 
	--				 ,@defaultIsAgreement , @defaultProvisional , @msg    
		IF @defaultAgreement IS NULL
		BEGIN;
			SELECT @defaultRevision = NULL, @defaultCoverage =NULL
			
		END;
/**********ServiceSite  ******* Required ******/  
-- ServiceSite is automatically the ServiceSite from vspSMWorkCompletedWorkOrderVal

/********** Default ServiceSite  ******* Required ******/  
            IF @ServiceSiteID<>0
				AND (ISNULL(@OverwriteServiceSite, 'Y') = 'Y' OR ISNULL(@IsEmptyServiceSite, 'Y') = 'Y')
				BEGIN;
					SELECT @ServiceSite=@defaultServiceSite;
					UPDATE IMWE
						SET IMWE.UploadVal = @ServiceSite
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.RecordType = @rectype
							AND IMWE.Identifier = @ServiceSiteID;
					SELECT @IsEmptyServiceSite=CASE WHEN @ServiceSite IS NULL THEN 'Y' ELSE 'N' END;
				END;
/********** Validate ServiceSite  ******* Required ******/  
			IF @ServiceSiteID<>0
				BEGIN;
				--SELECT @msg = convert(varchar(60),ServiceSite)
				--FROM dbo.vSMServiceSite WITH (nolock) WHERE SMCo = @SMCo AND ServiceSite=@ServiceSite;
				--IF @@rowcount=0
					IF ISNULL(@defaultServiceSite,'')<>isnull(@ServiceSite,'')
					BEGIN;
					UPDATE IMWE
						SET IMWE.UploadVal = '** Invalid Service Site must match Work Order'
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.RecordType = @rectype
							AND IMWE.Identifier = @ServiceSiteID;
					 END;
					 ELSE
					BEGIN;
					UPDATE IMWE
						SET IMWE.UploadVal = @ServiceSite
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.RecordType = @rectype
							AND IMWE.Identifier = @ServiceSiteID;
					END;
				 END;
				 
/**********JCCo  *************/  
        IF @JCCoID <> 0 
            --AND (ISNULL(@OverwriteJCCo, 'Y') = 'Y'  -- automatically set default
            --     OR ISNULL(@IsEmptyJCCo, 'Y') = 'Y') -- automatically set default
            BEGIN
                SELECT @JCCo = @defaultJCCo
                UPDATE IMWE
                    SET IMWE.UploadVal = @JCCo
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordSeq=@currrecseq
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @JCCoID;
                SET @IsEmptyJCCo = CASE WHEN @JCCo IS NULL then 'Y' ELSE 'N' END ; 
            END;

/********** Validate JCCo  *************/  
        IF @JCCoID <> 0 AND ISNULL(@JCCo,0)<>ISNULL(@defaultJCCo,0)
            BEGIN;	
				UPDATE IMWE
                SET IMWE.UploadVal = '** Invalid JCCo must match Work Order'
                WHERE IMWE.ImportTemplate=@ImportTemplate 
                    AND IMWE.ImportId=@ImportId 
                    AND IMWE.RecordSeq=@currrecseq
                    AND IMWE.RecordType = @rectype
                    AND IMWE.Identifier = @JCCoID;
             END;
                    				 
	                 
/**********Status  ******* Required ******/  
        IF @StatusID <> 0 
            AND (ISNULL(@OverwriteStatus, 'Y') = 'Y' 
                 OR ISNULL(@IsEmptyStatus, 'Y') = 'Y')
            BEGIN;
                SELECT @Status = 'New';
                UPDATE IMWE
                    SET IMWE.UploadVal = @Status
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordSeq=@currrecseq
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @StatusID;
                SET @IsEmptyStatus = CASE WHEN @Status IS NULL then 'Y' ELSE 'N' END ; 
            END;

/********** Validate Status  ******* Required ******/  
-- validate after cursor

                    
/**********Type  ******* Required ******/ 
-- done outside if cursor
              

                    
/**********Technician  *************/  
-- no default

/********** Validate Technician  *************/ 
		SELECT @defaultRate=null, @defaultPRCo=null -- reset values
        IF @TechnicianID <> 0 AND @Technician IS NOT NULL
            BEGIN;
			EXEC @rc = vspSMTechnicianVal @SMCo, @Technician
				, @PRCo=@defaultPRCo OUTPUT
				, @Rate=@defaultRate OUTPUT
				, @msg=@msg OUTPUT 
			IF @rc<>0  
				BEGIN;
				UPDATE IMWE
					SET IMWE.UploadVal = CAST('** '+ ISNULL(@msg,'Invalid') AS VARCHAR(60))
					WHERE IMWE.ImportTemplate=@ImportTemplate 
						AND IMWE.ImportId=@ImportId 
						AND IMWE.RecordSeq=@currrecseq
						AND IMWE.RecordType = @rectype
						AND IMWE.Identifier = @TechnicianID;
				 END;
			 END;
			 
/**********PRCo  *************/  
        IF @PRCoID <> 0 
            --AND (ISNULL(@OverwritePRCo, 'Y') = 'Y'   --- always force PRCo to the default
            --     OR ISNULL(@IsEmptyPRCo, 'Y') = 'Y')
            BEGIN
                SELECT @PRCo = @defaultPRCo
                UPDATE IMWE
                    SET IMWE.UploadVal = @PRCo
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordSeq=@currrecseq
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @PRCoID;
                SET @IsEmptyPRCo = CASE WHEN @PRCo IS NULL then 'Y' ELSE 'N' END ; 
            END;
         

/********** Validate PRCo  *************/  
        IF @PRCoID <> 0 AND @IsEmptyPRCo ='N'
            BEGIN;
            SELECT @msg = convert(varchar(60),PRCo)
            FROM bPRCO WITH (nolock) WHERE PRCo = @PRCo;
            IF @@rowcount=0			
            UPDATE IMWE
                SET IMWE.UploadVal = '** Invalid PRCo '
                WHERE IMWE.ImportTemplate=@ImportTemplate 
                    AND IMWE.ImportId=@ImportId 
                    AND IMWE.RecordSeq=@currrecseq
                    AND IMWE.RecordType = @rectype
                    AND IMWE.Identifier = @PRCoID;
             END;
                    
/**********Date  ******* Required ******/  
-- default above cursor

/********** Validate Date  ******* Required ******/ 
        IF @DateID <> 0 AND @Date IS NOT null
            BEGIN; 
            UPDATE IMWE  -- check if Date
                SET IMWE.UploadVal = '** Invalid'
                WHERE IMWE.ImportTemplate=@ImportTemplate 
                    AND IMWE.ImportId=@ImportId 
                    AND IMWE.RecordSeq=@currrecseq
                    AND IMWE.RecordType = @rectype
                    AND IMWE.Identifier = @DateID
                    AND ISDATE(dbo.IMWE.UploadVal)=0;
            END;
 
/**********Agreement  *************/  
        IF @AgreementID <> 0 
            AND (ISNULL(@OverwriteAgreement, 'Y') = 'Y' 
                 OR ISNULL(@IsEmptyAgreement, 'Y') = 'Y')
            BEGIN
                SELECT @Agreement = @defaultAgreement
                UPDATE IMWE
                    SET IMWE.UploadVal = @Agreement
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordSeq=@currrecseq
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @AgreementID;
            END;
            
/**********Revision  *************/   
        IF @RevisionID <> 0  -- always overwrite Revision
			AND (ISNULL(@OverwriteRevision, 'Y') = 'Y' 
				 OR ISNULL(@IsEmptyRevision, 'Y') = 'Y'
				 OR @Agreement IS NULL) -- set Revision to null if @Agreement is null))
            BEGIN;
                SELECT @Revision = CASE WHEN @Agreement IS NULL THEN NULL else @defaultRevision END;;
                UPDATE IMWE
                    SET IMWE.UploadVal = @Revision
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordSeq=@currrecseq
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @RevisionID;
                SET @IsEmptyRevision = CASE WHEN @Revision IS NULL THEN 'Y' ELSE 'N' END;
            END;
            
/********** Validate Agreement  *************/
			IF @AgreementID <> 0 AND @Agreement IS NOT NULL  
				BEGIN;
					SELECT @rc=0, @msg=null
					--IF @Agreement<>ISNULL(@defaultAgreement,'')
					--	SELECT @rc=1, @msg='Agreement cannot be different from Scope'
					--Else
					EXEC @rc=dbo.vspSMWorkCompletedAgreementVal @SMCo, @WorkOrder, @Agreement 
							,@Revision = null -- int
							--,@RevisionOut=NULL OUTPUT, -- int not needed at this time
							,@msg = @msg OUTPUT; -- varchar(255)
					IF @rc<>0  
						BEGIN;
							UPDATE IMWE
								SET IMWE.UploadVal = CAST('** '+ISNULL(@msg,'Invalid') AS VARCHAR(60))
								WHERE IMWE.ImportTemplate=@ImportTemplate 
									AND IMWE.ImportId=@ImportId 
									AND IMWE.RecordSeq=@currrecseq
									AND IMWE.RecordType = @rectype
									AND IMWE.Identifier = @AgreementID;
						END;
				END;
				


/********** Validate Revision  ***  sp_helptext vspSMWorkCompletedAgreementVal **********/  
			IF @RevisionID<>0 AND ISNULL(@IsEmptyRevision, 'Y') = 'N' 
				BEGIN;
					SELECT @msg=NULL, @rc=0;
					IF @Agreement IS NULL AND @Revision IS NULL
						SELECT @msg=NULL;
					ELSE IF @Agreement IS NULL AND @Revision IS NOT NULL
						SELECT @rc=1, @msg = '** Invalid - Revision not allowed if no Agreement';
					ELSE 
						BEGIN;
							EXEC @rc=dbo.vspSMWorkCompletedAgreementVal @SMCo, @WorkOrder, @Agreement 
								,@Revision = @Revision -- int
							   -- @RevisionOut OUTPUT, -- int not needed at this time
								, @msg = @msg OUTPUT; -- varchar(255)				
								IF @rc<>0  
								SELECT @msg = '** Invalid Revision';
						END;
					IF @rc<>0
					UPDATE IMWE
						SET IMWE.UploadVal = @msg
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.RecordType = @rectype
							AND IMWE.Identifier = @RevisionID
				 END;  

                   
/**********Coverage  *************/  
        IF @CoverageID <> 0 
            AND (ISNULL(@OverwriteCoverage, 'Y') = 'Y' 
                 OR ISNULL(@IsEmptyCoverage, 'Y') = 'Y'
                 OR @Agreement IS NULL) -- set Coverage to null if @Agreement is null)
            BEGIN;
                SELECT @Coverage = CASE WHEN @Agreement IS NULL THEN NULL else @defaultCoverage END;
                UPDATE IMWE
                    SET IMWE.UploadVal = @Coverage
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordSeq=@currrecseq
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @CoverageID;
                SET @IsEmptyCoverage = CASE WHEN @Coverage IS NULL THEN 'Y' ELSE 'N' END;
            END;

/********** Validate Coverage  *************/ 
			IF @CoverageID<>0 AND @Coverage IS NOT null -- null coverage allowable
				BEGIN;
					SELECT @msg=NULL;
					IF @Coverage<>'C' AND ISNULL(@Coverage,'A')<>'A'
						SELECT @msg = '** Invalid - Coverage can only be ''C'', ''A'' or blank.';
					IF @defaultAgreement IS NOT NULL AND @Coverage<>@defaultCoverage
						SELECT @msg = '** Invalid - A different Coverage than scope is not allowed when scope has an Agreement';
					IF @Agreement IS null AND @Coverage IS NOT NULL
						SELECT @msg = '** Invalid - Coverage not allowed if no Agreement';
					IF ISNULL(@Coverage,'')<>'C'
						BEGIN;
							IF NOT EXISTS (SELECT DatabaseValue FROM dbo.DDCI WHERE ComboType='SMWorkCompltCoverage')
								SELECT @msg='** Invalid Coverage does not exist';
						END;
					IF @msg IS NOT null	
					UPDATE IMWE
						SET IMWE.UploadVal = @msg
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.RecordType = @rectype
							AND IMWE.Identifier = @CoverageID
             END;        
                
/**********ReferenceNo  *************/  
  -- no default

/********** Validate ReferenceNo  *************/  
-- no validation


/**********Description  *************/  
  -- no default

/********** Validate Description  *************/  
-- no validation

/**********ServiceItem  *************/  
-- no default

/********** Validate ServiceItem  ******** sp_helptext vspSMServiceItemVal *****/  
			IF @ServiceItemID<>0 AND @ServiceItem IS NOT NULL
				BEGIN;
					EXEC @rc = dbo.vspSMServiceItemVal @SMCo = @SMCo, -- bCompany
						@ServiceSite = @ServiceSite, -- varchar(20)
						@ServiceableItem = @ServiceItem, -- varchar(20)
						@msg = @msg OUTPUT-- varchar(100)
					
					IF @rc<>0  
					UPDATE IMWE
						SET IMWE.UploadVal = '** Invalid '+ISNULL(@msg,'') 
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.RecordType = @rectype
							AND IMWE.Identifier = @ServiceItemID;
             END;


/**********PhaseGroup  *************/  
        IF @PhaseGroupID <> 0 
            --AND (ISNULL(@OverwritePhaseGroup, 'Y') = 'Y' 
            --     OR ISNULL(@IsEmptyPhaseGroup, 'Y') = 'Y')
            BEGIN
                SELECT @PhaseGroup = @defaultPhaseGroup;
                UPDATE IMWE
                    SET IMWE.UploadVal = @PhaseGroup
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordSeq=@currrecseq
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @PhaseGroupID;
                SET @IsEmptyPhaseGroup = CASE WHEN @PhaseGroup IS NULL THEN 'Y' ELSE 'N' END;
            END;

/********** Validate PhaseGroup  *************/  
-- PhaseGroup validated with CostType

/**********JCCostType  *************/ 
--JCCostType only if Job, JCCostType can be overwritten
        IF @JCCostTypeID <> 0 
            AND (ISNULL(@OverwriteJCCostType, 'Y') = 'Y' 
                 OR ISNULL(@IsEmptyJCCostType, 'Y') = 'Y')
            BEGIN;
                SELECT @JCCostType =  CASE WHEN @defaultJob IS NULL THEN NULL ELSE @defaultJCCostType END;
                UPDATE IMWE
                    SET IMWE.UploadVal = @JCCostType
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordSeq=@currrecseq
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @JCCostTypeID;
                SET @IsEmptyJCCostType=CASE WHEN @JCCostType IS NULL THEN 'Y' ELSE 'N' END;
            END;

/********** Validate JCCostType Customer  *******/ 
        IF @JCCostTypeID <> 0  AND @defaultJob IS NULL AND @JCCostType IS NOT null
			BEGIN;
					UPDATE IMWE
						SET IMWE.UploadVal = '** Invalid JC CostType not allowed on Customer WO'
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.RecordType = @rectype
							AND IMWE.Identifier = @JCCostTypeID;
				END;
				
        IF @JCCostTypeID <> 0  AND @defaultJob IS NOT NULL -- CostType must exist
			BEGIN;
			EXEC @rc = bspJCVCOSTTYPE @jcco=@JCCo
						, @job=@defaultJob
						, @PhaseGroup=@PhaseGroup
						, @phase=@defaultPhase
						, @costtype=@JCCostType
						, @override='N'
						, @msg=@msg OUTPUT;

					IF @rc<>0  
					UPDATE IMWE
						SET IMWE.UploadVal = CAST('** '+ISNULL(@msg,'Invalid') AS VARCHAR(60))
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.RecordType = @rectype
							AND IMWE.Identifier = @JCCostTypeID;
				END;
							
                    
/**********GLCo  ******* Required ******/  
        IF @GLCoID <> 0 
            --AND (ISNULL(@OverwriteGLCo, 'Y') = 'Y'   -- always overwrite
            --     OR ISNULL(@IsEmptyGLCo, 'Y') = 'Y')
            BEGIN
                SELECT @GLCo = @defaultSMGLCo
                UPDATE IMWE
                    SET IMWE.UploadVal = @GLCo
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordSeq=@currrecseq
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @GLCoID;
                SET @IsEmptyGLCo = CASE WHEN @GLCo IS NULL THEN 'Y' ELSE 'N' END;
            END;

/********** Validate GLCo  ******* Required ******/  
 -- validated with GLAccounts
         IF @GLCoID <> 0 AND @IsEmptyGLCo='N'
            BEGIN
                IF NOT EXISTS (SELECT dbo.bGLCO.GLCo FROM dbo.bGLCO WHERE GLCo=@GLCo)
					UPDATE IMWE
						SET IMWE.UploadVal = '** Invalid GLCo not a valid GL Company'
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.RecordType = @rectype
							AND IMWE.Identifier = @GLCoID;
                SET @IsEmptyGLCo = CASE WHEN @GLCo IS NULL THEN 'Y' ELSE 'N' END;
            END;
            
                    
/**********MonthToPostCost  *************/  
        IF @MonthToPostCostID <> 0 
            AND (ISNULL(@OverwriteMonthToPostCost, 'Y') = 'Y' 
                 OR ISNULL(@IsEmptyMonthToPostCost, 'Y') = 'Y')
            BEGIN;
                SELECT @MonthToPostCost = 
                       CONVERT(SMALLDATETIME,CONVERT(VARCHAR(4),YEAR(@Date))
							+'-'+CONVERT(VARCHAR(2),MONTH(@Date))+'-01');
                UPDATE IMWE
                    SET IMWE.UploadVal = @MonthToPostCost
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordSeq=@currrecseq
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @MonthToPostCostID;
               SET @IsEmptyMonthToPostCost = CASE WHEN @MonthToPostCost IS NULL THEN 'Y' ELSE 'N' END;
            END;

/********** Validate MonthToPostCost  *************/
			IF ISNULL(@IsEmptyMonthToPostCost, 'Y') = 'N' and @MonthToPostCost IS NULL
				BEGIN;
				UPDATE IMWE  
					SET IMWE.UploadVal = '** Invalid - Post month required'
					WHERE IMWE.ImportTemplate=@ImportTemplate 
						AND IMWE.ImportId=@ImportId 
						AND IMWE.RecordSeq=@currrecseq
						AND IMWE.RecordType = @rectype
						AND IMWE.Identifier = @MonthToPostCostID;
				END;				
			
			IF @MonthToPostCost IS NOT NULL
			BEGIN;
				EXEC @rc=bspGLMonthVal @glco=@GLCo
					, @mth=@MonthToPostCost
					, @msg = @msg OUTPUT;
				IF @rc<>0
					BEGIN;
					UPDATE IMWE  
						SET IMWE.UploadVal = CAST('** Invalid '+ISNULL(@msg,'') AS VARCHAR(60))
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.RecordType = @rectype
							AND IMWE.Identifier = @MonthToPostCostID;
					END;
			END;
							                   
/**********CostAccount  ******* Required ******/  
        IF @CostAccountID <> 0 
            AND (ISNULL(@OverwriteCostAccount, 'Y') = 'Y' 
                 OR ISNULL(@IsEmptyCostAccount, 'Y') = 'Y')
            BEGIN
                SELECT @CostAccount = @defaultCostAccount
                UPDATE IMWE
                    SET IMWE.UploadVal = @CostAccount
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordSeq=@currrecseq
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @CostAccountID;
            END;

/********** Validate CostAccount  ******* Required ******/  
        IF @CostAccountID <> 0 
            BEGIN;
				EXEC @rc = dbo.bspGLACfPostable  @glco = @GLCo, -- bCompany
				    @glacct = @CostAccount, -- bGLAcct
				    @chksubtype = 'S', -- char(1)
				    @msg = @msg OUTPUT -- varchar(255)
				
				IF @rc<>0  
					BEGIN;
						UPDATE IMWE
						SET IMWE.UploadVal = CAST('** Invalid Cost Account '+ISNULL(@msg,'') AS VARCHAR(60))
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.RecordType = @rectype
							AND IMWE.Identifier = @CostAccountID;
					END; 
			END;
			
			
/**********RevenueAccount  ******* Required ******/  
        IF @RevenueAccountID <> 0 
            AND (ISNULL(@OverwriteRevenueAccount, 'Y') = 'Y' 
                 OR ISNULL(@IsEmptyRevenueAccount, 'Y') = 'Y')
            BEGIN
                SELECT @RevenueAccount = @defaultRevenueAccount
                UPDATE IMWE
                    SET IMWE.UploadVal = @RevenueAccount
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordSeq=@currrecseq
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @RevenueAccountID;
            END;

/********** Validate RevenueAccount  ******* Required ******/  
        IF @RevenueAccountID <> 0 
            BEGIN;
				EXEC @rc = dbo.bspGLACfPostable  @glco = @GLCo, -- bCompany
				    @glacct = @RevenueAccount, -- bGLAcct
				    @chksubtype = 'S', -- char(1)
				    @msg = @msg OUTPUT -- varchar(255) 
				IF @rc<>0  
					BEGIN;
					UPDATE IMWE
						SET IMWE.UploadVal = CAST('** Invalid Revenue Account '+ISNULL(@msg,'') AS VARCHAR(60))
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.RecordType = @rectype
							AND IMWE.Identifier = @RevenueAccountID;
					END; 
			END;
			
/**********CostWIPAccount  ******* Required ******/  
        IF @CostWIPAccountID <> 0 
            AND (ISNULL(@OverwriteCostWIPAccount, 'Y') = 'Y' 
                 OR ISNULL(@IsEmptyCostWIPAccount, 'Y') = 'Y')
            BEGIN
                SELECT @CostWIPAccount = @defaultCostWIPAccount
                UPDATE IMWE
                    SET IMWE.UploadVal = @CostWIPAccount
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordSeq=@currrecseq
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @CostWIPAccountID;
            END;

/********** Validate CostWIPAccount  ******* Required ******/  
        IF @CostWIPAccountID <> 0 
            BEGIN;
				EXEC @rc = dbo.bspGLACfPostable  @glco = @GLCo, -- bCompany
				    @glacct = @CostWIPAccount, -- bGLAcct
				    @chksubtype = 'S', -- char(1)
				    @msg = @msg OUTPUT -- varchar(255)
				IF @rc<>0  
					BEGIN;
					UPDATE IMWE
						SET IMWE.UploadVal = CAST('** Invalid CostWIP Account '+ISNULL(@msg,'') AS VARCHAR(60))
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.RecordType = @rectype
							AND IMWE.Identifier = @CostWIPAccountID;
					END; 
			END;    
			  
/**********RevenueWIPAccount  ******* Required ******/  
        IF @RevenueWIPAccountID <> 0 
            AND (ISNULL(@OverwriteRevenueWIPAccount, 'Y') = 'Y' 
                 OR ISNULL(@IsEmptyRevenueWIPAccount, 'Y') = 'Y')
            BEGIN;
                SELECT @RevenueWIPAccount = @defaultRevWIPAccount;
                UPDATE IMWE
                    SET IMWE.UploadVal = @RevenueWIPAccount
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordSeq=@currrecseq
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @RevenueWIPAccountID;
            END;

/********** Validate RevenueWIPAccount  ******* Required ******/  
        IF @RevenueWIPAccountID <> 0 
            BEGIN;
				EXEC @rc = dbo.bspGLACfPostable  @glco = @GLCo, -- bCompany
				    @glacct = @RevenueWIPAccount, -- bGLAcct
				    @chksubtype = 'S', -- char(1)
				    @msg = @msg OUTPUT -- varchar(255) 
				IF @rc<>0  
					BEGIN;
					UPDATE IMWE
						SET IMWE.UploadVal = CAST('** Invalid Cost Account '+ISNULL(@msg,'') AS VARCHAR(60))
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.RecordType = @rectype
							AND IMWE.Identifier = @RevenueWIPAccountID;
					END; 
			END;    

/* Force Quantities */
		IF @CostQuantity IS NULL AND @StandardItem IS NOT NULL 
			SELECT @CostQuantity=1 , @IsEmptyCostQuantity='N';

            
/**********CostRate  ******* Required ******/  
        IF @CostRateID <> 0 
            AND (ISNULL(@OverwriteCostRate, 'Y') = 'Y' 
                 OR ISNULL(@IsEmptyCostRate, 'Y') = 'Y')
            BEGIN;
                SELECT @CostRate = @defaultCostRate;
                UPDATE IMWE
                    SET IMWE.UploadVal = @CostRate
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordSeq=@currrecseq
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @CostRateID;
               SET @IsEmptyCostRate = CASE WHEN @CostRate IS NULL THEN 'Y' ELSE 'N' END;
            END;
  
            
/********** Calculate Cost Total, Rate, Quantity  *************/  
			IF ISNULL(@ActualCost,0)<>0
				BEGIN;
					IF @ActualCost<>ISNULL(@CostRate,0)*ISNULL(@CostQuantity,0)
						SELECT @CostRate=NULL, @CostQuantity=NULL -- if total<>Q*Cost then null Q,Rate
					ELSE IF ISNULL(@CostRate,0)=0 AND ISNULL(@CostQuantity,0)=0
						SELECT @CostRate=@ActualCost , @CostQuantity=1;
					ELSE IF ISNULL(@CostRate,0)<>0
						SELECT @CostQuantity=CAST(@ActualCost/@CostRate AS numeric(12,3));
					ELSE IF ISNULL(@CostQuantity,0)<>0
						SELECT @CostRate=CAST(@ActualCost/@CostQuantity AS  numeric(16,5));
				END;
			ELSE
				BEGIN; -- Cost Total is null
					IF @CostRate IS NOT null AND @CostQuantity IS NOT null
						SELECT @ActualCost=ISNULL(@CostQuantity*@CostRate,0);
					ELSE -- if either Rate or Qty is null the 
						SELECT @ActualCost=NULL, @CostRate=NULL, @CostQuantity=NULL ;
				END
                   
		                   
/**********  CostQuantity  *************/  
		IF @CostQuantityID<>0 
            UPDATE IMWE
                SET IMWE.UploadVal = @CostQuantity
                WHERE IMWE.ImportTemplate=@ImportTemplate 
                    AND IMWE.ImportId=@ImportId 
                    AND IMWE.RecordSeq=@currrecseq
                    AND IMWE.RecordType = @rectype
                    AND IMWE.Identifier = @CostQuantityID
                    AND ISNULL(dbo.IMWE.UploadVal,'')<>ISNULL(CONVERT(varchar(20),@CostQuantity),'');
                    
/********** CostRate  *************/  
 		IF @CostRateID<>0 
            UPDATE IMWE
                SET IMWE.UploadVal = @CostRate
                WHERE IMWE.ImportTemplate=@ImportTemplate 
                    AND IMWE.ImportId=@ImportId 
                    AND IMWE.RecordSeq=@currrecseq
                    AND IMWE.RecordType = @rectype
                    AND IMWE.Identifier = @CostRateID
                    AND ISNULL(dbo.IMWE.UploadVal,'')<>ISNULL(CONVERT(varchar(20),@CostRate),'');
                    
/**********CostTotal  *************/  
 		IF @ActualCostID<>0 
            UPDATE IMWE
                SET IMWE.UploadVal = @ActualCost
                WHERE IMWE.ImportTemplate=@ImportTemplate 
                    AND IMWE.ImportId=@ImportId 
                    AND IMWE.RecordSeq=@currrecseq
                    AND IMWE.RecordType = @rectype
                    AND IMWE.Identifier = @ActualCostID
                    AND ISNULL(dbo.IMWE.UploadVal,'')<>ISNULL(CONVERT(varchar(20),@ActualCost),'');
                    
/**********PriceQuantity  *************/ 

        IF @PriceQuantity IS NULL AND @StandardItem IS NOT NULL 
			SELECT @PriceQuantity=@CostQuantity	, @IsEmptyPriceQuantity='N'; 
			  
/********** Calculate Price Total, Rate, Quantity  *************/
-- IF Coverage='C' THEN Billable cant be entered 
			IF @defaultJob IS NOT NULL
				SELECT @PriceTotal=@ActualCost, @PriceRate=@CostRate, @PriceQuantity=@CostQuantity;
			ELSE IF ISNULL(@Coverage,'')='C'
				SELECT @PriceTotal=0, @PriceRate=NULL, @PriceQuantity=NULL;
			ELSE IF ISNULL(@Coverage,'')<>'C'
				BEGIN;
					IF @IsEmptyPriceRate='Y'
						BEGIN
							SELECT @PriceRate=BillableRate
							from [dbo].[vfSMGetStandardItemRate] (@SMCo, @WorkOrder, @Scope, @Date, @StandardItem
														, @Agreement, @Revision , @Coverage )		
						END																	
					IF ISNULL(@PriceTotal,0)<>0 
						BEGIN;
							IF @PriceTotal<>ISNULL(@PriceRate,0)*ISNULL(@PriceQuantity,0)
								SELECT @PriceRate=NULL, @PriceQuantity=NULL -- if total<>Q*Cost then null Q,Rate
							IF ISNULL(@PriceRate,0)=0 AND ISNULL(@PriceQuantity,0)=0
								SELECT @PriceRate=null , @PriceQuantity=null;
							ELSE
							IF ISNULL(@PriceRate,0)<>0
								SELECT @PriceQuantity=CAST(@PriceTotal/@PriceRate AS numeric(12,3));
							ELSE
							IF ISNULL(@PriceQuantity,0)<>0
								SELECT @PriceRate=CAST(@PriceTotal/@PriceQuantity AS  numeric(16,5));
						END;
					ELSE
						BEGIN; -- Price Total is null
							IF ISNULL(@PriceRate,0)<>0 AND ISNULL(@PriceQuantity,0)<>0
								SELECT @PriceTotal=ISNULL(CAST(@PriceQuantity*@PriceRate AS  numeric(16,5)),0);
							ELSE
								SELECT @PriceTotal=0;
						END;
				END;
		                   
/**********  PriceQuantity  *************/ 
-- per meeting IF Coverage='C' THEN Billable cant be entered 
		IF @PriceQuantityID<>0 
            UPDATE IMWE
            SET IMWE.UploadVal = CASE WHEN @Coverage='C' THEN NULL ELSE @PriceQuantity end
            WHERE IMWE.ImportTemplate=@ImportTemplate 
                AND IMWE.ImportId=@ImportId 
                AND IMWE.RecordSeq=@currrecseq
                AND IMWE.RecordType = @rectype
                AND IMWE.Identifier = @PriceQuantityID
                AND ISNULL(dbo.IMWE.UploadVal,'')<>ISNULL(CONVERT(varchar(20),@PriceQuantity),'');
                    
/********** PriceRate  *************/  
 		IF @PriceRateID<>0 
            UPDATE IMWE
            SET IMWE.UploadVal = CASE WHEN @Coverage='C' THEN NULL ELSE @PriceRate end
            WHERE IMWE.ImportTemplate=@ImportTemplate 
                AND IMWE.ImportId=@ImportId 
                AND IMWE.RecordSeq=@currrecseq
                AND IMWE.RecordType = @rectype
                AND IMWE.Identifier = @PriceRateID
                AND ISNULL(dbo.IMWE.UploadVal,'')<>ISNULL(CONVERT(varchar(20),@PriceRate),'');
                    
/**********PriceTotal  *************/  
 		IF @PriceTotalID<>0 
            UPDATE IMWE
            SET IMWE.UploadVal = CASE WHEN @Coverage='C' THEN NULL ELSE @PriceTotal END 
            WHERE IMWE.ImportTemplate=@ImportTemplate 
                AND IMWE.ImportId=@ImportId 
                AND IMWE.RecordSeq=@currrecseq
                AND IMWE.RecordType = @rectype
                AND IMWE.Identifier = @PriceTotalID
                AND ISNULL(dbo.IMWE.UploadVal,'')<>ISNULL(CONVERT(varchar(20),@PriceTotal),'');
 --sp_helptext SMWorkCompletedAll             


/************************** TAXES ***************************************************/
   
/********** Default TaxCode  *************/  
        IF @TaxCodeID <> 0 
            AND (ISNULL(@OverwriteTaxCode, 'Y') = 'Y' 
                 OR ISNULL(@IsEmptyTaxCode, 'Y') = 'Y')
            BEGIN
                SELECT @TaxCode =CASE WHEN ISNULL(@defaultTaxable,'')='N' 
						OR @defaultJob IS NOT NULL 
						OR @Coverage='C' 
						OR ISNULL(@defaultTaxable,'')='' THEN NULL ELSE @defaultTaxCode END  
                UPDATE IMWE
                    SET IMWE.UploadVal = @TaxCode
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordSeq=@currrecseq
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @TaxCodeID;
				SELECT @IsEmptyTaxCode=CASE WHEN @TaxCode IS NULL THEN 'Y' ELSE 'N' END; 
                 
            END;

/********** Default TaxGroup  *************/ 
		IF @TaxGroupID <> 0 AND (ISNULL(@OverwriteTaxGroup, 'Y') = 'Y' 
                 OR ISNULL(@IsEmptyTaxGroup, 'Y') = 'Y')
			BEGIN;
				SELECT @TaxGroup=CASE WHEN @defaultJob IS NOT NULL THEN NULL ELSE dbo.bHQGP.Grp END		
					FROM bHQGP WHERE bHQGP.Grp=@TaxGroup
				UPDATE IMWE
					SET IMWE.UploadVal = @TaxGroup
					WHERE IMWE.ImportTemplate=@ImportTemplate 
						AND IMWE.ImportId=@ImportId 
						AND IMWE.RecordSeq=@currrecseq
						AND IMWE.RecordType = @rectype
						AND IMWE.Identifier = @TaxGroupID
						AND dbo.IMWE.UploadVal IS NOT null;
				   Select @IsEmptyTaxGroup=CASE WHEN @TaxGroup IS NULL THEN 'Y' ELSE 'N' END; ;
				END;
				
/********** Validate TaxGroup  *************/ 				
		IF @TaxGroupID <> 0 AND (@IsEmptyTaxGroup='N') 
			BEGIN;
				IF NOT EXISTS(SELECT dbo.bHQGP.Grp FROM bHQGP WHERE bHQGP.Grp=@TaxGroup)
				UPDATE IMWE
					SET IMWE.UploadVal = '** Invalid'
					WHERE IMWE.ImportTemplate=@ImportTemplate 
						AND IMWE.ImportId=@ImportId 
						AND IMWE.RecordSeq=@currrecseq
						AND IMWE.RecordType = @rectype
						AND IMWE.Identifier = @TaxGroupID
						AND dbo.IMWE.UploadVal IS NOT null;
		     END;
		     
/********** default TaxType  *************/  
        IF @TaxTypeID <> 0 
            AND (ISNULL(@OverwriteTaxType, 'Y') = 'Y' 
                 OR ISNULL(@IsEmptyTaxType, 'Y') = 'Y')
            BEGIN
                SELECT @TaxType = CASE WHEN @TaxCode IS NULL OR @defaultJob IS NOT NULL THEN NULL ELSE @defaultTaxType END
                IF NOT (@TaxType IS NULL OR @TaxType = 1 OR @TaxType = 2 OR @TaxType = 3)
					SET @TaxType = 'Invalid'
				
                UPDATE IMWE
                    SET IMWE.UploadVal = @TaxType
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordSeq=@currrecseq
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @TaxTypeID;
                SET @IsEmptyTaxType=CASE WHEN @TaxType IS NULL THEN 'Y' ELSE 'N' END;
            END;                                           

/********** Validate TaxCode  ***** sp_helptext vspHQTaxCodeVal ********/  
--clear default values
		SELECT @defaultTaxRate=0

		IF @TaxCodeID<>0  AND @IsEmptyTaxCode='N'
		BEGIN;
				SELECT @rc=0, @msg=NULL;
				IF ISNULL(@defaultJob,'')<>'' AND @TaxCode IS NOT NULL
					SELECT @rc=1, @msg = '** Invalid TaxCode not allowed if Job Work Order';				
				ELSE IF ISNULL(@Coverage,'')='C' AND @TaxCode IS NOT NULL
					SELECT @rc=1, @msg = '** Invalid TaxCode not allowed if Coverage';
				ELSE 
					BEGIN;								
						EXEC @rc = dbo.vspHQTaxCodeVal @taxgroup = @TaxGroup, -- bGroup sp_helptext vspHQTaxCodeVal
							@taxcode = @TaxCode, -- bTaxCode
							@compdate = NULL, -- bDate
							@taxtype = @TaxType, -- int
							@taxrate = @defaultTaxRate OUTPUT, -- bRate
							@taxphase = NULL, -- bPhase
							@taxjcctype = NULL, -- bJCCType
							@msg = @msg OUTPUT -- varchar(60)
							IF @rc<>0
								SELECT @msg='** Invalid Tax Code'
					END;
				IF @rc<>0	
					UPDATE IMWE
						SET IMWE.UploadVal = @msg
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.RecordType = @rectype
							AND IMWE.Identifier = @TaxCodeID;
		END;
IF @defaultTaxCode IS NULL OR @defaultJob IS NULL OR @Coverage='C' SET @IsEmptyTaxType='Y' -- trigger to reget the default


                                
/********** Validate TaxType  *************/  -- 
		IF  @TaxTypeID <> 0 AND @defaultJob IS NOT NULL
			BEGIN;
				SELECT @rc=0, @msg=NULL;
				IF @TaxType IS NULL AND @IsEmptyTaxType='Y'
					SELECT @msg = 'Okay',@rc=0;
				Else IF @TaxType IS NULL AND @IsEmptyTaxType='N'
					SELECT @msg = '** Invalid TaxType must be numeric',@rc=1;
				ELSE IF ISNULL(@defaultJob,'')='' AND @TaxType IS NOT NULL
					SELECT @msg = '** Invalid TaxType not allowed on Jobs',@rc=1;
				Else IF ISNULL(@Coverage,'')='C' AND @TaxType IS NOT NULL
					SELECT @msg = '** Invalid TaxType not allowed if Coverage',@rc=1;
				Else
					BEGIN;
						IF NOT EXISTS (SELECT DatabaseValue FROM dbo.DDCI WHERE ComboType='SMTaxType')
							SELECT @msg='** Invalid Tax Type',@rc=1;
					END;
				IF @rc<>0	
					BEGIN;
						UPDATE IMWE
							SET IMWE.UploadVal = @msg
							WHERE IMWE.ImportTemplate=@ImportTemplate 
								AND IMWE.ImportId=@ImportId 
								AND IMWE.RecordSeq=@currrecseq
								AND IMWE.RecordType = @rectype
								AND IMWE.Identifier = @TaxTypeID
					END;
             END;      
/**********TaxGroup  *************/  
-- default above cursor

						
/**********TaxBasis  *************/  
        IF @TaxBasisID <> 0
            AND (ISNULL(@OverwriteTaxBasis, 'Y') = 'Y' 
                 OR ISNULL(@IsEmptyTaxBasis, 'Y') = 'Y'
                 OR @IsEmptyTaxCode='Y' )
            BEGIN;
                SELECT @TaxBasis = 
					CASE WHEN @IsEmptyTaxCode='Y' THEN NULL ELSE @PriceTotal END;
                UPDATE IMWE
                    SET IMWE.UploadVal = @TaxBasis
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordSeq=@currrecseq
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @TaxBasisID;
				SET @IsEmptyTaxBasis=CASE WHEN @TaxBasis IS NULL THEN 'Y' ELSE 'N' END;                        
            END;
            
/********** Validate TaxBasis  *************/             
         IF @TaxBasisID <> 0 AND @defaultJob IS NOT NULL AND (ISNULL(@IsEmptyTaxBasis, 'Y') = 'N')
            BEGIN;
                SELECT @rc=0, @msg = NULL;
                IF @TaxBasis IS NULL 
					SELECT @msg = 'Okay',@rc=0;
        		Else If ISNULL(@defaultJob,'')='' AND @TaxBasis IS NOT NULL 
					SELECT @rc=1, @msg='**Invalid Tax Basis must be empty of Job';
				ELSE If ISNULL(@Coverage,'')='C' AND @TaxBasis IS NOT NULL 
					SELECT @rc=1, @msg='**Invalid Tax Basis must be empty when Coverage=C';			
				IF @rc<>0 
					UPDATE IMWE
					SET IMWE.UploadVal = @msg
					WHERE IMWE.ImportTemplate=@ImportTemplate 
						AND IMWE.ImportId=@ImportId 
						AND IMWE.RecordSeq=@currrecseq
						AND IMWE.RecordType = @rectype
						AND IMWE.Identifier = @TaxBasisID
						AND ISNULL(dbo.IMWE.UploadVal,'')<>ISNULL(@msg,'');
            END;



/**********TaxAmount  *************/  
        IF @TaxAmountID <> 0 
            AND (ISNULL(@OverwriteTaxAmount, 'Y') = 'Y' 
                 OR ISNULL(@IsEmptyTaxAmount, 'Y') = 'Y'
                 OR @IsEmptyTaxCode='Y')
            BEGIN
                SELECT @TaxAmount = @TaxBasis * ISNULL(@defaultTaxRate,0)
                UPDATE IMWE
                    SET IMWE.UploadVal = @TaxAmount
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordSeq=@currrecseq
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @TaxAmountID;
                SET @IsEmptyTaxAmount = CASE WHEN @TaxAmount IS NULL THEN 'Y' ELSE 'N' END;
            END;

/********** Validate TaxAmount  *************/  
         IF @TaxAmountID <> 0 AND (ISNULL(@IsEmptyTaxAmount, 'Y') = 'N')
            BEGIN;
                SELECT @msg = null
				If @IsEmptyTaxCode='Y' AND @TaxAmount IS NOT NULL 
					SELECT @msg='**Invalid Tax Amount must be null when there is no Tax Code'
				IF @msg IS NOT null
					UPDATE IMWE
						SET IMWE.UploadVal = @msg
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.RecordType = @rectype
							AND IMWE.Identifier = @TaxAmountID;
            END;
            

                    
/**********NoCharge  ******* Required ******/  
-- no default for NoCharge
-- validation after cursor
 -- Get Next RecSeq
 

/********** DefaultSMInvoiceID  *************/  
 -- none

/********** Validate SMInvoiceID  *************/  
-- clear default vars
        IF @SMInvoiceIDID <> 0 AND @IsEmptySMInvoiceID='N'
			BEGIN;
				SELECT @msg = null
				IF @IsEmptySMInvoiceID='N' AND @SMInvoiceID IS NULL
					SELECT @msg='** Invalid SMInvoice must be numeric or empty'
				ELSE IF @IsEmptySMInvoiceID='N'
					BEGIN;
						IF NOT EXISTS ( SELECT SMInvoiceID
							FROM [dbo].[vSMInvoice] WITH (nolock) 
							WHERE  [dbo].[vSMInvoice].[SMInvoiceID] = @SMInvoiceID)
							IF @@rowcount=0  
								SELECT @msg='** Invalid SMInvoiceID';
					END;
				IF @msg IS NOT NULL
					BEGIN;
						UPDATE IMWE
						SET IMWE.UploadVal ='** Invalid SMInvoiceID'
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.RecordType = @rectype
							AND IMWE.Identifier = @SMInvoiceIDID;
					END;
			END;

FinishCheck:
 -- clear variable for next use
 	    SELECT @SMCo=NULL, @WorkOrder=NULL, @WorkCompleted=NULL, @Scope=NULL
 	    SELECT @Type=NULL, @PRCo=NULL, @Revision=NULL, @SMCostType=NULL
 	    SELECT @PhaseGroup=NULL, @JCCo=NULL, @JCCostType=NULL
        SELECT @GLCo=NULL, @CostQuantity=NULL, @CostTotal=NULL, @PriceQuantity=NULL
        SELECT @PriceRate=NULL, @PriceTotal=NULL, @TaxType=NULL, @TaxGroup=NULL
        SELECT @TaxBasis=NULL, @TaxAmount=NULL, @ActualCost=NULL, @ActualUnits=NULL
        SELECT @Date=NULL, @PhaseGroup=NULL, @MonthToPostCost=NULL, @StandardItem=null
            
		SELECT @currrecseq = @Recseq;
		SELECT @counter = @counter + 1;
    
		END;		--End SET DEFAULT VALUE process
    END;		-- End @complete Loop, Last IMWE record has been processed

CLOSE WorkEditCursor;
DEALLOCATE WorkEditCursor;

----------------------------------------------------
-- after cursor validations
----------------------------------------------------

/********** Validate Status  ******* Required ******/  
IF @StatusID <> 0 
	BEGIN;
		UPDATE IMWE
			SET IMWE.UploadVal = '** Invalid'
			WHERE IMWE.ImportTemplate=@ImportTemplate 
				AND IMWE.ImportId=@ImportId 
				AND IMWE.RecordType = @rectype
				AND IMWE.Identifier = @StatusID
				AND ISNULL(UploadVal,'') NOT IN ('New') -- ('New','PreBilling','Billed','Provisional','Pending Inv');
    END;
            
/********** Validate NoCharge  ******* Required ******/  
IF @NoChargeID <> 0
	BEGIN;
		UPDATE IMWE
			SET IMWE.UploadVal = '** Invalid - must be Y or N'
			WHERE IMWE.ImportTemplate=@ImportTemplate 
				AND IMWE.ImportId=@ImportId 
				AND IMWE.RecordType = @rectype
				AND IMWE.Identifier = @NoChargeID
				AND dbo.IMWE.UploadVal NOT IN ('Y','N');
	END;
	
/********** Validate NonBillable  ******* Required ******/  
IF @NonBillableID <> 0
	BEGIN;
		UPDATE IMWE
			SET IMWE.UploadVal = '** Invalid - must be Y or N'
			WHERE IMWE.ImportTemplate=@ImportTemplate 
				AND IMWE.ImportId=@ImportId 
				AND IMWE.RecordType = @rectype
				AND IMWE.Identifier = @NonBillableID
				AND dbo.IMWE.UploadVal NOT IN ('Y','N');
	END;	

/** EXIT **/
SELECT @rcode=0;

vspexit:
SELECT @msg = isnull(@desc,'Header ') + char(13) + char(13) + '[vspIMVPDefaultsSMWOCMisc]';

RETURN @rcode;
GO
GRANT EXECUTE ON  [dbo].[vspIMVPDefaultsSMWOCMisc] TO [public]
GO
