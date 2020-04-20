SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vspIMViewpointDefaultsPRDD]
/***********************************************************
* CREATED BY:   Jim E  3/12/2013
*
* Usage:  Imports into PRDD table
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
SET nocount ON
 
DECLARE @rcode INT
  , @desc VARCHAR(120)
  , @status INT
  , @defaultvalue VARCHAR(30)
  , @CursorOpen INT	
 
 --Identifiers
DECLARE @PRCoID INT
DECLARE @EmpID INT
DECLARE @SeqID INT
DECLARE @TypeID INT
DECLARE @StatusID INT
DECLARE @MethodID INT
 
 
 --Values
 
 --Flags for dependent defaults
 
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
 
DECLARE @OverwritePRCo bYN
  , @OverwriteEmployee bYN
  , @OverwriteSeq bYN
  , @OverwriteRoutingId bYN --#139723
  , @OverwriteBankAcct bYN
  , @OverwriteOverLimit bYN
  , @OverwriteType bYN
  , @OverwriteStatus bYN
  , @OverwriteFrequency bYN
  , @OverwriteMethod bYN
  , @OverwritePct bYN
  , @OverwriteAmount bYN
  , @IsPRCoEmpty bYN
  , @IsEmployeeEmpty bYN
  , @IsSeqEmpty bYN
  , @IsRoutingIdEmpty bYN
  , @IsBankAcctEmpty bYN
  , @IsTypeEmpty bYN
  , @IsStatusEmpty bYN
  , @IsFrequencyEmpty bYN
  , @IsMethodEmpty bYN
  , @IsOverMiscAmtEmpty bYN
  , @IsPctEmpty bYN
  , @IsAmountEmpty bYN	 --#139723		


SELECT  @OverwritePRCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form,
 'PRCo', @rectype);
SELECT  @OverwriteEmployee = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Employee', @rectype);
SELECT  @OverwriteSeq = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form,
'Seq', @rectype);
		
SELECT  @TypeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Type',
 @rectype, 'N')
SELECT  @StatusID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Status', @rectype, 'N')
SELECT  @MethodID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Method', @rectype, 'N') 
 --get database default values	

 --set common defaults
SELECT  @PRCoID = DDUD.Identifier
      , @defaultvalue = IMTD.DefaultValue
FROM    IMTD WITH ( NOLOCK )
INNER JOIN DDUD
ON      IMTD.Identifier = DDUD.Identifier
        AND DDUD.Form = @Form
WHERE   IMTD.ImportTemplate = @ImportTemplate
        AND DDUD.ColumnName = 'PRCo' 
IF @@rowcount <> 0
    AND @defaultvalue = '[Bidtek]'
    AND ( ISNULL(@OverwritePRCo, 'Y') = 'Y' ) 
    BEGIN
        UPDATE  IMWE
        SET     IMWE.UploadVal = @Company
        WHERE   IMWE.ImportTemplate = @ImportTemplate
                AND IMWE.ImportId = @ImportId
                AND IMWE.Identifier = @PRCoID
    END

 --set common defaults
SELECT  @EmpID = DDUD.Identifier
      , @defaultvalue = IMTD.DefaultValue
FROM    IMTD WITH ( NOLOCK )
INNER JOIN DDUD
ON      IMTD.Identifier = DDUD.Identifier
        AND DDUD.Form = @Form
WHERE   IMTD.ImportTemplate = @ImportTemplate
        AND DDUD.ColumnName = 'Employee'
 
SELECT  @SeqID = DDUD.Identifier
      , @defaultvalue = IMTD.DefaultValue
FROM    IMTD WITH ( NOLOCK )
INNER JOIN DDUD
ON      IMTD.Identifier = DDUD.Identifier
        AND DDUD.Form = @Form
WHERE   IMTD.ImportTemplate = @ImportTemplate
        AND DDUD.ColumnName = 'Seq' 
                
IF @@rowcount <> 0
    AND @EmpID IS NOT NULL
    AND ( ISNULL(@OverwriteSeq, 'Y') = 'Y' ) 
    BEGIN
        UPDATE  IMWE
        SET     UploadVal = ISNULL(rn,1)
        FROM    IMWE
        LEFT JOIN ( SELECT   IMWE.ImportTemplate
                      , IMWE.ImportId
                      , IMWE.RecordSeq
                      , rn = ISNULL(mSeq, 0)
                        + ROW_NUMBER() OVER ( PARTITION BY PRCo, Employee ORDER BY PRCo, Employee, IMWE.RecordSeq )
               FROM     IMWE
               JOIN     ( SELECT    PRCo = UploadVal
                                  , RecordSeq
                                  , ImportTemplate
                                  , ImportId
                          FROM      IMWE
                          WHERE     IMWE.ImportTemplate = @ImportTemplate
                                    AND IMWE.ImportId = @ImportId
                                    AND IMWE.Identifier = @PRCoID ) p
               ON       IMWE.ImportTemplate = p.ImportTemplate
                        AND IMWE.ImportId = p.ImportId
                        AND IMWE.RecordSeq = p.RecordSeq
               JOIN     ( SELECT    Employee = UploadVal
                                  , RecordSeq
                                  , ImportTemplate
                                  , ImportId
                          FROM      IMWE
                          WHERE     IMWE.ImportTemplate = @ImportTemplate
                                    AND IMWE.ImportId = @ImportId
                                    AND IMWE.Identifier = @EmpID ) e
               ON       IMWE.ImportTemplate = e.ImportTemplate
                        AND IMWE.ImportId = e.ImportId
                        AND IMWE.RecordSeq = e.RecordSeq
               JOIN     ( SELECT    mPRCo = PRCo
                                  , mEmployee = Employee
                                  , mSeq = MAX(Seq)
                          FROM      PRDD
                          GROUP BY  PRCo
                                  , Employee ) AS NxtSeq
               ON       mPRCo = PRCo
                        AND mEmployee = Employee
               WHERE    IMWE.ImportTemplate = @ImportTemplate
                        AND IMWE.ImportId = @ImportId
                        AND IMWE.Identifier = @SeqID ) AS alljoin
        ON      IMWE.ImportTemplate = alljoin.ImportTemplate
                AND IMWE.ImportId = alljoin.ImportId
                AND IMWE.RecordSeq = alljoin.RecordSeq
        WHERE   IMWE.ImportTemplate = @ImportTemplate
                AND IMWE.ImportId = @ImportId
                AND IMWE.Identifier = @SeqID
    END

UPDATE  IMWE
SET     IMWE.UploadVal = 'C'
WHERE   IMWE.ImportTemplate = @ImportTemplate
        AND IMWE.ImportId = @ImportId
        AND ISNULL(IMWE.UploadVal, '') NOT IN ( 'S', 'C' )
        AND ( IMWE.Identifier = @TypeID )

UPDATE  IMWE
SET     IMWE.UploadVal = 'A'
WHERE   IMWE.ImportTemplate = @ImportTemplate
        AND IMWE.ImportId = @ImportId
        AND ISNULL(IMWE.UploadVal, '') NOT IN ( 'A', 'I', 'P' )
        AND ( IMWE.Identifier = @StatusID )
   
UPDATE  IMWE
SET     IMWE.UploadVal = 'A'
WHERE   IMWE.ImportTemplate = @ImportTemplate
        AND IMWE.ImportId = @ImportId
        AND ISNULL(IMWE.UploadVal, '') NOT IN ( 'A', 'P' )
        AND ( IMWE.Identifier = @MethodID )
	

bspexit:
 
IF @CursorOpen = 1 
    BEGIN
        CLOSE WorkEditCursor
        DEALLOCATE WorkEditCursor	
    END
 
SELECT  @msg = ISNULL(@desc, 'Clear') + CHAR(13) + CHAR(13)
        + '[vspIMViewpointDefaultsPRDD]';
 
RETURN @rcode;

GO
GRANT EXECUTE ON  [dbo].[vspIMViewpointDefaultsPRDD] TO [public]
GO
