SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspIMViewpointDefaultsPMPM]  
   /***********************************************************
    * CREATED BY:   Jim Emery  05/13/2013
    *
    * Usage:
    *	Used by Imports to create values for needed or missing
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
    , @msg VARCHAR(120) OUTPUT
    )
AS 
SET nocount ON;
   
DECLARE @rcode INT
  , @desc VARCHAR(120)
  , @status INT
  , @defaultvalue VARCHAR(30)
  , @CursorOpen INT
  , @rc INT;

   /* check required input params */
   
IF @ImportId IS NULL 
    BEGIN;
        SELECT  @desc = 'Missing ImportId.'
              , @rcode = 1;
        GOTO bspexit;
    END;

IF @ImportTemplate IS NULL 
    BEGIN;
        SELECT  @desc = 'Missing ImportTemplate.'
              , @rcode = 1;
        GOTO bspexit;
    END;
   
IF @Form IS NULL 
    BEGIN;
        SELECT  @desc = 'Missing Form.'
              , @rcode = 1;
        GOTO bspexit;
    END;
 

/******************/
/*** Identifiers ***/
/*******************/
DECLARE @maxContactCode INT
 
/***VendorGroup***/
DECLARE @VendorGroupID INT;
DECLARE @OverwriteVendorGroup bYN;
DECLARE @IsVendorGroupEmpty bYN;
DECLARE @VendorGroup bGroup
DECLARE @ynVendorGroup bYN;
SELECT  @ynVendorGroup = 'N';
SELECT  @OverwriteVendorGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'VendorGroup', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @VendorGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'VendorGroup', @rectype, 'N');

/***FirmNumber***/
DECLARE @FirmNumberID INT;
DECLARE @OverwriteFirmNumber bYN;
DECLARE @IsFirmNumberEmpty bYN;
DECLARE @FirmNumber bFirm
DECLARE @ynFirmNumber bYN;
SELECT  @ynFirmNumber = 'N';
SELECT  @OverwriteFirmNumber = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'FirmNumber', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @FirmNumberID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'FirmNumber', @rectype, 'N');

/***ContactCode***/
DECLARE @ContactCodeID INT;
DECLARE @OverwriteContactCode bYN;
DECLARE @IsContactCodeEmpty bYN;
DECLARE @ContactCode bEmployee;
DECLARE @IMWEContactCode bEmployee;
DECLARE @ynContactCode bYN;
SELECT  @ynContactCode = 'N';
SELECT  @OverwriteContactCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ContactCode', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @ContactCodeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ContactCode', @rectype, 'N');

/***SortName***/
DECLARE @SortNameID INT;
DECLARE @OverwriteSortName bYN;
DECLARE @IsSortNameEmpty bYN;
DECLARE @SortName bSortName
DECLARE @ynSortName bYN;
SELECT  @ynSortName = 'N';
SELECT  @OverwriteSortName = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SortName', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @SortNameID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SortName', @rectype, 'N');

/***LastName***/
DECLARE @LastNameID INT;
DECLARE @OverwriteLastName bYN;
DECLARE @IsLastNameEmpty bYN;
DECLARE @LastName VARCHAR(50)
DECLARE @ynLastName bYN;
SELECT  @ynLastName = 'N';
SELECT  @OverwriteLastName = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'LastName', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @LastNameID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'LastName', @rectype, 'N');

/***FirstName***/
DECLARE @FirstNameID INT;
DECLARE @OverwriteFirstName bYN;
DECLARE @IsFirstNameEmpty bYN;
DECLARE @FirstName VARCHAR(50)
DECLARE @ynFirstName bYN;
SELECT  @ynFirstName = 'N';
SELECT  @OverwriteFirstName = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'FirstName', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @FirstNameID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'FirstName', @rectype, 'N');


--/***EMail***/
--DECLARE @EMailID INT;
--DECLARE @OverwriteEMail bYN;
--DECLARE @IsEMailEmpty bYN;
--DECLARE @EMail VARCHAR(100)
--DECLARE @ynEMail bYN;
--SELECT  @ynEMail = 'N';
--SELECT  @OverwriteEMail = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EMail', @rectype); -- Overwrite with [BIDTEK] default
--SELECT  @EMailID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'EMail', @rectype, 'N');

