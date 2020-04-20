SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspIMVPDefaultsSMCustomer]

   /***********************************************************
    * CREATED BY:   Jim Emery  11/13/2012 TK-19537
    *
    * Usage:
    *	Used BY Imports to create defaults and validate SMCustomers.
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
   
	(   @Company bCompany, @ImportId varchar(20), @ImportTemplate varchar(20), 
   		@Form varchar(20), @rectype varchar(10), @msg varchar(120) output
    )
	AS
   
    SET NOCOUNT ON;
   
    DECLARE @rcode        int;
    DECLARE @desc         varchar(120);
    DECLARE @status       int;
    DECLARE @defaultvalue varchar(30);

  
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
    DECLARE @Active              bYN;
    DECLARE @BillToARCustomer    bCustomer;
    DECLARE @CustGroup           bGroup;
    DECLARE @Customer            bCustomer;
    DECLARE @CustomerPOSetting   char(1);
    DECLARE @InvoiceGrouping     char(1);
    DECLARE @InvoiceSummaryLevel char(1);
    DECLARE @Notes               varchar(8000);
    DECLARE @PrimaryTechnician   varchar(15);
    DECLARE @RateTemplate        varchar(10);
    DECLARE @ReportID            int;
    DECLARE @SMCo                bCompany;
    DECLARE @SMRateOverrideID    bigint;
    DECLARE @SMStandardItemDefaultID BIGINT;
    DECLARE @arcmActive			 CHAR(1);

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
    DECLARE @ActiveID              int;
    DECLARE @BillToARCustomerID    int;
    DECLARE @CustGroupID           int;
    DECLARE @CustomerID            int;
    DECLARE @CustomerPOSettingID   int;
    DECLARE @InvoiceGroupingID     int;
    DECLARE @InvoiceSummaryLevelID int;
    DECLARE @NotesID               int;
    DECLARE @PrimaryTechnicianID   int;
    DECLARE @RateTemplateID        int;
    DECLARE @ReportIDID            int;
    DECLARE @SMCoID                int;
    DECLARE @SMRateOverrideIDID    int;
    DECLARE @SMStandardItemDefaultIDID int; 

 
/* Empty flags */ 
    DECLARE @IsEmptyActive              bYN;
    DECLARE @IsEmptyBillToARCustomer    bYN;
    DECLARE @IsEmptyCustGroup           bYN;
    DECLARE @IsEmptyCustomer            bYN;
    DECLARE @IsEmptyCustomerPOSetting   bYN;
    DECLARE @IsEmptyInvoiceGrouping     bYN;
    DECLARE @IsEmptyInvoiceSummaryLevel bYN;
    DECLARE @IsEmptyNotes               bYN;
    DECLARE @IsEmptyPrimaryTechnician   bYN;
    DECLARE @IsEmptyRateTemplate        bYN;
    DECLARE @IsEmptyReportID            bYN;
    DECLARE @IsEmptySMCo                bYN;
    DECLARE @IsEmptySMRateOverrideID    bYN;
    DECLARE @IsEmptySMStandardItemDefaultID    bYN;
 
/* Overwrite flags */ 
    DECLARE @OverwriteActive                   bYN;
    DECLARE @OverwriteBillToARCustomer         bYN;
    DECLARE @OverwriteCustGroup                bYN;
    DECLARE @OverwriteCustomer                 bYN;
    DECLARE @OverwriteCustomerPOSetting        bYN;
    DECLARE @OverwriteInvoiceGrouping          bYN;
    DECLARE @OverwriteInvoiceSummaryLevel      bYN;
    DECLARE @OverwriteNotes                    bYN;
    DECLARE @OverwritePrimaryTechnician        bYN;
    DECLARE @OverwriteRateTemplate             bYN;
    DECLARE @OverwriteReportID                 bYN;
    DECLARE @OverwriteSMCo                     bYN;
    DECLARE @OverwriteSMRateOverrideID         bYN;
    DECLARE @OverwriteSMStandardItemDefaultID  bYN;

