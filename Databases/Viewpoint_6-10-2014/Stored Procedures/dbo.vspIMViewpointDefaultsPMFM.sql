SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspIMViewpointDefaultsPMFM]
    /***********************************************************
     * CREATED BY:   JRE  05/13/2013
     *
     * Usage:
     *	Used by Imports to create values for needed or missing
     *      data based upon Viewpoint default rules.
     *  Only non-vendors/non-customers are allowed - vendors and customers should be autoloaded using VP
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
SET nocount ON
    
DECLARE @rcode INT
  , @desc VARCHAR(120)
  , @status INT
  , @defaultvalue VARCHAR(30)
  , @CursorOpen INT
  , @rc INT
    
    --Identifiers
DECLARE @ContactNameID INT
  , @EMailID INT
  , @ExcludeYNID INT
  , @FaxID INT
  , @FirmNameID INT
  , @FirmNumberID INT
  , @FirmTypeID INT
  , @MailAddress2ID INT
  , @MailAddressID INT
  , @MailCityID INT
  , @MailCountryID INT
  , @MailStateID INT
  , @MailZipID INT
  , @NotesID INT
  , @PhoneID INT
  , @ShipAddress2ID INT
  , @ShipAddressID INT
  , @ShipCityID INT
  , @ShipCountryID INT
  , @ShipStateID INT
  , @ShipZipID INT
  , @SortNameID INT
  , @URLID INT
  , @UpdateAPID INT
  , @VendorGroupID INT
  , @VendorID INT;
--Flags
DECLARE @ynContactName bYN
  , @ynEMail bYN
  , @ynExcludeYN bYN
  , @ynFax bYN
  , @ynFirmName bYN
  , @ynFirmNumber bYN
  , @ynFirmType bYN
  , @ynMailAddress bYN
  , @ynMailAddress2 bYN
  , @ynMailCity bYN
  , @ynMailCountry bYN
  , @ynMailState bYN
  , @ynMailZip bYN
  , @ynNotes bYN
  , @ynPhone bYN
  , @ynShipAddress bYN
  , @ynShipAddress2 bYN
  , @ynShipCity bYN
  , @ynShipCountry bYN
  , @ynShipState bYN
  , @ynShipZip bYN
  , @ynSortName bYN
  , @ynURL bYN
  , @ynUpdateAP bYN
  , @ynVendor bYN
  , @ynVendorGroup bYN;
 
--YN
SELECT  @ynContactName = 'N'
      , @ynEMail = 'N'
      , @ynExcludeYN = 'N'
      , @ynFax = 'N'
      , @ynFirmName = 'N'
      , @ynFirmNumber = 'Y'
      , @ynFirmType = 'N'
      , @ynMailAddress = 'N'
      , @ynMailAddress2 = 'N'
      , @ynMailCity = 'N'
      , @ynMailCountry = 'N'
      , @ynMailState = 'N'
      , @ynMailZip = 'N'
      , @ynNotes = 'N'
      , @ynPhone = 'N'
      , @ynShipAddress = 'N'
      , @ynShipAddress2 = 'N'
      , @ynShipCity = 'N'
      , @ynShipCountry = 'N'
      , @ynShipState = 'N'
      , @ynShipZip = 'N'
      , @ynSortName = 'Y'
      , @ynURL = 'N'
      , @ynUpdateAP = 'Y'
      , @ynVendor = 'N'
      , @ynVendorGroup = 'N';
 
DECLARE @OverwriteContactName bYN
  , @OverwriteEMail bYN
  , @OverwriteExcludeYN bYN
  , @OverwriteFax bYN
  , @OverwriteFirmName bYN
  , @OverwriteFirmNumber bYN
  , @OverwriteFirmType bYN
  , @OverwriteMailAddress bYN
  , @OverwriteMailAddress2 bYN
  , @OverwriteMailCity bYN
  , @OverwriteMailCountry bYN
  , @OverwriteMailState bYN
  , @OverwriteMailZip bYN
  , @OverwriteNotes bYN
  , @OverwritePhone bYN
  , @OverwriteShipAddress bYN
  , @OverwriteShipAddress2 bYN
  , @OverwriteShipCity bYN
  , @OverwriteShipCountry bYN
  , @OverwriteShipState bYN
  , @OverwriteShipZip bYN
  , @OverwriteSortName bYN
  , @OverwriteURL bYN
  , @OverwriteUpdateAP bYN
  , @OverwriteVendor bYN
  , @OverwriteVendorGroup bYN;
    
    --Values
DECLARE @SortName bSortName
  , @DefVendorGroup bGroup
  , @VendorGroup bGroup
  , @FirmName VARCHAR(60)
  , @Vendor bVendor
  , @FirmNumber bFirm
DECLARE @FirmType bFirmType
  , @MailCountry VARCHAR(2)
  , @MailState bState			

DECLARE @ShipCountry VARCHAR(2)
  , @ShipState bState	
    
    /* check required input params */
    
