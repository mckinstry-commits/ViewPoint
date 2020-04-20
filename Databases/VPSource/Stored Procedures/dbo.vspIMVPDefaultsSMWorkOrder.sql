SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspIMVPDefaultsSMWorkOrder]

/***********************************************************
* CREATED BY:   Jim Emery  TK-18465 10/18/2012
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
    (
     @Company bCompany
    ,@ImportId VARCHAR(20)
    ,@ImportTemplate VARCHAR(20)
    ,@Form VARCHAR(20)
    ,@rectype VARCHAR(30)
    ,@msg VARCHAR(120) OUTPUT
    )
AS 
    SET NOCOUNT ON;

	DECLARE @rc INT;
    DECLARE @rcode INT;
    DECLARE @desc VARCHAR(120);
    DECLARE @status INT;
    DECLARE @defaultvalue VARCHAR(30);

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


/* Working Variables */
    DECLARE @ContactName		VARCHAR(60);
    DECLARE @ContactPhone		VARCHAR(20);
    DECLARE @CostingMethod 		VARCHAR(10);
    DECLARE @CustGroup 			bGroup;
    DECLARE @Customer 			bCustomer;
    DECLARE @Description 		VARCHAR(8000);
    DECLARE @EnteredBy 			bVPUserName;
    DECLARE @EnteredDateTime	DATETIME;
    DECLARE @IsNew 				TINYINT;  -- dont make it a bit;
    DECLARE @JCCo 				bCompany;
    DECLARE @Job 				bJob;
    DECLARE @LeadTechnician 	VARCHAR(15);
    DECLARE @Notes 				VARCHAR(8000);
    DECLARE @RequestedBy 		VARCHAR(50);
    DECLARE @RequestedByPhone	bPhone;
    DECLARE @RequestedDate 		DATETIME;
    DECLARE @RequestedTime 		DATETIME;
    DECLARE @SMCo 				bCompany;
    DECLARE @ServiceCenter 		VARCHAR(10);
    DECLARE @ServiceSite 		VARCHAR(20);
    DECLARE @WOStatus 			TINYINT;
    DECLARE @WorkOrder 			INT;
    DECLARE @smssCustGroup 			bGroup;
    DECLARE @smssCustomer 			bCustomer;
    DECLARE @smssJCCo 				bCompany;
    DECLARE @smssJob 				bJob;
    DECLARE @smssDefaultServiceCenter VARCHAR(10)
    DECLARE @smssDefaultContactGroup bGroup;
    DECLARE @smssDefaultContactSeq 	INT
    DECLARE @smssCostMethod 		VARCHAR(10);
    DECLARE @smssActive 			bYN;
    DECLARE @smssPhone 				VARCHAR(20);
    DECLARE @smssType 				VARCHAR(10);
    DECLARE @hqContactName 			VARCHAR(60);
    DECLARE @hqContactPhone			VARCHAR(20);
    DECLARE @MaxWorkOrder 			INT;
    DECLARE @MaxIMWorkOrder 		INT;

/* Cursor variables */
    DECLARE @Recseq 				INT; 
    DECLARE @Tablename 				VARCHAR(20);
    DECLARE @Column 				VARCHAR(30);
    DECLARE @Uploadval 				VARCHAR(60);
    DECLARE @Ident 					INT;
    DECLARE @valuelist 				VARCHAR(255);
    DECLARE @complete 				INT;
    DECLARE @counter 				INT;
    DECLARE @oldrecseq 				INT;
    DECLARE @currrecseq 			INT;
  
--Identifiers
    DECLARE @ContactNameID 			INT;
    DECLARE @ContactPhoneID 		INT;
    DECLARE @CostingMethodID 		INT;
    DECLARE @CustGroupID 			INT;
    DECLARE @CustomerID 			INT;
    DECLARE @DescriptionID 			INT;
    DECLARE @EnteredByID 			INT;
    DECLARE @EnteredDateTimeID 		INT;
    DECLARE @IsNewID 				INT;
    DECLARE @JCCoID 				INT;
    DECLARE @JobID 					INT;
    DECLARE @LeadTechnicianID 		INT;
    DECLARE @NotesID 				INT;
    DECLARE @RequestedByID 			INT;
    DECLARE @RequestedByPhoneID 	INT;
    DECLARE @RequestedDateID 		INT;
    DECLARE @RequestedTimeID 		INT;
    DECLARE @SMCoID 				INT;
    DECLARE @ServiceCenterID 		INT;
    DECLARE @ServiceSiteID 			INT;
    DECLARE @WOStatusID 			INT;
    DECLARE @WorkOrderID 			INT;


/* Empty flags */ 
    DECLARE @IsEmptyContactName bYN;
    DECLARE @IsEmptyContactPhone bYN;
    DECLARE @IsEmptyCostingMethod bYN;
    DECLARE @IsEmptyCustGroup bYN;
    DECLARE @IsEmptyCustomer bYN;
    DECLARE @IsEmptyDescription bYN;
    DECLARE @IsEmptyIsNew bYN;
    DECLARE @IsEmptyJCCo bYN;
    DECLARE @IsEmptyJob bYN;
    DECLARE @IsEmptyLeadTechnician bYN;
    DECLARE @IsEmptyNotes bYN;
    DECLARE @IsEmptyRequestedBy bYN;
    DECLARE @IsEmptyRequestedByPhone bYN;
    DECLARE @IsEmptyRequestedDate bYN;
    DECLARE @IsEmptyRequestedTime bYN;
    DECLARE @IsEmptyServiceCenter bYN;
    DECLARE @IsEmptyServiceSite bYN;
    DECLARE @IsEmptyWOStatus bYN;
    DECLARE @IsEmptyWorkOrder bYN;