;
/* Set Overwrite flags */ 
    SELECT @OverwriteActive =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Active', @rectype);
    SELECT @OverwriteBillToARCustomer =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BillToARCustomer', @rectype);
    SELECT @OverwriteCustGroup =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CustGroup', @rectype);
    SELECT @OverwriteCustomer =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Customer', @rectype);
    SELECT @OverwriteCustomerPOSetting =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CustomerPOSetting', @rectype);
    SELECT @OverwriteInvoiceGrouping =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'InvoiceGrouping', @rectype);
    SELECT @OverwriteInvoiceSummaryLevel =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'InvoiceSummaryLevel', @rectype);
    SELECT @OverwriteNotes =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Notes', @rectype);
    SELECT @OverwritePrimaryTechnician =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PrimaryTechnician', @rectype);
    SELECT @OverwriteRateTemplate =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RateTemplate', @rectype);
    SELECT @OverwriteReportID =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ReportID', @rectype);
    SELECT @OverwriteSMCo =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SMCo', @rectype);
    SELECT @OverwriteSMRateOverrideID =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SMRateOverrideID', @rectype);
    SELECT @OverwriteSMStandardItemDefaultID =
        dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SMStandardItemDefaultID', @rectype);

 
 
/***** GET COLUMN IDENTIFIERS -  YN field: 
  Y means ONLY when [Use Viewpoint Default] IS set.
  N means RETURN Identifier regardless of [Use Viewpoint Default] IS set 
*******/ 
    SELECT @ActiveID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Active', @rectype, 'N');
    SELECT @BillToARCustomerID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'BillToARCustomer', @rectype, 'N');
    SELECT @CustGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CustGroup', @rectype, 'N');
    SELECT @CustomerID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Customer', @rectype, 'N');
    SELECT @CustomerPOSettingID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CustomerPOSetting', @rectype, 'N');
    SELECT @InvoiceGroupingID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'InvoiceGrouping', @rectype, 'N');
    SELECT @InvoiceSummaryLevelID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'InvoiceSummaryLevel', @rectype, 'N');
    SELECT @NotesID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Notes', @rectype, 'N');
    SELECT @PrimaryTechnicianID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PrimaryTechnician', @rectype, 'N');
    SELECT @RateTemplateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RateTemplate', @rectype, 'N');
    SELECT @ReportIDID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ReportID', @rectype, 'N');
    SELECT @SMCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SMCo', @rectype, 'N');
    SELECT @SMRateOverrideIDID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SMRateOverrideID', @rectype, 'N');
    SELECT @SMStandardItemDefaultIDID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SMStandardItemDefaultID', @rectype, 'N');
 
/* Columns that can be updated to ALL imported records as a set.
   The value IS NOT unique to the individual imported record. */
 
 
--Co
    IF @SMCoID IS NOT NULL AND (ISNULL(@OverwriteSMCo, 'Y') = 'Y')
	    BEGIN
	    --Use Viewpoint Default = Y AND Overwrite Import Value = Y  
	    --(Set ALL import records to this Company)
	    UPDATE IMWE
	    SET IMWE.UploadVal = @Company
	    WHERE IMWE.ImportTemplate=@ImportTemplate AND
		    IMWE.ImportId=@ImportId AND IMWE.Identifier = @SMCoID AND IMWE.RecordType = @rectype;
  	    END;

    IF @SMCoID IS NOT NULL AND (ISNULL(@OverwriteSMCo, 'Y') = 'N')
    	BEGIN
	    --[Use Viewpoint Default] = Y AND [Overwrite Import Value] = N  
    	--(Set to this Company only IF no import value exists)
    	UPDATE IMWE
    	SET IMWE.UploadVal = @Company
        WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId 
			AND IMWE.Identifier = @SMCoID AND IMWE.RecordType = @rectype
			AND IMWE.UploadVal IS NULL;
        END;
        