IF @ImportId IS NULL 
    BEGIN
        SELECT  @desc = 'Missing ImportId.'
              , @rcode = 1
        GOTO bspexit
    END
IF @ImportTemplate IS NULL 
    BEGIN
        SELECT  @desc = 'Missing ImportTemplate.'
              , @rcode = 1
        GOTO bspexit
    END
    
IF @Form IS NULL 
    BEGIN
        SELECT  @desc = 'Missing Form.'
              , @rcode = 1
        GOTO bspexit
    END
    
SELECT  @CursorOpen = 0
    
    -- Check ImportTemplate detail for columns to set Bidtek Defaults
IF NOT EXISTS ( SELECT TOP 1
                        1
                FROM    IMTD WITH ( NOLOCK )
                WHERE   IMTD.ImportTemplate = @ImportTemplate
                        AND IMTD.DefaultValue = '[Bidtek]'
                        AND IMTD.RecordType = @rectype ) 
    GOTO bspexit
    
DECLARE @IsContactNameEmpty bYN
  , @IsEMailEmpty bYN
  , @IsExcludeYNEmpty bYN
  , @IsFaxEmpty bYN
  , @IsFirmNameEmpty bYN
  , @IsFirmNumberEmpty bYN
  , @IsFirmTypeEmpty bYN
  , @IsMailAddressEmpty bYN
  , @IsMailAddress2Empty bYN
  , @IsMailCityEmpty bYN
  , @IsMailCountryEmpty bYN
  , @IsMailStateEmpty bYN
  , @IsMailZipEmpty bYN
  , @IsNotesEmpty bYN
  , @IsPhoneEmpty bYN
  , @IsShipAddressEmpty bYN
  , @IsShipAddress2Empty bYN
  , @IsShipCityEmpty bYN
  , @IsShipCountryEmpty bYN
  , @IsShipStateEmpty bYN
  , @IsShipZipEmpty bYN
  , @IsSortNameEmpty bYN
  , @IsURLEmpty bYN
  , @IsUpdateAPEmpty bYN
  , @IsVendorEmpty bYN
  , @IsVendorGroupEmpty bYN

			
SELECT  @OverwriteContactName = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ContactName', @rectype);
SELECT  @OverwriteEMail = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EMail', @rectype);
SELECT  @OverwriteExcludeYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ExcludeYN', @rectype);
SELECT  @OverwriteFax = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Fax', @rectype);
SELECT  @OverwriteFirmName = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'FirmName', @rectype);
SELECT  @OverwriteFirmNumber = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'FirmNumber', @rectype);
SELECT  @OverwriteFirmType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'FirmType', @rectype);
SELECT  @OverwriteMailAddress = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MailAddress', @rectype);
SELECT  @OverwriteMailAddress2 = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MailAddress2', @rectype);
SELECT  @OverwriteMailCity = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MailCity', @rectype);
SELECT  @OverwriteMailCountry = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MailCountry', @rectype);
SELECT  @OverwriteMailState = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MailState', @rectype);
SELECT  @OverwriteMailZip = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MailZip', @rectype);
SELECT  @OverwriteNotes = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Notes', @rectype);
SELECT  @OverwritePhone = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Phone', @rectype);
SELECT  @OverwriteShipAddress = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ShipAddress', @rectype);
SELECT  @OverwriteShipAddress2 = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ShipAddress2', @rectype);
SELECT  @OverwriteShipCity = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ShipCity', @rectype);
SELECT  @OverwriteShipCountry = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ShipCountry', @rectype);
SELECT  @OverwriteShipState = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ShipState', @rectype);
SELECT  @OverwriteShipZip = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ShipZip', @rectype);
SELECT  @OverwriteSortName = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SortName', @rectype);
SELECT  @OverwriteURL = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'URL', @rectype);
SELECT  @OverwriteUpdateAP = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UpdateAP', @rectype);
SELECT  @OverwriteVendor = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Vendor', @rectype);
SELECT  @OverwriteVendorGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'VendorGroup', @rectype);


 
    --get database default values
