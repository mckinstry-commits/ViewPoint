SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create PROCEDURE [dbo].[vspIMVPDefaultsSMWOScope]

   /***********************************************************
    * CREATED BY:   Jim Emery  TK-18466 10/23/2012
    *
    * Usage:
    *	Creates Work Order Scopes on a Work Order.
    *   Note: The Workorder number must already exists in the header
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
    (
     @Company bCompany
    ,@ImportId VARCHAR(20)
    ,@ImportTemplate VARCHAR(20)
    ,@Form VARCHAR(20)
    ,@rectype VARCHAR(30)
    ,@msg VARCHAR(120) OUTPUT
    )
    WITH RECOMPILE
AS 
    SET NOCOUNT ON;
    DECLARE @rcode INT;
    DECLARE @rc INT;
    DECLARE @desc VARCHAR(120);
    DECLARE @status INT;
    DECLARE @defaultvalue VARCHAR(30);
    DECLARE @recode VARCHAR(30);
    DECLARE @errmsg VARCHAR(120);
    DECLARE @filler VARCHAR(1); 
    DECLARE @FormDetail VARCHAR(20);
    DECLARE @FormHeader VARCHAR(20);
    DECLARE @RecKey VARCHAR(60);
    DECLARE @RecKeyID INT;
    DECLARE @HeaderRecordType VARCHAR(30);
    DECLARE @HeaderReqSeq INT;
    DECLARE @HeaderSMCoID INT;
    DECLARE @HeaderWorkOrderID INT;
    DECLARE @HeaderServiceCenterID INT;
    DECLARE @HeaderCustGroupID INT;
    DECLARE @HeaderCustomerID INT;
    DECLARE @HeaderJCCoID INT;
    DECLARE @HeaderJobID INT;
    -- DECLARE @HeaderPhaseGroupID INT;
    DECLARE @HeaderPhaseID INT;
    DECLARE @HeaderServiceSiteID INT;
    


--DECLARE	@HeaderSMCoID INT;
    DECLARE @smwsWorkScopeSummary VARCHAR(MAX);
    DECLARE @smwsPhase VARCHAR(20);
    DECLARE @smwsPriorityName VARCHAR(10);
    DECLARE @smwsPhaseGroup TINYINT;
    DECLARE @return_value INT;


    SELECT  @FormHeader = 'SMWorkOrder'
    SELECT  @FormDetail = 'SMWorkOrderScope'
    SELECT  @Form = 'SMWorkOrderScope'

    SELECT  @HeaderRecordType = RecordType
    FROM    IMTR WITH ( NOLOCK )
    WHERE   @ImportTemplate = ImportTemplate
            AND Form = @FormHeader


 
/* Record KeyID is the link between Header and Detail that will allow us retrieve values
   from the Header, later, when needed. (Sometimes RecKey will need to be added to DDUD
   manually for both Form Header and Form Detail) */
    SELECT  @RecKeyID = a.Identifier			--1000
    FROM    dbo.IMTD a WITH ( NOLOCK )
            JOIN dbo.DDUD b WITH ( NOLOCK ) ON a.Identifier = b.Identifier
    WHERE   a.ImportTemplate = @ImportTemplate
            AND b.ColumnName = 'RecKey'
            AND a.RecordType = @rectype
            AND b.Form = @FormDetail
	
    SELECT  @HeaderCustGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'CustGroup', @rectype, 'N');
    SELECT  @HeaderCustomerID = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'Customer', @rectype, 'N');
    SELECT  @HeaderWorkOrderID = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'WorkOrder', @rectype, 'N');
    SELECT  @HeaderSMCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'SMCo', @rectype, 'N');
    SELECT  @HeaderServiceCenterID = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader,'ServiceCenter', @rectype, 'N');
    SELECT  @HeaderJCCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'JCCo', @rectype, 'N');
    SELECT  @HeaderJobID = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'Job', @rectype, 'N');
 --   SELECT  @HeaderPhaseGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'PhaseGroup', @rectype, 'N');
    SELECT  @HeaderPhaseID = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'Phase', @rectype, 'N');	
    SELECT  @HeaderServiceSiteID = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'ServiceSite', @rectype, 'N');
	
/* Working Variables */
    DECLARE @HeaderServiceSite	VARCHAR(20);
    DECLARE @Agreement			VARCHAR(15);
    DECLARE @BillToARCustomer	bCustomer;
    DECLARE @CallType			VARCHAR(10);
    DECLARE @CustGroup			bGroup;
    DECLARE @CustomerPO			VARCHAR(30);
    DECLARE @Customer			bCustomer;
    DECLARE @Description		VARCHAR(8000);
    DECLARE @Division			VARCHAR(10);
    DECLARE @DueEndDate			bDate;
    DECLARE @DueStartDate		bDate;
    DECLARE @IsComplete			bYN;
    DECLARE @IsTrackingWIP		bYN;
    DECLARE @JCCo				bCompany;
    DECLARE @Job				bJob;
    DECLARE @NotToExceed		bDollar;
    DECLARE @Phase				bPhase;
    DECLARE @PhaseGroup			bGroup;
    DECLARE @Price				bDollar;
    DECLARE @PriceMethod		CHAR(1);
    DECLARE @PriorityName		VARCHAR(10);
    DECLARE @RateTemplate		VARCHAR(10);
    DECLARE @Revision			INT;
    DECLARE @SMCo				bCompany;
    DECLARE @SaleLocation		TINYINT;
    DECLARE @Scope				INT;
    DECLARE @Service			INT;
    DECLARE @ServiceCenter		VARCHAR(10);
    DECLARE @ServiceItem		VARCHAR(20);
    DECLARE @UseAgreementRates	bYN;
    DECLARE @WorkOrder          INT;
    DECLARE @WorkScope          VARCHAR(20);
    DECLARE @MaxScope				INT;
    DECLARE @MaxIMScope				INT;
    DECLARE @defaultIsTrackingWIP bYN;
    DECLARE @RevisionOut			INT;    


/* Cursor variables */
    DECLARE @Recseq             INT; 
    DECLARE @Tablename          VARCHAR(20);
    DECLARE @Column             VARCHAR(30);
    DECLARE @Uploadval          VARCHAR(60);
    DECLARE @Ident INT;
    DECLARE @valuelist VARCHAR(255);
    DECLARE @complete INT;
    DECLARE @counter INT;
    DECLARE @oldrecseq INT;
    DECLARE @currrecseq INT;
  
    IF @ImportId IS NULL 
        BEGIN
            SELECT  @desc = 'Missing ImportId.'
                   ,@rcode = 1;
            GOTO vspexit;
        END;
    IF @ImportTemplate IS NULL 
        BEGIN
            SELECT  @desc = 'Missing ImportTemplate.'
                   ,@rcode = 1;
            GOTO vspexit;
        END;
    IF @Form IS NULL 
        BEGIN
            SELECT  @desc = 'Missing Form.'
                   ,@rcode = 1;
            GOTO vspexit;
        END;

 
--Identifiers
    DECLARE @AgreementID INT;
    DECLARE @BillToARCustomerID INT;
    DECLARE @CallTypeID INT;
    DECLARE @CustGroupID INT;
    DECLARE @CustomerPOID INT;
    DECLARE @DescriptionID INT;
    DECLARE @DivisionID INT;
    DECLARE @DueEndDateID INT;
    DECLARE @DueStartDateID INT;
    DECLARE @IsCompleteID INT;
    DECLARE @IsTrackingWIPID INT;
    DECLARE @JCCoID INT;
    DECLARE @JobID INT;
    DECLARE @NotToExceedID INT;
    DECLARE @PhaseGroupID INT;
    DECLARE @PhaseID INT;
    DECLARE @PriceID INT;
    DECLARE @PriceMethodID INT;
    DECLARE @PriorityNameID INT;
    DECLARE @RateTemplateID INT;
    DECLARE @RevisionID INT;
    DECLARE @SMCoID INT;
    DECLARE @SaleLocationID INT;
    DECLARE @ScopeID INT;
    DECLARE @ServiceCenterID INT;
    DECLARE @ServiceID INT;
    DECLARE @ServiceItemID INT;
    DECLARE @UseAgreementRatesID INT;
    DECLARE @WorkOrderID INT;
    DECLARE @WorkScopeID INT;

 
/* Empty flags */ 
    DECLARE @IsEmptyAgreement bYN;
    DECLARE @IsEmptyBillToARCustomer bYN;
    DECLARE @IsEmptyCallType bYN;
    DECLARE @IsEmptyCustGroup bYN;
    DECLARE @IsEmptyCustomerPO bYN;
    DECLARE @IsEmptyDescription bYN;
    DECLARE @IsEmptyDivision bYN;
    DECLARE @IsEmptyDueEndDate bYN;
    DECLARE @IsEmptyDueStartDate bYN;
    DECLARE @IsEmptyIsComplete bYN;
    DECLARE @IsEmptyIsTrackingWIP bYN;
    DECLARE @IsEmptyJCCo bYN;
    DECLARE @IsEmptyJob bYN;
    DECLARE @IsEmptyNotToExceed bYN;
    DECLARE @IsEmptyPhase bYN;
    DECLARE @IsEmptyPhaseGroup bYN;
    DECLARE @IsEmptyPrice bYN;
    DECLARE @IsEmptyPriceMethod bYN;
    DECLARE @IsEmptyPriorityName bYN;
    DECLARE @IsEmptyRateTemplate bYN;
    DECLARE @IsEmptyRevision bYN;
    DECLARE @IsEmptySMCo bYN;
    DECLARE @IsEmptySaleLocation bYN;
    DECLARE @IsEmptyScope bYN;
    DECLARE @IsEmptyService bYN;
    DECLARE @IsEmptyServiceCenter bYN;
    DECLARE @IsEmptyServiceItem bYN;
    DECLARE @IsEmptyUseAgreementRates bYN;
    DECLARE @IsEmptyWorkOrder bYN;
    DECLARE @IsEmptyWorkScope bYN;


