SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspIMViewpointDefaultsHRRM]
   /***********************************************************
    * CREATED BY:   Jim Emery  03/13/2013
    *
    * Usage:
    *	Used by HR Resource Master Imports to create values for needed or missing
    *      data based upon Viewpoint default rules.
    *
    * Input params:
    *	@ImportId	 Import Identifier
    *	@ImportTemplate	 Import Template
    *
    * Output params:
    *	@msg		error message
    *
    * Return code:
    *	0 = success, 1 = failure
    ************************************************************/
    ( @Company bCompany
    , @ImportId VARCHAR(20)
    , @ImportTemplate VARCHAR(20)
    , @Form VARCHAR(20)
    , @rectype VARCHAR(10)
    , @msg VARCHAR(120) OUTPUT )
WITH recompile
AS 

SET nocount ON;
   
DECLARE @rcode INT
  , @desc VARCHAR(120)
  , @status INT
  , @defaultvalue VARCHAR(30)
  , @CursorOpen INT
  , @rc INT;

 SELECT @rcode=0;
 
   /* check required input params */
   
IF @ImportId IS NULL 
    BEGIN;
        SELECT  @desc = 'Missing ImportId.', @rcode = 1;
        GOTO bspexit;
    END;

IF @ImportTemplate IS NULL 
    BEGIN;
        SELECT  @desc = 'Missing ImportTemplate.', @rcode = 1;
        GOTO bspexit;
    END;
   
IF @Form IS NULL 
    BEGIN;
        SELECT  @desc = 'Missing Form.', @rcode = 1;
        GOTO bspexit;
    END;
 


/** HRCo     0    **/
DECLARE @OverwriteHRCo bYN;
DECLARE @HRCoID INT;
SELECT  @OverwriteHRCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'HRCo', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @HRCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'HRCo', @rectype, 'N');

/** PREmp    bEmployee 4  bspHRPREmpValUnique bEmployee **/
DECLARE @PREmpID INT;
SELECT  @PREmpID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PREmp', @rectype, 'N');

/** HRRef   Required bHRRef 4  bspHRResourceVal bHRRef **/
DECLARE @OverwriteHRRef bYN;
DECLARE @HRRefID INT;
SELECT  @OverwriteHRRef = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'HRRef', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @HRRefID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'HRRef', @rectype, 'N');

DECLARE @OverwritePRCo bYN;
DECLARE @PRCoID INT;
SELECT  @OverwritePRCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PRCo', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @PRCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PRCo', @rectype, 'N');

DECLARE @OverwriteSSN bYN;
DECLARE @SSNID INT;
SELECT  @OverwriteSSN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SSN', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @SSNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SSN', @rectype, 'N');


DECLARE @OverwriteLastName bYN;
DECLARE @LastNameID INT;
SELECT  @OverwriteLastName = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'LastName', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @LastNameID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'LastName', @rectype, 'N');

DECLARE @FirstNameID INT;
SELECT  @FirstNameID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'FirstName', @rectype, 'N');

DECLARE @MiddleNameID INT;
SELECT  @MiddleNameID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MiddleName', @rectype, 'N');

/** Address     60   varchar **/
DECLARE @AddressID INT;
SELECT  @AddressID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Address', @rectype, 'N');

DECLARE @CityID INT;
SELECT  @CityID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'City', @rectype, 'N');

/** State    bState   bStatep **/
DECLARE @StateID INT;
SELECT  @StateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'State', @rectype, 'N');

/** Zip    bZip 12   bZip **/
DECLARE @ZipID INT;
SELECT  @ZipID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Zip', @rectype, 'N');


/** Address2     60   varchar **/
DECLARE @Address2ID INT;
SELECT  @Address2ID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Address2', @rectype, 'N');

/** Phone    bPhone 20   bPhone **/
DECLARE @PhoneID INT;
SELECT  @PhoneID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Phone', @rectype, 'N');

/** WorkPhone    bPhone 20   bPhone **/
DECLARE @WorkPhoneID INT;
SELECT  @WorkPhoneID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'WorkPhone', @rectype, 'N');


/** CellPhone    bPhone 20   bPhone **/
DECLARE @CellPhoneID INT;
SELECT  @CellPhoneID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CellPhone', @rectype, 'N');


/** PRGroup    bPRGroup 1  bspHRPRGroupVal bGroup **/
DECLARE @PRGroupID INT;
SELECT  @PRGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PRGroup', @rectype, 'N');
DECLARE @OverwritePRGroup bYN;
SELECT  @OverwritePRGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PRGroup', @rectype); -- Overwrite with [BIDTEK] default


/** PRDept    bPRDept 10  bspHRPRDeptVal bDept **/
DECLARE @PRDeptID INT;
SELECT  @PRDeptID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PRDept', @rectype, 'N');
DECLARE @OverwritePRDept bYN;
SELECT  @OverwritePRDept = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PRDept', @rectype); -- Overwrite with [BIDTEK] default



/** StdCraft    bCraft 10  bspHRPRCraftVal bCraft **/
DECLARE @StdCraftID INT;
SELECT  @StdCraftID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'StdCraft', @rectype, 'N');
DECLARE @OverwriteStdCraft bYN;
SELECT  @OverwriteStdCraft = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'StdCraft', @rectype); -- Overwrite with [BIDTEK] default


/** StdClass    bClass 10  bspHRPRCraftClassVal bClass **/
DECLARE @StdClassID INT;
SELECT  @StdClassID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'StdClass', @rectype, 'N');
DECLARE @OverwriteStdClass bYN;
SELECT  @OverwriteStdClass = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'StdClass', @rectype); -- Overwrite with [BIDTEK] default



/** StdInsCode    bInsCode 10  bspHQInsCodeVal bInsCode **/
DECLARE @StdInsCodeID INT;
SELECT  @StdInsCodeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'StdInsCode', @rectype, 'N');
DECLARE @OverwriteStdInsCode bYN;
SELECT  @OverwriteStdInsCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'StdInsCode', @rectype); -- Overwrite with [BIDTEK] default


/** StdTaxState    bState 4  vspHQCountryStateVal varchar **/
DECLARE @StdTaxStateID INT;
SELECT  @StdTaxStateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'StdTaxState', @rectype, 'N');
DECLARE @OverwriteStdTaxState bYN;
SELECT  @OverwriteStdTaxState = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'StdTaxState', @rectype); -- Overwrite with [BIDTEK] default


/** StdUnempState    bState 4  vspHQCountryStateVal varchar **/
DECLARE @StdUnempStateID INT;
SELECT  @StdUnempStateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'StdUnempState', @rectype, 'N');
DECLARE @OverwriteStdUnempState bYN;
SELECT  @OverwriteStdUnempState = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'StdUnempState', @rectype); -- Overwrite with [BIDTEK] default



/** StdInsState    bState 4  vspHQCountryStateVal varchar **/
DECLARE @StdInsStateID INT;
SELECT  @StdInsStateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'StdInsState', @rectype, 'N');
DECLARE @OverwriteStdInsState bYN;
SELECT  @OverwriteStdInsState = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'StdInsState', @rectype); -- Overwrite with [BIDTEK] default

/** StdLocal    bLocalCode 10  bspHRPRLocalVal bLocalCode **/
DECLARE @StdLocalID INT;
SELECT  @StdLocalID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'StdLocal', @rectype, 'N');
DECLARE @OverwriteStdLocal bYN;
SELECT  @OverwriteStdLocal = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'StdLocal', @rectype); -- Overwrite with [BIDTEK] default


--------

BEGIN
    UPDATE dbo.IMWE
    SET     IMWE.UploadVal = @Company
    WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @HRCoID AND @HRCoID IS NOT NULL AND ( IMWE.UploadVal IS NULL OR @OverwriteHRCo = 'Y' )
			
	/* insert invalid values */
    INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
            SELECT  ImportId, ImportTemplate, @Form, RecordSeq, 1, '**Invalid HR Company', @HRCoID
            FROM    dbo.IMWE
            LEFT JOIN dbo.HRCO
            ON      dbo.HRCO.HRCo = dbo.IMWE.UploadVal
            WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @HRCoID AND @HRCoID IS NOT NULL AND dbo.HRCO.HRCo IS NULL -- invalid
      
END  --HRCo

/** PRCo     1  vspHRPRCoVal bCompany **/
BEGIN
    UPDATE dbo.IMWE
    SET     IMWE.UploadVal = b.PRCo
    FROM    dbo.IMWE
    JOIN    dbo.IMWE a
    ON      --- get the HR Company
		a.ImportTemplate = IMWE.ImportTemplate AND a.ImportId = IMWE.ImportId AND a.RecordSeq = IMWE.RecordSeq AND a.RecordType = IMWE.RecordType AND a.Identifier = @HRCoID
    JOIN    dbo.bHRCO b
    ON      b.HRCo = a.UploadVal
    WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @PRCoID AND @PRCoID <> 0 AND ( IMWE.UploadVal IS NULL OR @OverwritePRCo = 'Y' )

	/* insert invalid values */
    INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
            SELECT TOP 100
                    ImportId, ImportTemplate, @Form, RecordSeq, 1, '**Invalid PR Company', @PRCoID
            FROM    dbo.IMWE
            LEFT JOIN dbo.PRCO
            ON      dbo.PRCO.PRCo = dbo.IMWE.UploadVal
            WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @PRCoID AND @PRCoID IS NOT NULL AND dbo.PRCO.PRCo IS NULL -- invalid
END  --PRCo


/** LastName   Required  30   varchar **/
BEGIN
	/* insert invalid values */
    INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
            SELECT  ImportId, ImportTemplate, @Form, RecordSeq, 1, '**Invalid LastName', @LastNameID
            FROM    dbo.IMWE
            WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
            AND IMWE.RecordType = @rectype AND IMWE.Identifier = @LastNameID AND @LastNameID <> 0 
            AND ( UploadVal IS NULL ) -- invalid
END  --LastName


/** FirstName   Required  30   varchar **/
BEGIN
	/* insert invalid values */
    INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
            SELECT  ImportId, ImportTemplate, @Form, RecordSeq, 1, '**Invalid FirstName', @FirstNameID
            FROM    dbo.IMWE
            WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @FirstNameID AND @FirstNameID <> 0 AND ( UploadVal IS NULL ) -- invalid
END  --FirstName


/** SortName   Required bHRResourceSortName 15  bspHRSortNameUnique varchar **/
DECLARE @OverwriteSortName bYN;
DECLARE @SortNameID INT;
SELECT  @OverwriteSortName = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SortName', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @SortNameID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SortName', @rectype, 'N');

/** Sex   Required  1   char **/
DECLARE @OverwriteSex bYN;
DECLARE @SexID INT;
SELECT  @OverwriteSex = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Sex', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @SexID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Sex', @rectype, 'N');
BEGIN
	/* insert invalid values */
    INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
            SELECT  ImportId, ImportTemplate, @Form, RecordSeq, 1, '**Invalid Sex', @SexID
            FROM    dbo.IMWE
            WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId
             AND IMWE.RecordType = @rectype AND IMWE.Identifier = @SexID AND @SexID <> 0
             AND ( dbo.IMWE.UploadVal NOT IN ('M', 'F' ) ) -- invalid
END  --Sex


/** Race     2  bspPRRaceVal char **/
DECLARE @OverwriteRace bYN;
DECLARE @RaceID INT;
SELECT  @OverwriteRace = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Race', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @RaceID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Race', @rectype, 'N');
BEGIN
	/* insert invalid values */
    INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
            SELECT TOP 100
                    dbo.IMWE.ImportId, dbo.IMWE.ImportTemplate, @Form, dbo.IMWE.RecordSeq, 1, '**Invalid Race', @RaceID
            FROM    dbo.IMWE
            LEFT JOIN IMWE a
            ON      a.ImportTemplate = IMWE.ImportTemplate AND a.ImportId = IMWE.ImportId
             AND a.RecordSeq = IMWE.RecordSeq AND a.RecordType = IMWE.RecordType 
             AND a.Identifier = @PRCoID AND ISNULL(@PRCoID,0) <> 0
            LEFT JOIN dbo.bPRRC b
            ON      b.PRCo = a.UploadVal AND b.Race = dbo.IMWE.UploadVal
            WHERE   IMWE.ImportTemplate = @ImportTemplate 
				AND IMWE.ImportId = @ImportId 
				AND IMWE.RecordType = @rectype
				 AND IMWE.Identifier = @RaceID 
				 AND @RaceID <> 0 
				 AND IMWE.UploadVal IS NOT NULL
				 AND b.Race IS null
                       
END


/** BirthDate    bLongDate 4   smalldatetime **/
DECLARE @OverwriteBirthDate bYN;
DECLARE @BirthDateID INT;
SELECT  @OverwriteBirthDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BirthDate', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @BirthDateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'BirthDate', @rectype, 'N');
BEGIN
	/* insert invalid values */
    INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
            SELECT TOP 100
                    ImportId, ImportTemplate, @Form, RecordSeq, 1, '**Invalid BirthDate', @BirthDateID
            FROM    dbo.IMWE
            WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @BirthDateID AND @BirthDateID <> 0 AND IMWE.UploadVal IS NOT NULL AND ISDATE(UploadVal) <> 1
END  --BirthDate


/** HireDate    bDate 4   bDate **/
DECLARE @OverwriteHireDate bYN;
DECLARE @HireDateID INT;
SELECT  @OverwriteHireDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'HireDate', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @HireDateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'HireDate', @rectype, 'N');
BEGIN
	/* insert invalid values */
    INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
            SELECT TOP 100
                    ImportId, ImportTemplate, @Form, RecordSeq, 1, '**Invalid HireDate', @HireDateID
            FROM    dbo.IMWE
            WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @HireDateID AND @HireDateID <> 0 AND IMWE.UploadVal IS NOT NULL AND ISDATE(UploadVal) <> 1