SELECT  @DefVendorGroup = VendorGroup
FROM    bHQCO WITH ( NOLOCK )
WHERE   HQCo = @Company

    --set common defaults
SELECT  @VendorGroupID = DDUD.Identifier
      , @defaultvalue = IMTD.DefaultValue
FROM    IMTD WITH ( NOLOCK )
INNER JOIN DDUD
ON      IMTD.Identifier = DDUD.Identifier
        AND DDUD.Form = @Form
WHERE   IMTD.ImportTemplate = @ImportTemplate
        AND DDUD.ColumnName = 'VendorGroup'
IF @@rowcount <> 0
    AND @defaultvalue = '[Bidtek]'
    AND ( ISNULL(@OverwriteVendorGroup, 'Y') = 'Y' ) 
    BEGIN
        UPDATE  IMWE
        SET     IMWE.UploadVal = @DefVendorGroup
        WHERE   IMWE.ImportTemplate = @ImportTemplate
                AND IMWE.ImportId = @ImportId
                AND IMWE.Identifier = @VendorGroupID
    END
    
    ------------------------------------------
    
SELECT  @VendorGroupID = DDUD.Identifier
      , @defaultvalue = IMTD.DefaultValue
FROM    IMTD WITH ( NOLOCK )
INNER JOIN DDUD
ON      IMTD.Identifier = DDUD.Identifier
        AND DDUD.Form = @Form
WHERE   IMTD.ImportTemplate = @ImportTemplate
        AND DDUD.ColumnName = 'VendorGroup'
IF @@rowcount <> 0
    AND @defaultvalue = '[Bidtek]'
    AND ( ISNULL(@OverwriteVendorGroup, 'Y') = 'N' ) 
    BEGIN
        UPDATE  IMWE
        SET     IMWE.UploadVal = @DefVendorGroup
        WHERE   IMWE.ImportTemplate = @ImportTemplate
                AND IMWE.ImportId = @ImportId
                AND IMWE.Identifier = @VendorGroupID
                AND IMWE.UploadVal IS NULL
    END
    
    --select @TypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    --inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    --Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Type'
    --if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteType, 'Y') = 'N')
    --begin
    --    UPDATE IMWE
    --    SET IMWE.UploadVal = 'R'
    --    where IMWE.ImportTemplate=@ImportTemplate and 
    --	IMWE.ImportId=@ImportId and IMWE.Identifier = @TypeID
    --	AND IMWE.UploadVal IS NULL
    --end
    
----------------------------------------------------------------------------------------------------------
   
    --Get Identifiers for dependent defaults.
SELECT  @ynSortName = 'N'
SELECT  @SortNameID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SortName', @rectype, 'N')
IF @SortNameID <> 0 
    SELECT  @ynSortName = 'Y'
    