/* Overwrite flags */ 
    DECLARE @OverwriteContactName bYN;
    DECLARE @OverwriteContactPhone bYN;
    DECLARE @OverwriteCostingMethod bYN;
    DECLARE @OverwriteCustGroup bYN;
    DECLARE @OverwriteCustomer bYN;
    DECLARE @OverwriteDescription bYN;
    DECLARE @OverwriteEnteredBy bYN;
    DECLARE @OverwriteEnteredDateTime bYN;
    DECLARE @OverwriteIsNew bYN;
    DECLARE @OverwriteJCCo bYN;
    DECLARE @OverwriteJob bYN;
    DECLARE @OverwriteLeadTechnician bYN;
    DECLARE @OverwriteNotes bYN;
    DECLARE @OverwriteRequestedBy bYN;
    DECLARE @OverwriteRequestedByPhone bYN;
    DECLARE @OverwriteRequestedDate bYN;
    DECLARE @OverwriteRequestedTime bYN;
    DECLARE @OverwriteSMCo bYN;
    DECLARE @OverwriteServiceCenter bYN;
    DECLARE @OverwriteServiceSite bYN;
    DECLARE @OverwriteWOStatus bYN;
    DECLARE @OverwriteWorkOrder bYN;

/* Set Overwrite flags */ 
	SELECT  @OverwriteContactName = dbo.vfIMTemplateOverwrite(@ImportTemplate,@Form,'ContactName',@rectype);
	SELECT  @OverwriteContactPhone = dbo.vfIMTemplateOverwrite(@ImportTemplate,@Form,'ContactPhone',@rectype);
	SELECT  @OverwriteCostingMethod = dbo.vfIMTemplateOverwrite(@ImportTemplate,@Form,'CostingMethod',@rectype);
	SELECT  @OverwriteCustGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate,@Form, 'CustGroup',@rectype);
	SELECT  @OverwriteCustomer = dbo.vfIMTemplateOverwrite(@ImportTemplate,@Form, 'Customer',@rectype);
	SELECT  @OverwriteDescription = dbo.vfIMTemplateOverwrite(@ImportTemplate,@Form,'Description',@rectype);
	SELECT  @OverwriteEnteredBy = dbo.vfIMTemplateOverwrite(@ImportTemplate,@Form, 'EnteredBy',@rectype);
	SELECT  @OverwriteEnteredDateTime = dbo.vfIMTemplateOverwrite(@ImportTemplate,@Form,'EnteredDateTime',@rectype);
	SELECT  @OverwriteIsNew = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form,'IsNew', @rectype);
	SELECT  @OverwriteJCCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form,'JCCo', @rectype);
	SELECT  @OverwriteJob = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form,'Job', @rectype);
	SELECT  @OverwriteLeadTechnician = dbo.vfIMTemplateOverwrite(@ImportTemplate,@Form,'LeadTechnician',@rectype);
	SELECT  @OverwriteNotes = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form,'Notes', @rectype);
	SELECT  @OverwriteRequestedBy = dbo.vfIMTemplateOverwrite(@ImportTemplate,@Form,'RequestedBy',@rectype);
	SELECT  @OverwriteRequestedByPhone = dbo.vfIMTemplateOverwrite(@ImportTemplate,@Form,'RequestedByPhone',@rectype);
	SELECT  @OverwriteRequestedDate = dbo.vfIMTemplateOverwrite(@ImportTemplate,@Form,'RequestedDate',@rectype);
	SELECT  @OverwriteRequestedTime = dbo.vfIMTemplateOverwrite(@ImportTemplate,@Form,'RequestedTime',@rectype);
	SELECT  @OverwriteSMCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form,'SMCo', @rectype);
	SELECT  @OverwriteServiceCenter = dbo.vfIMTemplateOverwrite(@ImportTemplate,@Form,'ServiceCenter',@rectype);
	SELECT  @OverwriteServiceSite = dbo.vfIMTemplateOverwrite(@ImportTemplate,@Form,'ServiceSite',@rectype);
	SELECT  @OverwriteWOStatus = dbo.vfIMTemplateOverwrite(@ImportTemplate,@Form, 'WOStatus',@rectype);
	SELECT  @OverwriteWorkOrder = dbo.vfIMTemplateOverwrite(@ImportTemplate,@Form, 'WorkOrder', @rectype);


--YN
    DECLARE @ynContactName bYN;
    DECLARE @ynContactPhone bYN;
    DECLARE @ynCostingMethod bYN;
    DECLARE @ynCustGroup bYN;
    DECLARE @ynCustomer bYN;
    DECLARE @ynDescription bYN;
    DECLARE @ynEnteredBy bYN;
    DECLARE @ynEnteredDateTime bYN;
    DECLARE @ynIsNew bYN;
    DECLARE @ynJCCo bYN;
    DECLARE @ynJob bYN;
    DECLARE @ynLeadTechnician bYN;
    DECLARE @ynNotes bYN;
    DECLARE @ynRequestedBy bYN;
    DECLARE @ynRequestedByPhone bYN;
    DECLARE @ynRequestedDate bYN;
    DECLARE @ynRequestedTime bYN;
    DECLARE @ynSMCo bYN;
    DECLARE @ynServiceCenter bYN;
    DECLARE @ynServiceSite bYN;
    DECLARE @ynWOStatus bYN;
    DECLARE @ynWorkOrder bYN;

    SELECT  @ynContactName = 'N';
    SELECT  @ynContactPhone = 'N';
    SELECT  @ynCostingMethod = 'N';
    SELECT  @ynCustGroup = 'N';
    SELECT  @ynCustomer = 'N';
    SELECT  @ynDescription = 'N';
    SELECT  @ynEnteredBy = 'N';
    SELECT  @ynEnteredDateTime = 'N';
    SELECT  @ynIsNew = 'N';
    SELECT  @ynJCCo = 'N';
    SELECT  @ynJob = 'N';
    SELECT  @ynLeadTechnician = 'N';
    SELECT  @ynNotes = 'N';
    SELECT  @ynRequestedBy = 'N';
    SELECT  @ynRequestedByPhone = 'N';
    SELECT  @ynRequestedDate = 'N';
    SELECT  @ynRequestedTime = 'N';
    SELECT  @ynSMCo = 'N';
    SELECT  @ynServiceCenter = 'N';
    SELECT  @ynServiceSite = 'N';
    SELECT  @ynWOStatus = 'N';
    SELECT  @ynWorkOrder = 'N';

 