/***PrefMethod***/
DECLARE @PrefMethodID INT;
DECLARE @OverwritePrefMethod bYN;
DECLARE @IsPrefMethodEmpty bYN;
DECLARE @PrefMethod CHAR(1)
DECLARE @ynPrefMethod bYN;
SELECT  @ynPrefMethod = 'N';
SELECT  @OverwritePrefMethod = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PrefMethod', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @PrefMethodID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PrefMethod', @rectype, 'N');


/***ExcludeYN***/
DECLARE @ExcludeYNID INT;
DECLARE @OverwriteExcludeYN bYN;
DECLARE @IsExcludeYNEmpty bYN;
DECLARE @ExcludeYN bYN
DECLARE @ynExcludeYN bYN;
SELECT  @ynExcludeYN = 'N';
SELECT  @OverwriteExcludeYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ExcludeYN', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @ExcludeYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ExcludeYN', @rectype, 'N');

/***MailAddress***/
DECLARE @MailAddressID INT;
DECLARE @OverwriteMailAddress bYN;
DECLARE @IsMailAddressEmpty bYN;
DECLARE @MailAddress VARCHAR(60)
DECLARE @ynMailAddress bYN;
SELECT  @ynMailAddress = 'N';
SELECT  @OverwriteMailAddress = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MailAddress', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @MailAddressID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MailAddress', @rectype, 'N');

/***MailCountry***/
DECLARE @MailCountryID INT;
DECLARE @OverwriteMailCountry bYN;
DECLARE @IsMailCountryEmpty bYN;
DECLARE @MailCountry CHAR(2);
DECLARE @ynMailCountry bYN;
SELECT  @ynMailCountry = 'N';
SELECT  @OverwriteMailCountry = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MailCountry', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @MailCountryID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MailCountry', @rectype, 'N');
    
/***MailState***/
DECLARE @MailStateID INT;
DECLARE @OverwriteMailState bYN;
DECLARE @IsMailStateEmpty bYN;
DECLARE @MailState VARCHAR(4);
DECLARE @ynMailState bYN;
SELECT  @ynMailState = 'N';
SELECT  @OverwriteMailState = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MailState', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @MailStateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MailState', @rectype, 'N');


/***AllowPortalAccess***/
DECLARE @AllowPortalAccessID INT;
DECLARE @OverwriteAllowPortalAccess bYN;
DECLARE @IsAllowPortalAccessEmpty bYN;
DECLARE @AllowPortalAccess bYN
DECLARE @ynAllowPortalAccess bYN;
SELECT  @ynAllowPortalAccess = 'N';
SELECT  @OverwriteAllowPortalAccess = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'AllowPortalAccess', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @AllowPortalAccessID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'AllowPortalAccess', @rectype, 'N');

/* Portal Name*/                       
DECLARE @PortalUserName VARCHAR(60)
DECLARE @IsPortalUserNameEmpty bYN;
                       
/***PortalPassword***/
--DECLARE @PortalPasswordID INT;
--DECLARE @OverwritePortalPassword bYN;
--DECLARE @IsPortalPasswordEmpty bYN;
--DECLARE @PortalPassword VARCHAR(50)
--DECLARE @ynPortalPassword bYN;
--SELECT  @ynPortalPassword = 'N';
--SELECT  @OverwritePortalPassword = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PortalPassword', @rectype); -- Overwrite with [BIDTEK] default
--SELECT  @PortalPasswordID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PortalPassword', @rectype, 'N');

/***PortalDefaultRole***/
DECLARE @PortalDefaultRoleID INT;
DECLARE @OverwritePortalDefaultRole bYN;
DECLARE @IsPortalDefaultRoleEmpty bYN;
DECLARE @PortalDefaultRole INT
DECLARE @ynPortalDefaultRole bYN;
SELECT  @ynPortalDefaultRole = 'N';
SELECT  @OverwritePortalDefaultRole = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PortalDefaultRole', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @PortalDefaultRoleID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PortalDefaultRole', @rectype, 'N');