SELECT  @ContactNameID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ContactName', @rectype, 'N');
SELECT  @EMailID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'EMail', @rectype, 'N');
SELECT  @ExcludeYNID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ExcludeYN', @rectype, 'N');
SELECT  @FaxID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Fax', @rectype, 'N');
SELECT  @FirmNameID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'FirmName', @rectype, 'N');
SELECT  @FirmNumberID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'FirmNumber', @rectype, 'N');
SELECT  @FirmTypeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'FirmType', @rectype, 'N');
SELECT  @MailAddress2ID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MailAddress2', @rectype, 'N');
SELECT  @MailAddressID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MailAddress', @rectype, 'N');
SELECT  @MailCityID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MailCity', @rectype, 'N');
SELECT  @MailCountryID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MailCountry', @rectype, 'N');
SELECT  @MailStateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MailState', @rectype, 'N');
SELECT  @MailZipID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'MailZip', @rectype, 'N');
SELECT  @NotesID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Notes', @rectype, 'N');
SELECT  @PhoneID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Phone', @rectype, 'N');
SELECT  @ShipAddress2ID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ShipAddress2', @rectype, 'N');
SELECT  @ShipAddressID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ShipAddress', @rectype, 'N');
SELECT  @ShipCityID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ShipCity', @rectype, 'N');
SELECT  @ShipCountryID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ShipCountry', @rectype, 'N');
SELECT  @ShipStateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ShipState', @rectype, 'N');
SELECT  @ShipZipID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ShipZip', @rectype, 'N');

SELECT  @URLID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'URL', @rectype, 'N');
SELECT  @UpdateAPID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UpdateAP', @rectype, 'N');
SELECT  @VendorGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'VendorGroup', @rectype, 'N');
SELECT  @VendorID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Vendor', @rectype, 'N');


    --Start Processing
DECLARE WorkEditCursor CURSOR LOCAL FAST_FORWARD
FOR
SELECT  IMWE.RecordSeq
      , IMWE.Identifier
      , DDUD.TableName
      , DDUD.ColumnName
      , IMWE.UploadVal
FROM    IMWE WITH ( NOLOCK )
INNER JOIN DDUD
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
--#142350 removing @importid, @seq
DECLARE @Recseq INT
  , @Tablename VARCHAR(20)
  , @Column VARCHAR(30)
  , @Uploadval VARCHAR(60)
  , @Ident INT
  , @complete INT