/* Overwrite flags */ 
    DECLARE @OverwriteAgreement bYN;
    DECLARE @OverwriteBillToARCustomer bYN;
    DECLARE @OverwriteCallType bYN;
    DECLARE @OverwriteCustGroup bYN;
    DECLARE @OverwriteCustomerPO bYN;
    DECLARE @OverwriteDescription bYN;
    DECLARE @OverwriteDivision bYN;
    DECLARE @OverwriteDueEndDate bYN;
    DECLARE @OverwriteDueStartDate bYN;
    DECLARE @OverwriteIsComplete bYN;
    DECLARE @OverwriteIsTrackingWIP bYN;
    DECLARE @OverwriteJCCo bYN;
    DECLARE @OverwriteJob bYN;
    DECLARE @OverwriteNotToExceed bYN;
    DECLARE @OverwritePhase bYN;
    DECLARE @OverwritePhaseGroup bYN;
    DECLARE @OverwritePrice bYN;
    DECLARE @OverwritePriceMethod bYN;
    DECLARE @OverwritePriorityName bYN;
    DECLARE @OverwriteRateTemplate bYN;
    DECLARE @OverwriteRevision bYN;
    DECLARE @OverwriteSMCo bYN;
    DECLARE @OverwriteSaleLocation bYN;
    DECLARE @OverwriteScope bYN;
    DECLARE @OverwriteService bYN;
    DECLARE @OverwriteServiceCenter bYN;
    DECLARE @OverwriteServiceItem bYN;
    DECLARE @OverwriteUseAgreementRates bYN;
    DECLARE @OverwriteWorkOrder bYN;
    DECLARE @OverwriteWorkScope bYN;

--YN
    DECLARE @ynAgreement bYN;
    DECLARE @ynBillToARCustomer bYN;
    DECLARE @ynCallType bYN;
    DECLARE @ynCustGroup bYN;
    DECLARE @ynCustomerPO bYN;
    DECLARE @ynDescription bYN;
    DECLARE @ynDivision bYN;
    DECLARE @ynDueEndDate bYN;
    DECLARE @ynDueStartDate bYN;
    DECLARE @ynIsComplete bYN;
    DECLARE @ynIsTrackingWIP bYN;
    DECLARE @ynJCCo bYN;
    DECLARE @ynJob bYN;
    DECLARE @ynNotToExceed bYN;
    DECLARE @ynPhase bYN;
    DECLARE @ynPhaseGroup bYN;
    DECLARE @ynPrice bYN;
    DECLARE @ynPriceMethod bYN;
    DECLARE @ynPriorityName bYN;
    DECLARE @ynRateTemplate bYN;
    DECLARE @ynRevision bYN;
    DECLARE @ynSMCo bYN;
    DECLARE @ynSaleLocation bYN;
    DECLARE @ynScope bYN;
    DECLARE @ynService bYN;
    DECLARE @ynServiceCenter bYN;
    DECLARE @ynServiceItem bYN;
    DECLARE @ynUseAgreementRates bYN;
    DECLARE @ynWorkOrder bYN;
    DECLARE @ynWorkScope bYN;

    SELECT  @ynAgreement = 'N';
    SELECT  @ynBillToARCustomer = 'N';
    SELECT  @ynCallType = 'N';
    SELECT  @ynCustGroup = 'N';
    SELECT  @ynCustomerPO = 'N';
    SELECT  @ynDescription = 'N';
    SELECT  @ynDivision = 'N';
    SELECT  @ynDueEndDate = 'N';
    SELECT  @ynDueStartDate = 'N';
    SELECT  @ynIsComplete = 'N';
    SELECT  @ynIsTrackingWIP = 'N';
    SELECT  @ynJCCo = 'N';
    SELECT  @ynJob = 'N';
    SELECT  @ynNotToExceed = 'N';
    SELECT  @ynPhase = 'N';
    SELECT  @ynPhaseGroup = 'N';
    SELECT  @ynPrice = 'N';
    SELECT  @ynPriceMethod = 'N';
    SELECT  @ynPriorityName = 'N';
    SELECT  @ynRateTemplate = 'N';
    SELECT  @ynRevision = 'N';
    SELECT  @ynSMCo = 'N';
    SELECT  @ynSaleLocation = 'N';
    SELECT  @ynScope = 'N';
    SELECT  @ynService = 'N';
    SELECT  @ynServiceCenter = 'N';
    SELECT  @ynServiceItem = 'N';
    SELECT  @ynUseAgreementRates = 'N';
    SELECT  @ynWorkOrder = 'N';
    SELECT  @ynWorkScope = 'N';

/* Set Overwrite flags */ 
    SELECT  @OverwriteAgreement = dbo.vfIMTemplateOverwrite(@ImportTemplate,
            @Form,  'Agreement', @rectype );
    SELECT  @OverwriteBillToARCustomer = dbo.vfIMTemplateOverwrite(@ImportTemplate,
            @Form,  'BillToARCustomer',  @rectype );
    SELECT  @OverwriteCallType = dbo.vfIMTemplateOverwrite(@ImportTemplate,
            @Form,  'CallType',@rectype );
    SELECT  @OverwriteCustGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate,
			@Form,  'CustGroup', @rectype );
    SELECT  @OverwriteCustomerPO = dbo.vfIMTemplateOverwrite(@ImportTemplate,
			@Form, 'CustomerPO', @rectype );
    SELECT  @OverwriteDescription = dbo.vfIMTemplateOverwrite(@ImportTemplate,
            @Form,    'Description',   @rectype );
    SELECT  @OverwriteDivision = dbo.vfIMTemplateOverwrite(@ImportTemplate,
            @Form,  'Division',@rectype );
    SELECT  @OverwriteDueEndDate = dbo.vfIMTemplateOverwrite(@ImportTemplate,
            @Form,   'DueEndDate',  @rectype );
    SELECT  @OverwriteDueStartDate = dbo.vfIMTemplateOverwrite(@ImportTemplate,
            @Form,  'DueStartDate',   @rectype );
    SELECT  @OverwriteIsComplete = dbo.vfIMTemplateOverwrite(@ImportTemplate,
            @Form,  'IsComplete',  @rectype );
    SELECT  @OverwriteIsTrackingWIP = dbo.vfIMTemplateOverwrite(@ImportTemplate,
            @Form,   'IsTrackingWIP',   @rectype );
    SELECT  @OverwriteJCCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form,
            'JCCo', @rectype);
    SELECT  @OverwriteJob = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form,
            'Job', @rectype);
    SELECT  @OverwriteNotToExceed = dbo.vfIMTemplateOverwrite(@ImportTemplate,
            @Form,  'NotToExceed', @rectype );
    SELECT  @OverwritePhase = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form,
            'Phase', @rectype);
    SELECT  @OverwritePhaseGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate,
			@Form, 'PhaseGroup',  @rectype );
    SELECT  @OverwritePrice = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form,
            'Price', @rectype);
    SELECT  @OverwritePriceMethod = dbo.vfIMTemplateOverwrite(@ImportTemplate,
            @Form,   'PriceMethod',   @rectype );
    SELECT  @OverwritePriorityName = dbo.vfIMTemplateOverwrite(@ImportTemplate,
            @Form,  'PriorityName',  @rectype );
    SELECT  @OverwriteRateTemplate = dbo.vfIMTemplateOverwrite(@ImportTemplate,
            @Form,  'RateTemplate',  @rectype );
    SELECT  @OverwriteRevision = dbo.vfIMTemplateOverwrite(@ImportTemplate,
            @Form,  'Revision', @rectype );
    SELECT  @OverwriteSMCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form,
            'SMCo', @rectype);
    SELECT  @OverwriteSaleLocation = dbo.vfIMTemplateOverwrite(@ImportTemplate,
            @Form, 'SaleLocation', @rectype );
    SELECT  @OverwriteScope = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form,
            'Scope', @rectype);
    SELECT  @OverwriteService = dbo.vfIMTemplateOverwrite(@ImportTemplate,
            @Form,  'Service', @rectype);
    SELECT  @OverwriteServiceCenter = dbo.vfIMTemplateOverwrite(@ImportTemplate,
             @Form,  'ServiceCenter',  @rectype );
    SELECT  @OverwriteServiceItem = dbo.vfIMTemplateOverwrite(@ImportTemplate,
            @Form, 'ServiceItem', @rectype );
    SELECT  @OverwriteUseAgreementRates = dbo.vfIMTemplateOverwrite(@ImportTemplate,
            @Form, 'UseAgreementRates', @rectype );
    SELECT  @OverwriteWorkOrder = dbo.vfIMTemplateOverwrite(@ImportTemplate,
            @Form,  'WorkOrder',  @rectype );
    SELECT  @OverwriteWorkScope = dbo.vfIMTemplateOverwrite(@ImportTemplate,
            @Form,  'WorkScope', @rectype );

/***** GET COLUMN IDENTIFIERS -  YN field: 
  Y means ONLY when [Use Viewpoint Default] IS set.
  N means RETURN Identifier regardless of [Use Viewpoint Default] IS set 
*******/ 
    SELECT  @AgreementID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form,  'Agreement', @rectype, 'N');
    SELECT  @BillToARCustomerID = dbo.bfIMTemplateDefaults(@ImportTemplate,  
            @Form, 'BillToARCustomer',   @rectype, 'N');
    SELECT  @CallTypeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CallType', @rectype, 'N');
    SELECT  @CustGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CustGroup', @rectype, 'N');
    SELECT  @CustomerPOID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form,   'CustomerPO', @rectype, 'N');
    SELECT  @DescriptionID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Description', @rectype, 'N');
    SELECT  @DivisionID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form,  'Division', @rectype, 'N');
    SELECT  @DueEndDateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'DueEndDate', @rectype,  'N');
    SELECT  @DueStartDateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form,
            'DueStartDate',   @rectype, 'N');
    SELECT  @IsCompleteID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'IsComplete', @rectype, 'N');
    SELECT  @IsTrackingWIPID = dbo.bfIMTemplateDefaults(@ImportTemplate, 
            @Form,  'IsTrackingWIP',  @rectype, 'N');
    SELECT  @JCCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'JCCo',  @rectype, 'N');
    SELECT  @JobID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Job',  @rectype, 'N');
    SELECT  @NotToExceedID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'NotToExceed', @rectype,   'N');
    SELECT  @PhaseGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form,  'PhaseGroup', @rectype,  'N');
    SELECT  @PhaseID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Phase', @rectype, 'N');
    SELECT  @PriceID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form,  'Price', @rectype, 'N');
    SELECT  @PriceMethodID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form,  'PriceMethod', @rectype,  'N');
    SELECT  @PriorityNameID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form,  'PriorityName',  @rectype, 'N');
    SELECT  @RateTemplateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form,  'RateTemplate',   @rectype, 'N');
    SELECT  @RevisionID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form,  'Revision', @rectype, 'N');
    SELECT  @SMCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SMCo',  @rectype, 'N');
    SELECT  @SaleLocationID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form,  'SaleLocation',  @rectype, 'N');
    SELECT  @ScopeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form,  'Scope', @rectype, 'N');
    SELECT  @ServiceCenterID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form,   'ServiceCenter',   @rectype, 'N');
    SELECT  @ServiceID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form,  'Service', @rectype, 'N');
    SELECT  @ServiceItemID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form,  'ServiceItem', @rectype,  'N');
    SELECT  @UseAgreementRatesID = dbo.bfIMTemplateDefaults(@ImportTemplate,  
            @Form,   'UseAgreementRates',   @rectype, 'N');
    SELECT  @WorkOrderID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form,  'WorkOrder', @rectype, 'N');
    SELECT  @WorkScopeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form,  'WorkScope', @rectype, 'N');
 