/***** GET COLUMN IDENTIFIERS -  YN field: 
  Y means ONLY when [Use Viewpoint Default] IS set.
  N means RETURN Identifier regardless of [Use Viewpoint Default] IS set 
*******/ 
    SELECT  @ContactNameID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form,  'ContactName', @rectype,  'N');
    SELECT  @ContactPhoneID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ContactPhone', @rectype, 'N');
    SELECT  @CostingMethodID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CostingMethod', @rectype, 'N');
    SELECT  @CustGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CustGroup', @rectype, 'N');
    SELECT  @CustomerID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Customer', @rectype, 'N');
    SELECT  @DescriptionID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Description', @rectype, 'Y');
    SELECT  @EnteredByID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'EnteredBy', @rectype, 'N');
    SELECT  @EnteredDateTimeID = dbo.bfIMTemplateDefaults(@ImportTemplate,@Form,'EnteredDateTime', @rectype, 'N');
    SELECT  @IsNewID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'IsNew', @rectype, 'N');
    SELECT  @JCCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'JCCo', @rectype, 'N');
    SELECT  @JobID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Job', @rectype, 'N');
    SELECT  @LeadTechnicianID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'LeadTechnician', @rectype, 'N');
    SELECT  @NotesID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Notes', @rectype, 'Y');
    SELECT  @RequestedByID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RequestedBy', @rectype, 'N');
    SELECT  @RequestedByPhoneID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form,'RequestedByPhone', @rectype, 'N');
    SELECT  @RequestedDateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RequestedDate', @rectype, 'N');
    SELECT  @RequestedTimeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RequestedTime', @rectype, 'N');
    SELECT  @SMCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SMCo', @rectype, 'N');
    SELECT  @ServiceCenterID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ServiceCenter', @rectype, 'N')
    SELECT  @ServiceSiteID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ServiceSite', @rectype, 'N');
    SELECT  @WOStatusID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'WOStatus', @rectype, 'N');
    SELECT  @WorkOrderID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'WorkOrder', @rectype, 'N');

 
/****
	Columns that can be updated to ALL imported records as a set.
	The value IS NOT unique to the individual imported record. 
****/
 
-- Use default company if SMCo is null or Overwrite='Y'
    IF @SMCoID IS NOT NULL 
        BEGIN
	--Use Viewpoint Default = Y AND Overwrite Import Value = Y  
	--(Set ALL import records to this Company)
            UPDATE  dbo.IMWE
            SET     dbo.IMWE.UploadVal = @Company
            WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
                    AND IMWE.ImportId = @ImportId
                    AND dbo.IMWE.Identifier = @SMCoID
                    AND ( ISNULL(@OverwriteSMCo, 'Y') = 'Y'
                          OR ISNULL(UploadVal, '') = '' )
                    AND dbo.IMWE.RecordType = @rectype;
        END;
        
 -- validate
    IF @SMCoID IS NOT NULL 
		BEGIN;
			UPDATE  dbo.IMWE
			SET     dbo.IMWE.UploadVal = '** Invalid SM Company'
			WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
					AND IMWE.ImportId = @ImportId
					AND dbo.IMWE.Identifier = @SMCoID
					AND dbo.IMWE.RecordType = @rectype
					AND dbo.IMWE.UploadVal NOT IN
						(SELECT CONVERT(VARCHAR(10),vSMCO.SMCo)
							FROM dbo.vSMCO);
		END;
         


/**********EnteredDateTime  *************/
    IF @EnteredDateTimeID <> 0 
        BEGIN
            SELECT  @msg = CONVERT(VARCHAR(20), GETDATE(), 20);
            UPDATE  dbo.IMWE
            SET     dbo.IMWE.UploadVal = @msg
            WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
                    AND dbo.IMWE.ImportId = @ImportId
                    AND dbo.IMWE.Identifier = @EnteredDateTimeID
                    AND dbo.IMWE.RecordType = @rectype
                    AND ( ISNULL(@OverwriteEnteredDateTime, 'Y') = 'Y'
                          OR UploadVal IS null);
                          
    -- validate
            SELECT  @msg = CONVERT(VARCHAR(20), GETDATE(), 20);
            UPDATE  dbo.IMWE
            SET     dbo.IMWE.UploadVal = 'Invalid Entered Date Time is not a date'
            WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
                    AND dbo.IMWE.ImportId = @ImportId
                    AND dbo.IMWE.Identifier = @EnteredDateTimeID
                    AND dbo.IMWE.RecordType = @rectype
                    AND ISDATE(ISNULL(UploadVal,'1/1/2000'))=0;   
        END;
  
/**********EnteredBy  *************/  
    IF @EnteredByID <> 0 
        BEGIN
            SELECT  @msg = SUSER_SNAME(); 
            UPDATE  dbo.bIMWENotes
            SET     dbo.bIMWENotes.UploadVal = @msg
            WHERE   dbo.bIMWENotes.ImportTemplate = @ImportTemplate
                    AND dbo.bIMWENotes.ImportId = @ImportId
                    AND dbo.bIMWENotes.Identifier = @EnteredByID
                    AND dbo.bIMWENotes.RecordType = @rectype
                    AND ( ISNULL(@OverwriteEnteredBy, 'Y') = 'Y'
                          OR bIMWENotes.UploadVal IS NULL);
        END;

 /********** Requested Date Validation *************/
     IF @RequestedDateID <> 0 
        BEGIN  
            UPDATE  dbo.IMWE
            SET     dbo.IMWE.UploadVal = 'Invalid RequestedDate is not a date'
            WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
                    AND dbo.IMWE.ImportId = @ImportId
                    AND dbo.IMWE.Identifier = @RequestedDateID
                    AND dbo.IMWE.RecordType = @rectype
                    AND ISDATE(ISNULL(UploadVal,'1/1/2000'))=0;   
        END;
  