DECLARE @currrecseq INT
  , @allownull INT
  , @error INT
  , @tsql VARCHAR(255)
  , @valuelist VARCHAR(255)
  , @columnlist VARCHAR(255)
  , @records INT
  , @oldrecseq INT

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
                IF @Column = 'FirmName' 
                    SELECT  @FirmName = @Uploadval

                IF @Column = 'SortName' 
                    IF @Uploadval IS NULL 
                        SET @IsSortNameEmpty = 'Y'
                    ELSE 
                        SET @IsSortNameEmpty = 'N'
                IF @Column = 'FirmNumber' 
                    BEGIN
                        SELECT  @FirmNumber = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsFirmNumberEmpty = 'Y'
                        ELSE 
                            SET @IsFirmNumberEmpty = 'N'
                    END
			
                IF @Column = 'Vendor' 
                    BEGIN
                        SELECT  @Vendor = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsVendorEmpty = 'Y'
                        ELSE 
                            SET @IsVendorEmpty = 'N'
                    END
                IF @Column = 'VendorGroup' 
                    BEGIN
                        SELECT  @VendorGroup = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsVendorGroupEmpty = 'Y'
                        ELSE 
                            SET @IsVendorGroupEmpty = 'N'
                    END
                IF @Column = 'ContactName' 
                    IF @Uploadval IS NULL 
                        SET @IsContactNameEmpty = 'Y'
                    ELSE 
                        SET @IsContactNameEmpty = 'N'

                IF @Column = 'EMail' 
                    IF @Uploadval IS NULL 
                        SET @IsEMailEmpty = 'Y'
                    ELSE 
                        SET @IsEMailEmpty = 'N'
			
                IF @Column = 'ExcludeYN' 
                    IF @Uploadval IS NULL 
                        SET @IsExcludeYNEmpty = 'Y'
                    ELSE 
                        SET @IsExcludeYNEmpty = 'N'
			
                IF @Column = 'Fax' 
                    IF @Uploadval IS NULL 
                        SET @IsFaxEmpty = 'Y'
                    ELSE 
                        SET @IsFaxEmpty = 'N'
			
                IF @Column = 'FirmName' 
                    BEGIN
                        SELECT  @FirmName = @Uploadval 
                        IF @Uploadval IS NULL 
                            SET @IsFirmNameEmpty = 'Y'
                        ELSE 
                            SET @IsFirmNameEmpty = 'N'
                    END

                IF @Column = 'FirmType' 
                    BEGIN
                        SELECT  @FirmType = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsFirmTypeEmpty = 'Y'
                        ELSE 
                            SET @IsFirmTypeEmpty = 'N'
                    END	
                IF @Column = 'MailAddress' 
                    IF @Uploadval IS NULL 
                        SET @IsMailAddressEmpty = 'Y'
                    ELSE 
                        SET @IsMailAddressEmpty = 'N'
			
                IF @Column = 'MailAddress2' 
                    IF @Uploadval IS NULL 
                        SET @IsMailAddress2Empty = 'Y'
                    ELSE 
                        SET @IsMailAddress2Empty = 'N'
			
                IF @Column = 'MailCity' 
                    IF @Uploadval IS NULL 
                        SET @IsMailCityEmpty = 'Y'
                    ELSE 
                        SET @IsMailCityEmpty = 'N'
                IF @Column = 'MailCountry' 
                    BEGIN
                        SELECT  @MailCountry = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsMailCountryEmpty = 'Y'
                        ELSE 
                            SET @IsMailCountryEmpty = 'N'
                    END	
                IF @Column = 'MailState' 
                    BEGIN
                        SELECT  @MailState = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsMailStateEmpty = 'Y'
                        ELSE 
                            SET @IsMailStateEmpty = 'N'
                    END		
                IF @Column = 'MailZip' 
                    IF @Uploadval IS NULL 
                        SET @IsMailZipEmpty = 'Y'
                    ELSE 
                        SET @IsMailZipEmpty = 'N'
			
                IF @Column = 'Notes' 
                    IF @Uploadval IS NULL 
                        SET @IsNotesEmpty = 'Y'
                    ELSE 
                        SET @IsNotesEmpty = 'N'
			
                IF @Column = 'Phone' 
                    IF @Uploadval IS NULL 
                        SET @IsPhoneEmpty = 'Y'
                    ELSE 
                        SET @IsPhoneEmpty = 'N'
			
                IF @Column = 'ShipAddress' 
                    IF @Uploadval IS NULL 
                        SET @IsShipAddressEmpty = 'Y'
                    ELSE 
                        SET @IsShipAddressEmpty = 'N'
			
                IF @Column = 'ShipAddress2' 
                    IF @Uploadval IS NULL 
                        SET @IsShipAddress2Empty = 'Y'
                    ELSE 
                        SET @IsShipAddress2Empty = 'N'
			
                IF @Column = 'ShipCity' 
                    IF @Uploadval IS NULL 
                        SET @IsShipCityEmpty = 'Y'
                    ELSE 
                        SET @IsShipCityEmpty = 'N'

                IF @Column = 'ShipCountry' 
                    BEGIN
                        SELECT  @ShipCountry = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsShipCountryEmpty = 'Y'
                        ELSE 
                            SET @IsShipCountryEmpty = 'N'
                    END	
                IF @Column = 'ShipState' 
                    BEGIN
                        SELECT  @ShipCountry = @Uploadval
                        IF @Uploadval IS NULL 
                            SET @IsShipStateEmpty = 'Y'
                        ELSE 
                            SET @IsShipStateEmpty = 'N'
                    END	
                IF @Column = 'ShipZip' 
                    IF @Uploadval IS NULL 
                        SET @IsShipZipEmpty = 'Y'
                    ELSE 
                        SET @IsShipZipEmpty = 'N'
			
                IF @Column = 'URL' 
                    IF @Uploadval IS NULL 
                        SET @IsURLEmpty = 'Y'
                    ELSE 
                        SET @IsURLEmpty = 'N'
			
                IF @Column = 'UpdateAP' 
                    IF @Uploadval IS NULL 
                        SET @IsUpdateAPEmpty = 'Y'
                    ELSE 
                        SET @IsUpdateAPEmpty = 'N'
			

		
    
                SELECT  @oldrecseq = @Recseq

    --fetch next record
                FETCH NEXT FROM WorkEditCursor INTO @Recseq, @Ident, @Tablename, @Column, @Uploadval

	-- if this is the last record, set the sequence to -1 to process last record.
                IF @@fetch_status <> 0 
                    SELECT  @Recseq = -1

            END -- same Seq
        ELSE 
            BEGIN -- differnet Seq

	-- set defaults for non null fields
                IF @IsVendorEmpty <> 'Y' 
                    BEGIN
                        INSERT  INTO IMWM
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
                                , 1
                                , '** Vendors not allowed in import **'
                                , @VendorID )			
 			
                        SELECT  @rcode = 1
                        SELECT  @desc = @msg
                        UPDATE  IMWE
                        SET     IMWE.UploadVal = '** Vendors not allowed in import **'
                        WHERE   IMWE.ImportTemplate = @ImportTemplate
                                AND IMWE.ImportId = @ImportId
                                AND IMWE.RecordSeq = @currrecseq
                                AND IMWE.Identifier = @VendorID
                                AND IMWE.RecordType = @rectype
                    END	

                IF @ynFirmNumber = 'Y'
                    AND ( ISNULL(@OverwriteFirmNumber, 'Y') = 'Y'
                    OR ISNULL(@IsFirmNumberEmpty, 'Y') = 'Y' ) 
                    BEGIN
                        SELECT  @FirmNumber = MAX(FirmNumber) + @currrecseq
                        FROM    PMFM
                        WHERE   dbo.PMFM.VendorGroup = @VendorGroup
						IF @FirmNumber IS NULL
							SELECT @FirmNumber=2 -- reserve 1 for our firm                      
						IF @FirmNumber>999999 
							SELECT @desc='FirmNumber must be less than 1,000,000'
						ELSE IF ABS(@FirmNumber)<>@FirmNumber
							SELECT @desc='FirmNumber must not have decimals'
						ELSE
							SELECT @desc=@FirmNumber                    
                        
                        UPDATE  IMWE
                        SET     IMWE.UploadVal = @desc
                        WHERE   IMWE.ImportTemplate = @ImportTemplate
                                AND IMWE.ImportId = @ImportId
                                AND IMWE.RecordSeq = @currrecseq
                                AND IMWE.Identifier = @FirmNumberID
                                AND IMWE.RecordType = @rectype
                    END	
				
                IF @IsVendorGroupEmpty = 'Y' 
                    BEGIN
                        UPDATE  IMWE
                        SET     IMWE.UploadVal = @DefVendorGroup
                        WHERE   IMWE.ImportTemplate = @ImportTemplate
                                AND IMWE.ImportId = @ImportId
                                AND IMWE.RecordSeq = @currrecseq
                                AND IMWE.Identifier = @VendorGroupID
                                AND IMWE.RecordType = @rectype
                    END