/* Columns that can be updated to ALL imported records as a set.
   The value IS NOT unique to the individual imported record. */
 
/********* Begin default process. *******
 Multiple cursor records make up a single Import record
 determined BY a change in the RecSeq value.
 New RecSeq signals the beginning of the NEXT Import record. 
*/ 

    DECLARE WorkEditCursor CURSOR LOCAL FAST_FORWARD
    FOR
        SELECT  IMWE.RecordSeq
               ,IMWE.Identifier
               ,DDUD.TableName
               ,DDUD.ColumnName
               ,IMWE.UploadVal
        FROM    dbo.IMWE WITH ( NOLOCK )
                INNER JOIN DDUD WITH ( NOLOCK ) ON IMWE.Identifier = DDUD.Identifier
                                                   AND DDUD.Form = IMWE.Form
        WHERE   IMWE.ImportId = @ImportId
                AND IMWE.ImportTemplate = @ImportTemplate
                AND IMWE.Form = @Form
                AND IMWE.RecordType = @rectype
        ORDER BY IMWE.RecordSeq
               ,IMWE.Identifier;

    OPEN WorkEditCursor;

    FETCH NEXT FROM WorkEditCursor INTO @Recseq, @Ident, @Tablename, @Column,
        @Uploadval;
    
    SELECT  @currrecseq = @Recseq
           ,@complete = 0
           ,@counter = 1;