END  --HireDate


/** TermDate    bDate 4   bDate **/
DECLARE @OverwriteTermDate bYN;
DECLARE @TermDateID INT;
SELECT  @OverwriteTermDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TermDate', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @TermDateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TermDate', @rectype, 'N');
BEGIN
	/* insert invalid values */
    INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
            SELECT TOP 100
                    ImportId, ImportTemplate, @Form, RecordSeq, 1, '**Invalid TermDate', @TermDateID
            FROM    dbo.IMWE
            WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @TermDateID AND @TermDateID <> 0 AND IMWE.UploadVal IS NOT NULL AND ISDATE(UploadVal) <> 1
END  --TermDate


/** TermReason     20  bspHRCodeVal varchar **/
DECLARE @OverwriteTermReason bYN;
DECLARE @TermReasonID INT;
SELECT  @OverwriteTermReason = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TermReason', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @TermReasonID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TermReason', @rectype, 'N');
-- use cursur validation


/** ActiveYN   Required bYN 1   bYN **/
DECLARE @OverwriteActiveYN bYN;
DECLARE @ActiveYNID INT;
SELECT  @OverwriteActiveYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ActiveYN', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @ActiveYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ActiveYN', @rectype, 'N');
BEGIN
    UPDATE dbo.IMWE
    SET     IMWE.UploadVal = 'Y'
    FROM    IMWE
    WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @ActiveYNID AND @ActiveYNID <> 0 AND ( IMWE.UploadVal IS NULL OR @OverwriteActiveYN = 'Y' )

	/* insert invalid values */
    INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
            SELECT  ImportId, ImportTemplate, @Form, RecordSeq, 1, '**Invalid ActiveYN', @ActiveYNID
            FROM    dbo.IMWE
            WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @ActiveYNID AND @ActiveYNID <> 0 AND ( ISNULL(IMWE.UploadVal,
                                                                                                        '') NOT IN ( 'Y',
                    'N' ) )
END  --ActiveYN


/** Status     10  bspHRStatCodeVal varchar **/
DECLARE @StatusID INT;
SELECT  @StatusID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Status', @rectype, 'N');
DECLARE @OverwriteStatus bYN;
SELECT  @OverwriteStatus = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Status', @rectype); -- Overwrite with [BIDTEK] default

BEGIN
	/* insert invalid values */
    INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
            SELECT TOP 100
                    IMWE.ImportId, IMWE.ImportTemplate, @Form, IMWE.RecordSeq, 1, '**Invalid Status', @StatusID
            FROM    IMWE
            LEFT JOIN IMWE a
            ON      a.ImportTemplate = IMWE.ImportTemplate AND a.ImportId = IMWE.ImportId AND a.RecordSeq = IMWE.RecordSeq AND a.RecordType = IMWE.RecordType AND a.Identifier = @HRCoID AND ISNULL(@HRCoID,0) IS NOT NULL 
            LEFT JOIN HRST b
            ON      b.HRCo = a.UploadVal AND b.[StatusCode] = IMWE.UploadVal
            WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId
             AND IMWE.RecordType = @rectype AND IMWE.Identifier = @StatusID 
             AND @StatusID <> 0 
             AND ( IMWE.UploadVal IS NOT NULL ) 
             AND b.[StatusCode] IS NULL -- doesnt exist 
END  --Status


/** W4CompleteYN   Required bYN 1   bYN **/
DECLARE @W4CompleteYNID INT;
SELECT  @W4CompleteYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'W4CompleteYN', @rectype, 'N');
DECLARE @OverwriteW4CompleteYN bYN;
SELECT  @OverwriteW4CompleteYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'W4CompleteYN', @rectype); -- Overwrite with [BIDTEK] default

BEGIN
    UPDATE dbo.IMWE
    SET     IMWE.UploadVal = 'Y'
    FROM    IMWE
    WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype 
			AND IMWE.Identifier = @W4CompleteYNID AND @W4CompleteYNID <> 0 
			AND ( ISNULL(IMWE.UploadVal,'') NOT IN ( 'Y','N' ) OR @OverwriteW4CompleteYN = 'Y' )
END  --W4CompleteYN


/** PositionCode     10  bspHRPositionVal varchar **/
DECLARE @PositionCodeID INT;
SELECT  @PositionCodeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PositionCode', @rectype, 'N');
DECLARE @OverwritePositionCode bYN;
SELECT  @OverwritePositionCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PositionCode', @rectype); -- Overwrite with [BIDTEK] default


/** NoRehireYN   Required bYN 1   bYN **/
DECLARE @NoRehireYNID INT;
SELECT  @NoRehireYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'NoRehireYN', @rectype, 'N');
DECLARE @OverwriteNoRehireYN bYN;
SELECT  @OverwriteNoRehireYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'NoRehireYN', @rectype); -- Overwrite with [BIDTEK] default

BEGIN
    UPDATE dbo.IMWE
    SET     IMWE.UploadVal = 'N'
    FROM    IMWE
    WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @NoRehireYNID AND @NoRehireYNID <> 0 AND ( ISNULL(IMWE.UploadVal,
                                                                                                        '') NOT IN ( 'Y',
            'N' ) OR @OverwriteNoRehireYN = 'Y' )
END  --NoRehireYN


/** MaritalStatus     1   char **/
DECLARE @MaritalStatusID INT;
SELECT  @MaritalStatusID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MaritalStatus', @rectype, 'N');
DECLARE @OverwriteMaritalStatus bYN;
SELECT  @OverwriteMaritalStatus = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MaritalStatus', @rectype); -- Overwrite with [BIDTEK] default

BEGIN
	/* insert invalid values */
    INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
            SELECT TOP 100
                    IMWE.ImportId, IMWE.ImportTemplate, @Form, IMWE.RecordSeq, 1, '**Invalid MaritalStatus',
                    @MaritalStatusID
            FROM    IMWE
            WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype
				 AND IMWE.Identifier = @MaritalStatusID AND @MaritalStatusID <> 0 
				 AND ISNULL(IMWE.UploadVal,'') NOT IN ( '','S', 'M', 'D', 'O' )
END  --MaritalStatus


/** PassPort   Required bYN 1   bYN **/
DECLARE @PassPortID INT;
SELECT  @PassPortID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PassPort', @rectype, 'N');
DECLARE @OverwritePassPort bYN;
SELECT  @OverwritePassPort = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PassPort', @rectype); -- Overwrite with [BIDTEK] default

BEGIN
    UPDATE dbo.IMWE
    SET     IMWE.UploadVal = 'N'
    FROM    IMWE
    WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @PassPortID 
    AND @PassPortID <> 0 
    AND ( ISNULL(IMWE.UploadVal,'') NOT IN ( 'Y','N' ) OR @OverwritePassPort = 'Y' )

	
END  --PassPort


/** RelativesYN   Required bYN 1   bYN **/
DECLARE @RelativesYNID INT;
SELECT  @RelativesYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RelativesYN', @rectype, 'N');
DECLARE @OverwriteRelativesYN bYN;
SELECT  @OverwriteRelativesYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RelativesYN', @rectype); -- Overwrite with [BIDTEK] default

BEGIN
    UPDATE dbo.IMWE
    SET     IMWE.UploadVal = 'N'
    FROM    IMWE
    WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
    AND IMWE.RecordType = @rectype AND IMWE.Identifier = @RelativesYNID 
    AND @RelativesYNID <> 0 
    AND ( ISNULL(IMWE.UploadVal,'') NOT IN ( 'Y', 'N' ) OR @OverwriteRelativesYN = 'Y' )
END  --RelativesYN


/** HandicapYN   Required bYN 1   bYN **/
DECLARE @HandicapYNID INT;
SELECT  @HandicapYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'HandicapYN', @rectype, 'N');
DECLARE @OverwriteHandicapYN bYN;
SELECT  @OverwriteHandicapYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'HandicapYN', @rectype); -- Overwrite with [BIDTEK] default

BEGIN
    UPDATE dbo.IMWE
    SET     IMWE.UploadVal = 'N'
    FROM    IMWE
    WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @HandicapYNID AND @HandicapYNID <> 0 AND ( ISNULL(IMWE.UploadVal,
                                                                                                        '') NOT IN ( 'Y',
            'N' ) OR @OverwriteHandicapYN = 'Y' )
END  --HandicapYN

/** VetJobCategory     2   varchar **/
DECLARE @VetJobCategoryID INT;
SELECT  @VetJobCategoryID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'VetJobCategory', @rectype, 'N');
DECLARE @OverwriteVetJobCategory bYN;
SELECT  @OverwriteVetJobCategory = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'VetJobCategory', @rectype); -- Overwrite with [BIDTEK] default

BEGIN
	/* insert invalid values */
    INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
            SELECT TOP 100
                    IMWE.ImportId, IMWE.ImportTemplate, @Form, IMWE.RecordSeq, 1, '**Invalid VetJobCategory',
                    @VetJobCategoryID
            FROM    IMWE
            WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @VetJobCategoryID AND @VetJobCategoryID <> 0 AND ISNULL(IMWE.UploadVal,
                                                                                                        '') NOT IN ( '',
                    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10' )
END  --VetJobCategory


/** PhysicalYN   Required bYN 1   bYN **/
DECLARE @PhysicalYNID INT;
SELECT  @PhysicalYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PhysicalYN', @rectype, 'N');
DECLARE @OverwritePhysicalYN bYN;
SELECT  @OverwritePhysicalYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PhysicalYN', @rectype); -- Overwrite with [BIDTEK] default

BEGIN
    UPDATE dbo.IMWE
    SET     IMWE.UploadVal = 'N'
    FROM    IMWE
    WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @PhysicalYNID AND @PhysicalYNID <> 0 AND ( ISNULL(IMWE.UploadVal,
                                                                                                        '') NOT IN ( 'Y',
            'N' ) OR @OverwritePhysicalYN = 'Y' )
END  --PhysicalYN


/** PhysDate    bDate 4   bDate **/
DECLARE @PhysDateID INT;
SELECT  @PhysDateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PhysDate', @rectype, 'N');
DECLARE @OverwritePhysDate bYN;
SELECT  @OverwritePhysDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PhysDate', @rectype); -- Overwrite with [BIDTEK] default

BEGIN
	/* insert invalid values */
    INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
            SELECT TOP 100
                    IMWE.ImportId, IMWE.ImportTemplate, @Form, IMWE.RecordSeq, 1, '**Invalid PhysDate', @PhysDateID
            FROM    IMWE
            WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @PhysDateID AND @PhysDateID <> 0 AND IMWE.UploadVal IS NOT NULL AND ISDATE(IMWE.UploadVal) <> 1
END  --PhysDate


/** PhysExpireDate    bDate 4   bDate **/
DECLARE @PhysExpireDateID INT;
SELECT  @PhysExpireDateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PhysExpireDate', @rectype, 'N');
DECLARE @OverwritePhysExpireDate bYN;
SELECT  @OverwritePhysExpireDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PhysExpireDate', @rectype); -- Overwrite with [BIDTEK] default

BEGIN
	/* insert invalid values */
    INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
            SELECT TOP 100
                    IMWE.ImportId, IMWE.ImportTemplate, @Form, IMWE.RecordSeq, 1, '**Invalid PhysExpireDate',
                    @PhysExpireDateID
            FROM    IMWE
            WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @PhysExpireDateID AND @PhysExpireDateID <> 0 AND IMWE.UploadVal IS NOT NULL AND ISDATE(IMWE.UploadVal) <> 1
END  --PhysExpireDate


/** LicNumber     20   varchar **/
DECLARE @LicNumberID INT;
SELECT  @LicNumberID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'LicNumber', @rectype, 'N');
DECLARE @OverwriteLicNumber bYN;
SELECT  @OverwriteLicNumber = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'LicNumber', @rectype); -- Overwrite with [BIDTEK] default



/** LicState    bState 4  vspHQCountryStateVal varchar **/
DECLARE @LicStateID INT;
SELECT  @LicStateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'LicState', @rectype, 'N');
DECLARE @OverwriteLicState bYN;
SELECT  @OverwriteLicState = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'LicState', @rectype); -- Overwrite with [BIDTEK] default


/** LicExpDate    bDate 4   bDate **/
DECLARE @LicExpDateID INT;
SELECT  @LicExpDateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'LicExpDate', @rectype, 'N');
DECLARE @OverwriteLicExpDate bYN;
SELECT  @OverwriteLicExpDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'LicExpDate', @rectype); -- Overwrite with [BIDTEK] default

BEGIN

	/* insert invalid values */
    INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
            SELECT TOP 100
                    IMWE.ImportId, IMWE.ImportTemplate, @Form, IMWE.RecordSeq, 1, '**Invalid LicExpDate', @LicExpDateID
            FROM    IMWE
            WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @LicExpDateID AND @LicExpDateID <> 0 AND ( IMWE.UploadVal IS NOT NULL AND ISDATE(IMWE.UploadVal) <> 1 )
END  --LicExpDate


/** DriveCoVehiclesYN   Required bYN 1   bYN **/
DECLARE @DriveCoVehiclesYNID INT;
SELECT  @DriveCoVehiclesYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'DriveCoVehiclesYN', @rectype, 'N');
DECLARE @OverwriteDriveCoVehiclesYN bYN;
SELECT  @OverwriteDriveCoVehiclesYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'DriveCoVehiclesYN', @rectype); -- Overwrite with [BIDTEK] default

BEGIN
    UPDATE dbo.IMWE
    SET     IMWE.UploadVal = 'N'
    FROM    IMWE
    WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @DriveCoVehiclesYNID AND @DriveCoVehiclesYNID <> 0 AND ( ISNULL(IMWE.UploadVal,
                                                                                                        '') NOT IN ( 'Y',
            'N' ) OR @OverwriteDriveCoVehiclesYN = 'Y' )