/********* Begin default process. *******
 Multiple cursor records make up a single Import record
 determined BY a change in the RecSeq value.
 New RecSeq signals the beginning of the NEXT Import record. 
*/

    DECLARE WorkEditCursor CURSOR LOCAL FAST_FORWARD
    FOR
        SELECT  dbo.IMWE.RecordSeq
               ,dbo.IMWE.Identifier
               ,DDUD.TableName
               ,DDUD.ColumnName
               ,dbo.IMWE.UploadVal
        FROM    dbo.IMWE WITH ( NOLOCK )
        INNER JOIN DDUD WITH ( NOLOCK )
                ON dbo.IMWE.Identifier = DDUD.Identifier
                   AND DDUD.Form = dbo.IMWE.Form
        WHERE   dbo.IMWE.ImportId = @ImportId
                AND dbo.IMWE.ImportTemplate = @ImportTemplate
                AND dbo.IMWE.Form = @Form
                AND dbo.IMWE.RecordType = @rectype
        ORDER BY dbo.IMWE.RecordSeq
               ,dbo.IMWE.Identifier;
    
    OPEN WorkEditCursor;

    FETCH NEXT FROM WorkEditCursor INTO @Recseq, @Ident, @Tablename, @Column,
        @Uploadval;

    SELECT  @currrecseq = @Recseq
           ,@complete = 0
           ,@counter = 1;

/***********Start Loop *******************/
    WHILE @complete = 0 
        BEGIN

            IF @@fetch_status <> 0 
                SELECT  @Recseq = -1;

            IF @Recseq = @currrecseq  --Check if a new record has started
                BEGIN
	/***** GET UPLOADED VALUES FOR THIS IMPORT RECORD ********/
	/* For each imported record:  (Each imported record has multiple records
	   in the dbo.IMWE table representing columns of the import record)
       Cursor will cycle through each column of an imported record 
	   AND set the imported value INTO a variable that could be used 
	   during the defaulting process later IF desired.  
	   
	   The imported value here IS only needed IF the value will be 
	   used to help determine another default value in some way. */
                    IF @Column = 'CustGroup'  
						If ISNUMERIC(@Uploadval) = 1 
							SELECT  @CustGroup = CONVERT(INT, @Uploadval)
						ELSE
							SELECT  @CustGroup = null;
                    IF @Column = 'Customer'  
						IF ISNUMERIC(@Uploadval) = 1 
							SELECT  @Customer = CONVERT(INT, @Uploadval)
						ELSE
							SELECT  @Customer = NULL;
                    IF @Column = 'JCCo'  
                    	IF ISNUMERIC(@Uploadval) = 1 
							SELECT  @JCCo = CONVERT(INT, @Uploadval)
						ELSE
							SELECT  @JCCo = NULL;
                    IF @Column = 'SMCo'    
                    	IF ISNUMERIC(@Uploadval) = 1 
							SELECT  @SMCo = CONVERT(INT, @Uploadval)
						ELSE
							SELECT  @SMCo = NULL;
                    IF @Column = 'WOStatus'   
                    	IF ISNUMERIC(@Uploadval) = 1 
							SELECT  @WOStatus = CONVERT(INT, @Uploadval)
						ELSE
							SELECT  @WOStatus = NULL;
                    IF @Column = 'WorkOrder'   
                    	IF ISNUMERIC(@Uploadval) = 1 
							SELECT  @WorkOrder = CONVERT(INT, @Uploadval)
						ELSE
							SELECT  @WorkOrder = NULL;
                    IF @Column = 'IsNew'   
                    	IF ISNUMERIC(@Uploadval) = 1 
							SELECT  @IsNew = CONVERT(INT, @Uploadval)
						ELSE
							SELECT  @IsNew = NULL;
                    IF @Column = 'ContactName' 
                        SELECT  @ContactName = @Uploadval;
                    IF @Column = 'ContactPhone' 
                        SELECT  @ContactPhone = @Uploadval;
                    IF @Column = 'CostingMethod' 
                        SELECT  @CostingMethod = @Uploadval;

                    IF @Column = 'Job' 
                        SELECT  @Job = @Uploadval;
                    IF @Column = 'LeadTechnician' 
                        SELECT  @LeadTechnician = @Uploadval;
                    IF @Column = 'RequestedBy' 
                        SELECT  @RequestedBy = @Uploadval;
                    IF @Column = 'RequestedByPhone' 
                        SELECT  @RequestedByPhone = @Uploadval;
                    IF @Column = 'ServiceCenter' 
                        SELECT  @ServiceCenter = @Uploadval;
                    IF @Column = 'ServiceSite' 
                        SELECT  @ServiceSite = @Uploadval;
                    IF @Column = 'ContactName' 
                        SET @IsEmptyContactName = CASE WHEN @Uploadval IS NULL
                                                       THEN 'Y'
                                                       ELSE 'N'
                                                  END;
                    IF @Column = 'ContactPhone' 
                        SET @IsEmptyContactPhone = CASE WHEN @Uploadval IS NULL
                                                        THEN 'Y'
                                                        ELSE 'N'
                                                   END;
                    IF @Column = 'CostingMethod' 
                        SET @IsEmptyCostingMethod = CASE WHEN @Uploadval IS NULL
                                                         THEN 'Y'
                                                         ELSE 'N'
                                                    END;
                    IF @Column = 'CustGroup' 
                        SET @IsEmptyCustGroup = CASE WHEN @Uploadval IS NULL
                                                     THEN 'Y'
                                                     ELSE 'N'
                                                END;
                    IF @Column = 'Customer' 
                        SET @IsEmptyCustomer = CASE WHEN @Uploadval IS NULL
                                                    THEN 'Y'
                                                    ELSE 'N'
                                               END;
                    IF @Column = 'IsNew' 
                        SET @IsEmptyIsNew = CASE WHEN @Uploadval IS NULL
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
                    IF @Column = 'LeadTechnician' 
                        SET @IsEmptyLeadTechnician = CASE WHEN @Uploadval IS NULL
                                                          THEN 'Y'
                                                          ELSE 'N'
                                                     END;
		--IF @Column='Notes'
		--	   SET @IsEmptyNotes = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
                    IF @Column = 'RequestedBy' 
                        SET @IsEmptyRequestedBy = CASE WHEN @Uploadval IS NULL
                                                       THEN 'Y'
                                                       ELSE 'N'
                                                  END;
                    IF @Column = 'RequestedByPhone' 
                        SET @IsEmptyRequestedByPhone = CASE WHEN @Uploadval IS NULL
                                                            THEN 'Y'
                                                            ELSE 'N'
                                                       END;
                    IF @Column = 'ServiceCenter' 
                        SET @IsEmptyServiceCenter = CASE WHEN @Uploadval IS NULL
                                                         THEN 'Y'
                                                         ELSE 'N'
                                                    END;
                    IF @Column = 'ServiceSite' 
                        SET @IsEmptyServiceSite = CASE WHEN @Uploadval IS NULL
                                                       THEN 'Y'
                                                       ELSE 'N'
                                                  END;
                    IF @Column = 'WOStatus' 
                        SET @IsEmptyWOStatus = CASE WHEN @Uploadval IS NULL
                                                    THEN 'Y'
                                                    ELSE 'N'
                                               END;
                    IF @Column = 'WorkOrder' 
                        SET @IsEmptyWorkOrder = CASE WHEN @Uploadval IS NULL
                                                     THEN 'Y'
                                                     ELSE 'N'
                                                END;

                    IF @@fetch_status <> 0 
                        SELECT  @complete = 1;	--set only after ALL records in dbo.IMWE have been processed

                    SELECT  @oldrecseq = @Recseq;

                    FETCH NEXT FROM WorkEditCursor 
			INTO @Recseq, @Ident, @Tablename, @Column, @Uploadval;
                END;
            ELSE 
                BEGIN
	/* A DIFFERENT import RecordSeq has been detected.  
	   Before moving on, set the default values for our previous Import Record. */
 