-- WHILE cursor IS not empty
    WHILE @complete = 0 
        BEGIN

            IF @@fetch_status <> 0 
                SELECT  @Recseq = -1;

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
		   
                    IF @Column = 'BillToARCustomer'
                        AND ISNUMERIC(@Uploadval) = 1 
                        SELECT  @BillToARCustomer = CONVERT(INT, @Uploadval);
                    IF @Column = 'CustGroup'
                        AND ISNUMERIC(@Uploadval) = 1 
                        SELECT  @CustGroup = CONVERT(INT, @Uploadval);
                    IF @Column = 'JCCo'
                        AND ISNUMERIC(@Uploadval) = 1 
                        SELECT  @JCCo = CONVERT(INT, @Uploadval);
                    IF @Column = 'NotToExceed'
                        AND ISNUMERIC(@Uploadval) = 1 
                        SELECT  @NotToExceed = CONVERT(DECIMAL(16,2), @Uploadval);
                    IF @Column = 'PhaseGroup'
                        AND ISNUMERIC(@Uploadval) = 1 
                        SELECT  @PhaseGroup = CONVERT(INT, @Uploadval);
                    IF @Column = 'Price'
                        AND ISNUMERIC(@Uploadval) = 1 
                        SELECT  @Price = CONVERT(DECIMAL(16,2), @Uploadval);
                    IF @Column = 'Revision'
                        AND ISNUMERIC(@Uploadval) = 1 
                        SELECT  @Revision = CONVERT(INT, @Uploadval);
                    IF @Column = 'SMCo'
                        AND ISNUMERIC(@Uploadval) = 1 
                        SELECT  @SMCo = CONVERT(INT, @Uploadval);
                    IF @Column = 'SaleLocation'
                        AND ISNUMERIC(@Uploadval) = 1 
                        SELECT  @SaleLocation = CONVERT(INT, @Uploadval);
                    IF @Column = 'Scope'
                        AND ISNUMERIC(@Uploadval) = 1 
                        SELECT  @Scope = CONVERT(INT, @Uploadval);
                    IF @Column = 'Service'
                        AND ISNUMERIC(@Uploadval) = 1 
                        SELECT  @Service = CONVERT(INT, @Uploadval);
                    IF @Column = 'WorkOrder'
                        AND ISNUMERIC(@Uploadval) = 1 
                        SELECT  @WorkOrder = CONVERT(INT, @Uploadval);
                    IF @Column = 'DueEndDate'
                        AND ISDATE(@Uploadval) = 1 
                        SELECT  @DueEndDate = CONVERT(SMALLDATETIME, @Uploadval);
                    IF @Column = 'DueStartDate'
                        AND ISDATE(@Uploadval) = 1 
                        SELECT  @DueStartDate = CONVERT(SMALLDATETIME, @Uploadval);
                    IF @Column = 'Agreement' 
                        SELECT  @Agreement = @Uploadval;
                    IF @Column = 'CallType' 
                        SELECT  @CallType = @Uploadval;
                    IF @Column = 'CustomerPO' 
                        SELECT  @CustomerPO = @Uploadval;
                    IF @Column = 'Description' 
                        SELECT  @Description = @Uploadval;
                    IF @Column = 'Division' 
                        SELECT  @Division = @Uploadval;
                    IF @Column = 'IsComplete' 
                        SELECT  @IsComplete = @Uploadval;
                    IF @Column = 'IsTrackingWIP' 
                        SELECT  @IsTrackingWIP = @Uploadval;
                    IF @Column = 'Job' 
                        SELECT  @Job = @Uploadval;
                    IF @Column = 'Phase' 
                        SELECT  @Phase = @Uploadval;
                    IF @Column = 'PriceMethod' 
                        SELECT  @PriceMethod = @Uploadval;
                    IF @Column = 'PriorityName' 
                        SELECT  @PriorityName = @Uploadval;
                    IF @Column = 'RateTemplate' 
                        SELECT  @RateTemplate = @Uploadval;
                    IF @Column = 'ServiceCenter' 
                        SELECT  @ServiceCenter = @Uploadval;
                    IF @Column = 'ServiceItem' 
                        SELECT  @ServiceItem = @Uploadval;
                    IF @Column = 'UseAgreementRates' 
                        SELECT  @UseAgreementRates = @Uploadval;
                    IF @Column = 'WorkScope' 
                        SELECT  @WorkScope = @Uploadval;	 
                    IF @Column = 'Agreement' 
                        SET @IsEmptyAgreement = CASE WHEN @Uploadval IS NULL
                                                     THEN 'Y'
                                                     ELSE 'N'
                                                END;
                    IF @Column = 'BillToARCustomer' 
                        SET @IsEmptyBillToARCustomer = CASE WHEN @Uploadval IS NULL
                                                            THEN 'Y'
                                                            ELSE 'N'
                                                       END;
                    IF @Column = 'CallType' 
                        SET @IsEmptyCallType = CASE WHEN @Uploadval IS NULL
                                                    THEN 'Y'
                                                    ELSE 'N'
                                               END;
                    IF @Column = 'CustGroup' 
                        SET @IsEmptyCustGroup = CASE WHEN @Uploadval IS NULL
                                                     THEN 'Y'
                                                     ELSE 'N'
                                                END;
                    IF @Column = 'CustomerPO' 
                        SET @IsEmptyCustomerPO = CASE WHEN @Uploadval IS NULL
                                                      THEN 'Y'
                                                      ELSE 'N'
                                                 END;
                    IF @Column = 'Description' 
                        SET @IsEmptyDescription = CASE WHEN @Uploadval IS NULL
                                                       THEN 'Y'
                                                       ELSE 'N'
                                                  END;
                    IF @Column = 'Division' 
                        SET @IsEmptyDivision = CASE WHEN @Uploadval IS NULL
                                                    THEN 'Y'
                                                    ELSE 'N'
                                               END;
                    IF @Column = 'DueEndDate' 
                        SET @IsEmptyDueEndDate = CASE WHEN @Uploadval IS NULL
                                                      THEN 'Y'
                                                      ELSE 'N'
                                                 END;
                    IF @Column = 'DueStartDate' 
                        SET @IsEmptyDueStartDate = CASE WHEN @Uploadval IS NULL
                                                        THEN 'Y'
                                                        ELSE 'N'
                                                   END;
                    IF @Column = 'IsComplete' 
                        SET @IsEmptyIsComplete = CASE WHEN @Uploadval IS NULL
                                                      THEN 'Y'
                                                      ELSE 'N'
                                                 END;
                    IF @Column = 'IsTrackingWIP' 
                        SET @IsEmptyIsTrackingWIP = CASE WHEN @Uploadval IS NULL
                                                         THEN 'Y'
                                                         ELSE 'N'
                                                    END;
                    IF @Column = 'JCCo' 
                        SET @IsEmptyJCCo = CASE WHEN @Uploadval IS NULL
                                                THEN 'Y'
                                                ELSE 'N'
                                           END;
                    IF @Column = 'Job' 
                        SET @IsEmptyJob = CASE WHEN @Uploadval IS NULL
                                               THEN 'Y'
                                               ELSE 'N'
                                          END;
                    IF @Column = 'NotToExceed' 
                        SET @IsEmptyNotToExceed = CASE WHEN @Uploadval IS NULL
                                                       THEN 'Y'
                                                       ELSE 'N'
                                                  END;
                    IF @Column = 'Phase' 
                        SET @IsEmptyPhase = CASE WHEN @Uploadval IS NULL
                                                 THEN 'Y'
                                                 ELSE 'N'
                                            END;
                    IF @Column = 'PhaseGroup' 
                        SET @IsEmptyPhaseGroup = CASE WHEN @Uploadval IS NULL
                                                      THEN 'Y'
                                                      ELSE 'N'
                                                 END;
                    IF @Column = 'Price' 
                        SET @IsEmptyPrice = CASE WHEN @Uploadval IS NULL
                                                 THEN 'Y'
                                                 ELSE 'N'
                                            END;
                    IF @Column = 'PriceMethod' 
                        SET @IsEmptyPriceMethod = CASE WHEN @Uploadval IS NULL
                                                       THEN 'Y'
                                                       ELSE 'N'
                                                  END;
                    IF @Column = 'PriorityName' 
                        SET @IsEmptyPriorityName = CASE WHEN @Uploadval IS NULL
                                                        THEN 'Y'
                                                        ELSE 'N'
                                                   END;
                    IF @Column = 'RateTemplate' 
                        SET @IsEmptyRateTemplate = CASE WHEN @Uploadval IS NULL
                                                        THEN 'Y'
                                                        ELSE 'N'
                                                   END;
                    IF @Column = 'Revision' 
                        SET @IsEmptyRevision = CASE WHEN @Uploadval IS NULL
                                                    THEN 'Y'
                                                    ELSE 'N'
                                               END;
                    IF @Column = 'SMCo' 
                        SET @IsEmptySMCo = CASE WHEN @Uploadval IS NULL
                                                THEN 'Y'
                                                ELSE 'N'
                                           END;
                    IF @Column = 'SaleLocation' 
                        SET @IsEmptySaleLocation = CASE WHEN @Uploadval IS NULL
                                                        THEN 'Y'
                                                        ELSE 'N'
                                                   END;
                    IF @Column = 'Scope' 
                        SET @IsEmptyScope = CASE WHEN @Uploadval IS NULL
                                                 THEN 'Y'
                                                 ELSE 'N'
                                            END;
                    IF @Column = 'Service' 
                        SET @IsEmptyService = CASE WHEN @Uploadval IS NULL
                                                   THEN 'Y'
                                                   ELSE 'N'
                                              END;
                    IF @Column = 'ServiceCenter' 
                        SET @IsEmptyServiceCenter = CASE WHEN @Uploadval IS NULL
                                                         THEN 'Y'
                                                         ELSE 'N'
                                                    END;
                    IF @Column = 'ServiceItem' 
                        SET @IsEmptyServiceItem = CASE WHEN @Uploadval IS NULL
                                                       THEN 'Y'
                                                       ELSE 'N'
                                                  END;
                       IF @Column = 'UseAgreementRates' 
                        SET @IsEmptyUseAgreementRates = CASE WHEN @Uploadval IS NULL
                                                             THEN 'Y'
                                                             ELSE 'N'
                                                        END;
                    IF @Column = 'WorkOrder' 
                        SET @IsEmptyWorkOrder = CASE WHEN @Uploadval IS NULL
                                                     THEN 'Y'
                                                     ELSE 'N'
                                                END;
                    IF @Column = 'WorkScope' 
                        SET @IsEmptyWorkScope = CASE WHEN @Uploadval IS NULL
                                                     THEN 'Y'
                                                     ELSE 'N'
                                                END;

                    IF @@fetch_status <> 0 
                        SELECT  @complete = 1;	--set only after ALL records in IMWE have been processed

                    SELECT  @oldrecseq = @Recseq;

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

		/* Retrieve necessary Header values here - This is a 3 step process. */
		--Step #1:  Get UploadVal for this RecKey column.  UploadVal is the pointer back to the Header record.
                    SELECT  @RecKey = IMWE.UploadVal
                    FROM    dbo.IMWE WITH ( NOLOCK )
                    WHERE   IMWE.ImportTemplate = @ImportTemplate
                            AND IMWE.ImportId = @ImportId
                            AND IMWE.Identifier = @RecKeyID
                            AND IMWE.RecordType = @rectype
                            AND IMWE.RecordSeq = @currrecseq;
		--Step #2:  Get Header RecordSeq value for the Header record Type using the UploadVal retrieved in Step #1.
                    SELECT  @HeaderReqSeq = IMWE.RecordSeq
                    FROM    dbo.IMWE WITH ( NOLOCK )
                    WHERE   IMWE.ImportTemplate = @ImportTemplate
                            AND IMWE.ImportId = @ImportId
                            AND IMWE.Identifier = @RecKeyID
                            AND IMWE.RecordType = @HeaderRecordType  -- SELECT * FROM IMWE
                            AND IMWE.UploadVal = @RecKey;
	--SELECT @RecKeyID, @HeaderRecordType, @HeaderReqSeq, @RecKey,
	--	@rectype, @currrecseq                          
        
        --Step #3:  Get the desired Header values from the Header RecordSeq retrieved in Step #2
        /* Company # */
                    SELECT  @msg = IMWE.UploadVal
                    FROM    dbo.IMWE WITH ( NOLOCK )
                    WHERE   IMWE.ImportTemplate = @ImportTemplate
                            AND IMWE.ImportId = @ImportId
                            AND IMWE.Identifier = @HeaderSMCoID
                            AND IMWE.RecordType = @HeaderRecordType
                            AND IMWE.RecordSeq = @HeaderReqSeq;
					SELECT @SMCo=CASE when ISNUMERIC(@msg)=1 THEN @msg ELSE NULL end
                    UPDATE  dbo.IMWE
                    SET     IMWE.UploadVal = @msg
                    WHERE   IMWE.ImportTemplate = @ImportTemplate
                            AND IMWE.ImportId = @ImportId
                            AND IMWE.RecordSeq = @currrecseq
                            AND IMWE.Identifier = @SMCoID
                            AND IMWE.RecordType = @rectype;

		/* Work order # */
                    SELECT  @msg = IMWE.UploadVal
                    FROM    dbo.IMWE WITH ( NOLOCK )
                    WHERE   IMWE.ImportTemplate = @ImportTemplate
                            AND IMWE.ImportId = @ImportId
                            AND IMWE.Identifier = @HeaderWorkOrderID
                            AND IMWE.RecordType = @HeaderRecordType
                            AND IMWE.RecordSeq = @HeaderReqSeq;
					SELECT @WorkOrder=CASE when ISNUMERIC(@msg)=1 THEN @msg ELSE NULL end
                 
                    UPDATE  dbo.IMWE
                    SET     IMWE.UploadVal = @msg
                    WHERE   IMWE.ImportTemplate = @ImportTemplate
                            AND IMWE.ImportId = @ImportId
                            AND IMWE.RecordSeq = @currrecseq
                            AND IMWE.Identifier = @WorkOrderID
                            AND IMWE.RecordType = @rectype
                            AND (UploadVal IS NULL 
                                OR @WorkOrder<>ISNULL(IMWE.UploadVal, 0)
                                );
			
		/*** ServiceCenter  = Header **/ 
                    SELECT  @ServiceCenter = IMWE.UploadVal
                    FROM    dbo.IMWE WITH ( NOLOCK )
                    WHERE   IMWE.ImportTemplate = @ImportTemplate
                            AND IMWE.ImportId = @ImportId
                            AND IMWE.Identifier = @HeaderServiceCenterID
                            AND IMWE.RecordType = @HeaderRecordType
                            AND IMWE.RecordSeq = @HeaderReqSeq 
                    UPDATE  dbo.IMWE
                    SET     IMWE.UploadVal = @ServiceCenter
                    WHERE   IMWE.ImportTemplate = @ImportTemplate
                            AND IMWE.ImportId = @ImportId
                            AND IMWE.RecordSeq = @currrecseq
                            AND IMWE.Identifier = @ServiceCenterID
                            AND IMWE.RecordType = @rectype
                            AND @ServiceCenter <> ISNULL(IMWE.UploadVal, '');
			
		/*** ServiceSite  from Header for use later **/ -- select * from vSMWorkOrderScope
                    SELECT  @HeaderServiceSite = IMWE.UploadVal
                    FROM    dbo.IMWE WITH ( NOLOCK )
                    WHERE   IMWE.ImportTemplate = @ImportTemplate
                            AND IMWE.ImportId = @ImportId
                            AND IMWE.Identifier = @HeaderServiceSiteID
                            AND IMWE.RecordType = @HeaderRecordType
                            AND IMWE.RecordSeq = @HeaderReqSeq 
			
			/**********CustGroup = Header *************/  
                    SELECT  @msg = IMWE.UploadVal
                    FROM    dbo.IMWE WITH ( NOLOCK )
                    WHERE   IMWE.ImportTemplate = @ImportTemplate
                            AND IMWE.ImportId = @ImportId
                            AND IMWE.Identifier = @HeaderCustGroupID
                            AND IMWE.RecordType = @HeaderRecordType
                            AND IMWE.RecordSeq = @HeaderReqSeq;
                    SELECT @CustGroup=CASE when ISNUMERIC(@msg)=1 THEN @msg ELSE NULL end
					IF @CustGroup IS NULL
						SELECT @CustGroup= CustGroup FROM dbo.bHQCO WITH (NOLOCK) 
							WHERE HQCo=@SMCo;
							
                    UPDATE  dbo.IMWE
                    SET     IMWE.UploadVal = @CustGroup
                    WHERE   IMWE.ImportTemplate = @ImportTemplate
                            AND IMWE.ImportId = @ImportId  
                            AND IMWE.RecordSeq = @currrecseq
                            AND IMWE.Identifier = @CustGroupID
                            AND IMWE.RecordType = @rectype
                            AND ISNULL(CONVERT(VARCHAR(10),@CustGroup), '') <> ISNULL(IMWE.UploadVal,'');
               
               /**********Customer from Header *************/      
                    -- this is needed for later processing        
                   	SELECT  @Customer = IMWE.UploadVal
								FROM    dbo.IMWE WITH ( NOLOCK )
								WHERE   IMWE.ImportTemplate = @ImportTemplate
										AND IMWE.ImportId = @ImportId
										AND IMWE.Identifier = @HeaderCustomerID
										AND IMWE.RecordType = @HeaderRecordType
										AND IMWE.RecordSeq = @HeaderReqSeq  
											
	/**********PhaseGroup ScopeVal *************/  
	-- there is no hase at the header
     --               SELECT  @PhaseGroup = IMWE.UploadVal
     --               FROM    dbo.IMWE WITH ( NOLOCK )
     --               WHERE   IMWE.ImportTemplate = @ImportTemplate
     --                       AND IMWE.ImportId = @ImportId
     --                       AND IMWE.Identifier = @HeaderPhaseGroupID
     --                       AND IMWE.RecordType = @HeaderRecordType
     --                       AND IMWE.RecordSeq = @HeaderReqSeq;
					--IF @PhaseGroup IS NULL
					--	SELECT @PhaseGroup= PhaseGroup FROM dbo.bHQCO WITH (NOLOCK)   -- select * 
					--		WHERE HQCo=@SMCo
										
     --               UPDATE  dbo.IMWE
     --               SET     IMWE.UploadVal = @PhaseGroup
     --               WHERE   IMWE.ImportTemplate = @ImportTemplate
     --                       AND IMWE.ImportId = @ImportId
     --                       AND IMWE.RecordSeq = @currrecseq
     --                       AND IMWE.Identifier = @PhaseGroupID
     --                       AND IMWE.RecordType = @rectype
     --                       AND ISNULL(CONVERT(VARCHAR(10),@PhaseGroup), '') <> ISNULL(IMWE.UploadVal,'');