END  --DriveCoVehiclesYN




/** NoContactEmplYN   Required bYN 1   bYN **/
DECLARE @NoContactEmplYNID INT;
SELECT  @NoContactEmplYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'NoContactEmplYN', @rectype, 'N');
DECLARE @OverwriteNoContactEmplYN bYN;
SELECT  @OverwriteNoContactEmplYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'NoContactEmplYN', @rectype); -- Overwrite with [BIDTEK] default

BEGIN
    UPDATE dbo.IMWE
    SET     IMWE.UploadVal = 'Y'
    FROM    IMWE
    WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @NoContactEmplYNID AND @NoContactEmplYNID <> 0 AND ( ISNULL(IMWE.UploadVal,
                                                                                                        '') NOT IN ( 'Y',
            'N' ) OR @OverwriteNoContactEmplYN = 'Y' )
END  --NoContactEmplYN



/** ExistsInPR   Required bYN 1   bYN **/
DECLARE @ExistsInPRID INT;
SELECT  @ExistsInPRID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ExistsInPR', @rectype, 'N');
DECLARE @OverwriteExistsInPR bYN;
SELECT  @OverwriteExistsInPR = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ExistsInPR', @rectype); -- Overwrite with [BIDTEK] default

/** EarnCode    bEDLCode 2  bspHRPREarnDedLiabVal bEDLCode **/
DECLARE @EarnCodeID INT;
SELECT  @EarnCodeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'EarnCode', @rectype, 'N');
DECLARE @OverwriteEarnCode bYN;
SELECT  @OverwriteEarnCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EarnCode', @rectype); -- Overwrite with [BIDTEK] default


/** TempWorker   Required bYN 1   bYN **/
DECLARE @TempWorkerID INT;
SELECT  @TempWorkerID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TempWorker', @rectype, 'N');
DECLARE @OverwriteTempWorker bYN;
SELECT  @OverwriteTempWorker = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TempWorker', @rectype); -- Overwrite with [BIDTEK] default

BEGIN
    UPDATE dbo.IMWE
    SET     IMWE.UploadVal = 'N'
    FROM    IMWE
    WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @TempWorkerID AND @TempWorkerID <> 0 AND ( ISNULL(IMWE.UploadVal,
                                                                                                        '') NOT IN ( 'Y',
            'N' ) OR @OverwriteTempWorker = 'Y' )

END  --TempWorker

DECLARE @SuffixID INT;
SELECT  @SuffixID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Suffix', @rectype, 'N');
/** Email     60   varchar **/
DECLARE @EmailID INT;
SELECT  @EmailID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Email', @rectype, 'N');
DECLARE @OverwriteEmail bYN;
SELECT  @OverwriteEmail = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Email', @rectype); -- Overwrite with [BIDTEK] default


/** DisabledVetYN   Required bYN 1   bYN **/
DECLARE @DisabledVetYNID INT;
SELECT  @DisabledVetYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'DisabledVetYN', @rectype, 'N');
DECLARE @OverwriteDisabledVetYN bYN;
SELECT  @OverwriteDisabledVetYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'DisabledVetYN', @rectype); -- Overwrite with [BIDTEK] default

BEGIN
    UPDATE dbo.IMWE
    SET     IMWE.UploadVal = 'N'
    FROM    IMWE
    WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @DisabledVetYNID AND @DisabledVetYNID <> 0 AND ( ISNULL(IMWE.UploadVal,
                                                                                                        '') NOT IN ( 'Y',
            'N' ) OR @OverwriteDisabledVetYN = 'Y' )
END  --DisabledVetYN


/** VietnamVetYN   Required bYN 1   bYN **/
DECLARE @VietnamVetYNID INT;
SELECT  @VietnamVetYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'VietnamVetYN', @rectype, 'N');
DECLARE @OverwriteVietnamVetYN bYN;
SELECT  @OverwriteVietnamVetYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'VietnamVetYN', @rectype); -- Overwrite with [BIDTEK] default

BEGIN
    UPDATE dbo.IMWE
    SET     IMWE.UploadVal = 'N'
    FROM    IMWE
    WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @VietnamVetYNID AND @VietnamVetYNID <> 0 AND ( ISNULL(IMWE.UploadVal,
                                                                                                        '') NOT IN ( 'Y',
            'N' ) OR @OverwriteVietnamVetYN = 'Y' )
END  --VietnamVetYN


/** OtherVetYN   Required bYN 1   bYN **/
DECLARE @OtherVetYNID INT;
SELECT  @OtherVetYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'OtherVetYN', @rectype, 'N');
DECLARE @OverwriteOtherVetYN bYN;
SELECT  @OverwriteOtherVetYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'OtherVetYN', @rectype); -- Overwrite with [BIDTEK] default

BEGIN
    UPDATE dbo.IMWE
    SET     IMWE.UploadVal = 'N'
    FROM    IMWE
    WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @OtherVetYNID AND @OtherVetYNID <> 0 AND ( ISNULL(IMWE.UploadVal,
                                                                                                        '') NOT IN ( 'Y',
            'N' ) OR @OverwriteOtherVetYN = 'Y' )

END  --OtherVetYN


/** VetDischargeDate    bDate 4   bDate **/
DECLARE @VetDischargeDateID INT;
SELECT  @VetDischargeDateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'VetDischargeDate', @rectype, 'N');
DECLARE @OverwriteVetDischargeDate bYN;
SELECT  @OverwriteVetDischargeDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'VetDischargeDate', @rectype); -- Overwrite with [BIDTEK] default


/** OccupCat     10  bspHRPROccupCatVal varchar **/
DECLARE @OccupCatID INT;
SELECT  @OccupCatID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'OccupCat', @rectype, 'N');
DECLARE @OverwriteOccupCat bYN;
SELECT  @OverwriteOccupCat = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'OccupCat', @rectype); -- Overwrite with [BIDTEK] default



/** CatStatus     1  bspPROccupCatStatusVal char **/
DECLARE @CatStatusID INT;
SELECT  @CatStatusID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CatStatus', @rectype, 'N');
DECLARE @OverwriteCatStatus bYN;
SELECT  @OverwriteCatStatus = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CatStatus', @rectype); -- Overwrite with [BIDTEK] default



/** LicClass     1   char **/
DECLARE @LicClassID INT;
SELECT  @LicClassID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'LicClass', @rectype, 'N');
DECLARE @OverwriteLicClass bYN;
SELECT  @OverwriteLicClass = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'LicClass', @rectype); -- Overwrite with [BIDTEK] default

BEGIN

	/* insert invalid values */
    INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
            SELECT TOP 100
                    IMWE.ImportId, IMWE.ImportTemplate, @Form, IMWE.RecordSeq, 1, '**Invalid LicClass', @LicClassID
            FROM    IMWE
            WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @LicClassID AND @LicClassID <> 0 AND ( IMWE.UploadVal IS NOT NULL AND IMWE.UploadVal NOT IN (
                    'A', 'B', 'C', 'D' ) )
END  --LicClass


/** DOLHireState    bState 4   varchar **/
DECLARE @DOLHireStateID INT;
SELECT  @DOLHireStateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'DOLHireState', @rectype, 'N');
DECLARE @OverwriteDOLHireState bYN;
SELECT  @OverwriteDOLHireState = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'DOLHireState', @rectype); -- Overwrite with [BIDTEK] default


/** NonResAlienYN   Required bYN 1   char **/
DECLARE @NonResAlienYNID INT;
SELECT  @NonResAlienYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'NonResAlienYN', @rectype, 'N');
DECLARE @OverwriteNonResAlienYN bYN;
SELECT  @OverwriteNonResAlienYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'NonResAlienYN', @rectype); -- Overwrite with [BIDTEK] default

BEGIN
    UPDATE dbo.IMWE
    SET     IMWE.UploadVal = 'N'
    FROM    IMWE
    WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @NonResAlienYNID AND @NonResAlienYNID <> 0 AND ( ISNULL(IMWE.UploadVal,
                                                                                                        '') NOT IN ( 'Y',
            'N' ) OR @OverwriteNonResAlienYN = 'Y' )
END  --NonResAlienYN


/** Country     2  vspHQCountryStateVal char **/
DECLARE @CountryID INT;
SELECT  @CountryID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Country', @rectype, 'N');
DECLARE @OverwriteCountry bYN;
SELECT  @OverwriteCountry = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Country', @rectype); -- Overwrite with [BIDTEK] default


/** LicCountry     2  vspHQCountryStateVal char **/
DECLARE @LicCountryID INT;
SELECT  @LicCountryID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'LicCountry', @rectype, 'N');
DECLARE @OverwriteLicCountry bYN;
SELECT  @OverwriteLicCountry = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'LicCountry', @rectype); -- Overwrite with [BIDTEK] default



/** OTOpt   Required  1   char **/
DECLARE @OTOptID INT;
SELECT  @OTOptID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'OTOpt', @rectype, 'N');
DECLARE @OverwriteOTOpt bYN;
SELECT  @OverwriteOTOpt = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'OTOpt', @rectype); -- Overwrite with [BIDTEK] default


/** OTSched     1  bspPROTSchedVal tinyint **/
DECLARE @OTSchedID INT;
SELECT  @OTSchedID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'OTSched', @rectype, 'N');
DECLARE @OverwriteOTSched bYN;
SELECT  @OverwriteOTSched = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'OTSched', @rectype); -- Overwrite with [BIDTEK] default

BEGIN 
	/* insert invalid values */
    INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
            SELECT TOP 100
                    IMWE.ImportId, IMWE.ImportTemplate, @Form, IMWE.RecordSeq, 1, '**Invalid OTSched', @OTSchedID
            FROM    IMWE
            LEFT JOIN IMWE a
            ON      a.ImportTemplate = IMWE.ImportTemplate AND a.ImportId = IMWE.ImportId AND a.RecordSeq = IMWE.RecordSeq AND a.RecordType = IMWE.RecordType AND a.Identifier = @PRCoID AND ISNULL(@PRCoID,
                                                                                                        0) IS NOT NULL
            LEFT JOIN PROT b
            ON      b.PRCo = a.UploadVal AND b.OTSched = IMWE.UploadVal
            WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @OTSchedID AND @OTSchedID <> 0 AND ( IMWE.UploadVal IS NOT NULL ) AND b.OTSched IS NULL -- doesnt exist 
END  --OTSched


/** Shift     1   tinyint **/
DECLARE @ShiftID INT;
SELECT  @ShiftID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Shift', @rectype, 'N');
DECLARE @OverwriteShift bYN;
SELECT  @OverwriteShift = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Shift', @rectype); -- Overwrite with [BIDTEK] default

BEGIN
	/* insert invalid values */
    INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
            SELECT TOP 100
                    IMWE.ImportId, IMWE.ImportTemplate, @Form, IMWE.RecordSeq, 1, '**Invalid Shift', @ShiftID
            FROM    IMWE
            WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @ShiftID AND @ShiftID <> 0 AND ( IMWE.UploadVal IS NOT NULL AND IMWE.UploadVal NOT LIKE '[ 0-2][ 0-9][ 0-9]' )
END  --Shift


/** PTOAppvrGrp    bGroup 1  vspHRApprovalGroupVal bGroup **/
DECLARE @PTOAppvrGrpID INT;
SELECT  @PTOAppvrGrpID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PTOAppvrGrp', @rectype, 'N');
DECLARE @OverwritePTOAppvrGrp bYN;
SELECT  @OverwritePTOAppvrGrp = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PTOAppvrGrp', @rectype); -- Overwrite with [BIDTEK] default

BEGIN
	/* insert invalid values */
    INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
            SELECT TOP 100
                    IMWE.ImportId, IMWE.ImportTemplate, @Form, IMWE.RecordSeq, 1, '**Invalid PTOAppvrGrp',
                    @PTOAppvrGrpID
            FROM    IMWE
            LEFT JOIN IMWE a
            ON      a.ImportTemplate = IMWE.ImportTemplate AND a.ImportId = IMWE.ImportId AND a.RecordSeq = IMWE.RecordSeq AND a.RecordType = IMWE.RecordType AND a.Identifier = @HRCoID AND @HRCoID IS NOT NULL
            LEFT JOIN dbo.HRAG b
            ON      b.HRCo = a.UploadVal AND b.PTOAppvrGrp = IMWE.UploadVal
            WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @PTOAppvrGrpID AND @PTOAppvrGrpID <> 0 AND ( IMWE.UploadVal IS NOT NULL ) AND b.PTOAppvrGrp IS NULL -- doesnt exist 
END  --PTOAppvrGrp


/** AFServiceMedalVetYN   Required bYN 1   bYN **/
DECLARE @AFServiceMedalVetYNID INT;
SELECT  @AFServiceMedalVetYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'AFServiceMedalVetYN', @rectype, 'N');
DECLARE @OverwriteAFServiceMedalVetYN bYN;
SELECT  @OverwriteAFServiceMedalVetYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'AFServiceMedalVetYN',
                                                                  @rectype); -- Overwrite with [BIDTEK] default

BEGIN
    UPDATE dbo.IMWE
    SET     IMWE.UploadVal = 'N'
    FROM    IMWE
    WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @rectype AND IMWE.Identifier = @AFServiceMedalVetYNID AND @AFServiceMedalVetYNID <> 0 AND ( ISNULL(IMWE.UploadVal,
                                                                                                        '') NOT IN ( '',
            'Y', 'N' ) OR @OverwriteAFServiceMedalVetYN = 'Y' )
END  --AFServiceMedalVetYN



/** WOTaxState    bState 4  vspHQCountryStateVal varchar **/
DECLARE @WOTaxStateID INT;
SELECT  @WOTaxStateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'WOTaxState', @rectype, 'N');
DECLARE @OverwriteWOTaxState bYN;
SELECT  @OverwriteWOTaxState = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'WOTaxState', @rectype); -- Overwrite with [BIDTEK] default