/**********InvoiceSummaryLevel  ******* Required ******/  
    IF @InvoiceSummaryLevelID <> 0 AND ISNULL(@OverwriteInvoiceSummaryLevel, 'Y') = 'Y'              
        BEGIN
            UPDATE IMWE
                SET IMWE.UploadVal = 'L'
                WHERE IMWE.ImportTemplate=@ImportTemplate 
                    AND IMWE.ImportId=@ImportId 
                    AND IMWE.RecordType = @rectype
                    AND IMWE.Identifier = @InvoiceSummaryLevelID;
        END;
        
   IF @InvoiceSummaryLevelID <> 0 AND ISNULL(@OverwriteInvoiceSummaryLevel, 'Y') = 'N'              
        BEGIN
            UPDATE IMWE
                SET IMWE.UploadVal = 'L'
                WHERE IMWE.ImportTemplate=@ImportTemplate 
                    AND IMWE.ImportId=@ImportId 
                    AND IMWE.RecordType = @rectype
                    AND IMWE.Identifier = @InvoiceSummaryLevelID
                    AND IMWE.UploadVal IS NULL;
        END;


/********** Validate InvoiceSummaryLevel  ******* Required ******/  
            UPDATE IMWE
                SET IMWE.UploadVal = '** Invalid - (L,C,T)'
                WHERE IMWE.ImportTemplate=@ImportTemplate 
                    AND IMWE.ImportId=@ImportId 
                    AND IMWE.RecordType = @rectype
                    AND IMWE.Identifier = @InvoiceSummaryLevelID
                    AND dbo.IMWE.UploadVal NOT IN ('L','C','T');

/**********InvoiceGrouping  ******* Required ******/  
        IF @InvoiceGroupingID <> 0 AND ISNULL(@OverwriteInvoiceGrouping, 'Y') = 'Y' 
            BEGIN
                UPDATE IMWE
                    SET IMWE.UploadVal = 'C'
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @InvoiceGroupingID;
            END;
        IF @InvoiceGroupingID <> 0 AND ISNULL(@OverwriteInvoiceGrouping, 'Y') = 'N' 
            BEGIN
                UPDATE IMWE
                    SET IMWE.UploadVal = 'C'
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @InvoiceGroupingID
                        AND dbo.IMWE.UploadVal IS null;
            END;
/********** Validate InvoiceGrouping  ******* Required ******/  
            UPDATE IMWE
                SET IMWE.UploadVal = '** Invalid (C,S,W)'
                WHERE IMWE.ImportTemplate=@ImportTemplate 
                    AND IMWE.ImportId=@ImportId 
                    AND IMWE.RecordType = @rectype
                    AND IMWE.Identifier = @InvoiceGroupingID
                    AND dbo.IMWE.UploadVal NOT IN ('C','S','W');
                    
/**********CustomerPOSetting  ******* Required ******/  
        IF @CustomerPOSettingID <> 0 AND ISNULL(@OverwriteCustomerPOSetting, 'Y') = 'Y' 
              BEGIN
                UPDATE IMWE
                    SET IMWE.UploadVal = 'N'
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @CustomerPOSettingID;
            END;

        IF @CustomerPOSettingID <> 0 AND ISNULL(@OverwriteCustomerPOSetting, 'Y') = 'N' 
              BEGIN
                UPDATE IMWE
                    SET IMWE.UploadVal = 'N'
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @CustomerPOSettingID
                        AND ISNULL(dbo.IMWE.UploadVal,'') = '';
            END;