/* SORT NAME*/
                IF @ynSortName = 'Y'
                    AND ( ISNULL(@OverwriteSortName, 'Y') = 'Y'
                    OR ISNULL(@IsSortNameEmpty, 'Y') = 'Y' ) 
                    BEGIN
                        DECLARE @vreccount INT
                          , @vendtemp VARCHAR(10)
                          , @wreccount INT
                        SELECT  @SortName = UPPER(@FirmName)
	
		--check if the sortname is in use by another Vendor
                        SELECT  @vreccount = COUNT(*)
                        FROM    bPMFM WITH ( NOLOCK )
                        WHERE   VendorGroup = @VendorGroup
                                AND SortName = @SortName
                                AND FirmNumber <> @FirmNumber	--exclude existing record for this firm
                        IF @vreccount > 0 --if sortname is already in use, append firm number
                            BEGIN	--(max length of SortName is 15 characters)
                                SELECT  @vendtemp = CONVERT(VARCHAR(10), @FirmNumber)	
                                SELECT  @SortName = UPPER(RTRIM(LEFT(@FirmName, 15 - LEN(@vendtemp)))) + @vendtemp
                            END
		--issue #123214, also check IMWE for existing SortName.
                        SELECT  @vreccount = COUNT(*)
                        FROM    IMWE
                        WHERE   IMWE.ImportTemplate = @ImportTemplate
                                AND IMWE.Identifier = @SortNameID
                                AND IMWE.RecordType = @rectype
                                AND IMWE.UploadVal = @SortName
                        IF @vreccount > 0	--if sortname is already in use, append firm number
                            BEGIN	--(max length of SortName is 15 characters)
                                SELECT  @vendtemp = CONVERT(VARCHAR(10), @FirmNumber)
                                SELECT  @SortName = UPPER(LEFT(@FirmName, 15 - LEN(@vendtemp))) + @vendtemp
                            END
                        UPDATE  IMWE
                        SET     IMWE.UploadVal = @SortName
                        WHERE   IMWE.ImportTemplate = @ImportTemplate
                                AND IMWE.ImportId = @ImportId
                                AND IMWE.RecordSeq = @currrecseq
                                AND IMWE.Identifier = @SortNameID
                                AND IMWE.RecordType = @rectype
                    END