/** WOLocalCode    bLocalCode 10  bspHRPRLocalVal bLocalCode **/
DECLARE @WOLocalCodeID INT;
SELECT  @WOLocalCodeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'WOLocalCode', @rectype, 'N');
DECLARE @OverwriteWOLocalCode bYN;
SELECT  @OverwriteWOLocalCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'WOLocalCode', @rectype); -- Overwrite with [BIDTEK] default


-- special for PREM

  
   -- Check ImportTemplate detail for columns to set Bidtek Defaults
IF NOT EXISTS ( SELECT TOP 1
                        1
                FROM    IMTD WITH ( NOLOCK )
                WHERE   IMTD.ImportTemplate = @ImportTemplate AND IMTD.DefaultValue = '[Bidtek]' AND IMTD.RecordType = @rectype ) 
    GOTO bspexit;
  
  
    --Start Processing
DECLARE @Recseq INT
  , @Tablename VARCHAR(20)
  , @Column VARCHAR(30)
  , @Uploadval VARCHAR(60)
  , @Ident INT
  , @complete INT
  , @currrecseq INT
  , @allownull INT
  , @error INT
  , @tsql VARCHAR(255)
  , @valuelist VARCHAR(255)
  , @columnlist VARCHAR(255)
  , @records INT
  , @oldrecseq INT
  
/******************/
/*** Identifiers ***/
/*******************/
 

/***HRCo***/
DECLARE @IsHRCoEmpty bYN
  , @HRCo bCompany
/***HRRef***/
DECLARE @IsHRRefEmpty bYN
  , @HRRef bHRRef
/***PRCo***/
DECLARE @IsPRCoEmpty bYN
  , @PRCo bCompany
/***PREmp***/
DECLARE @IsPREmpEmpty bYN
  , @PREmp bEmployee
/***LastName***/
DECLARE @IsLastNameEmpty bYN
  , @LastName VARCHAR(30)
/***FirstName***/
DECLARE @IsFirstNameEmpty bYN
  , @FirstName VARCHAR(30)
/***MiddleName***/
DECLARE @IsMiddleNameEmpty bYN
  , @MiddleName VARCHAR(15)
/***SortName***/
DECLARE @IsSortNameEmpty bYN  
  , @SortName VARCHAR(15)
/***Address***/
DECLARE @IsAddressEmpty bYN
  , @Address VARCHAR(60)
/***City***/
DECLARE @IsCityEmpty bYN
  , @City VARCHAR(30)
/***State***/
DECLARE @IsStateEmpty bYN
  , @State VARCHAR(4)
/***Zip***/
DECLARE @IsZipEmpty bYN
  , @Zip bZip
/***Address2***/
DECLARE @IsAddress2Empty bYN
  , @Address2 VARCHAR(60)
/***Phone***/
DECLARE @IsPhoneEmpty bYN
  , @Phone bPhone
/***WorkPhone***/
DECLARE @IsWorkPhoneEmpty bYN;
DECLARE @WorkPhone bPhone

/***CellPhone***/
DECLARE @IsCellPhoneEmpty bYN;
DECLARE @CellPhone bPhone

/***SSN***/
DECLARE @IsSSNEmpty bYN;
DECLARE @SSN CHAR(11)
/***Sex***/
DECLARE @IsSexEmpty bYN;
DECLARE @Sex CHAR(1)
/***Race***/
DECLARE @IsRaceEmpty bYN;
DECLARE @Race CHAR(1)

/***TermDate***/
DECLARE @IsTermDateEmpty bYN;
DECLARE @TermDate bDate
/***TermReason***/
DECLARE @IsTermReasonEmpty bYN;
DECLARE @TermReason VARCHAR(20)
/***ActiveYN***/
DECLARE @IsActiveYNEmpty bYN;
DECLARE @ActiveYN bYN

/***Status***/
DECLARE @IsStatusEmpty bYN;
DECLARE @Status VARCHAR(10)

/***PRGroup***/
DECLARE @IsPRGroupEmpty bYN;
DECLARE @PRGroup bGroup

/***PRDept***/
DECLARE @IsPRDeptEmpty bYN;
DECLARE @PRDept bDept

/***StdCraft***/
DECLARE @IsStdCraftEmpty bYN;
DECLARE @StdCraft bCraft

/***StdClass***/
DECLARE @IsStdClassEmpty bYN;
DECLARE @StdClass bClass

/***StdInsCode***/
DECLARE @IsStdInsCodeEmpty bYN;
DECLARE @StdInsCode bInsCode

/***StdTaxState***/
DECLARE @IsStdTaxStateEmpty bYN;
DECLARE @StdTaxState VARCHAR(4)

/***StdUnempState***/
DECLARE @IsStdUnempStateEmpty bYN;
DECLARE @StdUnempState VARCHAR(4)

/***StdInsState***/
DECLARE @IsStdInsStateEmpty bYN;
DECLARE @StdInsState VARCHAR(4)

/***StdLocal***/
DECLARE @IsStdLocalEmpty bYN;
DECLARE @StdLocal bLocalCode

/***W4CompleteYN***/
DECLARE @IsW4CompleteYNEmpty bYN;
DECLARE @W4CompleteYN bYN

/***PositionCode***/
DECLARE @IsPositionCodeEmpty bYN;
DECLARE @PositionCode VARCHAR(10)

/***NoRehireYN***/
DECLARE @IsNoRehireYNEmpty bYN;
DECLARE @NoRehireYN bYN

/***MaritalStatus***/

DECLARE @IsMaritalStatusEmpty bYN;
DECLARE @MaritalStatus CHAR(1)

/***HandicapYN***/
DECLARE @IsHandicapYNEmpty bYN;
DECLARE @HandicapYN bYN

/***VetJobCategory***/
DECLARE @IsVetJobCategoryEmpty bYN;
DECLARE @VetJobCategory VARCHAR(2)

/***PhysicalYN***/

DECLARE @IsPhysicalYNEmpty bYN;
DECLARE @PhysicalYN bYN

/***PhysDate***/

DECLARE @IsPhysDateEmpty bYN;
DECLARE @PhysDate bDate

/***PhysExpireDate***/

DECLARE @IsPhysExpireDateEmpty bYN;
DECLARE @PhysExpireDate bDate

/***LicNumber***/

DECLARE @IsLicNumberEmpty bYN;
DECLARE @LicNumber VARCHAR(20)

/***LicType***/

DECLARE @IsLicTypeEmpty bYN;
DECLARE @LicType VARCHAR(20)

/***LicState***/

DECLARE @IsLicStateEmpty bYN;
DECLARE @LicState VARCHAR(4)

/***LicExpDate***/

DECLARE @IsLicExpDateEmpty bYN;
DECLARE @LicExpDate bDate

/***DriveCoVehiclesYN***/

DECLARE @IsDriveCoVehiclesYNEmpty bYN;
DECLARE @DriveCoVehiclesYN bYN

/***I9Status***/

DECLARE @IsI9StatusEmpty bYN;
DECLARE @I9Status VARCHAR(20)

/***I9Citizen***/

DECLARE @IsI9CitizenEmpty bYN;
DECLARE @I9Citizen VARCHAR(20)

/***I9ReviewDate***/

DECLARE @IsI9ReviewDateEmpty bYN;
DECLARE @I9ReviewDate bDate

/***ExistsInPR***/
DECLARE @IsExistsInPREmpty bYN;
DECLARE @ExistsInPR bYN

/***EarnCode***/
DECLARE @IsEarnCodeEmpty bYN;
DECLARE @EarnCode bEDLCode

/***Email***/
DECLARE @IsEmailEmpty bYN;
DECLARE @Email VARCHAR(60)

/***Suffix***/
DECLARE @IsSuffixEmpty bYN;
DECLARE @Suffix VARCHAR(4)

/***OccupCat***/
DECLARE @IsOccupCatEmpty bYN;
DECLARE @OccupCat VARCHAR(10)

/***CatStatus***/
DECLARE @IsCatStatusEmpty bYN;
DECLARE @CatStatus CHAR(1)


/***DOLHireState***/
DECLARE @IsDOLHireStateEmpty bYN;
DECLARE @DOLHireState VARCHAR(4)

/***NonResAlienYN***/
DECLARE @IsNonResAlienYNEmpty bYN;
DECLARE @NonResAlienYN CHAR(1)

/***Country***/
DECLARE @IsCountryEmpty bYN;
DECLARE @Country CHAR(2)

/***LicCountry***/
DECLARE @IsLicCountryEmpty bYN;
DECLARE @LicCountry CHAR(2)

/***OTOpt***/
DECLARE @IsOTOptEmpty bYN
  , @OTOpt CHAR(1)
DECLARE @IsOTSchedEmpty bYN
  , @OTSched TINYINT
DECLARE @IsShiftEmpty bYN
  , @Shift TINYINT
   DECLARE @IsPTOAppvrGrpEmpty bYN
  , @PTOAppvrGrp bGroup
DECLARE @IsWOTaxStateEmpty bYN
  , @WOTaxState VARCHAR(4)
DECLARE @IsWOLocalCodeEmpty bYN
  , @WOLocalCode bLocalCode;	

/* these are for update HR with PR info if an employee*/
DECLARE @PRPRCo [bCompany]
  , @PREmployee bEmployee
  , @PRLastName VARCHAR(30)
  , @PRFirstName VARCHAR(30)
  , @PRMiddleName VARCHAR(15)
  , @PRSortName VARCHAR(15)
  , @PRAddress VARCHAR(60)
  , @PRCity VARCHAR(30)
  , @PRState VARCHAR(40)
  , @PRZip bZip
  , @PRAddress2 VARCHAR(60)
  , @PRPhone bPhone
  , @PRCellPhone [bPhone]
  , @PRSSN [char](11)
  , @PRSex [char](1)
  , @PRRace [char](2)
  , @PRBirthDate [smalldatetime]
  , @PRHireDate [bDate]
  , @PRTermDate [bDate]
  , @PRActiveYN [bYN]
  , @PRPRGroup [bGroup]
  , @PRPRDept [bDept]
  , @PRStdCraft [bCraft]
  , @PRStdClass [bClass]
  , @PRStdInsCode [bInsCode]
  , @PRStdTaxState [varchar](4)
  , @PRStdUnempState [varchar](4)
  , @PRStdInsState [varchar](4)
  , @PRStdLocal [bLocalCode]
  , @PRExistsInPR [bYN]
  , @PREarnCode [bEDLCode]
  , @PREmail [varchar](60)
  , @PRSuffix [varchar](4)
  , @PROccupCat [varchar](10)
  , @PRCatStatus [char](1)
  , @PRNonResAlienYN [char](1)
  , @PRCountry [char](2)
  , @PROTOpt [char](1)
  , @PROTSched [tinyint]
  , @PRShift [tinyint]
  , @PRWOTaxState [varchar](4)
  , @PRWOLocalCode [bLocalCode]
	

DECLARE WorkEditCursor CURSOR LOCAL FAST_FORWARD
FOR
SELECT  IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
FROM    IMWE WITH ( NOLOCK )
INNER JOIN DDUD
ON      IMWE.Identifier = DDUD.Identifier AND DDUD.Form = IMWE.Form
WHERE   IMWE.ImportId = @ImportId AND IMWE.ImportTemplate = @ImportTemplate AND IMWE.Form = @Form
ORDER BY IMWE.RecordSeq, IMWE.Identifier

OPEN WorkEditCursor
-- set open cursor flag
SELECT  @CursorOpen = 1

  
SELECT  @complete = 0

FETCH NEXT FROM WorkEditCursor INTO @Recseq, @Ident, @Tablename, @Column, @Uploadval
SELECT  @complete = @@fetch_status
SELECT  @currrecseq = @Recseq

-- while cursor is not empty 
WHILE @complete = 0 
    BEGIN