/**********JCCo  header *************/  
                    SELECT  @JCCo = IMWE.UploadVal
                    FROM    dbo.IMWE WITH ( NOLOCK )
                    WHERE   IMWE.ImportTemplate = @ImportTemplate
                            AND IMWE.ImportId = @ImportId
                            AND IMWE.Identifier = @HeaderJCCoID
                            AND IMWE.RecordType = @HeaderRecordType
                            AND IMWE.RecordSeq = @HeaderReqSeq;
			
                    UPDATE  dbo.IMWE
                    SET     IMWE.UploadVal = @JCCo
                    WHERE   IMWE.ImportTemplate = @ImportTemplate
                            AND IMWE.ImportId = @ImportId
                            AND IMWE.RecordSeq = @currrecseq
                            AND IMWE.Identifier = @JCCoID
                            AND IMWE.RecordType = @rectype
                            AND ISNULL(CONVERT(VARCHAR(10),@JCCo), '') <> ISNULL(IMWE.UploadVal,'');

/**********Job header *************/ 
                    SELECT  @Job = IMWE.UploadVal
                    FROM    dbo.IMWE WITH ( NOLOCK )
                    WHERE   IMWE.ImportTemplate = @ImportTemplate
                            AND IMWE.ImportId = @ImportId
                            AND IMWE.Identifier = @HeaderJobID
                            AND IMWE.RecordType = @HeaderRecordType
                            AND IMWE.RecordSeq = @HeaderReqSeq;
			
                    UPDATE  dbo.IMWE
                    SET     IMWE.UploadVal = @Job
                    WHERE   IMWE.ImportTemplate = @ImportTemplate
                            AND IMWE.ImportId = @ImportId
                            AND IMWE.RecordSeq = @currrecseq
                            AND IMWE.Identifier = @JobID
                            AND IMWE.RecordType = @rectype
                            AND ISNULL(@Job, '') <> ISNULL(IMWE.UploadVal, '');		
  

/**********Scope  ******* Required ******/  

/* check if scope is not numeric */
					IF @ScopeID <> 0  AND 
						 ISNULL(@IsEmptyScope, 'Y') = 'N' AND @Scope IS NULL AND ISNULL(@OverwriteScope,'')<>'Y'
					BEGIN;
						UPDATE IMWE
						SET IMWE.UploadVal = '** Invalid scope'
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.Identifier = @ScopeID
							AND IMWE.RecordType = @rectype
						SET @IsEmptyScope = CASE WHEN @Scope IS NULL THEN 'Y' ELSE 'N' END;
						GOTO getnextrecseq -- don't bother checking anything else
					END;
					
/* Scope (in db the column Scope is the Seq # is different */
					IF @ScopeID <> 0  AND 
						(
							ISNULL(@IsEmptyScope, 'Y') = 'Y' 
							OR
							@OverwriteScope='Y'
						)
					BEGIN;
						SELECT @MaxScope=0, @MaxIMScope=0;
						
						SELECT @MaxScope = MAX(Scope)+1
						FROM SMWorkOrderScope WITH (nolock) WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder;
						
						IF ISNULL(@MaxScope,0)=0 
							SELECT @MaxScope=1;

				-- get the maximum Scope from inside the imports
                        SELECT  @MaxIMScope = MAX(CONVERT(INT,UploadVal)) + 1
                        FROM    dbo.IMWE
                        JOIN ( SELECT    RecordSeq
                                  FROM      IMWE  -- get the max Scope for a work order
                                  WHERE     IMWE.ImportTemplate = @ImportTemplate
                                            AND dbo.IMWE.ImportId = @ImportId
                                            AND dbo.IMWE.Identifier = @SMCoID
                                            AND dbo.IMWE.RecordType = @rectype
                                            AND dbo.IMWE.UploadVal = @SMCo
                                ) AS CO
                                ON CO.RecordSeq = dbo.IMWE.RecordSeq
                        JOIN    ( SELECT    RecordSeq
                                  FROM      IMWE  -- get the max Scope for a work order
                                  WHERE     IMWE.ImportTemplate = @ImportTemplate
                                            AND dbo.IMWE.ImportId = @ImportId
                                            AND dbo.IMWE.Identifier = @WorkOrderID
                                            AND dbo.IMWE.RecordType = @rectype
                                            AND dbo.IMWE.UploadVal = CONVERT(VARCHAR(10),@WorkOrder)
                                            AND ISNUMERIC(dbo.IMWE.UploadVal)=1
                                ) AS WO
                                ON WO.RecordSeq = dbo.IMWE.RecordSeq 
                                   AND WO.RecordSeq = CO.RecordSeq 
                                
                         WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
                                AND dbo.IMWE.ImportId = @ImportId
                                AND dbo.IMWE.Identifier = @ScopeID
                                AND dbo.IMWE.RecordType = @rectype
                                AND dbo.IMWE.UploadVal IS NOT null
								AND ISNUMERIC(dbo.IMWE.UploadVal)=1;
								
                        IF ISNULL(@MaxIMScope, 0) = 0 
                            SELECT  @MaxIMScope = 1;
                            
                        SELECT  @Scope = CASE WHEN @MaxScope >= @MaxIMScope
                                             THEN @MaxScope
                                             ELSE @MaxIMScope 
                                             END;				
						UPDATE IMWE
						SET IMWE.UploadVal = @Scope
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.Identifier = @ScopeID
							AND IMWE.RecordType = @rectype
						SET @IsEmptyScope = CASE WHEN @Scope IS NULL THEN 'Y' ELSE 'N' END;
					END;
					ELSE IF (@Scope < 1)
					BEGIN;
						-- Validate the Scope value.
						UPDATE IMWE
						SET IMWE.UploadVal = '** Scope not > 0'
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.Identifier = @ScopeID
							AND IMWE.RecordType = @rectype
						SET @IsEmptyScope = CASE WHEN @Scope IS NULL THEN 'Y' ELSE 'N' END;
						GOTO getnextrecseq -- don't bother checking anything else
					END;
					
/**********Validate WorkScope  *************/  
					SELECT @smwsWorkScopeSummary = null
							,@smwsPriorityName = null
							,@smwsPhaseGroup = null
							,@smwsPhase = null

                    IF @WorkScopeID <> 0 AND @IsEmptyWorkScope='N'
                        BEGIN; 
                            SELECT @WorkScope=WorkScope
								   ,@smwsWorkScopeSummary = WorkScopeSummary  -- for later default
                                   ,@smwsPriorityName = PriorityName -- for later default
                                   ,@smwsPhaseGroup = PhaseGroup     -- for later default
                                   ,@smwsPhase = Phase               -- for later default
                            FROM    dbo.vSMWorkScope WITH (NOLOCK)
                            WHERE   SMCo = @SMCo
                                    AND WorkScope = @WorkScope
                            IF @@rowcount = 0 
								UPDATE  dbo.IMWE
								SET     IMWE.UploadVal = '** Invalid WorkScope '
									+ISNULL(CAST(@WorkScope AS VARCHAR(60)),'null')
								WHERE   IMWE.ImportTemplate = @ImportTemplate
										AND IMWE.ImportId = @ImportId
										AND IMWE.RecordSeq = @currrecseq
										AND IMWE.Identifier = @WorkScopeID
										AND IMWE.RecordType = @rectype;
                        END;
                                    
 /**********Description  *************/ 
 /* Special Handling since description is in IMWENotes and not IMWE*/
	 
					IF @DescriptionID <> 0 AND (ISNULL(@OverwriteDescription, 'Y') = 'Y' OR ISNULL(@Description, '') = '')
						Begin
							SELECT @Description=dbo.bIMWENotes.UploadVal
								FROM bIMWENotes
								WHERE bIMWENotes.ImportTemplate=@ImportTemplate 
									AND bIMWENotes.ImportId=@ImportId 
									AND bIMWENotes.RecordSeq=@currrecseq
									AND bIMWENotes.Identifier = @DescriptionID
									AND bIMWENotes.RecordType = @rectype;
							UPDATE bIMWENotes
							SET bIMWENotes.UploadVal = @smwsWorkScopeSummary 
							WHERE bIMWENotes.ImportTemplate=@ImportTemplate 
								AND bIMWENotes.ImportId=@ImportId 
								AND bIMWENotes.RecordSeq=@currrecseq
								AND bIMWENotes.Identifier = @DescriptionID
								AND bIMWENotes.RecordType = @rectype;
							SET @OverwriteDescription=CASE WHEN @Description IS NULL THEN 'Y' ELSE 'N' END;
						END;
-- select * from bIMWENotes

/**********Priority   *************/  
                    IF @PriorityNameID <> 0 
                        BEGIN 
                            IF ( ISNULL(@OverwritePriorityName, 'Y') = 'Y'
                                 OR ISNULL(@IsEmptyPriorityName, 'Y') = 'Y'
                               ) 
                                BEGIN -- default it
                                    SELECT  @PriorityName = @smwsPriorityName;
                                    UPDATE  dbo.IMWE
									SET     IMWE.UploadVal = @PriorityName
									WHERE   IMWE.ImportTemplate = @ImportTemplate
											AND IMWE.ImportId = @ImportId
											AND IMWE.RecordSeq = @currrecseq
											AND IMWE.Identifier = @PriorityNameID
											AND IMWE.RecordType = @rectype
									SELECT @IsEmptyPriorityName=CASE WHEN @PriorityName IS NULL THEN 'Y' ELSE 'N' END;
                                END;
	
	/* validate */
							IF ISNULL(@PriorityName,'') NOT IN ('','High', 'Med', 'Low' )
								BEGIN;
									UPDATE  dbo.IMWE
									SET     IMWE.UploadVal = '** Invalid Priority'
									WHERE   IMWE.ImportTemplate = @ImportTemplate
											AND IMWE.ImportId = @ImportId
											AND IMWE.RecordSeq = @currrecseq
											AND IMWE.Identifier = @PriorityNameID
											AND IMWE.RecordType = @rectype
											AND ISNULL(@PriorityName,'') NOT IN ('','High', 'Med', 'Low' ) ;
								END;
                        END;
		