/***UseAddressOvr***/
DECLARE @UseAddressOvrID INT;
DECLARE @OverwriteUseAddressOvr bYN;
DECLARE @IsUseAddressOvrEmpty bYN;
DECLARE @UseAddressOvr bYN
DECLARE @ynUseAddressOvr bYN;
SELECT  @ynUseAddressOvr = 'N';
SELECT  @OverwriteUseAddressOvr = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UseAddressOvr', @rectype); -- Overwrite with [BIDTEK] default
SELECT  @UseAddressOvrID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UseAddressOvr', @rectype, 'N');

 
   -- Check ImportTemplate detail for columns to set Bidtek Defaults
IF NOT EXISTS ( SELECT TOP 1
                        1
                FROM    dbo.IMTD WITH ( NOLOCK )
                WHERE   IMTD.ImportTemplate = @ImportTemplate
                        AND IMTD.DefaultValue = '[Bidtek]'
                        AND IMTD.RecordType = @rectype ) 
    GOTO bspexit;
    

/* Set VendorGroup */ 
DECLARE @DefVendorGroup bGroup
SELECT  @DefVendorGroup = dbo.HQCO.VendorGroup
FROM    dbo.HQCO
WHERE   dbo.HQCO.HQCo = @Company 
  
SELECT  @VendorGroup = @DefVendorGroup
UPDATE  dbo.IMWE
SET     IMWE.UploadVal = @VendorGroup
WHERE   IMWE.ImportTemplate = @ImportTemplate
        AND IMWE.ImportId = @ImportId
        AND IMWE.Identifier = @VendorGroupID
        AND IMWE.RecordType = @rectype
        AND (ISNULL(@OverwriteVendorGroup, 'Y') = 'Y' OR UploadVal IS NULL ) 
        

         
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
  

  
DECLARE WorkEditCursor CURSOR LOCAL FAST_FORWARD
FOR
SELECT  IMWE.RecordSeq
      , IMWE.Identifier
      , DDUD.TableName
      , DDUD.ColumnName
      , IMWE.UploadVal
FROM    dbo.IMWE WITH ( NOLOCK )
INNER JOIN dbo.DDUD
ON      IMWE.Identifier = DDUD.Identifier
        AND DDUD.Form = IMWE.Form
WHERE   IMWE.ImportId = @ImportId
        AND IMWE.ImportTemplate = @ImportTemplate
        AND IMWE.Form = @Form