-- if rec sequence = current rec sequence flag
        IF @Recseq = @currrecseq 
            BEGIN
 
                IF @Column = 'HRCo' 
                    BEGIN
                        SELECT  @HRCo = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsHRCoEmpty = 'Y'
                        ELSE 
                            SET @IsHRCoEmpty = 'N'
                    END
                IF @Column = 'HRRef' 
                    BEGIN
                        SELECT  @HRRef = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsHRRefEmpty = 'Y'
                        ELSE 
                            SET @IsHRRefEmpty = 'N'
                    END
                IF @Column = 'PRCo' 
                    BEGIN
                        SELECT  @PRCo = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsPRCoEmpty = 'Y'
                        ELSE 
                            SET @IsPRCoEmpty = 'N'
                    END
                IF @Column = 'PREmp' 
                    BEGIN
                        SELECT  @PREmp = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsPREmpEmpty = 'Y'
                        ELSE 
                            SET @IsPREmpEmpty = 'N'
                    END
                IF @Column = 'LastName' 
                    BEGIN
                        SELECT  @LastName = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsLastNameEmpty = 'Y'
                        ELSE 
                            SET @IsLastNameEmpty = 'N'
                     
                            
                    END
                IF @Column = 'FirstName' 
                    BEGIN
                        SELECT  @FirstName = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsFirstNameEmpty = 'Y'
                        ELSE 
                            SET @IsFirstNameEmpty = 'N'
                    END
                IF @Column = 'MiddleName' 
                    BEGIN
                        SELECT  @MiddleName = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsMiddleNameEmpty = 'Y'
                        ELSE 
                            SET @IsMiddleNameEmpty = 'N'
                    END
                IF @Column = 'SortName' 
                    BEGIN
                        SELECT  @SortName = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsSortNameEmpty = 'Y'
                        ELSE 
                            SET @IsSortNameEmpty = 'N'
                    END
                IF @Column = 'Address' 
                    BEGIN
                        SELECT  @Address = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsAddressEmpty = 'Y'
                        ELSE 
                            SET @IsAddressEmpty = 'N'
                    END
                IF @Column = 'City' 
                    BEGIN
                        SELECT  @City = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsCityEmpty = 'Y'
                        ELSE 
                            SET @IsCityEmpty = 'N'
                    END
                IF @Column = 'State' 
                    BEGIN
                        SELECT  @State = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsStateEmpty = 'Y'
                        ELSE 
                            SET @IsStateEmpty = 'N'
                    END
                IF @Column = 'Zip' 
                    BEGIN
                        SELECT  @Zip = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsZipEmpty = 'Y'
                        ELSE 
                            SET @IsZipEmpty = 'N'
                    END
                IF @Column = 'Address2' 
                    BEGIN
                        SELECT  @Address2 = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsAddress2Empty = 'Y'
                        ELSE 
                            SET @IsAddress2Empty = 'N'
                    END
                IF @Column = 'Phone' 
                    BEGIN
                        SELECT  @Phone = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsPhoneEmpty = 'Y'
                        ELSE 
                            SET @IsPhoneEmpty = 'N'
                    END
                IF @Column = 'WorkPhone' 
                    BEGIN
                        SELECT  @WorkPhone = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsWorkPhoneEmpty = 'Y'
                        ELSE 
                            SET @IsWorkPhoneEmpty = 'N'
                    END

                IF @Column = 'CellPhone' 
                    BEGIN
                        SELECT  @CellPhone = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsCellPhoneEmpty = 'Y'
                        ELSE 
                            SET @IsCellPhoneEmpty = 'N'
                    END
                IF @Column = 'SSN' 
                    BEGIN
                        SELECT  @SSN = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsSSNEmpty = 'Y'
                        ELSE 
                            SET @IsSSNEmpty = 'N'
                    END
                IF @Column = 'Sex' 
                    BEGIN
                        SELECT  @Sex = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsSexEmpty = 'Y'
                        ELSE 
                            SET @IsSexEmpty = 'N'
                    END
                IF @Column = 'Race' 
                    BEGIN
                        SELECT  @Race = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsRaceEmpty = 'Y'
                        ELSE 
                            SET @IsRaceEmpty = 'N'
                    END

                 IF @Column = 'TermDate' 
                    BEGIN
                        SELECT  @TermDate = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsTermDateEmpty = 'Y'
                        ELSE 
                            SET @IsTermDateEmpty = 'N'
                    END
                IF @Column = 'TermReason' 
                    BEGIN
                        SELECT  @TermReason = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsTermReasonEmpty = 'Y'
                        ELSE 
                            SET @IsTermReasonEmpty = 'N'
                    END
                IF @Column = 'ActiveYN' 
                    BEGIN
                        SELECT  @ActiveYN = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsActiveYNEmpty = 'Y'
                        ELSE 
                            SET @IsActiveYNEmpty = 'N'
                    END
                IF @Column = 'Status' 
                    BEGIN
                        SELECT  @Status = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsStatusEmpty = 'Y'
                        ELSE 
                            SET @IsStatusEmpty = 'N'
                    END
                IF @Column = 'PRGroup' 
                    BEGIN
                        SELECT  @PRGroup = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsPRGroupEmpty = 'Y'
                        ELSE 
                            SET @IsPRGroupEmpty = 'N'
                    END
                IF @Column = 'PRDept' 
                    BEGIN
                        SELECT  @PRDept = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsPRDeptEmpty = 'Y'
                        ELSE 
                            SET @IsPRDeptEmpty = 'N'
                    END
                IF @Column = 'StdCraft' 
                    BEGIN
                        SELECT  @StdCraft = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsStdCraftEmpty = 'Y'
                        ELSE 
                            SET @IsStdCraftEmpty = 'N'
                    END
                IF @Column = 'StdClass' 
                    BEGIN
                        SELECT  @StdClass = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsStdClassEmpty = 'Y'
                        ELSE 
                            SET @IsStdClassEmpty = 'N'
                    END
                IF @Column = 'StdInsCode' 
                    BEGIN
                        SELECT  @StdInsCode = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsStdInsCodeEmpty = 'Y'
                        ELSE 
                            SET @IsStdInsCodeEmpty = 'N'
                    END
                IF @Column = 'StdTaxState' 
                    BEGIN
                        SELECT  @StdTaxState = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsStdTaxStateEmpty = 'Y'
                        ELSE 
                            SET @IsStdTaxStateEmpty = 'N'
                    END
                IF @Column = 'StdUnempState' 
                    BEGIN
                        SELECT  @StdUnempState = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsStdUnempStateEmpty = 'Y'
                        ELSE 
                            SET @IsStdUnempStateEmpty = 'N'
                    END
                IF @Column = 'StdInsState' 
                    BEGIN
                        SELECT  @StdInsState = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsStdInsStateEmpty = 'Y'
                        ELSE 
                            SET @IsStdInsStateEmpty = 'N'
                    END
                IF @Column = 'StdLocal' 
                    BEGIN
                        SELECT  @StdLocal = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsStdLocalEmpty = 'Y'
                        ELSE 
                            SET @IsStdLocalEmpty = 'N'
                    END
                IF @Column = 'W4CompleteYN' 
                    BEGIN
                        SELECT  @W4CompleteYN = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsW4CompleteYNEmpty = 'Y'
                        ELSE 
                            SET @IsW4CompleteYNEmpty = 'N'
                    END
                IF @Column = 'PositionCode' 
                    BEGIN
                        SELECT  @PositionCode = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsPositionCodeEmpty = 'Y'
                        ELSE 
                            SET @IsPositionCodeEmpty = 'N'
                    END
                IF @Column = 'NoRehireYN' 
                    BEGIN
                        SELECT  @NoRehireYN = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsNoRehireYNEmpty = 'Y'
                        ELSE 
                            SET @IsNoRehireYNEmpty = 'N'
                    END
                IF @Column = 'MaritalStatus' 
                    BEGIN
                        SELECT  @MaritalStatus = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsMaritalStatusEmpty = 'Y'
                        ELSE 
                            SET @IsMaritalStatusEmpty = 'N'
                    END

                IF @Column = 'HandicapYN' 
                    BEGIN
                        SELECT  @HandicapYN = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsHandicapYNEmpty = 'Y'
                        ELSE 
                            SET @IsHandicapYNEmpty = 'N'
                    END

                IF @Column = 'VetJobCategory' 
                    BEGIN
                        SELECT  @VetJobCategory = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsVetJobCategoryEmpty = 'Y'
                        ELSE 
                            SET @IsVetJobCategoryEmpty = 'N'
                    END
                IF @Column = 'PhysicalYN' 
                    BEGIN
                        SELECT  @PhysicalYN = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsPhysicalYNEmpty = 'Y'
                        ELSE 
                            SET @IsPhysicalYNEmpty = 'N'
                    END
                IF @Column = 'PhysDate' 
                    BEGIN
                        SELECT  @PhysDate = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsPhysDateEmpty = 'Y'
                        ELSE 
                            SET @IsPhysDateEmpty = 'N'
                    END
                IF @Column = 'PhysExpireDate' 
                    BEGIN
                        SELECT  @PhysExpireDate = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsPhysExpireDateEmpty = 'Y'
                        ELSE 
                            SET @IsPhysExpireDateEmpty = 'N'
                    END

                IF @Column = 'LicNumber' 
                    BEGIN
                        SELECT  @LicNumber = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsLicNumberEmpty = 'Y'
                        ELSE 
                            SET @IsLicNumberEmpty = 'N'
                    END
                IF @Column = 'LicType' 
                    BEGIN
                        SELECT  @LicType = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsLicTypeEmpty = 'Y'
                        ELSE 
                            SET @IsLicTypeEmpty = 'N'
                    END
                IF @Column = 'LicState' 
                    BEGIN
                        SELECT  @LicState = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsLicStateEmpty = 'Y'
                        ELSE 
                            SET @IsLicStateEmpty = 'N'
                    END
                IF @Column = 'LicExpDate' 
                    BEGIN
                        SELECT  @LicExpDate = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsLicExpDateEmpty = 'Y'
                        ELSE 
                            SET @IsLicExpDateEmpty = 'N'
                    END
                IF @Column = 'DriveCoVehiclesYN' 
                    BEGIN
                        SELECT  @DriveCoVehiclesYN = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsDriveCoVehiclesYNEmpty = 'Y'
                        ELSE 
                            SET @IsDriveCoVehiclesYNEmpty = 'N'
                    END
                IF @Column = 'I9Status' 
                    BEGIN
                        SELECT  @I9Status = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsI9StatusEmpty = 'Y'
                        ELSE 
                            SET @IsI9StatusEmpty = 'N'
                    END
                IF @Column = 'I9Citizen' 
                    BEGIN
                        SELECT  @I9Citizen = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsI9CitizenEmpty = 'Y'
                        ELSE 
                            SET @IsI9CitizenEmpty = 'N'
                    END
                IF @Column = 'I9ReviewDate' 
                    BEGIN
                        SELECT  @I9ReviewDate = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsI9ReviewDateEmpty = 'Y'
                        ELSE 
                            SET @IsI9ReviewDateEmpty = 'N'
                    END


                IF @Column = 'ExistsInPR' 
                    BEGIN
                        SELECT  @ExistsInPR = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsExistsInPREmpty = 'Y'
                        ELSE 
                            SET @IsExistsInPREmpty = 'N'
                    END
                IF @Column = 'EarnCode' 
                    BEGIN
                        SELECT  @EarnCode = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsEarnCodeEmpty = 'Y'
                        ELSE 
                            SET @IsEarnCodeEmpty = 'N'
                    END
                IF @Column = 'Email' 
                    BEGIN
                        SELECT  @Email = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsEmailEmpty = 'Y'
                        ELSE 
                            SET @IsEmailEmpty = 'N'
                    END
                IF @Column = 'Suffix' 
                    BEGIN
                        SELECT  @Suffix = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsSuffixEmpty = 'Y'
                        ELSE 
                            SET @IsSuffixEmpty = 'N'
                    END
                IF @Column = 'OccupCat' 
                    BEGIN
                        SELECT  @OccupCat = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsOccupCatEmpty = 'Y'
                        ELSE 
                            SET @IsOccupCatEmpty = 'N'
                    END
                IF @Column = 'CatStatus' 
                    BEGIN
                        SELECT  @CatStatus = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsCatStatusEmpty = 'Y'
                        ELSE 
                            SET @IsCatStatusEmpty = 'N'
                    END
                IF @Column = 'DOLHireState' 
                    BEGIN
                        SELECT  @DOLHireState = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsDOLHireStateEmpty = 'Y'
                        ELSE 
                            SET @IsDOLHireStateEmpty = 'N'
                    END
                IF @Column = 'NonResAlienYN' 
                    BEGIN
                        SELECT  @NonResAlienYN = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsNonResAlienYNEmpty = 'Y'
                        ELSE 
                            SET @IsNonResAlienYNEmpty = 'N'
                    END
                IF @Column = 'Country' 
                    BEGIN
                        SELECT  @Country = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsCountryEmpty = 'Y'
                        ELSE 
                            SET @IsCountryEmpty = 'N'
                    END
                IF @Column = 'LicCountry' 
                    BEGIN
                        SELECT  @LicCountry = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsLicCountryEmpty = 'Y'
                        ELSE 
                            SET @IsLicCountryEmpty = 'N'
                    END
                IF @Column = 'OTOpt' 
                    BEGIN
                        SELECT  @OTOpt = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsOTOptEmpty = 'Y'
                        ELSE 
                            SET @IsOTOptEmpty = 'N'
                    END
                IF @Column = 'OTSched' 
                    BEGIN
                        SELECT  @OTSched = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsOTSchedEmpty = 'Y'
                        ELSE 
                            SET @IsOTSchedEmpty = 'N'
                    END
                IF @Column = 'Shift' 
                    BEGIN
                        SELECT  @Shift = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsShiftEmpty = 'Y'
                        ELSE 
                            SET @IsShiftEmpty = 'N'
                    END
                IF @Column = 'PTOAppvrGrp' 
                    BEGIN
                        SELECT  @PTOAppvrGrp = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsPTOAppvrGrpEmpty = 'Y'
                        ELSE 
                            SET @IsPTOAppvrGrpEmpty = 'N'
                    END
                IF @Column = 'WOTaxState' 
                    BEGIN
                        SELECT  @WOTaxState = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsWOTaxStateEmpty = 'Y'
                        ELSE 
                            SET @IsWOTaxStateEmpty = 'N'
                    END
                IF @Column = 'WOLocalCode' 
                    BEGIN
                        SELECT  @WOLocalCode = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsWOLocalCodeEmpty = 'Y'
                        ELSE 
                            SET @IsWOLocalCodeEmpty = 'N'
                    END

 
                SELECT  @oldrecseq = @Recseq

--fetch next record
                FETCH NEXT FROM WorkEditCursor INTO @Recseq, @Ident, @Tablename, @Column, @Uploadval

-- if this is the last record, set the sequence to -1 to process last record.

                IF @@fetch_status <> 0 
                    SELECT  @Recseq = -1
            END -- same Seq
        ELSE 
            BEGIN -- different Seq
 
                SELECT  @PRExistsInPR = 'N'

/* HRRef   Required bHRRef 4  bspHRResourceValbHRRef */
                IF ISNULL(@IsHRRefEmpty, 'Y') = 'Y' 
                    BEGIN
                        SELECT  @HRRef = MAX(HRRef) + @currrecseq
                        FROM    dbo.HRRM
                        WHERE   dbo.HRRM.HRCo = @HRCo
            
						SELECT @IsHRRefEmpty='N'
                        UPDATE dbo.IMWE
                        SET     IMWE.UploadVal = @HRRef
                        WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @HRRefID AND IMWE.RecordType = @rectype
                    END	