/**********CallType  vspSMCallTypeVal *************/  
					SELECT @defaultIsTrackingWIP=null
                    IF @CallTypeID <> 0 AND @IsEmptyCallType='N' 
                        BEGIN;
							SELECT @msg=NULL
							IF @CallType IS NULL AND @IsEmptyCallType='N' 
								SELECT @msg='** Invalid CallType'		
							ELSE 
								BEGIN
									 EXEC @return_value = [dbo].[vspSMCallTypeVal] @SMCo = @SMCo,
											@CallType = @CallType, @WorkOrder = @WorkOrder,
											@Scope = @Scope, @HasWorkCompleted = 'N',  
											@IsTrackingWIP = @defaultIsTrackingWIP OUTPUT,
											@msg = @msg OUTPUT;
										IF @return_value <> 0
										 SELECT @msg= '** Invalid '+ISNULL(@msg,'');
								END;
								
							IF @msg IS NOT null	                         
								BEGIN ; /* there is an error in validation*/
									UPDATE  dbo.IMWE
									SET     IMWE.UploadVal = @msg
									WHERE   IMWE.ImportTemplate = @ImportTemplate
											AND IMWE.ImportId = @ImportId
											AND IMWE.RecordSeq = @currrecseq
											AND IMWE.Identifier = @CallTypeID
											AND IMWE.RecordType = @rectype
								END;
						END;



/**********Division  = vspSMDivisionVal *************/  
-- no default

/********** validate Division  = vspSMDivisionVal *** varchar **********/     
            IF @DivisionID <> 0 AND @IsEmptyDivision = 'N'                                    
				BEGIN;
                     EXEC @rc=dbo.vspSMDivisionVal @SMCo = @SMCo, -- bCompany
                         @ServiceCenter = @ServiceCenter, -- varchar(10)
                         @Division = @Division, -- varchar(10)
                         @MustBeActive = NULL, -- bit
                         @msg = @msg -- varchar(255)
                     IF @rc <> 0  
                        BEGIN;
						UPDATE  dbo.IMWE
						SET     IMWE.UploadVal = '** Invalid Division '+ISNULL(@Division,'')
						WHERE   IMWE.ImportTemplate = @ImportTemplate
								AND IMWE.ImportId = @ImportId
								AND IMWE.RecordSeq = @currrecseq
								AND IMWE.Identifier = @DivisionID
								AND IMWE.RecordType = @rectype;
                        END;
				END;
				

/**********BillToARCustomer vspSMARCustomerVal *************/
-- sp_helptext vspSMARCustomerVal  
                IF @BillToARCustomerID <> 0
                    AND ( ISNULL(@OverwriteBillToARCustomer, 'Y') = 'Y'
                          OR ISNULL(@IsEmptyBillToARCustomer, 'Y') = 'Y'
                        ) 
					BEGIN ; 
						SELECT @BillToARCustomer = NULL;
					-- get the customer # from the header
						IF @Job IS NOT NULL -- jobs dont have Bill to
							BEGIN;
								SELECT @BillToARCustomer=null;
							END;
						ELSE
							BEGIN;
								-- get the BillToCustomer from the SMCustomer Master
								SELECT  @BillToARCustomer = ISNULL(BillToARCustomer,Customer)
								FROM    dbo.vSMCustomer WITH ( NOLOCK )
								WHERE   CustGroup = @CustGroup
									AND Customer = @Customer
									AND SMCo = @SMCo;
							END;
									
						UPDATE  dbo.IMWE
						SET     IMWE.UploadVal = @BillToARCustomer
						WHERE   IMWE.ImportTemplate = @ImportTemplate
								AND IMWE.ImportId = @ImportId
								AND IMWE.RecordSeq = @currrecseq
								AND IMWE.Identifier = @BillToARCustomerID
								AND IMWE.RecordType = @rectype
								AND ISNULL(UploadVal,'')<>ISNULL(CONVERT(VARCHAR(10),@BillToARCustomer),'');
						SET @IsEmptyBillToARCustomer=CASE WHEN @BillToARCustomer IS NULL THEN 'Y' ELSE 'N' END;
					END;

/** Validate Billto Customer **/
			IF @BillToARCustomerID<>0 AND @IsEmptyBillToARCustomer='N'
				BEGIN; 
					SELECT @msg=NULL
					IF @BillToARCustomer IS NULL AND @IsEmptyBillToARCustomer='N' 
						SELECT @msg='** Invalid BillToARCustomer is not numeric'		
					ELSE IF NOT EXISTS (SELECT Customer FROM dbo.bARCM WITH (nolock) 
						WHERE dbo.bARCM.CustGroup = @CustGroup AND dbo.bARCM.Customer=@BillToARCustomer)
						SELECT @msg= '** Invalid - BillToARCustomer not in ARCM '

					IF @msg IS NOT NULL
						UPDATE IMWE
							SET IMWE.UploadVal = @msg							
							WHERE IMWE.ImportTemplate=@ImportTemplate 
								AND IMWE.ImportId=@ImportId 
								AND IMWE.RecordSeq=@currrecseq
								AND IMWE.RecordType = @rectype
								AND IMWE.Identifier = @BillToARCustomerID;
                END;  


/**********RateTemplate  vspSMRateTemplateVal *************/  
                    IF @RateTemplateID <> 0 
                        AND ( ISNULL(@OverwriteRateTemplate, 'Y') = 'Y'
                              OR ISNULL(@IsEmptyRateTemplate, 'Y') = 'Y'
                            ) 
                       BEGIN;
							SELECT @RateTemplate=NULL -- clear out
                            SELECT @RateTemplate = RateTemplate
							FROM   dbo.vSMServiceSite WITH ( NOLOCK )
                            WHERE  SMCo = @SMCo
                                   AND ServiceSite = @HeaderServiceSite;
                            IF @RateTemplate IS NULL AND @Customer IS NOT null -- if not in ServiceSite, check customer
								BEGIN;
									SELECT  @RateTemplate = RateTemplate
									FROM    dbo.vSMCustomer WITH ( NOLOCK )
									WHERE   SMCo = @SMCo
											AND Customer = @Customer
											AND CustGroup = @CustGroup
								END;                            
							UPDATE  dbo.IMWE
							SET     IMWE.UploadVal = @RateTemplate
							WHERE   IMWE.ImportTemplate = @ImportTemplate
									AND IMWE.ImportId = @ImportId
									AND IMWE.RecordSeq = @currrecseq
									AND IMWE.Identifier = @RateTemplateID
									AND IMWE.RecordType = @rectype; 
							SET @IsEmptyRateTemplate=CASE WHEN @RateTemplate IS NULL THEN 'Y' ELSE 'N'                      END;    
                       END;
                       
/**********Validate RateTemplate  vspSMRateTemplateVal *************/  

				IF @RateTemplateID <> 0	AND @IsEmptyRateTemplate='N'
					BEGIN;
						SELECT  @msg = vSMRateTemplate.RateTemplate  
						FROM    dbo.vSMRateTemplate WITH (NOLOCK)
						WHERE   SMCo = @SMCo
								AND RateTemplate = @RateTemplate AND Active='Y'
						IF @@rowcount = 0 
							BEGIN; 
								UPDATE  dbo.IMWE
								SET     IMWE.UploadVal = '** Invalid Rate Template **'
								WHERE   IMWE.ImportTemplate = @ImportTemplate
										AND IMWE.ImportId = @ImportId
										AND IMWE.RecordSeq = @currrecseq
										AND IMWE.Identifier = @RateTemplateID
										AND IMWE.RecordType = @rectype;
							END;
					END;


/**********Validate ServiceItem sp_helptext vspSMServiceItemVal *************/						    
		     
				IF @ServiceItemID <> 0 AND @IsEmptyServiceItem='N'
                    BEGIN;
						SELECT @msg=null
						EXEC @rc = dbo.vspSMServiceItemVal  @SMCo = @SMCo, -- bCompany
						    @ServiceSite = @HeaderServiceSite, -- varchar(20)
						    @ServiceableItem = @ServiceItem, -- varchar(20)
						    @msg = @msg OUTPUT 
                        IF @rc <>0 
							UPDATE  dbo.IMWE
							SET     IMWE.UploadVal = '** Invalid '+ISNULL(@msg,'') 
							WHERE   IMWE.ImportTemplate = @ImportTemplate
									AND IMWE.ImportId = @ImportId
									AND IMWE.RecordSeq = @currrecseq
									AND IMWE.Identifier = @ServiceItemID
									AND IMWE.RecordType = @rectype;
					END;


/**********SaleLocation   ******* Required ******/  
				IF @SaleLocationID <> 0  
					AND (ISNULL(@OverwriteSaleLocation, 'Y') = 'Y' OR ISNULL(@IsEmptySaleLocation, 'Y') = 'Y')
					BEGIN;
						SELECT @SaleLocation = 0 -- @ServiceCenter
						UPDATE IMWE
						SET IMWE.UploadVal = @SaleLocation
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.Identifier = @SaleLocationID
							AND IMWE.RecordType = @rectype;
						SET @IsEmptySaleLocation=CASE WHEN @SaleLocation IS NULL THEN 'N' ELSE 'Y' END;
					END;

-- validate
				IF @SaleLocationID <> 0  AND @IsEmptySaleLocation='N'
					BEGIN;
						UPDATE IMWE
						SET IMWE.UploadVal = '** Invalid, Sales location must be 0 or 1'
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.Identifier = @SaleLocationID
							AND IMWE.RecordType = @rectype
							AND ISNULL(dbo.IMWE.UploadVal,'') NOT IN ('0','1');
					END;					
				
				
/**********IsComplete  ******* Required ******/  
					IF @IsCompleteID <> 0 
						AND (ISNULL(@OverwriteIsComplete, 'Y') = 'Y' OR ISNULL(@IsEmptyIsComplete, 'Y') = 'Y')
						BEGIN;
							SELECT @IsComplete = 'N'; 
							UPDATE IMWE
							SET IMWE.UploadVal = @IsComplete
							WHERE IMWE.ImportTemplate=@ImportTemplate 
								AND IMWE.ImportId=@ImportId 
								AND IMWE.RecordSeq=@currrecseq
								AND IMWE.Identifier = @IsCompleteID
								AND IMWE.RecordType = @rectype
								AND ISNULL(dbo.IMWE.UploadVal,'')<>@IsComplete;
							SET @IsEmptyIsComplete=CASE WHEN @IsComplete IS NULL THEN 'Y' ELSE 'N' END;
						END;