ORDER BY IMWE.RecordSeq
      , IMWE.Identifier

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
            IF @Column = 'VendorGroup' 
            BEGIN
                SELECT  @VendorGroup = CASE WHEN ISNUMERIC(@Uploadval) = 1 THEN @Uploadval
                                            ELSE NULL
                                       END
                IF @VendorGroup IS NULL 
                    SET @IsVendorGroupEmpty = 'Y'
                ELSE 
                    SET @IsVendorGroupEmpty = 'N'
            END
            IF @Column = 'FirmNumber' 
                BEGIN
                    SELECT  @FirmNumber = CASE WHEN ISNUMERIC(@Uploadval) = 1 THEN @Uploadval
                                               ELSE NULL
                                          END
                    IF @FirmNumber IS NULL 
                        SET @IsFirmNumberEmpty = 'Y'
                    ELSE 
                        SET @IsFirmNumberEmpty = 'N'
                END
            IF @Column = 'ContactCode' 
                BEGIN
                    SELECT  @ContactCode = CASE WHEN ISNUMERIC(@Uploadval) = 1 THEN @Uploadval
                                                ELSE NULL
                                           END
                    IF @ContactCode IS NULL 
                        SET @IsContactCodeEmpty = 'Y'
                    ELSE 
                        SET @IsContactCodeEmpty = 'N'
                END
            IF @Column = 'SortName' 
                BEGIN
                    SELECT  @SortName = @Uploadval
                    IF @Uploadval IS NULL 
                        SET @IsSortNameEmpty = 'Y'
                    ELSE 
                        SET @IsSortNameEmpty = 'N'
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


            --IF @Column = 'EMail' 
            --    BEGIN
            --        SELECT  @EMail = @Uploadval
            --        IF @Uploadval IS NULL 
            --            SET @IsEMailEmpty = 'Y'
            --        ELSE 
            --            SET @IsEMailEmpty = 'N'
            --    END
            IF @Column = 'PrefMethod' 
                BEGIN
                    SELECT  @PrefMethod = @Uploadval
                    IF @Uploadval IS NULL 
                        SET @IsPrefMethodEmpty = 'Y'
                    ELSE 
                        SET @IsPrefMethodEmpty = 'N'
                END

            IF @Column = 'ExcludeYN' 
                BEGIN
                    SELECT  @ExcludeYN = @Uploadval
                    IF @Uploadval IS NULL 
                        SET @IsExcludeYNEmpty = 'Y'
                    ELSE 
                        SET @IsExcludeYNEmpty = 'N'
                END
            IF @Column = 'MailAddress' 
                BEGIN
                    SELECT  @MailAddress = @Uploadval
                    IF @Uploadval IS NULL 
                        SET @IsMailAddressEmpty = 'Y'
                    ELSE 
                        SET @IsMailAddressEmpty = 'N'
                END

            IF @Column = 'MailState' 
                BEGIN
                    SELECT  @MailState = @Uploadval
                    IF @Uploadval IS NULL 
                        SET @IsMailStateEmpty = 'Y'
                    ELSE 
                        SET @IsMailStateEmpty = 'N'
                END

            IF @Column = 'AllowPortalAccess' 
                BEGIN
                    SELECT  @AllowPortalAccess = @Uploadval
                    IF @Uploadval IS NULL 
                        SET @IsAllowPortalAccessEmpty = 'Y'
                    ELSE 
                        SET @IsAllowPortalAccessEmpty = 'N'
                END
            IF @Column = 'PortalUserName' 
                BEGIN
                    SELECT  @PortalUserName = @Uploadval
                    IF @PortalUserName IS NULL 
                        SET @IsPortalUserNameEmpty = 'Y'
                    ELSE 
                        SET @IsPortalUserNameEmpty = 'N'
                END

            IF @Column = 'PortalDefaultRole' 
                BEGIN
                    SELECT  @PortalDefaultRole = CASE WHEN ISNUMERIC(@Uploadval) = 1 THEN @Uploadval
                                                      ELSE NULL
                                                 END
                    IF @PortalDefaultRole IS NULL 
                        SET @IsPortalDefaultRoleEmpty = 'Y'
                    ELSE 
                        SET @IsPortalDefaultRoleEmpty = 'N'
                END
            IF @Column = 'MailCountry' 
                BEGIN
                    SELECT  @MailCountry = @Uploadval
                    IF @Uploadval IS NULL 
                        SET @IsMailCountryEmpty = 'Y'
                    ELSE 
                        SET @IsMailCountryEmpty = 'N'
                END
            IF @Column = 'UseAddressOvr' 
                BEGIN
                    SELECT  @UseAddressOvr = @Uploadval
                    IF @Uploadval IS NULL 
                        SET @IsUseAddressOvrEmpty = 'Y'
                    ELSE 
                        SET @IsUseAddressOvrEmpty = 'N'
				END
     -- set record number
                SELECT  @oldrecseq = @Recseq
--fetch next record

                FETCH NEXT FROM WorkEditCursor INTO @Recseq, @Ident, @Tablename, @Column, @Uploadval
                IF @@fetch_status <> 0 
                    SELECT  @Recseq=-1
     

            END -- same Seq
        ELSE 
            BEGIN -- different Seq

/* VendorGroup*/  
                IF NOT EXISTS ( SELECT  dbo.HQGP.Grp
                                FROM    dbo.HQGP
                                WHERE   HQGP.Grp = @VendorGroup ) 
                    BEGIN				
                        SELECT  @VendorGroup = NULL
							, @rcode = 1
                              , @desc = '** Invalid Vendor Group **'
                        INSERT  INTO dbo.IMWM 
							(ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier)
                        VALUES  ( @ImportId, @ImportTemplate, @Form, @currrecseq, @rcode, @desc
                                , @VendorGroupID )                          
                        UPDATE  dbo.IMWE
                        SET     IMWE.UploadVal = '** Invalid **'
                        WHERE   IMWE.ImportTemplate = @ImportTemplate
                                AND IMWE.ImportId = @ImportId
                                AND IMWE.RecordSeq = @currrecseq
                                AND IMWE.Identifier = @VendorGroupID
                                AND IMWE.RecordType = @rectype
                    END