/* PREmp    bEmployee 4  bspHRPREmpValUniquebEmployee */
                IF ISNULL(@IsPREmpEmpty, 'Y') <> 'Y' 
                    BEGIN
                        BEGIN
            SELECT  @PRPRCo = [PRCo], @PREmployee = [Employee], @PRLastName = [LastName],
                    @PRFirstName = [FirstName], @PRMiddleName = [MidName], @PRSortName = [SortName],
                    @PRAddress = [Address], @PRCity = [City], @PRState = [State], @PRZip = [Zip],
                    @PRAddress2 = [Address2], @PRPhone = [Phone], @PRCellPhone = [CellPhone],
                    @PRSSN = [SSN], @PRSex = [Sex], @PRRace = [Race], @PRBirthDate = [BirthDate],
                    @PRHireDate = [HireDate], @PRTermDate = [TermDate], @ActiveYN = [ActiveYN],
                    @PRPRGroup = [PRGroup], @PRPRDept = [PRDept], @PRStdCraft = [Craft],
                    @PRStdClass = [Class], @PRStdInsCode = [InsCode], @PRStdTaxState = [TaxState],
                    @PRStdUnempState = [UnempState], @PRStdInsState = [InsState],
                    @PRStdLocal = [LocalCode], @PRExistsInPR = 'Y', @PREarnCode = [EarnCode],
                    @PREmail = [Email], @PRSuffix = [Suffix], @PROccupCat = [OccupCat],
                    @PRCatStatus = [CatStatus], @PRNonResAlienYN = [NonResAlienYN],
                    @PRCountry = [Country], @PROTOpt = [OTOpt], @OTSched = [OTSched], @PRShift = [Shift],
                    @PRWOTaxState = [WOTaxState], @PRWOLocalCode = [WOLocalCode]
            FROM    PREH
            WHERE   dbo.PREH.PRCo = @PRCo AND dbo.PREH.Employee = @PREmp
        END
        IF ISNULL(@SSN, '') <> ISNULL(@PRSSN, 'zzzz') 
			OR UPPER(ISNULL(@LastName, '')) <> UPPER(ISNULL(@PRLastName,'zzzz')) 
			OR UPPER(ISNULL(@FirstName,'')) <> UPPER(ISNULL(@PRFirstName, 'zzzz')) 
                            BEGIN
                                SELECT  @PREmp = NULL, @PRExistsInPR = 'N', @rcode = 1,
                                        @desc = ISNULL(@msg, '** PREmp does not match PR')
                                INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
                                VALUES  ( @ImportId, @ImportTemplate, @Form, @currrecseq, @rcode, @desc, @PREmpID )			
                                UPDATE dbo.IMWE
                                SET     IMWE.UploadVal = '** Invalid **'
                                WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
									AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @PREmpID AND IMWE.RecordType = @rectype
                            END	
                    END
               
                    

/* SortName   Required bHRResourceSortName 15  bspHRSortNameUniquevarchar */
                IF ( ISNULL(@OverwriteSortName, 'Y') = 'Y' OR ISNULL(@IsSortNameEmpty, 'Y') = 'Y' ) 
                    BEGIN
                        DECLARE @hreccount INT
                          , @resourcetemp VARCHAR(10)
                          , @wreccount INT
                        SELECT  @SortName = UPPER(ISNULL(@LastName, '') + ISNULL(@FirstName, ''))

--check if the sortname is in use by another Resource
                        SELECT  @hreccount = COUNT(*)
                        FROM    bHRRM WITH ( NOLOCK )
                        WHERE   HRCo = @HRCo AND SortName = @SortName AND HRRef <> @HRRef	--exclude existing record for this firm
                        IF @hreccount > 0 --if sortname is already in use, append HRREF number
                            BEGIN	--(max length of SortName is 15 characters)
                                SELECT  @resourcetemp = CONVERT(VARCHAR(10), @HRRef)	
                                SELECT  @SortName = UPPER(RTRIM(LEFT(ISNULL(@LastName, '') + ISNULL(@FirstName, ''), 15 - LEN(@resourcetemp)))) + @resourcetemp
                            END
--issue #123214, also check IMWE for existing SortName.
                        SELECT  @hreccount = COUNT(*)
                        FROM    IMWE
                        WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.Identifier = @SortNameID AND IMWE.RecordType = @rectype AND IMWE.UploadVal = @SortName
                        IF @hreccount > 0	--if sortname is already in use, append firm number
                            BEGIN	--(max length of SortName is 15 characters)
                                SELECT  @resourcetemp = CONVERT(VARCHAR(10), @HRRef)
                                SELECT  @SortName = UPPER(RTRIM(LEFT(ISNULL(@LastName, '') + ISNULL(@FirstName, ''),15 - LEN(@resourcetemp)))) + @resourcetemp
                            END
                        UPDATE dbo.IMWE
                        SET     IMWE.UploadVal = @SortName
                        WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @SortNameID AND IMWE.RecordType = @rectype
                    END

/* rewrite exists in PR if something has changed */
                BEGIN
                    UPDATE dbo.IMWE
                    SET     IMWE.UploadVal = @PRExistsInPR
                    FROM    IMWE
                    WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
						AND IMWE.RecordType = @rectype AND IMWE.Identifier = @ExistsInPRID 
						AND @ExistsInPRID <> 0 AND ISNULL(IMWE.UploadVal, '') <> @PRExistsInPR OR @OverwriteExistsInPR = 'Y'
                END

			
/* Country     2  vspHQCountryStateValchar */
       --         IF @PRExistsInPR = 'Y' 
       --             BEGIN
       --                 SELECT  @Country = @PRCountry
       --                 UPDATE dbo.IMWE
       --                 SET     IMWE.UploadVal = @Country
       --                 WHERE   IMWE.ImportTemplate = @ImportTemplate 
							--AND IMWE.ImportId = @ImportId 
							--AND IMWE.RecordSeq = @currrecseq 
							--AND IMWE.Identifier = @CountryID 
							--AND IMWE.RecordType = @rectype
       --             END
                IF @Country IS NOT NULL 
                    BEGIN -- sp_helptext vspHQCountryStateVal
                        EXEC @rc= vspHQCountryStateVal @hqco = @HRCo, @country = @Country, @state = NULL, @msg = @msg output 
                        IF @rc <> 0 
                            BEGIN
                                SELECT  @Country = NULL
									, @rcode = @rc, 
									@desc = ISNULL(@msg, 'Country Invalid')
                                INSERT  INTO IMWM ( ImportId, ImportTemplate, Form,
									 RecordSeq, Error, Message, Identifier )
                                VALUES  ( @ImportId, @ImportTemplate, @Form, 
									@currrecseq, @rcode, @desc, @CountryID )			
                                UPDATE dbo.IMWE
                                SET     IMWE.UploadVal = '** Invalid Country **'  --
                                WHERE   IMWE.ImportTemplate = @ImportTemplate 
									AND IMWE.ImportId = @ImportId 
									AND IMWE.RecordSeq = @currrecseq 
									AND IMWE.Identifier = @CountryID 
									AND IMWE.RecordType = @rectype
                            END	
                    END 

/* Dont Update First or Last Name comming from PR*/
/* MiddleName     15  varchar */
                IF @PRExistsInPR = 'Y' AND @MiddleName IS null
                    BEGIN
                        UPDATE dbo.IMWE
                        SET     IMWE.UploadVal = @PRMiddleName
                        WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @MiddleNameID AND IMWE.RecordType = @rectype
                    END

/* Address     60  varchar */
                IF @PRExistsInPR = 'Y' AND @Address IS null
                    BEGIN
                        UPDATE dbo.IMWE
                        SET     IMWE.UploadVal = @PRAddress
                        WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @AddressID AND IMWE.RecordType = @rectype AND ISNULL(IMWE.UploadVal,'')<>@PRAddress
                    END

/* City     30  varchar */
                IF @PRExistsInPR = 'Y'  AND @City IS null
                    BEGIN
                        UPDATE dbo.IMWE
                        SET     IMWE.UploadVal = @PRCity
                        WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @CityID AND IMWE.RecordType = @rectype
                    END

/* State    bState 4  vspHQCountryStateValvarchar */
                IF @PRExistsInPR = 'Y'  AND @State IS null
                    BEGIN
                        SELECT  @State = @PRState
                        UPDATE dbo.IMWE
                        SET     IMWE.UploadVal = @State
                        WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @StateID AND IMWE.RecordType = @rectype
                    END
     
/* Zip    bZip 12  bZip */
                IF @PRExistsInPR = 'Y'  AND @Zip IS null
                    BEGIN
                        SELECT  @Zip = @PRZip
                        UPDATE dbo.IMWE
                        SET     IMWE.UploadVal = @PRZip
                        WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @ZipID AND IMWE.RecordType = @rectype
                    END
     

/* Address2     60  varchar */
                IF @PRExistsInPR = 'Y'  AND @Address2 IS null
                    BEGIN
						SELECT  @Address2 = @PRAddress2
                        UPDATE dbo.IMWE
                        SET     IMWE.UploadVal = @PRAddress2
                        WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @Address2ID AND IMWE.RecordType = @rectype
                    END

/* Phone    bPhone 20  bPhone */
                IF @PRExistsInPR = 'Y'  AND @Phone IS null
                    BEGIN
                        UPDATE dbo.IMWE
                        SET     IMWE.UploadVal = @PRPhone
                        WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @PhoneID AND IMWE.RecordType = @rectype
                    END

/* CellPhone    bPhone 20  bPhone */
                IF @PRExistsInPR = 'Y' AND @CellPhone IS null
                    BEGIN
                        UPDATE dbo.IMWE
                        SET     IMWE.UploadVal = @PRCellPhone
                        WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @CellPhoneID AND IMWE.RecordType = @rectype
                    END
     
     
/* SSN   Required  11 \d{3}[-]?\d{2}[-]?\d{4} bspHRSSNUniquechar */
                IF ISNULL(@Country,'US')='US' AND @SSN is not null and @SSN NOT LIKE '[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]' 
                    BEGIN
                        SELECT  @SSN = NULL, @rcode = 1, @desc = ISNULL(@msg, 'SSN Invalid')
                        INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq,
							 Error, Message, Identifier )
                        VALUES  ( @ImportId, @ImportTemplate, @Form, @currrecseq
							, @rcode, @desc, @SSNID )			
                        UPDATE dbo.IMWE
                        SET     IMWE.UploadVal = '** Invalid SSN format **'
                        WHERE   IMWE.ImportTemplate = @ImportTemplate 
							AND IMWE.ImportId = @ImportId 
							AND IMWE.RecordSeq = @currrecseq 
							AND IMWE.Identifier = @SSNID AND IMWE.RecordType = @rectype
                    END	

/* SSN Unique*/
				EXEC @rc = [dbo].[bspHRSSNUnique] @HRCo, @PRCo, @HRRef, @SSN, @msg OUTPUT
				IF @rc <>0 
                    BEGIN
                        UPDATE dbo.IMWE
                        SET     IMWE.UploadVal = '** SSN exists in HR or PR'
                        WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @SSNID AND IMWE.RecordType = @rectype
						INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
								SELECT  @ImportId, @ImportTemplate, @Form, @currrecseq, 1, '** SSN exists in HR or PR', @SSNID			
                    END

/* SortName Unique  although at this point we should have generated a new SortName if a duplicate this is a double check */
				EXEC @rc = [dbo].[bspHRSortNameUnique] @HRCo, @HRRef, @SortName, @msg OUTPUT
				IF @rc <>0 
                    BEGIN
                        UPDATE dbo.IMWE
                        SET     IMWE.UploadVal = '** SortName exists in HR '
                        WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
							AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @SortNameID AND IMWE.RecordType = @rectype
						INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
						SELECT  @ImportId, @ImportTemplate, @Form, @currrecseq, 1, '** SSN exists in HR', @SortNameID
                    END
  				IF @PREmp IS NOT NULL
  				BEGIN
  					EXEC @rc = [dbo].[bspPRSortNameUnique] @prco=@PRCo, @empl=@PREmp, @sortname=@SortName, @msg=@msg OUTPUT
					IF @rc <>0 
						BEGIN
							UPDATE dbo.IMWE
							SET     IMWE.UploadVal = '** SortName exists in PR'
							WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
								AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @SortNameID AND IMWE.RecordType = @rectype
						END
				END

/* Sex   Required  1  char */
                IF @PRExistsInPR = 'Y' AND @Sex IS null
                    BEGIN
                        UPDATE dbo.IMWE
                        SET     IMWE.UploadVal = @PRSex
                        WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @SexID AND IMWE.RecordType = @rectype
                    END

/* Race     2  bspPRRaceValchar */
                IF @PRExistsInPR = 'Y' AND @Race IS null
                    BEGIN
                        UPDATE dbo.IMWE
                        SET     IMWE.UploadVal = @PRRace
                        WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @currrecseq 
                         AND IMWE.Identifier = @RaceID AND IMWE.RecordType = @rectype
                    END


--/* TermReason     20  bspHRCodeValvarchar */
                IF @TermReason IS NOT NULL 
                    BEGIN
                        EXEC @rc= dbo.bspHRCodeVal  -- -1,115,'N'
                            @HRCo = @HRCo, @Code = @TermReason, @Type = 'N', @msg = @msg output 
                        IF @rc <> 0 
                            BEGIN
                                SELECT  @TermReason = NULL, @rcode = @rc
									, @desc = ISNULL(@msg, 'TermReason Invalid')
                                INSERT  INTO IMWM ( ImportId, ImportTemplate, Form,
									 RecordSeq, Error, Message, Identifier )
                                VALUES  ( @ImportId, @ImportTemplate, @Form
									, @currrecseq, @rcode, @desc, @TermReasonID )
                                UPDATE dbo.IMWE
                                SET     IMWE.UploadVal = '** Invalid **'
                                WHERE   IMWE.ImportTemplate = @ImportTemplate 
									AND IMWE.ImportId = @ImportId 
									AND IMWE.RecordSeq = @currrecseq 
									AND IMWE.Identifier = @TermReasonID 
									AND IMWE.RecordType = @rectype
                            END	
                    END