/********** Validate CustomerPOSetting  ******* Required ******/  
            UPDATE IMWE
                SET IMWE.UploadVal = '** Invalid (R,N)'
                WHERE IMWE.ImportTemplate=@ImportTemplate 
                    AND IMWE.ImportId=@ImportId 
                    AND IMWE.RecordType = @rectype
                    AND IMWE.Identifier = @CustomerPOSettingID
                    AND dbo.IMWE.UploadVal NOT IN ('R','N');                    
 
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
		   
        IF @Column='BillToARCustomer' 
			SELECT @BillToARCustomer=CASE WHEN ISNUMERIC(@Uploadval)=1 THEN CONVERT(int, @Uploadval) 
				ELSE NULL END;
        IF @Column='CustGroup' 
			SELECT @CustGroup=CASE WHEN @Uploadval IS NULL THEN NULL 
				WHEN ISNUMERIC(@Uploadval)=1 THEN CONVERT(int, @Uploadval) 
				ELSE NULL END;
        IF @Column='Customer' 
			SELECT @Customer=CASE WHEN @Uploadval IS NULL THEN NULL 
				WHEN ISNUMERIC(@Uploadval)=1  THEN CONVERT(int, @Uploadval) 
				ELSE NULL END;
        IF @Column='ReportID' 
			SELECT @ReportID=CASE WHEN @Uploadval IS NULL THEN NULL 
				WHEN ISNUMERIC(@Uploadval)=1  THEN CONVERT(int, @Uploadval) 
				ELSE NULL END;   
        IF @Column='SMCo' 
			SELECT @SMCo=CASE WHEN @Uploadval IS NULL THEN NULL 
				WHEN ISNUMERIC(@Uploadval)=1  THEN CONVERT(int, @Uploadval) 
				ELSE NULL END;
        IF @Column='SMRateOverrideID' 
			SELECT @SMRateOverrideID=CASE WHEN @Uploadval IS NULL THEN NULL 
				WHEN ISNUMERIC(@Uploadval)=1  THEN CONVERT(bigint, @Uploadval) 
				ELSE NULL END;   
        IF @Column='SMStandardItemDefaultID' 
			SELECT @SMStandardItemDefaultID=CASE WHEN @Uploadval IS NULL THEN NULL 
				WHEN ISNUMERIC(@Uploadval)=1  THEN CONVERT(bigint, @Uploadval) 
				ELSE NULL END;							
        IF @Column='Active' SELECT @Active=@Uploadval;
        IF @Column='PrimaryTechnician' SELECT @PrimaryTechnician=@Uploadval;
        IF @Column='RateTemplate' SELECT @RateTemplate=@Uploadval;
--
        IF @Column='Active'
            SET @IsEmptyActive = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='BillToARCustomer'
            SET @IsEmptyBillToARCustomer = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='CustGroup'
            SET @IsEmptyCustGroup = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='Customer'
            SET @IsEmptyCustomer = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='Notes'
            SET @IsEmptyNotes = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='PrimaryTechnician'
            SET @IsEmptyPrimaryTechnician = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='RateTemplate'
            SET @IsEmptyRateTemplate = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='ReportID'
            SET @IsEmptyReportID = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='SMCo'
            SET @IsEmptySMCo = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='SMRateOverrideID'
            SET @IsEmptySMRateOverrideID = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;
        IF @Column='SMStandardItemDefaultID'
            SET @IsEmptySMStandardItemDefaultID = CASE WHEN @Uploadval IS NULL then 'Y' ELSE 'N' END ;

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
		IF @SMCoID<>0
				BEGIN;
				SELECT @msg = convert(varchar(12),SMCo)
				FROM dbo.vSMCO WITH (nolock) WHERE  dbo.vSMCO.SMCo = @SMCo;
				IF @@rowcount=0
				UPDATE IMWE
					SET IMWE.UploadVal = '** Invalid SM Company '
						+ISNULL(CAST(@SMCo AS VARCHAR(60)),'null') 
						+' does not exist'
					WHERE IMWE.ImportTemplate=@ImportTemplate 
						AND IMWE.ImportId=@ImportId 
						AND IMWE.RecordSeq=@currrecseq
						AND IMWE.RecordType = @rectype
						AND IMWE.Identifier = @SMCoID;
            END;
                    