/* FirmNumber*/
                IF @IsFirmNumberEmpty = 'Y' 
                    BEGIN
                        SELECT  @FirmNumber = NULL
							  , @rcode = 1
                              , @desc = '** Firm must be filled in **'
                        INSERT  INTO dbo.IMWM 
							(ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier)
                        VALUES  ( @ImportId, @ImportTemplate, @Form, @currrecseq, @rcode, @desc
                                , @FirmNumberID )			
                        UPDATE  dbo.IMWE
                        SET     IMWE.UploadVal = '** Invalid **'
                        WHERE   IMWE.ImportTemplate = @ImportTemplate
                                AND IMWE.ImportId = @ImportId
                                AND IMWE.RecordSeq = @currrecseq
                                AND IMWE.Identifier = @FirmNumberID
                                AND IMWE.RecordType = @rectype
                    END

/* ContactCode*/  
                IF ( ISNULL(@OverwriteContactCode, 'Y') = 'Y'
                    OR ISNULL(@IsContactCodeEmpty, 'Y') = 'Y' ) 
                    BEGIN
                        SELECT  @ContactCode = ISNULL(MAX(bPMPM.ContactCode), 0) + 1
                        FROM    dbo.bPMPM
                        WHERE   dbo.bPMPM.VendorGroup = @VendorGroup
                                AND dbo.bPMPM.FirmNumber = @FirmNumber
                        SELECT  @IMWEContactCode = ISNULL(MAX(tCC.UploadVal), 0) + 1
                        FROM    dbo.IMWE AS tCC
                        JOIN    dbo.IMWE AS tVenGroup ON
								tCC.ImportTemplate = tVenGroup.ImportTemplate
                                AND tCC.ImportId = tVenGroup.ImportId
                                AND tVenGroup.Identifier = @VendorGroupID
                                AND tCC.RecordType = tVenGroup.RecordType
                                AND tCC.RecordSeq = tVenGroup.RecordSeq
                        JOIN    dbo.IMWE AS tFirm ON
								tCC.ImportTemplate = tFirm.ImportTemplate
                                AND tCC.ImportId = tFirm.ImportId
                                AND tFirm.Identifier = @FirmNumberID
                                AND tCC.RecordType = tFirm.RecordType
                                AND tCC.RecordSeq = tFirm.RecordSeq
                        WHERE   tCC.ImportTemplate = @ImportTemplate
                                AND tCC.ImportId = @ImportId
                                AND tCC.Identifier = @ContactCodeID
                                AND tCC.RecordType = @rectype
                        SELECT @ContactCode=CASE 
							WHEN @IMWEContactCode>@ContactCode THEN @IMWEContactCode
							ELSE @ContactCode
						END                                   
                        UPDATE  dbo.IMWE
                        SET     IMWE.UploadVal = @ContactCode
                        WHERE   IMWE.ImportTemplate = @ImportTemplate
                                AND IMWE.ImportId = @ImportId
                                AND IMWE.RecordSeq = @currrecseq
                                AND IMWE.Identifier = @ContactCodeID
                                AND IMWE.RecordType = @rectype
                        SELECT @IsContactCodeEmpty='N'
                    END
                    IF @ContactCode IS NULL OR ISNUMERIC(@ContactCode)<>1
                    BEGIN
                        SELECT  @FirmNumber = NULL
							  , @rcode = 1
                              , @desc = '** ContractCode is not numeric **'
                        INSERT  INTO dbo.IMWM 
							(ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier)
                        VALUES  ( @ImportId, @ImportTemplate, @Form, @currrecseq, @rcode, @desc
                                , @ContactCodeID )			
                        UPDATE  dbo.IMWE
                        SET     IMWE.UploadVal = '** Invalid **'
                        WHERE   IMWE.ImportTemplate = @ImportTemplate
                                AND IMWE.ImportId = @ImportId
                                AND IMWE.RecordSeq = @currrecseq
                                AND IMWE.Identifier = @ContactCodeID
                                AND IMWE.RecordType = @rectype
                    END