/* Status     10  bspHRStatCodeValvarchar */
                IF @Status IS NOT NULL 
                    BEGIN
                        EXEC @rc= bspHRStatCodeVal @HRCo = @HRCo, @Code = @Status
							, @msg = @msg output 
                        IF @rc <> 0 
                            BEGIN
                                SELECT  @Status = NULL, @rcode = @rc
									, @desc = ISNULL(@msg, 'Status Invalid')
                                INSERT  INTO IMWM ( ImportId, ImportTemplate, Form
									, RecordSeq, Error, Message, Identifier )
                                VALUES  ( @ImportId, @ImportTemplate, @Form
									, @currrecseq, @rcode, @desc, @StatusID )			
                                UPDATE dbo.IMWE
                                SET     IMWE.UploadVal = '** Invalid **'
                                WHERE   IMWE.ImportTemplate = @ImportTemplate 
									AND IMWE.ImportId = @ImportId 
									AND IMWE.RecordSeq = @currrecseq 
									AND IMWE.Identifier = @StatusID 
									AND IMWE.RecordType = @rectype
                            END	
                    END

/* PRGroup    bPRGroup 1  bspHRPRGroupValbGroup */
       --         IF @PRExistsInPR = 'Y' AND @PRGroup IS null
       --             BEGIN
       --                 SELECT  @PRGroup = @PRPRGroup
       --                 UPDATE dbo.IMWE
       --                 SET     IMWE.UploadVal = @PRPRGroup
       --                 WHERE   IMWE.ImportTemplate = @ImportTemplate 
							--AND IMWE.ImportId = @ImportId 
							--AND IMWE.RecordSeq = @currrecseq 
							--AND IMWE.Identifier = @PRGroupID 
							--AND IMWE.RecordType = @rectype
       --             END
                IF @PRGroup IS NOT NULL 
                    BEGIN
                        EXEC @rc= bspHRPRGroupVal @hrco = @HRCo, @prco = @PRCo
							, @group = @PRGroup, @msg = @msg output 
                        IF @rc <> 0 
                            BEGIN
                                SELECT  @PRGroup = NULL, @rcode = @rc
									, @desc = ISNULL(@msg, 'PRGroup Invalid')
                                INSERT  INTO IMWM ( ImportId, ImportTemplate, Form
									, RecordSeq, Error, Message, Identifier )
                                VALUES  ( @ImportId, @ImportTemplate, @Form
									, @currrecseq, @rcode, @desc, @PRGroupID )			
                                UPDATE dbo.IMWE
                                SET     IMWE.UploadVal = '** Invalid PRGroup **'
                                WHERE   IMWE.ImportTemplate = @ImportTemplate 
									AND IMWE.ImportId = @ImportId 
									AND IMWE.RecordSeq = @currrecseq 
									AND IMWE.Identifier = @PRGroupID 
									AND IMWE.RecordType = @rectype
                            END	
                    END

/* PRDept    bPRDept 10  bspHRPRDeptValbDept */
       --         IF @PRExistsInPR = 'Y' 
       --             BEGIN
       --                 UPDATE dbo.IMWE
       --                 SET     IMWE.UploadVal = @PRPRDept
       --                 WHERE   IMWE.ImportTemplate = @ImportTemplate 
							--AND IMWE.ImportId = @ImportId 
							--AND IMWE.RecordSeq = @currrecseq 
							--AND IMWE.Identifier = @PRDeptID
							--AND IMWE.RecordType = @rectype
       --             END
               IF @PRDept IS NOT null 
                 BEGIN
                    EXEC @rc= bspHRPRDeptVal -- -1,5,140
                        @hrco = @HRCo, @prco = @PRCo, @dept = @PRDept, @msg = @msg output 
                    IF @rc <> 0 
                        BEGIN
                            SELECT  @PRDept = NULL, @rcode = @rc
								, @desc = ISNULL(@msg, 'PRDept Invalid')
                            INSERT  INTO IMWM ( ImportId, ImportTemplate, Form
								, RecordSeq, Error, Message, Identifier )
                            VALUES  ( @ImportId, @ImportTemplate, @Form
								, @currrecseq, @rcode, @desc, @PRDeptID )			
                            UPDATE dbo.IMWE
                            SET     IMWE.UploadVal = '** Invalid **'
                            WHERE   IMWE.ImportTemplate = @ImportTemplate 
								AND IMWE.ImportId = @ImportId 
								AND IMWE.RecordSeq = @currrecseq 
								AND IMWE.Identifier = @PRDeptID 
								AND IMWE.RecordType = @rectype
                        END	
                END

/* StdCraft    bCraft 10  bspHRPRCraftValbCraft */
       --         IF @PRExistsInPR = 'Y' 
       --             BEGIN
       --                 SELECT  @StdCraft = @PRStdCraft
       --                 UPDATE dbo.IMWE
       --                 SET     IMWE.UploadVal = @PRStdCraft
       --                 WHERE   IMWE.ImportTemplate = @ImportTemplate 
							--AND IMWE.ImportId = @ImportId 
							--AND IMWE.RecordSeq = @currrecseq 
							--AND IMWE.Identifier = @StdCraftID 
							--AND IMWE.RecordType = @rectype
       --             END
                IF @StdCraft IS NOT null
                BEGIN
                    EXEC @rc= bspHRPRCraftVal -- -1,5,145
                        @hrco = @HRCo, @prco = @PRCo, @craft = @StdCraft, @msg = @msg output 
                    IF @rc <> 0 
                        BEGIN
                            SELECT  @StdCraft = NULL, @rcode = @rc, @desc = ISNULL(@msg, 'StdCraft Invalid')
                            INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
                            VALUES  ( @ImportId, @ImportTemplate, @Form, @currrecseq, @rcode, @desc, @StdCraftID )			
                            UPDATE dbo.IMWE
                            SET     IMWE.UploadVal = '** Invalid **'
                            WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @StdCraftID AND IMWE.RecordType = @rectype
                        END	
                END

/* StdClass    bClass 10  bspHRPRCraftClassValbClass */
                --IF @PRExistsInPR = 'Y' 
                --    BEGIN
                --        SELECT  @StdClass = @PRStdClass
                --        UPDATE dbo.IMWE
                --        SET     IMWE.UploadVal = @PRStdClass
                --        WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @StdClassID AND IMWE.RecordType = @rectype
                --    END
                IF @StdClass IS NOT null
                BEGIN
                    EXEC @rc= bspHRPRCraftClassVal @hrco = @HRCo, @prco = @PRCo, @craft = @StdCraft, @class = @StdClass,
                        @msg = @msg output 
                    IF @rc <> 0 
                        BEGIN
                            SELECT  @StdClass = NULL, @rcode = @rc, @desc = ISNULL(@msg, 'StdClass Invalid')
                            INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
                            VALUES  ( @ImportId, @ImportTemplate, @Form, @currrecseq, @rcode, @desc, @StdClassID )			
                            UPDATE dbo.IMWE
                            SET     IMWE.UploadVal = '** Invalid **'
                            WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @StdClassID AND IMWE.RecordType = @rectype
                        END	
                END
     


/* StdInsCode    bInsCode 10  bspHQInsCodeValbInsCode */
                --IF @PRExistsInPR = 'Y' 
                --    BEGIN
                --        SELECT  @StdInsCode = @PRStdInsCode
                --        UPDATE dbo.IMWE
                --        SET     IMWE.UploadVal = @PRStdInsCode
                --        WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @StdInsCodeID AND IMWE.RecordType = @rectype
                --    END
                IF @StdInsCode IS NOT NULL
                BEGIN
                    EXEC @rc= bspHQInsCodeVal @inscode = @StdInsCode, @msg = @msg output 
                    IF @rc <> 0 
                        BEGIN
                            SELECT  @StdInsCode = NULL, @rcode = @rc, @desc = ISNULL(@msg, 'StdInsCode Invalid')
                            INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
                            VALUES  ( @ImportId, @ImportTemplate, @Form, @currrecseq, @rcode, @desc, @StdInsCodeID )			
                            UPDATE dbo.IMWE
                            SET     IMWE.UploadVal = '** Invalid **'
                            WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @StdInsCodeID AND IMWE.RecordType = @rectype
                        END	
                END 	


/* StdTaxState    bState 4  vspHQCountryStateValvarchar */
                --IF @PRExistsInPR = 'Y' 
                --    BEGIN
                --        SELECT  @StdTaxState = @PRStdTaxState
                --        UPDATE dbo.IMWE
                --        SET     IMWE.UploadVal = @StdTaxState
                --        WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @StdTaxStateID AND IMWE.RecordType = @rectype
                --    END
                IF @StdTaxState IS NOT NULL 
                    BEGIN
                        EXEC @rc= vspHQCountryStateVal @hqco = @HRCo, @country = @Country, @state = @StdTaxState,
                            @msg = @msg output 
                        IF @rc <> 0 
                            BEGIN
                                SELECT  @StdTaxState = NULL, @rcode = @rc, @desc = ISNULL(@msg, 'StdTaxState Invalid')
                                INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message,
                                                    Identifier )
                                VALUES  ( @ImportId, @ImportTemplate, @Form, @currrecseq, @rcode, @desc, @StdTaxStateID )			
                                UPDATE dbo.IMWE
                                SET     IMWE.UploadVal = '** Invalid **'
                                WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @StdTaxStateID AND IMWE.RecordType = @rectype
                            END	
                    END 	
    
/* StdUnempState    bState 4  vspHQCountryStateValvarchar */
       --         IF @PRExistsInPR = 'Y' 
       --             BEGIN
       --                 SELECT  @StdUnempState = @PRStdUnempState
       --                 UPDATE dbo.IMWE
       --                 SET     IMWE.UploadVal = @StdUnempState
       --                 WHERE   IMWE.ImportTemplate = @ImportTemplate 
							--AND IMWE.ImportId = @ImportId 
							--AND IMWE.RecordSeq = @currrecseq 
							--AND IMWE.Identifier = @StdUnempStateID AND IMWE.RecordType = @rectype
       --             END
                IF @StdUnempState IS NOT NULL 
                    BEGIN
                        EXEC @rc= vspHQCountryStateVal @hqco = @HRCo
							,@country = @Country, @state = @StdUnempState,@msg = @msg output 
                        IF @rc <> 0 
                            BEGIN
                                SELECT  @StdUnempState = NULL, @rcode = @rc,
                                        @desc = ISNULL(@msg, 'StdUnempState Invalid')
                                INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message,
                                                    Identifier )
                                VALUES  ( @ImportId, @ImportTemplate, @Form, @currrecseq, @rcode, @desc,
                                          @StdUnempStateID )			
                                UPDATE dbo.IMWE
                                SET     IMWE.UploadVal = '** Invalid **'
                                WHERE   IMWE.ImportTemplate = @ImportTemplate 
									AND IMWE.ImportId = @ImportId 
									AND IMWE.RecordSeq = @currrecseq 
									AND IMWE.Identifier = @StdUnempStateID 
									AND IMWE.RecordType = @rectype
                            END	
                    END 

/* StdInsState    bState 4  vspHQCountryStateValvarchar */
                --IF @PRExistsInPR = 'Y' 
                --    BEGIN
                --        SELECT  @StdInsState = @PRStdInsState
                --        UPDATE dbo.IMWE
                --        SET     IMWE.UploadVal = @StdInsState
                --        WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @StdInsStateID AND IMWE.RecordType = @rectype
                --    END
                IF @StdInsState IS NOT NULL 
                    BEGIN
                        EXEC @rc= vspHQCountryStateVal @hqco = @HRCo
                        , @country = @Country, @state = @StdInsState, @msg = @msg output 
                        IF @rc <> 0 
                            BEGIN
                                SELECT  @StdInsState = NULL, @rcode = @rc
									, @desc = ISNULL(@msg, 'StdInsState Invalid')
                                INSERT  INTO IMWM ( ImportId, ImportTemplate, Form
									, RecordSeq, Error, Message,Identifier )
                                VALUES  ( @ImportId, @ImportTemplate, @Form
									, @currrecseq, @rcode, @desc, @StdInsStateID )
                                UPDATE dbo.IMWE
                                SET     IMWE.UploadVal = '** Invalid **'
                                WHERE   IMWE.ImportTemplate = @ImportTemplate 
									AND IMWE.ImportId = @ImportId 
									AND IMWE.RecordSeq = @currrecseq 
									AND IMWE.Identifier = @StdInsStateID 
									AND IMWE.RecordType = @rectype
                            END	
                    END 

/* StdLocal    bLocalCode 10  bspHRPRLocalValbLocalCode */
                --IF @PRExistsInPR = 'Y' 
                --    BEGIN
                --        SELECT  @StdLocal = @PRStdLocal
                --        UPDATE dbo.IMWE
                --        SET     IMWE.UploadVal = @StdLocal
                --        WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @StdLocalID AND IMWE.RecordType = @rectype
                --    END
                IF @StdLocal IS NOT NULL 
                    BEGIN
                        EXEC @rc= bspHRPRLocalVal @hrco = @HRCo, @prco = @PRCo
							, @local = @StdLocal, @msg = @msg output 
                        IF @rc <> 0 
                            BEGIN
                                SELECT  @StdLocal = NULL, @rcode = @rc
									, @desc = ISNULL(@msg, 'StdLocal Invalid')
                                INSERT  INTO IMWM ( ImportId, ImportTemplate, Form
									, RecordSeq, Error, Message, Identifier )
                                VALUES  ( @ImportId, @ImportTemplate, @Form
									, @currrecseq, @rcode, @desc, @StdLocalID )			
                                UPDATE dbo.IMWE
                                SET     IMWE.UploadVal = '** Invalid **'
                                WHERE   IMWE.ImportTemplate = @ImportTemplate 
									AND IMWE.ImportId = @ImportId 
									AND IMWE.RecordSeq = @currrecseq 
									AND IMWE.Identifier = @StdLocalID 
									AND IMWE.RecordType = @rectype
                            END	
                    END 