/********* SET DEFAULT VALUES ************
 At this moment, all columns of a single imported record have been processed above.
 The defaults for this single imported record will be set below before the 
 cursor moves on to the columns of the NEXT imported record.  */
 

  
/**********WorkOrder  ******* Required ******/  
-- Only generate new number if empty
					-- check when supplied a numeric work order
					IF @WorkOrderID <> 0 AND @IsEmptyWorkOrder = 'N'   -- value supplied
										 AND @WorkOrder IS NOT NULL  --  a numeric work Order			 
						BEGIN;
							IF EXISTS (SELECT  WorkOrder 
								FROM dbo.vSMWorkOrder
								WHERE SMCo=@SMCo AND WorkOrder=@WorkOrder)
								BEGIN;
									UPDATE  dbo.IMWE
									SET     dbo.IMWE.UploadVal = '** Invalid only new Work Orders allowed'
									WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
											AND dbo.IMWE.ImportId = @ImportId
											AND dbo.IMWE.RecordSeq = @currrecseq
											AND dbo.IMWE.Identifier = @WorkOrderID
											AND dbo.IMWE.RecordType = @rectype;
									GOTO GetNext
								END;
							END;
                        
					IF @WorkOrderID <> 0 AND @IsEmptyWorkOrder = 'N' AND @WorkOrder IS NULL -- 
                        BEGIN;
							UPDATE  dbo.IMWE
							SET     dbo.IMWE.UploadVal = '** Invalid Work Order must be numeric'
							WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
									AND dbo.IMWE.ImportId = @ImportId
									AND dbo.IMWE.RecordSeq = @currrecseq
									AND dbo.IMWE.Identifier = @WorkOrderID
									AND dbo.IMWE.RecordType = @rectype;
							SELECT @WorkOrder=NULL, @IsEmptyWorkOrder='Y'
							GOTO GetNext
                        END;								
								
                                                
                    IF @WorkOrderID <> 0 AND ( ISNULL(@IsEmptyWorkOrder, 'Y') = 'Y' ) 
                        BEGIN
                            SELECT  @MaxWorkOrder = 0
                                   ,@MaxIMWorkOrder = 0;
                            SELECT  @MaxWorkOrder = MAX(WorkOrder) + 1
                            FROM    SMWorkOrder WITH ( NOLOCK )
                            WHERE   SMCo = @SMCo;
                            IF ISNULL(@MaxWorkOrder, 0) = 0 
                                SELECT  @MaxWorkOrder = 1
                                
                            SELECT  @MaxIMWorkOrder = MAX(UploadVal) + 1
                            FROM    dbo.IMWE
                            WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
                                    AND dbo.IMWE.ImportId = @ImportId
                                    AND dbo.IMWE.Identifier = @WorkOrderID
                                    AND dbo.IMWE.RecordType = @rectype
                                    AND ISNUMERIC(UploadVal)=1;
                            IF ISNULL(@MaxIMWorkOrder, 0) = 0 
                                SELECT  @MaxIMWorkOrder = 1
		
                            SELECT  @WorkOrder = CASE WHEN @MaxWorkOrder > @MaxIMWorkOrder
                                                      THEN @MaxWorkOrder
                                                      ELSE @MaxIMWorkOrder
                                                 END
                            UPDATE  dbo.IMWE
                            SET     dbo.IMWE.UploadVal = @WorkOrder
                            WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
                                    AND dbo.IMWE.ImportId = @ImportId
                                    AND dbo.IMWE.RecordSeq = @currrecseq
                                    AND dbo.IMWE.Identifier = @WorkOrderID
                                    AND dbo.IMWE.RecordType = @rectype;
                        END;