/**********CustGroup  ******* Required ******/  
        IF @CustGroupID <> 0 
            AND (ISNULL(@OverwriteCustGroup, 'Y') = 'Y' 
                 OR ISNULL(@IsEmptyCustGroup, 'Y') = 'Y')
            BEGIN;
                SELECT @CustGroup = CustGroup
                FROM dbo.bHQCO WITH (nolock) WHERE dbo.bHQCO.HQCo = @SMCo;
                UPDATE IMWE
                    SET IMWE.UploadVal = @CustGroup
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordSeq=@currrecseq
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @CustGroupID;
               SELECT @IsEmptyCustGroup=CASE WHEN @CustGroup IS NULL THEN 'Y' ELSE 'N' END;
            END;

/********** Validate CustGroup  ******* Required ******/  
        IF @CustGroupID <> 0 
			BEGIN;
				SELECT @msg=null
				IF @CustGroup IS NULL 
					SELECT @msg='** Cust Group is empty or not numeric'		
				ELSE IF NOT EXISTS (SELECT dbo.bHQGP.Grp FROM dbo.bHQGP WHERE Grp=@CustGroup)
					SELECT @msg= '** Group not in HQ Groups'

				IF @msg IS NOT NULL
					BEGIN;
						UPDATE IMWE
							SET IMWE.UploadVal = @msg
							WHERE IMWE.ImportTemplate=@ImportTemplate 
								AND IMWE.ImportId=@ImportId 
								AND IMWE.RecordSeq=@currrecseq
								AND IMWE.RecordType = @rectype
								AND IMWE.Identifier = @CustGroupID;
					END;
            END;
                    


/********** Validate Customer  ******* sp_helptext vspSMCustomerVal  ******/  
			SELECT @arcmActive=NULL -- clear default
			IF @CustomerID <> 0
				BEGIN;
					SELECT @msg=NULL
					IF @Customer IS NULL AND @IsEmptyCustomer='Y' 
						SELECT @msg='** Invalid Customer # must be provided'
					ELSE IF @Customer IS NULL AND @IsEmptyCustomer='N' 
						SELECT @msg='** Invalid Customer is not numeric'		
					ELSE 
						BEGIN;
							SELECT @arcmActive = dbo.bARCM.Status   -- select distinct Status from ARCM
							FROM bARCM WITH (nolock) 
							WHERE dbo.bARCM.CustGroup = @CustGroup
								AND dbo.bARCM.Customer = @Customer;        
							SELECT @msg=CASE when @@rowcount<>0 and ISNULL(@arcmActive,'X')='I'  THEN '** Customer Not Active'
										 WHEN @@rowcount=0 THEN '** Customer not in AR'
										 ELSE NULL END;
						END;										 
					IF @msg IS NOT NULL 
						BEGIN;				 
							UPDATE IMWE
								SET IMWE.UploadVal = @msg
								WHERE IMWE.ImportTemplate=@ImportTemplate 
									AND IMWE.ImportId=@ImportId 
									AND IMWE.RecordSeq=@currrecseq
									AND IMWE.RecordType = @rectype
									AND IMWE.Identifier = @CustomerID;
						END;
				END;
                    
/**********Active  ******* Required ******/  
        IF @ActiveID <> 0 
            AND (ISNULL(@OverwriteActive, 'Y') = 'Y' 
                 OR ISNULL(@IsEmptyActive, 'Y') = 'Y')
            BEGIN;
                SELECT @Active = CASE WHEN ISNULL(@arcmActive,'') <> 'I' THEN 'Y' ELSE 'N' END;
                UPDATE IMWE
                    SET IMWE.UploadVal = @Active
                    WHERE IMWE.ImportTemplate=@ImportTemplate 
                        AND IMWE.ImportId=@ImportId 
                        AND IMWE.RecordSeq=@currrecseq
                        AND IMWE.RecordType = @rectype
                        AND IMWE.Identifier = @ActiveID;
            END;