/* SortName*/
                IF ( ISNULL(@OverwriteSortName, 'Y') = 'Y'
                    OR ISNULL(@IsSortNameEmpty, 'Y') = 'Y' ) 
                    BEGIN
                        DECLARE @vreccount INT
                          , @vendtemp VARCHAR(10)
                          , @wreccount INT
                        SELECT  @SortName = UPPER(ISNULL(@LastName, '') + ISNULL(@FirstName, ''))

--check if the sortname is in use by another Contact
                        SELECT  @vreccount = COUNT(*)
                        FROM    dbo.bPMPM WITH ( NOLOCK )
                        WHERE   bPMPM.VendorGroup = @VendorGroup
                                AND bPMPM.SortName = @SortName
                                AND ( bPMPM.ContactCode <> @ContactCode ) --exclude existing record
                        IF @vreccount > 0 --if sortname in use, append contact #
                            BEGIN	--(max length of SortName is 15 chars )
                                SELECT  @vendtemp = CONVERT(VARCHAR(10), @ContactCode)	
                                SELECT  @SortName = UPPER(RTRIM(LEFT(ISNULL(@LastName, '') + ISNULL(@FirstName,
                                                                                                ''),
                                                                     15 - LEN(@vendtemp)))) + @vendtemp
                            END
                        ELSE 
                            BEGIN
                                SELECT  @vreccount = COUNT(*)
                                FROM    dbo.IMWE
                                WHERE   IMWE.ImportTemplate = @ImportTemplate
                                        AND IMWE.Identifier = @SortNameID
                                        AND IMWE.RecordType = @rectype
                                        AND IMWE.UploadVal = @SortName
                                IF @vreccount > 0	--if sortname is use, append Contact# 
                                    BEGIN	--(max length of SortName is 15 characters)
                                        SELECT  @vendtemp = CONVERT(VARCHAR(10), @ContactCode)
                                        SELECT  @SortName = UPPER(LEFT(@ContactCode, 15 - LEN(@vendtemp)))
                                                + @vendtemp
                                    END
                            END
                        UPDATE  dbo.IMWE
                        SET     IMWE.UploadVal = @SortName
                        WHERE   IMWE.ImportTemplate = @ImportTemplate
                                AND IMWE.ImportId = @ImportId
                                AND IMWE.RecordSeq = @currrecseq
                                AND IMWE.Identifier = @SortNameID
                                AND IMWE.RecordType = @rectype
                    END


/* LastName*/
                IF @IsLastNameEmpty = 'Y' 
                    BEGIN
                        SELECT  @desc = '** Missing Last name **'
							,   @rcode=1
                        INSERT  INTO dbo.IMWM
							(ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier)
                        VALUES  ( @ImportId, @ImportTemplate, @Form, @currrecseq, @rcode, @desc
							 , @LastNameID )			
                        UPDATE  dbo.IMWE
                        SET     IMWE.UploadVal = '** Invalid **'
                        WHERE   IMWE.ImportTemplate = @ImportTemplate
                                AND IMWE.ImportId = @ImportId
                                AND IMWE.RecordSeq = @currrecseq
                                AND IMWE.Identifier = @LastNameID
                                AND IMWE.RecordType = @rectype
                    END

/* FirstName*/
                IF @IsFirstNameEmpty = 'Y' 
                    BEGIN
                        SELECT  @desc = '** Missing First name **'
                        INSERT  INTO dbo.IMWM 
							(ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier)
                        VALUES  ( @ImportId
                                , @ImportTemplate
                                , @Form
                                , @currrecseq
                                , 1
                                , @desc
                                , @FirstNameID )			
                        SELECT  @rcode = 1
                        UPDATE  dbo.IMWE
                        SET     IMWE.UploadVal = '** Invalid **'
                        WHERE   IMWE.ImportTemplate = @ImportTemplate
                                AND IMWE.ImportId = @ImportId
                                AND IMWE.RecordSeq = @currrecseq
                                AND IMWE.Identifier = @FirstNameID
                                AND IMWE.RecordType = @rectype
                    END