/********** IsNew  *************/
/* if other Work Completed exists then this is not new else it is new*/
/* update regardless of what is in the import template*/ 
                    IF @IsNewID <> 0  
                       BEGIN
                            UPDATE  dbo.IMWE
                            SET     dbo.IMWE.UploadVal = CASE WHEN KeyID IS NULL THEN '1' ELSE '0' END
                            FROM dbo.IMWE 
                            CROSS JOIN (SELECT MAX(KeyID) AS KeyID FROM dbo.SMWorkCompleted 
								WHERE SMCo=@SMCo AND WorkOrder=@WorkOrder
								) AS SMWorkCompleted  
                            WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
                                    AND IMWE.ImportId = @ImportId
                                    AND dbo.IMWE.RecordSeq = @currrecseq
                                    AND dbo.IMWE.Identifier = @IsNewID
                                    AND dbo.IMWE.RecordType = @rectype
                        END;
                        
                        
/**********Validate ServiceSite  ******* 
 get default values from service site and contact info ******/ 
                    IF @ServiceSiteID <> 0 
                        BEGIN
                            SELECT  @smssCustGroup = NULL --read only
                                   ,@smssCustomer = NULL --read only
                                   ,@smssJCCo = NULL --read only
                                   ,@smssJob = NULL --read only 
                                   ,@smssDefaultServiceCenter = NULL
                                   ,@smssDefaultContactGroup = NULL
                                   ,@smssDefaultContactSeq = NULL
                                   ,@smssCostMethod = NULL
                                   ,@smssActive = NULL
                                   ,@smssPhone = NULL
                                   ,@smssType = NULL
		
                            SELECT  @ServiceSite = dbo.vSMServiceSite.ServiceSite
                                   ,@smssCustGroup = dbo.vSMServiceSite.CustGroup --read only
                                   ,@smssCustomer = dbo.vSMServiceSite.Customer --read only
                                   ,@smssJCCo = dbo.vSMServiceSite.JCCo --read only
                                   ,@smssJob = dbo.vSMServiceSite.Job --read only 
                                   ,@smssDefaultServiceCenter = dbo.vSMServiceSite.DefaultServiceCenter
                                   ,@smssDefaultContactGroup = dbo.vSMServiceSite.ContactGroup
                                   ,@smssDefaultContactSeq = dbo.vSMServiceSite.ContactSeq
                                   ,@smssCostMethod = dbo.vSMServiceSite.CostingMethod
                                   ,@smssActive = dbo.vSMServiceSite.Active
                                   ,@smssPhone = dbo.vSMServiceSite.Phone
                                   ,@smssType = dbo.vSMServiceSite.Type
                            FROM    dbo.vSMServiceSite WITH ( NOLOCK )
                            WHERE   SMCo = @SMCo
                                    AND ServiceSite = @ServiceSite;
                            IF @@rowcount=0
                                BEGIN
                                    UPDATE  dbo.IMWE
                                    SET     dbo.IMWE.UploadVal = '** Invalid Service Site **'
                                    WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
                                            AND dbo.IMWE.ImportId = @ImportId
                                            AND dbo.IMWE.RecordSeq = @currrecseq
                                            AND dbo.IMWE.Identifier = @ServiceSiteID
                                            AND dbo.IMWE.RecordType = @rectype;
                                END
                        END;

/**********ServiceCenter  ******* Required ******/ 
/* if default='y' make it default service center
   if default='n' use import value*/ 
                    IF @ServiceCenterID <> 0
                        AND ( ISNULL(@OverwriteServiceCenter, 'Y') = 'Y'
                              OR ISNULL(@IsEmptyServiceCenter, 'Y') = 'Y' ) 
                        BEGIN
                            SELECT  @ServiceCenter = @smssDefaultServiceCenter;
                            UPDATE  dbo.IMWE
							SET     dbo.IMWE.UploadVal = @ServiceCenter
							WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
									AND dbo.IMWE.ImportId = @ImportId
									AND dbo.IMWE.RecordSeq = @currrecseq
									AND dbo.IMWE.Identifier = @ServiceCenterID
									AND dbo.IMWE.RecordType = @rectype;
							SELECT @IsEmptyServiceCenter=CASE WHEN @ServiceCenter IS NULL THEN 'Y' ELSE 'N' END
                        END;

-- validate
		      IF @ServiceCenterID <> 0
					BEGIN;
						SELECT  @msg = ServiceCenter
						FROM    dbo.vSMServiceCenter WITH ( NOLOCK )
						WHERE   vSMServiceCenter.SMCo = @SMCo
								AND dbo.vSMServiceCenter.ServiceCenter = @ServiceCenter;
						IF @@rowcount = 0 
							BEGIN;
							UPDATE  dbo.IMWE
							SET     dbo.IMWE.UploadVal = '** Invalid Service Center **'
							WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
									AND dbo.IMWE.ImportId = @ImportId
									AND dbo.IMWE.RecordSeq = @currrecseq
									AND dbo.IMWE.Identifier = @ServiceCenterID
									AND dbo.IMWE.RecordType = @rectype;
							END;
					END;


/**********CustGroup  ******* Required ******/  
                    IF @CustGroupID <> 0 -- Cust group must match Service Site
                        BEGIN;
                            SELECT  @CustGroup = @smssCustGroup;
							UPDATE  dbo.IMWE
								SET     dbo.IMWE.UploadVal =@CustGroup
								WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
										AND dbo.IMWE.ImportId = @ImportId
										AND dbo.IMWE.RecordSeq = @currrecseq
										AND dbo.IMWE.Identifier = @CustGroupID
										AND dbo.IMWE.RecordType = @rectype;
							SET @IsEmptyCustGroup= CASE WHEN @CustGroup IS NULL THEN 'Y' ELSE 'N' END;										