-- Validate
					IF @IsCompleteID <> 0 AND @IsEmptyIsComplete='N'
						BEGIN;
							UPDATE IMWE
							SET IMWE.UploadVal = '** Invalid IsComplete must be empty, Y, or N'
							WHERE IMWE.ImportTemplate=@ImportTemplate 
								AND IMWE.ImportId=@ImportId 
								AND IMWE.RecordSeq=@currrecseq
								AND IMWE.Identifier = @IsCompleteID
								AND IMWE.RecordType = @rectype
								AND ISNULL(dbo.IMWE.UploadVal,'') NOT IN ('Y','N');
						END;
						
/**********IsTrackingWIP  ******* Required ******/

                    IF @IsTrackingWIPID <> 0
                        AND ( ISNULL(@OverwriteIsTrackingWIP, 'Y') = 'Y' OR @IsEmptyIsTrackingWIP = 'Y') 
                        BEGIN;
							IF @CallType IS NULL	
								SELECT @IsTrackingWIP='N';
							Else
								SELECT  @IsTrackingWIP = IsTrackingWIP
								FROM    dbo.vSMCallType WITH ( NOLOCK )
								WHERE   SMCo = @SMCo
										AND CallType = @CallType;
							IF @IsTrackingWIP IS NULL
								SELECT @IsTrackingWIP='N';
							UPDATE  dbo.IMWE
							SET     IMWE.UploadVal = @IsTrackingWIP
							WHERE   IMWE.ImportTemplate = @ImportTemplate
									AND IMWE.ImportId = @ImportId
									AND IMWE.RecordSeq = @currrecseq
									AND IMWE.Identifier = @IsTrackingWIPID
									AND @IsTrackingWIPID<>0
									AND IMWE.RecordType = @rectype
							SET @IsEmptyIsTrackingWIP=CASE WHEN @IsTrackingWIP IS NULL THEN 'Y' ELSE 'N' END;	
                        END;
-- VALIDATE                        
					IF @IsTrackingWIPID <> 0 AND @IsEmptyIsTrackingWIP='N'
						BEGIN;
							UPDATE  dbo.IMWE
							SET     IMWE.UploadVal = '** Invalid Tracking WIP - should be Y or N'
							WHERE   IMWE.ImportTemplate = @ImportTemplate
									AND IMWE.ImportId = @ImportId
									AND IMWE.RecordSeq = @currrecseq
									AND IMWE.Identifier = @IsTrackingWIPID
									AND @IsTrackingWIPID<>0
									AND IMWE.RecordType = @rectype
									AND ISNULL(@IsTrackingWIP, '') NOT IN ( 'Y', 'N' ) ;
						END;


/**********Validate DueStartDate  none *************/  
                    IF @DueStartDateID <> 0 AND @IsEmptyDueStartDate='N'
                        BEGIN;
                            UPDATE  dbo.IMWE
                            SET     IMWE.UploadVal ='** DueStartDate must be a date or empty'
                            WHERE   IMWE.ImportTemplate = @ImportTemplate
                                    AND IMWE.ImportId = @ImportId
                                    AND IMWE.RecordSeq = @currrecseq
                                    AND IMWE.Identifier = @DueStartDateID
                                    AND IMWE.RecordType = @rectype
                                    AND ISDATE(ISNULL(dbo.IMWE.UploadVal,'1/1/2000'))=0;
                        END;
                        
/**********Validate DueEndDate  none *************/  
                    IF @DueEndDateID <> 0 AND @IsEmptyDueEndDate='N'
                        BEGIN;
                            UPDATE  dbo.IMWE
                            SET     IMWE.UploadVal ='** DueEndDate must be a date or empty'
                            WHERE   IMWE.ImportTemplate = @ImportTemplate
                                    AND IMWE.ImportId = @ImportId
                                    AND IMWE.RecordSeq = @currrecseq
                                    AND IMWE.Identifier = @DueEndDateID
                                    AND IMWE.RecordType = @rectype
                                    AND ISDATE(ISNULL(dbo.IMWE.UploadVal,'1/1/2000'))=0;
                        END;
                        
/**********CustomerPO none  *************/  
--IF @CustomerPOID <> 0 AND (ISNULL(@OverwriteCustomerPO, 'Y') = 'Y' OR ISNULL(@IsEmptyCustomerPO, 'Y') = 'Y')
--BEGIN
--	SELECT @CustomerPO = CustomerPO
--	FROM ???? WITH (nolock) WHERE ??? = @Co;

--	UPDATE IMWE
--	SET IMWE.UploadVal = @CustomerPO
--	WHERE IMWE.ImportTemplate=@ImportTemplate 
--		AND IMWE.ImportId=@ImportId 
--		AND IMWE.RecordSeq=@currrecseq
--		AND IMWE.Identifier = @CustomerPOID
--		AND IMWE.RecordType = @rectype;
--END;

/**********NotToExceed  none *************/  
                    IF @NotToExceedID <> 0
                        AND  ISNULL(@OverwriteNotToExceed, 'Y') = 'Y' OR @IsEmptyNotToExceed='Y'
                        BEGIN;
                            SELECT  @NotToExceed = NULL
                            UPDATE  dbo.IMWE
                            SET     IMWE.UploadVal = @NotToExceed
                            WHERE   IMWE.ImportTemplate = @ImportTemplate
                                    AND IMWE.ImportId = @ImportId
                                    AND IMWE.RecordSeq = @currrecseq
                                    AND IMWE.Identifier = @NotToExceedID
                                    AND IMWE.RecordType = @rectype;
							SET @IsEmptyNotToExceed=CASE WHEN @NotToExceed IS NULL THEN 'Y' ELSE 'N' END;                                    
                        END;

/**********Validate NotToExceed  none *************/  
                    IF @NotToExceedID <> 0
                        BEGIN;
                            UPDATE  dbo.IMWE
                            SET     IMWE.UploadVal ='** Not to Exceed must be numeric'
                            WHERE   IMWE.ImportTemplate = @ImportTemplate
                                    AND IMWE.ImportId = @ImportId
                                    AND IMWE.RecordSeq = @currrecseq
                                    AND IMWE.Identifier = @NotToExceedID
                                    AND IMWE.RecordType = @rectype
                                    AND ISNUMERIC(ISNULL(dbo.IMWE.UploadVal,0))=0;
                        END;

/********** default Phase Group *************/ 				
					IF @PhaseGroupID <> 0 
					BEGIN
						SELECT @PhaseGroup=@smwsPhaseGroup
						IF @PhaseGroup IS NULL AND @Phase IS NOT null
							SELECT @PhaseGroup=PhaseGroup FROM dbo.HQCO
								WHERE HQCO.HQCo=@SMCo
						UPDATE IMWE
							SET IMWE.UploadVal = @PhaseGroup
							WHERE IMWE.ImportTemplate=@ImportTemplate 
								AND IMWE.ImportId=@ImportId 
								AND IMWE.RecordSeq=@currrecseq
								AND IMWE.Identifier = @PhaseGroupID
								AND IMWE.RecordType = @rectype;
						SET @IsEmptyPhaseGroup=CASE WHEN @PhaseGroup IS NULL THEN 'Y' ELSE 'N' END;
					END;                        


/**********Phase Default *************/ 
-- select object_name(id) from syscolumns where object_name(id) like 'vSM%' and name ='Agreement'
-- vSMWorkScope SMCo,WorkScope
                    IF @PhaseID <> 0 AND ( ISNULL(@OverwritePhase, 'Y') = 'Y' OR ISNULL(@IsEmptyPhase, 'Y') = 'Y'
                            ) 
                        BEGIN;
							IF @Job IS NULL
								SELECT @Phase=NULL
							ELSE
								SELECT  @Phase = @smwsPhase
								
                            UPDATE  dbo.IMWE
                            SET     IMWE.UploadVal = @Phase
                            WHERE   IMWE.ImportTemplate = @ImportTemplate
                                    AND IMWE.ImportId = @ImportId
                                    AND IMWE.RecordSeq = @currrecseq
                                    AND IMWE.Identifier = @PhaseID
                                    AND IMWE.RecordType = @rectype;
                            SET @IsEmptyPhase=CASE WHEN @Phase IS NULL THEN 'Y' ELSE 'N' END;
                        END;

/**********Phase Validation *************/ 				
					IF @PhaseID <> 0 AND @IsEmptyPhase='N' 
					BEGIN
						EXEC @rc=dbo.vspSMWorkOrderScopePhaseVal @JCCo = @JCCo, -- bCompany
						    @Job = @Job, -- bJob
						    @Phase = @Phase, -- bPhase
						    @phasegroup = @PhaseGroup, -- tinyint
						    @msg = @msg OUTPUT-- varchar(255)
						IF @rc<>0
							UPDATE IMWE
							SET IMWE.UploadVal = CAST('** '+ISNULL(@msg,'Invalid') AS VARCHAR(60))
							WHERE IMWE.ImportTemplate=@ImportTemplate 
								AND IMWE.ImportId=@ImportId 
								AND IMWE.RecordSeq=@currrecseq
								AND IMWE.Identifier = @PhaseID
								AND IMWE.RecordType = @rectype;
					END;                        


/**********Agreement  vspSMWorkCompletedAgreementVal  (SMAgre******* Required ******/  
/********* ERIC V. - an Agreement should never default on an import */
-- sp_helptext vspSMWorkCompletedAgreementVal
SELECT @RevisionOut=null
/* validate agreement */ 
				IF @AgreementID<>0 AND (@IsEmptyAgreement='N' OR @Agreement IS NOT NULL)
					BEGIN;	
						--EXEC @rc=dbo.vspSMWorkCompletedAgreementVal @SMCo, @WorkOrder, @Agreement ,
						--	@Revision = @Revision, -- int
						--    @RevisionOut =@RevisionOut OUTPUT, -- int not needed at this time
						--	@msg = @msg OUTPUT; -- varchar(255)