/********** Validate Active  ******* Required ******/  
            IF @ActiveID<>0
				BEGIN;
					UPDATE IMWE
					SET IMWE.UploadVal = '** Invalid - Active not Y or N'
					WHERE IMWE.ImportTemplate=@ImportTemplate 
						AND IMWE.ImportId=@ImportId 
						AND IMWE.RecordSeq=@currrecseq
						AND IMWE.RecordType = @rectype
						AND IMWE.Identifier = @ActiveID
						AND ISNULL(IMWE.UploadVal,'') NOT IN ('Y','N');
				END;

/********** Validate RateTemplate  *************/  -- select * from vSMRateTemplate
			IF @RateTemplateID<>0 

			BEGIN;
				SELECT @msg=NULL
				IF @RateTemplate IS NULL AND @IsEmptyRateTemplate='Y' 
					SELECT @msg=null
				ELSE IF @RateTemplate IS NULL AND @IsEmptyRateTemplate='N' 
					SELECT @msg='** Invalid RateTemplate value'		
				ELSE IF NOT EXISTS (SELECT dbo.vSMRateTemplate.RateTemplate
						 FROM dbo.vSMRateTemplate 
						 WHERE vSMRateTemplate.SMCo=@SMCo AND RateTemplate=@RateTemplate)
					SELECT @msg= '** RateTemplate not in RateTemplate'

				IF @msg IS NOT NULL
					UPDATE IMWE
						SET IMWE.UploadVal = @msg
						WHERE IMWE.ImportTemplate = @ImportTemplate 
							AND IMWE.ImportId = @ImportId 
							AND IMWE.RecordSeq = @currrecseq
							AND IMWE.RecordType = @rectype
							AND IMWE.Identifier = @RateTemplateID;
			END; 

/********** Validate BillToARCustomer  *************/  
			IF @BillToARCustomerID<>0 
				BEGIN; 
					SELECT @msg=NULL
					IF @BillToARCustomer IS NULL AND @IsEmptyBillToARCustomer='Y' 
						SELECT @msg=NULL -- okay
					ELSE IF @BillToARCustomer IS NULL AND @IsEmptyBillToARCustomer='N' 
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
                    

/********** Validate ReportID  *************/  -- select * from vRPRTc
			IF @ReportIDID<>0 
				BEGIN;
					SELECT @msg=NULL
					IF @ReportID IS NULL AND @IsEmptyReportID='Y' 
						SELECT @msg=NULL -- okay
					ELSE IF @ReportID IS NULL AND @IsEmptyReportID='N' 
						SELECT @msg='** Invalid ReportID is not numeric'		
					ELSE IF NOT EXISTS (SELECT ReportID
										FROM dbo.vRPRTc (nolock) 
										WHERE  dbo.vRPRTc.ReportID = @ReportID)
						SELECT @msg= '** ReportID not in Report Titles table'

					IF @msg IS NOT NULL
						UPDATE IMWE
							SET IMWE.UploadVal = @msg
							WHERE IMWE.ImportTemplate=@ImportTemplate 
								AND IMWE.ImportId=@ImportId 
								AND IMWE.RecordSeq=@currrecseq
								AND IMWE.RecordType = @rectype
								AND IMWE.Identifier = @ReportIDID;
                END;           


/********** Validate SMRateOverrideID  *************/  --- select * from vSMRateOverride
			--IF @SMRateOverrideIDID<>0 
			--	BEGIN;
			--		SELECT @msg=NULL
			--		IF @SMRateOverrideID IS NULL AND @IsEmptySMRateOverrideID='Y' 
			--			SELECT @msg=NULL -- okay
			--		ELSE IF @SMRateOverrideID IS NULL AND @IsEmptySMRateOverrideID='N' 
			--			SELECT @msg='** Invalid SMRateOverrideID is not numeric'		
			--		ELSE IF NOT EXISTS (SELECT @SMRateOverrideID
			--							FROM dbo.vSMRateOverride (nolock) 
			--							WHERE dbo.vSMRateOverride.SMRateOverrideID  = @SMRateOverrideID
			--								AND dbo.vSMRateOverride.SMCo=@SMCo)
			--			SELECT @msg= '** SMRateOverrideID not in vSMRateOverride'

			--		IF @msg IS NOT NULL
			--			UPDATE IMWE
			--				SET IMWE.UploadVal = @msg
			--				WHERE IMWE.ImportTemplate=@ImportTemplate 
			--					AND IMWE.ImportId=@ImportId 
			--					AND IMWE.RecordSeq=@currrecseq
			--					AND IMWE.RecordType = @rectype
			--					AND IMWE.Identifier = @SMRateOverrideIDID;
   --             END;
                