/* PositionCode     10  bspHRPositionVal varchar */
                IF @PositionCode IS NOT NULL 
                    BEGIN
                        EXEC @rc= bspHRPositionVal -- -1,130
                            @HRCo = @HRCo, @Code = @PositionCode, @msg = @msg output 
                        IF @rc <> 0 
                            BEGIN
                                SELECT  @PositionCode = NULL, @rcode = @rc
									, @desc = ISNULL(@msg, 'PositionCode Invalid')
                                INSERT  INTO IMWM ( ImportId, ImportTemplate, Form
									, RecordSeq, Error, Message, Identifier )
                                VALUES  ( @ImportId, @ImportTemplate, @Form, @currrecseq, @rcode, @desc, @PositionCodeID )			
                                UPDATE dbo.IMWE
                                SET     IMWE.UploadVal = '** Invalid **'
                                WHERE   IMWE.ImportTemplate = @ImportTemplate 
									AND IMWE.ImportId = @ImportId 
									AND IMWE.RecordSeq = @currrecseq 
									AND IMWE.Identifier = @PositionCodeID 
									AND IMWE.RecordType = @rectype
                            END	
                    END

/* LicState    bState 4  vspHQCountryStateValvarchar */
                IF @LicState IS NOT NULL 
                    BEGIN
                        EXEC @rc= vspHQCountryStateVal @hqco = @HRCo
							, @country = @Country, @state = @LicState, @msg = @msg output 
                        IF @rc <> 0 
                            BEGIN
                                SELECT  @LicState = NULL, @rcode = @rc
									, @desc = ISNULL(@msg, 'LicState Invalid')
                                INSERT  INTO IMWM ( ImportId, ImportTemplate, Form
									, RecordSeq, Error, Message, Identifier )
                                VALUES  ( @ImportId, @ImportTemplate, @Form
									, @currrecseq, @rcode, @desc, @LicStateID )			
                                UPDATE dbo.IMWE
                                SET     IMWE.UploadVal = '** Invalid **'
                                WHERE   IMWE.ImportTemplate = @ImportTemplate 
									AND IMWE.ImportId = @ImportId 
									AND IMWE.RecordSeq = @currrecseq 
									AND IMWE.Identifier = @LicStateID 
									AND IMWE.RecordType = @rectype
                            END	
                    END 


/* EarnCode    bEDLCode 2  bspHRPREarnDedLiabValbEDLCode */
       --         IF @PRExistsInPR = 'Y' 
       --             BEGIN
       --                 SELECT  @EarnCode = @PREarnCode
       --                 UPDATE dbo.IMWE
       --                 SET     IMWE.UploadVal =  @EarnCode
       --                 WHERE   IMWE.ImportTemplate = @ImportTemplate 
							--AND IMWE.ImportId = @ImportId
							--AND IMWE.RecordSeq = @currrecseq 
							--AND IMWE.Identifier = @EarnCodeID 
							--AND IMWE.RecordType = @rectype
       --             END
                IF @EarnCode IS NOT NULL 
                    BEGIN
                        IF NOT EXISTS ( SELECT  * FROM    PREC
                                        WHERE   PRCo = @PRCo 
											AND dbo.PREC.EarnCode = @EarnCode ) 
                            BEGIN
                                SELECT  @EarnCode = NULL, @rcode = 1
									, @desc = ISNULL(@msg, 'EarnCode Invalid')
                                INSERT  INTO IMWM ( ImportId, ImportTemplate, Form
									, RecordSeq, Error, Message, Identifier )
                                VALUES  ( @ImportId, @ImportTemplate, @Form
									, @currrecseq, @rcode, @desc, @EarnCodeID )			
                                UPDATE dbo.IMWE
                                SET     IMWE.UploadVal = '** Invalid **'
                                WHERE   IMWE.ImportTemplate = @ImportTemplate 
									AND IMWE.ImportId = @ImportId 
									AND IMWE.RecordSeq = @currrecseq 
									AND IMWE.Identifier = @EarnCodeID 
									AND IMWE.RecordType = @rectype
                            END	
                    END

/* Email     60  varchar */
       --         IF @PRExistsInPR = 'Y' 
       --             BEGIN
       --                 SELECT  @Email = @PREmail
       --                 UPDATE dbo.IMWE
       --                 SET     IMWE.UploadVal = @Email
       --                 WHERE   IMWE.ImportTemplate = @ImportTemplate 
							--AND IMWE.ImportId = @ImportId 
							--AND IMWE.RecordSeq = @currrecseq 
							--AND IMWE.Identifier = @EmailID 
							--AND IMWE.RecordType = @rectype
       --             END
     
/* Suffix     4  varchar */
     --               IF @PRExistsInPR = 'Y' 
					--BEGIN
					--	SELECT  @Suffix = @PRSuffix
					--	UPDATE dbo.IMWE
					--	SET     IMWE.UploadVal = @Suffix
					--	WHERE   IMWE.ImportTemplate = @ImportTemplate 
					--		AND IMWE.ImportId = @ImportId 
					--		AND IMWE.RecordSeq = @currrecseq 
					--		AND IMWE.Identifier = @SuffixID 
					--		AND IMWE.RecordType = @rectype
					--END

/* OccupCat     10  bspHRPROccupCatValvarchar */

                --IF @PRExistsInPR = 'Y' 
                --    BEGIN
                --        SELECT  @OccupCat = @PROccupCat
                --        UPDATE dbo.IMWE
                --        SET     IMWE.UploadVal = @OccupCat
                --        WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @OccupCatID AND IMWE.RecordType = @rectype
                --    END
                IF @OccupCat IS NOT NULL 
                    BEGIN
                        EXEC @rc= bspHRPROccupCatVal -- -1,130
                            @hrco = @HRCo, @prco = @PRCo, @occupcat = @OccupCat
                            , @msg = @msg output 
                        IF @rc <> 0 
                            BEGIN
                                SELECT  @OccupCat = NULL, @rcode = @rc
									, @desc = ISNULL(@msg, 'OccupCat Invalid')
                                INSERT  INTO IMWM ( ImportId, ImportTemplate, Form
									, RecordSeq, Error, Message,Identifier )
                                VALUES  ( @ImportId, @ImportTemplate, @Form
									, @currrecseq, @rcode, @desc, @OccupCatID )			
                                UPDATE dbo.IMWE
                                SET     IMWE.UploadVal = '** Invalid **'
                                WHERE   IMWE.ImportTemplate = @ImportTemplate 
									AND IMWE.ImportId = @ImportId 
									AND IMWE.RecordSeq = @currrecseq 
									AND IMWE.Identifier = @OccupCatID 
									AND IMWE.RecordType = @rectype
                            END	
                    END
    
    
/* CatStatus     1  bspPROccupCatStatusValchar */

       --         IF @PRExistsInPR = 'Y' 
       --             BEGIN
       --                 SELECT  @CatStatus = @PRCatStatus
       --                 UPDATE dbo.IMWE
       --                 SET     IMWE.UploadVal = @CatStatus
       --                 WHERE   IMWE.ImportTemplate = @ImportTemplate 
							--AND IMWE.ImportId = @ImportId 
							--AND IMWE.RecordSeq = @currrecseq 
							--AND IMWE.Identifier = @CatStatusID 
							--AND IMWE.RecordType = @rectype
       --             END
                IF @CatStatus IS NOT NULL 
                    BEGIN
                        EXEC @rc= bspPROccupCatStatusVal -- -1,130
                            @catstatus = @CatStatus, @msg = @msg output 
                        IF @rc <> 0 
                            BEGIN
                                SELECT  @CatStatus = NULL, @rcode = @rc
									, @desc = ISNULL(@msg, 'CatStatus Invalid')
                                INSERT  INTO IMWM ( ImportId, ImportTemplate, Form
									, RecordSeq, Error, Message, Identifier )
                                VALUES  ( @ImportId, @ImportTemplate, @Form
									, @currrecseq, @rcode, @desc, @CatStatusID )
                                UPDATE dbo.IMWE
                                SET     IMWE.UploadVal = '** Invalid **'
                                WHERE   IMWE.ImportTemplate = @ImportTemplate 
									AND IMWE.ImportId = @ImportId 
									AND IMWE.RecordSeq = @currrecseq 
									AND IMWE.Identifier = @CatStatusID 
									AND IMWE.RecordType = @rectype
                            END	
                    END
    
    
/* LicCountry     2  vspHQCountryStateValchar */
                --IF @PRExistsInPR = 'Y' 
                    IF @LicCountry IS NOT NULL 
                        BEGIN
                            EXEC @rc= vspHQCountryStateVal @hqco = @HRCo, @country = @LicCountry, @state = NULL,
                                @msg = @msg output 
                            IF @rc <> 0 
                                BEGIN
                                    SELECT  @LicCountry = NULL, @rcode = @rc,
                                            @desc = ISNULL(@msg, 'License Country Invalid')
                                    INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message,
                                                        Identifier )
                                    VALUES  ( @ImportId, @ImportTemplate, @Form, @currrecseq, @rcode, @desc, @CountryID )			
                                    UPDATE dbo.IMWE
                                    SET     IMWE.UploadVal = '** Invalid **'
                                    WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @LicCountryID AND IMWE.RecordType = @rectype
                                END	
                        END 	

	

/* OTSched     1  bspPROTSchedVal tinyint */
                IF ( ISNULL(@OverwriteOTSched, 'Y') = 'Y' OR ISNULL(@IsStdUnempStateEmpty, 'Y') = 'Y' ) 
                    BEGIN
                        UPDATE dbo.IMWE
                        SET     IMWE.UploadVal = '1'
                        WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @currrecseq AND IMWE.Identifier = @OTSchedID AND @OTSchedID > 0 AND IMWE.RecordType = @rectype AND ( dbo.IMWE.UploadVal IS NULL OR ISNULL(@OverwriteOTSched,
                                                                                                        'N') = 'Y' )
                    END


/* WOTaxState    bState 4  vspHQCountryStateValvarchar */
                IF @WOTaxState IS NOT NULL 
                    BEGIN
                        EXEC @rc= vspHQCountryStateVal @hqco = @HRCo
							, @country = @Country, @state = @StdTaxState, @msg = @msg output 
                        IF @rc <> 0 
                            BEGIN
                                SELECT  @WOTaxState = NULL, @rcode = @rc
									, @desc = ISNULL(@msg, 'WOTaxState Invalid')
                                INSERT  INTO IMWM ( ImportId, ImportTemplate, Form
									, RecordSeq, Error, Message, Identifier )
                                VALUES  ( @ImportId, @ImportTemplate, @Form
									, @currrecseq, @rcode, @desc, @WOTaxStateID )
                                UPDATE dbo.IMWE
                                SET     IMWE.UploadVal = '** Invalid **'
                                WHERE   IMWE.ImportTemplate = @ImportTemplate 
									AND IMWE.ImportId = @ImportId 
									AND IMWE.RecordSeq = @currrecseq 
									AND IMWE.Identifier = @WOTaxStateID 
									AND IMWE.RecordType = @rectype
                            END	
                    END 	

  
-- set Current Req Seq to next @Recseq unless we are processing last record.
                IF @Recseq = -1 
                    SELECT  @complete = 1	-- exit the loop
                ELSE 
                    SELECT  @currrecseq = @Recseq
            END
    END
SELECT @msg=''

/* FOR EXTRA UPDATE */    
UPDATE dbo.IMWE
SET     IMWE.UploadVal = UPPER(IMWE.UploadVal)
WHERE   IMWE.ImportTemplate = @ImportTemplate
        AND IMWE.ImportId = @ImportId
        AND IMWE.RecordType = @rectype
        AND IMWE.Identifier = @SortNameID
        AND ISNULL(IMWE.UploadVal, '') <> UPPER(ISNULL(IMWE.UploadVal, '')) 

/** Check for dupilicate SSN in import file **/
BEGIN
	/* insert invalid values */
    INSERT  INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier )
            SELECT  TOP 100 IMWE.ImportId, IMWE.ImportTemplate, @Form, IMWE.RecordSeq, 1
				, '**Duplicate SSN in Upload File', @SSNID
            FROM    dbo.IMWE
            JOIN dbo.IMWE AS SSNDups ON IMWE.ImportTemplate=SSNDups.ImportTemplate
				 AND IMWE.ImportId = SSNDups.ImportId AND IMWE.RecordType = SSNDups.RecordType 
				 AND IMWE.Identifier = SSNDups.Identifier AND IMWE.UploadVal = ISNULL(SSNDups.UploadVal ,'')
				 AND IMWE.RecordSeq <> SSNDups.RecordSeq -- =Different Record Number should not have same SSN
            WHERE   IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId 
            AND IMWE.RecordType = @rectype AND IMWE.Identifier = @SSNID AND @SSNID <> 0 
            AND ( IMWE.UploadVal IS NOT NULL ) AND IMWE.UploadVal NOT LIKE '%**%'
END  

bspexit:

IF @CursorOpen = 1 
    BEGIN
        CLOSE WorkEditCursor
        DEALLOCATE WorkEditCursor	
    END

SELECT  @msg = ISNULL(@desc, 'Clear') + CHAR(13) + CHAR(10) + '[vspIMViewpointDefaultsHRRM]'

RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMViewpointDefaultsHRRM] TO [public]
GO