/* cant use the standard vspSMWorkCompletedAgreementVal because the WorkOrder is not created yet*/											SELECT @rc=0
						SELECT TOP 1
							@msg = SMAgreement.[Description],
							@RevisionOut = SMAgreement.Revision
						FROM dbo.SMAgreement
						WHERE SMAgreement.SMCo = @SMCo
							AND SMAgreement.CustGroup = @CustGroup
							AND dbo.SMAgreement.Customer = @Customer
							AND SMAgreement.Agreement = @Agreement
							AND SMAgreement.Revision = ISNULL(@Revision, SMAgreement.Revision)
							AND SMAgreement.DateActivated IS NOT NULL
						ORDER BY SMAgreement.Revision DESC						
						IF @@rowcount=0
							SELECT @rc=1, @msg='** Invalid Agreement for this customer'
						IF @rc<>0
							BEGIN;
								UPDATE IMWE
									SET IMWE.UploadVal = @msg
									WHERE IMWE.ImportTemplate=@ImportTemplate 
										AND IMWE.ImportId=@ImportId 
										AND IMWE.RecordSeq=@currrecseq
										AND IMWE.RecordType = @rectype
										AND IMWE.Identifier = @AgreementID;
							END;
					END;
/********** DefaultRevision  ******* Required ******/  
/* Eric said that a Revision should never be required */
                    IF @RevisionID <> 0
                        AND ( ISNULL(@OverwriteRevision, 'Y') = 'Y'
                              OR ISNULL(@IsEmptyRevision, 'Y') = 'Y'
                            ) 
                        BEGIN
                            SELECT @Revision=@RevisionOut
                            UPDATE IMWE
                            SET IMWE.UploadVal = @Revision
							WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.RecordType = @rectype
							AND IMWE.Identifier = @RevisionID;
							SET @IsEmptyRevision=CASE WHEN @Revision IS NULL THEN 'Y' ELSE 'N' END;
                        END;

/********* validate @Revision *********/
				IF @RevisionID <> 0 AND @IsEmptyAgreement='N' -- yes this should say is empty agreement
					BEGIN;
					--EXEC @rc=dbo.vspSMWorkCompletedAgreementVal @SMCo, @WorkOrder, @Agreement,
					--	@Revision = @Revision, -- int
					--    @RevisionOut = @RevisionOut OUTPUT, -- int not needed at this time
					--	@msg = @msg OUTPUT; -- varchar(255)
/* cant use the standard vspSMWorkCompletedAgreementVal because the WorkOrder is not created yet*/				
						SELECT TOP 1
							@msg = SMAgreement.[Description]
						FROM dbo.SMAgreement
						WHERE SMAgreement.SMCo = @SMCo
							AND SMAgreement.CustGroup = @CustGroup
							AND dbo.SMAgreement.Customer = @Customer
							AND SMAgreement.Agreement = @Agreement
							AND SMAgreement.Revision = ISNULL(@Revision,'')
							AND SMAgreement.DateActivated IS NOT NULL
						ORDER BY SMAgreement.Revision DESC						
						IF @@rowcount=0					
							BEGIN;
							UPDATE IMWE
								SET IMWE.UploadVal = '** Invalid Revision'
							WHERE IMWE.ImportTemplate=@ImportTemplate 
								AND IMWE.ImportId=@ImportId 
								AND IMWE.RecordSeq=@currrecseq
								AND IMWE.RecordType = @rectype
								AND IMWE.Identifier = @RevisionID;
							END;
					END;


/**********PriceMethod  *************/

/*************************************************if agreement than it can change */  
				IF @PriceMethodID <> 0 
					AND (ISNULL(@OverwritePriceMethod, 'Y') = 'Y' OR ISNULL(@IsEmptyPriceMethod, 'Y') = 'Y')
				BEGIN
					SELECT @PriceMethod = 'T'
					UPDATE IMWE
					SET IMWE.UploadVal = @PriceMethod
					WHERE IMWE.ImportTemplate=@ImportTemplate 
						AND IMWE.ImportId=@ImportId 
						AND IMWE.RecordSeq=@currrecseq
						AND IMWE.Identifier = @PriceMethodID
						AND IMWE.RecordType = @rectype;
					SET @IsEmptyPriceMethod=CASE WHEN @PriceMethod IS NULL THEN 'Y' ELSE 'N' END;
				END;
-- validation				
				IF @PriceMethodID <> 0 
				BEGIN
					UPDATE IMWE
					SET IMWE.UploadVal = '** Invalid Price Method should be C,T, or F'
					WHERE IMWE.ImportTemplate=@ImportTemplate 
						AND IMWE.ImportId=@ImportId 
						AND IMWE.RecordSeq=@currrecseq
						AND IMWE.Identifier = @PriceMethodID
						AND IMWE.RecordType = @rectype
						AND ISNULL(dbo.IMWE.UploadVal,'') NOT IN ('C','T','F');
				END;				
				
/**********Price  *************/  
				IF @PriceID <> 0 AND (ISNULL(@OverwritePrice, 'Y') = 'Y' OR @IsEmptyPrice='Y' )
				BEGIN
					SELECT @Price = null
					UPDATE IMWE
					SET IMWE.UploadVal = @Price
					WHERE IMWE.ImportTemplate=@ImportTemplate 
						AND IMWE.ImportId=@ImportId 
						AND IMWE.RecordSeq=@currrecseq
						AND IMWE.Identifier = @PriceID
						AND IMWE.RecordType = @rectype;
					SET @IsEmptyPrice=CASE WHEN @Price IS NULL THEN 'Y' ELSE 'N' END;
				END;
-- validation				
				IF @PriceID <> 0 AND @IsEmptyPrice='N'
				BEGIN
					UPDATE IMWE
					SET IMWE.UploadVal = '** Invalid Price must be numeric'
					WHERE IMWE.ImportTemplate=@ImportTemplate 
						AND IMWE.ImportId=@ImportId 
						AND IMWE.RecordSeq=@currrecseq
						AND IMWE.Identifier = @PriceID
						AND IMWE.RecordType = @rectype
						AND ISNUMERIC(ISNULL(dbo.IMWE.UploadVal,0)) =0;
				END;	
				
/**********Service  ******* Required ******/  -- select Service from SMWorkOrderScope
				IF @ServiceID <> 0  AND (ISNULL(@OverwriteService, 'Y') = 'Y' OR @IsEmptyService='Y' )
				BEGIN;
					IF @Agreement IS NULL 
						SELECT  @Service = NULL
					Else
						SELECT @Service = 1
					UPDATE IMWE  
					SET IMWE.UploadVal = @Service
					WHERE IMWE.ImportTemplate=@ImportTemplate  
						AND IMWE.ImportId=@ImportId 
						AND IMWE.RecordSeq=@currrecseq
						AND IMWE.Identifier = @ServiceID
						AND IMWE.RecordType = @rectype
						AND ISNULL(dbo.IMWE.UploadVal,0)<>ISNULL(@Service,0);
					SET @IsEmptyService=CASE WHEN @Service IS NULL THEN 'Y' ELSE 'N' END;
				END;

/********** Validate Service  ******* Required ******/  
				IF @ServiceID <> 0  AND (@IsEmptyService='N' )
				BEGIN;
					UPDATE IMWE  
					SET IMWE.UploadVal = '** Service must be numeric'
					WHERE IMWE.ImportTemplate=@ImportTemplate 
						AND IMWE.ImportId=@ImportId 
						AND IMWE.RecordSeq=@currrecseq
						AND IMWE.Identifier = @ServiceID
						AND IMWE.RecordType = @rectype
						AND ISNUMERIC(ISNULL(dbo.IMWE.UploadVal,0))=0 ;
				END;

				
/**********UseAgreementRates  *************/  
				IF @UseAgreementRatesID <> 0 AND (ISNULL(@OverwriteUseAgreementRates, 'Y') = 'Y'  OR @IsEmptyUseAgreementRates='Y')
				BEGIN;
					--SELECT CASE WHEN @Agreement IS NULL THEN NULL
					--			WHEN @Agreement IS NOT NULL AND @PriceMethod='T' THEN 'N' 
					--			ELSE NULL END;
					SELECT @UseAgreementRates='N'  -- Use Agreement Rates should Always default to N. Unless overridden by the import.
					UPDATE IMWE
					SET IMWE.UploadVal = @UseAgreementRates
					WHERE IMWE.ImportTemplate=@ImportTemplate 
						AND IMWE.ImportId=@ImportId 
						AND IMWE.RecordSeq=@currrecseq
						AND IMWE.Identifier = @UseAgreementRatesID
						AND IMWE.RecordType = @rectype;
				END;

-- validate UseAgreementRates
				IF @UseAgreementRatesID <> 0
				BEGIN;
					SELECT @msg=NULL, @rc=0
					IF  @Agreement IS  NULL AND @UseAgreementRates ='Y'
						SELECT @rc=1, @msg='** Invalid - Can not use agreement rates.' 
					ELSE IF ISNULL(@UseAgreementRates,'') NOT IN ('Y','N')
						SELECT @rc=1,@msg='** Invalid - should be Y or N'
					IF @rc<>0
						UPDATE IMWE
						SET IMWE.UploadVal = @msg
						WHERE IMWE.ImportTemplate=@ImportTemplate 
							AND IMWE.ImportId=@ImportId 
							AND IMWE.RecordSeq=@currrecseq
							AND IMWE.Identifier = @UseAgreementRatesID
							AND IMWE.RecordType = @rectype
				END;
				
 -- Get Next RecSeq
 getnextrecseq:
 
                SELECT  @currrecseq = @Recseq;
                SELECT  @counter = @counter + 1;
                /* Peformance improvement -rebuild index every 500 records */
				IF @counter/500.0 = Round(@counter/500.0,0)
					BEGIN
						ALTER INDEX ALL ON dbo.IMWE
						REBUILD WITH (FILLFACTOR = 50, SORT_IN_TEMPDB = ON,
						STATISTICS_NORECOMPUTE = ON);
					END;
            END;		--End SET DEFAULT VALUE process
        END;		-- End @complete Loop, Last IMWE record has been processed

    CLOSE WorkEditCursor;
    DEALLOCATE WorkEditCursor;
	SELECT @rcode=0;

/** EXIT **/
    vspexit:
    SELECT  @msg = ISNULL(@desc, 'Detail ') + CHAR(13) + CHAR(13)
            + '[vspIMVPDefaultsSMWOScope]';

    RETURN @rcode;

GO
GRANT EXECUTE ON  [dbo].[vspIMVPDefaultsSMWOScope] TO [public]
GO