-- validate
								
                            SELECT  @msg = Grp  
                            FROM    dbo.HQGP WITH ( NOLOCK )
                            WHERE   Grp = @CustGroup;
                            IF @@rowcount = 0 
								BEGIN;
								UPDATE  dbo.IMWE
								SET     dbo.IMWE.UploadVal ='** Invalid Customer Group **'
								WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
										AND dbo.IMWE.ImportId = @ImportId
										AND dbo.IMWE.RecordSeq = @currrecseq
										AND dbo.IMWE.Identifier = @CustGroupID
										AND dbo.IMWE.RecordType = @rectype;
								END;
                        END;

/**********Customer  *************/  
                    IF @CustomerID <> 0 AND @smssType = 'Customer' 
                        BEGIN
                            SELECT  @Customer = @smssCustomer;
							UPDATE  dbo.IMWE
							SET     dbo.IMWE.UploadVal = @Customer
							WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
									AND dbo.IMWE.ImportId = @ImportId
									AND dbo.IMWE.RecordSeq = @currrecseq
									AND dbo.IMWE.Identifier = @CustomerID
									AND dbo.IMWE.RecordType = @rectype;                          
                            
-- validate
                            SELECT  @msg = Customer
                            FROM    dbo.vSMCustomer WITH ( NOLOCK )
                            WHERE   dbo.vSMCustomer.CustGroup = @CustGroup
                                    AND dbo.vSMCustomer.Customer = @Customer;
                            IF @@rowcount = 0 
								BEGIN;
								UPDATE  dbo.IMWE
								SET     dbo.IMWE.UploadVal = '** Invalid Customer'
								WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
										AND dbo.IMWE.ImportId = @ImportId
										AND dbo.IMWE.RecordSeq = @currrecseq
										AND dbo.IMWE.Identifier = @CustomerID
										AND dbo.IMWE.RecordType = @rectype;
								END;
                        END;
                        

/** get contact defaults based on contact info */
                    SELECT  @hqContactName = null
                           ,@hqContactPhone = null -- clear out previous results
    
                    SELECT  @hqContactName = CASE WHEN dbo.HQContact.FirstName IS NOT NULL
                                                  THEN dbo.HQContact.FirstName+ ' '
                                                  ELSE ''
                                             END
                            + ISNULL(dbo.HQContact.LastName, '')
                           ,@hqContactPhone = ISNULL(dbo.HQContact.Phone, '')
                            + CASE WHEN dbo.HQContact.PhoneExtension IS NOT NULL
                                   THEN ' ' + dbo.HQContact.PhoneExtension
                                   ELSE ''
                              END
                    FROM    HQContact WITH ( NOLOCK )
                    WHERE   dbo.HQContact.ContactGroup = @smssDefaultContactGroup
                            AND dbo.HQContact.ContactSeq = @smssDefaultContactSeq;

		
/**********ContactName  *************/  
                    IF @ContactNameID <> 0
                        AND ( ISNULL(@OverwriteContactName, 'Y') = 'Y'
                              OR ISNULL(@IsEmptyContactName, 'Y') = 'Y' ) 
                        BEGIN	
                            SELECT  @ContactName = @hqContactName
                            UPDATE  dbo.IMWE
                            SET     dbo.IMWE.UploadVal = @ContactName
                            WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
                                    AND dbo.IMWE.ImportId = @ImportId
                                    AND dbo.IMWE.RecordSeq = @currrecseq
                                    AND dbo.IMWE.Identifier = @ContactNameID
                                    AND dbo.IMWE.RecordType = @rectype
                                    AND ISNULL(UploadVal, '') <> ISNULL(@ContactName,'');
                        END;

/**********ContactPhone  *************/  
                    IF @ContactPhoneID <> 0
                        AND ( ISNULL(@OverwriteContactPhone, 'Y') = 'Y'
                              OR ISNULL(@IsEmptyContactPhone, 'Y') = 'Y' ) 
                        BEGIN
                            SELECT  @ContactPhone = @hqContactPhone
                            UPDATE  dbo.IMWE
                            SET     dbo.IMWE.UploadVal = @ContactPhone
                            WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
                                    AND dbo.IMWE.ImportId = @ImportId
                                    AND dbo.IMWE.RecordSeq = @currrecseq
                                    AND dbo.IMWE.Identifier = @ContactPhoneID
                                    AND dbo.IMWE.RecordType = @rectype
                                    AND ISNULL(UploadVal, '') <> ISNULL(@ContactPhone, '');
                        END;


/**********Lead Technician  ******* Required ******/ 
-- no default 

/* validate LeadTechnician */
					IF @LeadTechnicianID <> 0 AND @LeadTechnician IS NOT null
						BEGIN 
						SELECT @msg=Technician
							FROM dbo.vSMTechnician WITH (NOLOCK)
							WHERE SMCo=@SMCo AND Technician = @LeadTechnician
							IF @@rowcount=0
								BEGIN
								UPDATE  dbo.IMWE
								SET     UploadVal = '** Invalid LeadTechnician **'
								WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
										AND dbo.IMWE.ImportId = @ImportId
										AND dbo.IMWE.RecordSeq = @currrecseq
										AND dbo.IMWE.Identifier = @LeadTechnicianID
										AND dbo.IMWE.RecordType = @rectype
								END;
						END;
                            
/**********WOStatus  ******* Required ******/  
                    IF @WOStatusID <> 0
                        AND ( ISNULL(@OverwriteWOStatus, 'Y') = 'Y'
                              OR ISNULL(@IsEmptyWOStatus, 'Y') = 'Y' ) 
                        BEGIN;
                            SELECT  @WOStatus = 0;
                            UPDATE  dbo.IMWE
                            SET     dbo.IMWE.UploadVal = @WOStatus
                            WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
                                    AND dbo.IMWE.ImportId = @ImportId
                                    AND dbo.IMWE.RecordSeq = @currrecseq
                                    AND dbo.IMWE.Identifier = @WOStatusID
                                    AND dbo.IMWE.RecordType = @rectype;
                        END;