/* PrefMethod*/
                IF ( ISNULL(@OverwritePrefMethod, 'Y') = 'Y'
                    OR ISNULL(@IsPrefMethodEmpty, 'Y') = 'Y' ) 
                    BEGIN
                        SELECT  @PrefMethod = 'E'
                        UPDATE  dbo.IMWE
                        SET     IMWE.UploadVal = @PrefMethod
                        WHERE   IMWE.ImportTemplate = @ImportTemplate
                                AND IMWE.ImportId = @ImportId
                                AND IMWE.RecordSeq = @currrecseq
                                AND IMWE.Identifier = @PrefMethodID
                                AND IMWE.RecordType = @rectype
                    END
                IF @PrefMethod NOT IN ( 'M', 'E', 'F' ) 
                    BEGIN
                        SELECT  @desc = '** Invalid Preferred Method **'
                        INSERT  INTO dbo.IMWM 
							(ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier)
                        VALUES  ( @ImportId
                                , @ImportTemplate
                                , @Form
                                , @currrecseq
                                , 1
                                , @desc
                                , @PrefMethodID )			
                        SELECT  @rcode = 1
                        UPDATE  dbo.IMWE
                        SET     IMWE.UploadVal = '** Invalid **'
                        WHERE   IMWE.ImportTemplate = @ImportTemplate
                                AND IMWE.ImportId = @ImportId
                                AND IMWE.RecordSeq = @currrecseq
                                AND IMWE.Identifier = @PrefMethodID
                                AND IMWE.RecordType = @rectype
                    END		

/* ExcludeYN*/
                IF ( ISNULL(@OverwriteExcludeYN, 'Y') = 'Y'
                    OR ISNULL(@IsExcludeYNEmpty, 'Y') = 'Y' ) 
                    BEGIN
                        SELECT  @ExcludeYN = 'N'
                        UPDATE  dbo.IMWE
                        SET     IMWE.UploadVal = @ExcludeYN
                        WHERE   IMWE.ImportTemplate = @ImportTemplate
                                AND IMWE.ImportId = @ImportId
                                AND IMWE.RecordSeq = @currrecseq
                                AND IMWE.Identifier = @ExcludeYNID
                                AND IMWE.RecordType = @rectype
                    END	

/* MailState*/
        IF @IsMailStateEmpty <> 'Y' 
            BEGIN
                EXEC @rc= dbo.vspHQCountryStateVal 
                    @hqco = @VendorGroup
                  , @country = @MailCountry
                  , @state = @MailState
                  , @msg = @msg 
                IF @rc <> 0 
                    BEGIN
                        INSERT  INTO dbo.IMWM 
							(ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier)
                        VALUES  ( @ImportId
                                , @ImportTemplate
                                , @Form
                                , @currrecseq
                                , @rc
                                , ISNULL(@msg, 'Invalid')
                                , @MailStateID )			
                        SELECT  @rcode = @rc
                              , @desc = @msg
                        UPDATE  dbo.IMWE
                        SET     IMWE.UploadVal = '** Invalid **'
                        WHERE   IMWE.ImportTemplate = @ImportTemplate
                                AND IMWE.ImportId = @ImportId
                                AND IMWE.RecordSeq = @currrecseq
                                AND IMWE.Identifier = @MailStateID
                                AND IMWE.RecordType = @rectype
                    END	
            END



/* MailCountry*/
        IF @IsMailCountryEmpty <> 'Y' 
            BEGIN
                EXEC @rc= dbo.vspHQCountryStateVal 
                    @hqco = @VendorGroup
                  , @country = @MailCountry
                  , @state = @MailState
                  , @msg = @msg 
                IF @rc <> 0 
                    BEGIN
                        INSERT  INTO dbo.IMWM
                                ( ImportId
                                , ImportTemplate
                                , Form
                                , RecordSeq
                                , Error
                                , Message
                                , Identifier )
                        VALUES  ( @ImportId
                                , @ImportTemplate
                                , @Form
                                , @currrecseq
                                , @rc
                                , ISNULL(@msg, 'Invalid')
                                , @MailCountryID )			
                        SELECT  @rcode = @rc
                              , @desc = @msg
                        UPDATE  dbo.IMWE
                        SET     IMWE.UploadVal = '** Invalid **'
                        WHERE   IMWE.ImportTemplate = @ImportTemplate
                                AND IMWE.ImportId = @ImportId
                                AND IMWE.RecordSeq = @currrecseq
                                AND IMWE.Identifier = @MailCountryID
                                AND IMWE.RecordType = @rectype
                    END	
            END