--UPDATE dbo.IMWE SET UploadVal=ImportedVal WHERE ImportId = 'smcust'

/********** Validate SMStandardItemDefaultID  *************/  -- select * from SMStandardItemDefault
		--IF  @SMStandardItemDefaultIDID<>0 
		--	BEGIN;
		--		SELECT @msg=NULL
		--		IF @SMStandardItemDefaultID IS NULL AND @IsEmptySMStandardItemDefaultID='Y'
		--			SELECT @msg=null -- okay	
		--		ELSE IF @SMStandardItemDefaultID IS NULL AND @IsEmptySMStandardItemDefaultID='N'
		--			SELECT @msg='** SMStandardItemDefaultID is not numeric' 	
		--		ELSE IF NOT EXISTS (SELECT dbo.vSMStandardItem.SMStandardItemID
		--				 FROM dbo.vSMStandardItem WHERE SMStandardItemID=@SMStandardItemDefaultID)
		--			SELECT @msg= '** SMStandardItemDefaultID not in SMStandardItem'

		--		IF @msg IS NOT NULL
		--			UPDATE IMWE
		--				SET IMWE.UploadVal = @msg
		--				WHERE IMWE.ImportTemplate=@ImportTemplate 
		--					AND IMWE.ImportId=@ImportId 
		--					AND IMWE.RecordSeq=@currrecseq
		--					AND IMWE.RecordType = @rectype
		--					AND IMWE.Identifier = @SMStandardItemDefaultIDID;
  --          END;
                                   
                    
/********** Validate PrimaryTechnician  ***** varchar ********/  -- select * from SMTechnician 
			IF @PrimaryTechnicianID<>0 AND @PrimaryTechnician IS NOT NULL
				BEGIN;
            	SELECT @msg = Technician
            	FROM dbo.SMTechnician WITH (nolock) 
            	WHERE dbo.SMTechnician.SMCo = @SMCo 
            	  AND dbo.SMTechnician.Technician=@PrimaryTechnician;
            	IF @@rowcount=0
              	 	UPDATE IMWE
               			SET IMWE.UploadVal = '** Invalid - Technician '
							+ISNULL(CAST(@PrimaryTechnician AS VARCHAR(60)),'null')
							+' does not exist'
                		WHERE IMWE.ImportTemplate=@ImportTemplate 
                    		AND IMWE.ImportId=@ImportId 
                    		AND IMWE.RecordSeq=@currrecseq
                    		AND IMWE.RecordType = @rectype
                    		AND IMWE.Identifier = @PrimaryTechnicianID;
                END;
                
 -- Get Next RecSeq      
		SELECT @BillToARCustomer=NULL, @CustGroup=NULL, @Customer=NULL
		SELECT @ReportID=NULL, @SMCo=NULL, @SMRateOverrideID=NULL, @SMStandardItemDefaultID=null
 
		SELECT @currrecseq = @Recseq;
		SELECT @counter = @counter + 1;
    
		END;		--End SET DEFAULT VALUE process
    END;		-- End @complete Loop, Last IMWE record has been processed

CLOSE WorkEditCursor;
DEALLOCATE WorkEditCursor;

/** EXIT **/
vspexit:
SELECT @msg = isnull(@desc,'Header ') + char(13) + char(13) + '[vspIMVPDefaultsSMCustomer]';

RETURN @rcode;


GO
GRANT EXECUTE ON  [dbo].[vspIMVPDefaultsSMCustomer] TO [public]
GO