/* validate WOStatus */
                    IF @WOStatusID <> 0
						BEGIN;
						UPDATE  dbo.IMWE
						SET     UploadVal = '** Invalid WO Status **/'
						WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
								AND dbo.IMWE.ImportId = @ImportId
								AND dbo.IMWE.RecordSeq = @currrecseq
								AND dbo.IMWE.Identifier = @WOStatusID
								AND dbo.IMWE.RecordType = @rectype
								AND ISNULL(UploadVal, 'z') NOT IN ( '0', '1', '2' );
						END;

/**********JCCo always equals the ServiceSite JCCo *************/  
                    IF @JCCoID <> 0 AND @smssType = 'Job' 
                        BEGIN
                            SELECT  @JCCo = @smssJCCo   
                            UPDATE  dbo.IMWE
                            SET     dbo.IMWE.UploadVal = @JCCo
                            WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
                                    AND dbo.IMWE.ImportId = @ImportId
                                    AND dbo.IMWE.RecordSeq = @currrecseq
                                    AND dbo.IMWE.Identifier = @JCCoID
                                    AND dbo.IMWE.RecordType = @rectype
                                    AND ISNULL(dbo.IMWE.UploadVal, '') <> CONVERT(VARCHAR(10),@JCCo);
                        END;

/**********Job always equals the ServiceSite Job *************/  
                    IF @JobID <> 0  
                        BEGIN;
                            SELECT @Job= CASE WHEN @smssType = 'Job' then @smssJob ELSE NULL end;
                            UPDATE  dbo.IMWE
								SET     dbo.IMWE.UploadVal = @Job
								WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
										AND dbo.IMWE.ImportId = @ImportId
										AND dbo.IMWE.RecordSeq = @currrecseq
										AND dbo.IMWE.Identifier = @JobID
										AND dbo.IMWE.RecordType = @rectype;
						END;
                            
/********** validate Job *************/   
                     IF @JobID <> 0 AND (@Job IS NOT null OR @smssType = 'Job')
                        BEGIN;                         
							SELECT  @msg = Job
							FROM    dbo.bJCJM WITH ( NOLOCK )
							WHERE   dbo.bJCJM.JCCo = @JCCo
									AND dbo.bJCJM.Job = @Job;
							IF @@rowcount = 0 
								BEGIN;
									UPDATE  dbo.IMWE
									SET     dbo.IMWE.UploadVal = '** Invalid Job **'
									WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
											AND dbo.IMWE.ImportId = @ImportId
											AND dbo.IMWE.RecordSeq = @currrecseq
											AND dbo.IMWE.Identifier = @JobID
											AND dbo.IMWE.RecordType = @rectype;
								END;
                        END;

/********** CostingMethod defaults the ServiceSite Costing Method *************/  
                    IF @CostingMethodID <> 0 
                        AND ( ISNULL(@OverwriteCostingMethod, 'Y') = 'Y'
                              OR ISNULL(@IsEmptyCostingMethod, 'Y') = 'Y' ) 
                        BEGIN
							SELECT @CostingMethod= 
								CASE WHEN @smssType = 'Job' then @smssCostMethod ELSE NULL end;
								UPDATE  dbo.IMWE
								SET     dbo.IMWE.UploadVal = @CostingMethod
								WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
										AND dbo.IMWE.ImportId = @ImportId
										AND dbo.IMWE.RecordSeq = @currrecseq
										AND dbo.IMWE.Identifier = @CostingMethodID
										AND dbo.IMWE.RecordType = @rectype;																END;
/********** Validate CostingMethod  *************/					
						IF @CostingMethodID <> 0  
						     BEGIN;
								SELECT @msg=NULL, @rc=0
								IF @smssType = 'Job' AND @CostingMethod NOT IN ( 'Cost', 'Revenue' )
									SELECT @rc=1, @msg='** Invalid - Should be Cost or Revenue' 
							    ELSE IF ISNULL(@smssType,'') <> 'Job' AND @CostingMethod IS NOT NULL
									SELECT @rc=1, @msg='** Invalid - Should be null' 														IF @rc<>0
									BEGIN                            
										UPDATE  dbo.IMWE
										SET     dbo.IMWE.UploadVal = @msg
										WHERE   dbo.IMWE.ImportTemplate = @ImportTemplate
												AND dbo.IMWE.ImportId = @ImportId
												AND dbo.IMWE.RecordSeq = @currrecseq
												AND dbo.IMWE.Identifier = @CostingMethodID
												AND dbo.IMWE.RecordType = @rectype;							
									END;
							END;
 -- Get Next RecSeq
 GetNext:
 
                    SELECT  @currrecseq = @Recseq;
                    SELECT  @counter = @counter + 1;
    
                END;		--End SET DEFAULT VALUE process
        END;		-- End @complete Loop, Last dbo.IMWE record has been processed

    CLOSE WorkEditCursor;
    DEALLOCATE WorkEditCursor;

--/* Set required (dollar) inputs to 0 WHERE not already set with some other value */    
--UPDATE dbo.IMWE
--SET dbo.IMWE.UploadVal = 0
--WHERE dbo.IMWE.ImportTemplate=@ImportTemplate AND dbo.IMWE.ImportId=@ImportId 
--	AND dbo.IMWE.RecordType = @rectype AND isnull(IMWE.UploadVal,'')=''
--	AND	(IMWE.Identifier = @?x? OR dbo.IMWE.Identifier = @?x? );
	-------------------------********************* add as many 0 values here as needed

/** EXIT **/
    vspexit:
    SELECT  @msg = ISNULL(@desc, 'Header ') + CHAR(13) + CHAR(13)
            + '[[vspIMVPDefaultsSMWorkOrder]';

    RETURN @rcode;
GO
GRANT EXECUTE ON  [dbo].[vspIMVPDefaultsSMWorkOrder] TO [public]
GO