/* AllowPortalAccess*/
        IF ( ISNULL(@OverwriteAllowPortalAccess, 'Y') = 'Y'
            OR ISNULL(@IsAllowPortalAccessEmpty, 'Y') = 'Y'
            OR ISNULL(@AllowPortalAccess, '') NOT IN ( 'Y', 'N' ) ) 
            BEGIN
                SELECT  @AllowPortalAccess = CASE WHEN @PortalUserName IS NULL THEN 'N'
                                                  ELSE 'Y'
                                             END
                UPDATE  dbo.IMWE
                SET     IMWE.UploadVal = @AllowPortalAccess
                WHERE   IMWE.ImportTemplate = @ImportTemplate
                        AND IMWE.ImportId = @ImportId
                        AND IMWE.RecordSeq = @currrecseq
                        AND IMWE.Identifier = @AllowPortalAccessID
                        AND IMWE.RecordType = @rectype
            END

/* PortalDefaultRole*/

        IF @IsPortalDefaultRoleEmpty = 'N' 
            BEGIN
                EXEC @rc= dbo.vspPMPMPortalRoleVal 
                    @role = @PortalDefaultRole
                  , @msg = @msg 
                IF @rc <> 0 
                    BEGIN
                        INSERT  INTO dbo.IMWM
                                ( ImportId, ImportTemplate
                                , Form
                                , RecordSeq
                                , Error
                                , Message
                                , Identifier )
                        VALUES  ( @ImportId
                                , @ImportTemplate
                                , @Form
                                , @currrecseq
                                , @rc
                                , ISNULL(@msg, 'Invalid Portal Default')
                                , @PortalDefaultRoleID )	
                        SELECT  @rcode = @rc
                              , @desc = ISNULL(@msg, 'Invalid') 	
                        UPDATE  dbo.IMWE
                        SET     IMWE.UploadVal = '** Invalid **'
                        WHERE   IMWE.ImportTemplate = @ImportTemplate
                                AND IMWE.ImportId = @ImportId
                                AND IMWE.RecordSeq = @currrecseq
                                AND IMWE.Identifier = @PortalDefaultRoleID
                                AND IMWE.RecordType = @rectype
                    END
            END


/* UseAddressOvr*/
			IF ( ISNULL(@OverwriteUseAddressOvr, 'Y') = 'Y'
				OR ISNULL(@IsUseAddressOvrEmpty, 'Y') = 'Y'
				OR @UseAddressOvr NOT IN ( 'Y', 'N' ) ) 
				BEGIN
					IF @IsMailAddressEmpty = 'N' 
						SELECT  @UseAddressOvr = 'Y';
					ELSE 
						SELECT  @UseAddressOvr = 'N';
		
					UPDATE  dbo.IMWE
					SET     IMWE.UploadVal = @UseAddressOvr
					WHERE   IMWE.ImportTemplate = @ImportTemplate
							AND IMWE.ImportId = @ImportId
							AND IMWE.RecordSeq = @currrecseq
							AND IMWE.Identifier = @UseAddressOvrID
							AND IMWE.RecordType = @rectype;
				END;


-- set Current Req Seq to next @Recseq unless we are processing last record.
        IF @Recseq = -1 
            SELECT  @complete = 1	-- exit the loop
        Else
        SELECT  @currrecseq = @Recseq
    END

END
    
--/* FOR EXTRA UPDATE */    
UPDATE  dbo.IMWE
SET     IMWE.UploadVal = UPPER(IMWE.UploadVal)
WHERE   IMWE.ImportTemplate = @ImportTemplate
        AND IMWE.ImportId = @ImportId
        AND IMWE.RecordType = @rectype
        AND IMWE.Identifier = @SortNameID
        AND ISNULL(IMWE.UploadVal, '') <> UPPER(ISNULL(IMWE.UploadVal, '')) 

bspexit:

IF @CursorOpen = 1 
    BEGIN
        CLOSE WorkEditCursor
        DEALLOCATE WorkEditCursor	
    END

SELECT  @msg = ISNULL(@desc, 'Clear') + CHAR(13) + CHAR(10) + '[vspIMViewpointDefaultsPMPM]'

RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMViewpointDefaultsPMPM] TO [public]
GO