/* Firm Type*/	
                IF @IsFirmTypeEmpty <> 'Y' 
                    BEGIN
                        EXEC @rc= bspPMFirmTypeVal 
                            @firmtype = @FirmType
                          , @msg = @msg 
                        IF @rc <> 0 
                            BEGIN
                                INSERT  INTO IMWM
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
                                        , ISNULL(@msg, 'Invalid Firm Type')
                                        , @FirmTypeID )			
                                SELECT  @rcode = 1
                                SELECT  @desc = @msg
                                UPDATE  IMWE
                                SET     IMWE.UploadVal = '** Invalid **'
                                WHERE   IMWE.ImportTemplate = @ImportTemplate
                                        AND IMWE.ImportId = @ImportId
                                        AND IMWE.RecordSeq = @currrecseq
                                        AND IMWE.Identifier = @FirmTypeID
                                        AND IMWE.RecordType = @rectype
                            END	
                    END
                    
/* force a 'N' for update AP since non-of these firms should be vendors*/
                BEGIN
                    UPDATE  IMWE
                    SET     IMWE.UploadVal = 'N'
                    WHERE   IMWE.ImportTemplate = @ImportTemplate
                            AND IMWE.ImportId = @ImportId
                            AND IMWE.RecordSeq = @currrecseq
                            AND IMWE.Identifier = @UpdateAPID
                            AND IMWE.RecordType = @rectype
                            AND ISNULL(IMWE.UploadVal, '') <> 'N'
                END
		
		
/* force a 'N' for ExcludeYN if its not a Y*/
                BEGIN
                    UPDATE  IMWE
                    SET     IMWE.UploadVal = 'N'
                    WHERE   IMWE.ImportTemplate = @ImportTemplate
                            AND IMWE.ImportId = @ImportId
                            AND IMWE.RecordSeq = @currrecseq
                            AND IMWE.Identifier = @ExcludeYNID
                            AND IMWE.RecordType = @rectype
                            AND ISNULL(IMWE.UploadVal, '') NOT IN ( 'N', 'Y' )
                END	
  
    	-- set Current Req Seq to next @Recseq unless we are processing last record.
                IF @Recseq = -1 
                    SELECT  @complete = 1	-- exit the loop
                ELSE 
                    SELECT  @currrecseq = @Recseq
    
            END
    END
    
/* SORT NAMES MUST BE UPPERCASE*/    
UPDATE  IMWE
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

SELECT  @msg = ISNULL(@desc, 'Clear') + CHAR(13) + CHAR(10) + '[vspIMViewpointDefaultsPMFM]'

RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMViewpointDefaultsPMFM] TO [public]
GO
