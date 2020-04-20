SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsINPD]
/***********************************************************
* CREATED BY:   JIME 
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
    (
     @Company bCompany
    ,@ImportId VARCHAR(20)
    ,@ImportTemplate VARCHAR(20)
    ,@Form VARCHAR(20)
    ,@rectype VARCHAR(10)
    ,@msg VARCHAR(120) OUTPUT
    )
AS 
    SET nocount ON

/* General Declares */        
    DECLARE @rcode INT
       ,@recode INT
       ,@desc VARCHAR(120)
       ,@defaultvalue VARCHAR(30)
       ,@errmsg VARCHAR(120)
       ,@FormDetail VARCHAR(20)
       ,@FormHeader VARCHAR(20)
       ,@reckeyid INT
       ,@RecKey VARCHAR(60)
       ,@HeaderRecordType VARCHAR(10)
       ,@HeaderReqSeq INT

/* Column ID's */        
    DECLARE @BatchId INT
       ,@BatchSeq INT
       ,@Co INT
       ,@CompLoc INT
       ,@CompMatl INT
       ,@ECM INT
       ,@MatlGroup INT
       ,@Mth INT
       ,@PECM INT
       ,@ProdSeqID INT
       ,@UM INT
       ,@UnitCost INT
       ,@UnitPrice INT
       ,@Units INT
	 

    DECLARE @ynActDate bYN
       ,@ynBatchId bYN
       ,@ynBatchSeq bYN
       ,@ynCo bYN
       ,@ynDescription bYN
       ,@ynECM bYN
       ,@ynPECM bYN
       ,@ynCompMatl bYN
       ,@ynKeyID bYN
       ,@ynMatlGroup bYN
       ,@ynMth bYN
       ,@ynProdLoc bYN
       ,@ynUM bYN
       ,@ynUniqueAttchID bYN
       ,@ynUnitCost bYN
       ,@ynUnits bYN


    DECLARE @ActDateid INT
       ,@BatchIdid INT
       ,@BatchSeqid INT
       ,@Coid INT
       ,@Descriptionid INT
       ,@ECMid INT
       ,@CompMatlid INT
       ,@CompLocid INT
       ,@KeyIDid INT
       ,@MatlGroupid INT
       ,@Mthid INT
       ,@PECMid INT
       ,@ProdSeqid INT
       ,@ProdLocid INT
       ,@UMid INT
       ,@UniqueAttchIDid INT
       ,@UnitCostid INT
       ,@Unitsid INT
       ,@UnitPriceid INT

    DECLARE @headBatchIdid INT
       ,@headBatchSeqid INT
       ,@headCoid INT
       ,@headFinMatlid INT
       ,@headKeyIDid INT
       ,@headMatlGroupid INT
       ,@headMthid INT
 
--DECLARE @MatlGroupid INT
--  , @CompMatlid INT
--  , @UMid INT
--  , @Unitsid INT
--  , @UnitCostid INT
--  , @ECMid INT
--  , @UnitPriceid INT
--  , @PECMid INT
--  , @CompLocid INT
--  , @ProdSeqid INT 
	
    SELECT  @ynActDate = 'N'
           ,@ynBatchId = 'N'
           ,@ynBatchSeq = 'N'
           ,@ynCo = 'N'
           ,@ynDescription = 'N'
           ,@ynECM = 'N'
           ,@ynCompMatl = 'N'
           ,@ynKeyID = 'N'
           ,@ynMatlGroup = 'N'
           ,@ynMth = 'N'
           ,@ynProdLoc = 'N'
           ,@ynUM = 'N'
           ,@ynUniqueAttchID = 'N'
           ,@ynUnitCost = 'N'
           ,@ynUnits = 'N'
           ,@ynPECM = 'N'
 
    DECLARE @OverwriteActDate bYN
       ,@OverwriteBatchId bYN
       ,@OverwriteBatchSeq bYN
       ,@OverwriteCo bYN
       ,@OverwriteDescription bYN
       ,@OverwriteECM bYN
       ,@OverwriteCompMatl bYN
       ,@OverwriteKeyID bYN
       ,@OverwriteMatlGroup bYN
       ,@OverwriteMth bYN
       ,@OverwriteProdLoc bYN
       ,@OverwriteUM bYN
       ,@OverwriteUniqueAttchID bYN
       ,@OverwriteUnitCost bYN
       ,@OverwriteUnits bYN
       ,@OverwritePECM bYN
       ,@OverwriteUnitPrice bYN
			
--select 'select @Overwrite'+c.name+' = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, '''
--      +c.name+''', @rectype);' from syscolumns c where object_name(id)='bINPB'

SELECT  @OverwriteActDate = dbo.vfIMTemplateOverwrite(@ImportTemplate,@Form, 'ActDate',@rectype);
SELECT  @OverwriteBatchId = dbo.vfIMTemplateOverwrite(@ImportTemplate,@Form, 'BatchId',@rectype);
SELECT  @OverwriteBatchSeq = dbo.vfIMTemplateOverwrite(@ImportTemplate,@Form, 'BatchSeq',@rectype);
SELECT  @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form,'Co', @rectype);
SELECT  @OverwriteDescription = dbo.vfIMTemplateOverwrite(@ImportTemplate,@Form,'Description',@rectype);
SELECT  @OverwriteECM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form,'ECM', @rectype);
SELECT  @OverwriteCompMatl = dbo.vfIMTemplateOverwrite(@ImportTemplate,@Form, 'CompMatl',@rectype);
SELECT  @OverwriteKeyID = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form,'KeyID', @rectype);
SELECT  @OverwriteMatlGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate,@Form, 'MatlGroup',@rectype);
SELECT  @OverwriteMth = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form,'Mth', @rectype);
SELECT  @OverwritePECM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PECM', @rectype);
SELECT  @OverwriteProdLoc = dbo.vfIMTemplateOverwrite(@ImportTemplate,@Form, 'ProdLoc',@rectype);
SELECT  @OverwriteUM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form,'UM', @rectype);
SELECT  @OverwriteUniqueAttchID = dbo.vfIMTemplateOverwrite(@ImportTemplate,@Form,'UniqueAttchID',@rectype);
SELECT  @OverwriteUnitCost = dbo.vfIMTemplateOverwrite(@ImportTemplate,@Form, 'UnitCost',@rectype);
SELECT  @OverwriteUnits = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Units', @rectype);

/* Cursor variables */
    DECLARE @Recseq INT
       ,@Tablename VARCHAR(20)
       ,@Column VARCHAR(30)
       ,@Uploadval VARCHAR(60)
       ,@Ident INT

    SELECT  @rcode = 0
           ,@msg = '' 

/* check required input params */

    IF @ImportId IS NULL 
        BEGIN
            SELECT  @desc = 'Missing ImportId.'
                   ,@rcode = 1
            GOTO bspexit
        END
	
    IF @ImportTemplate IS NULL 
        BEGIN
            SELECT  @desc = 'Missing ImportTemplate.'
                   ,@rcode = 1
            GOTO bspexit
        END

    IF @Form IS NULL 
        BEGIN
            SELECT  @desc = 'Missing Form.'
                   ,@rcode = 1
            GOTO bspexit
        END
        
    SELECT  @FormHeader = 'INProduction'
    SELECT  @FormDetail = 'INProdComponents'  
    SELECT  @Form = 'INProduction'
        
    SELECT  @HeaderRecordType = RecordType
    FROM    IMTR WITH ( NOLOCK )
    WHERE   @ImportTemplate = ImportTemplate
            AND Form = @FormHeader

/****************************************************************************************
*																						*
*			RECORDS ALREADY EXIST IN THE IMWE TABLE FROM THE IMPORTED TEXTFILE			*
*																						*
*			All records with the same RecordSeq represent a single import record		*
*																						*
****************************************************************************************/
        
/* Check ImportTemplate detail for columns to set Bidtek Defaults */
/* REM'D BECAUSE:  We cannot assume that user has imported every non-nullable value required by the table.
   If we exit this routine, then any non-nullable fields without an imported value will cause a
   table constraint error during the final upload process.  This procedure should provide enough
   defaults to SAVE the record, without error, if the import has not done so. */         
--if not exists(select IMTD.DefaultValue From IMTD
--		Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
--			and IMTD.RecordType = @rectype)
--goto bspexit

/* Record KeyID is the link between Header and Detail that will allow us retrieve values
   from the Header, later, when needed. (Sometimes RecKey will need to be added to DDUD
   manually for both Form Header and Form Detail) */
    SELECT  @reckeyid = a.Identifier			--1000
    FROM    IMTD a WITH ( NOLOCK )
    JOIN    DDUD b WITH ( NOLOCK )
            ON a.Identifier = b.Identifier
    WHERE   a.ImportTemplate = @ImportTemplate
            AND b.ColumnName = 'RecKey'
            AND a.RecordType = @rectype
            AND b.Form = @FormDetail

---- needed for other defaults

---- get detail columns
--SELECT  @MatlGroupid = a.Identifier
--FROM    IMTD a
--JOIN    DDUD b
--ON      a.Identifier = b.Identifier
--WHERE   a.ImportTemplate = @ImportTemplate
--        AND b.ColumnName = 'MatlGroup'
--        AND a.RecordType = @rectype
--        AND b.Form = @FormDetail

---- get detail columns
--SELECT  @CompMatlid = a.Identifier
--FROM    IMTD a
--JOIN    DDUD b
--ON      a.Identifier = b.Identifier
--WHERE   a.ImportTemplate = @ImportTemplate
--        AND b.ColumnName = 'CompMatl'
--        AND a.RecordType = @rectype
--        AND b.Form = @FormDetail

---- get detail columns
--SELECT  @ProdSeqid = a.Identifier
--FROM    IMTD a
--JOIN    DDUD b
--ON      a.Identifier = b.Identifier
--WHERE   a.ImportTemplate = @ImportTemplate
--        AND b.ColumnName = 'ProdSeq'
--        AND a.RecordType = @rectype
--        AND b.Form = @FormDetail

---- get detail columns
--SELECT  @CompLocid = a.Identifier
--FROM    IMTD a
--JOIN    DDUD b
--ON      a.Identifier = b.Identifier
--WHERE   a.ImportTemplate = @ImportTemplate
--        AND b.ColumnName = 'CompLoc'
--        AND a.RecordType = @rectype
--        AND b.Form = @FormDetail

---- get detail columns
--SELECT  @UMid = a.Identifier
--FROM    IMTD a
--JOIN    DDUD b
--ON      a.Identifier = b.Identifier
--WHERE   a.ImportTemplate = @ImportTemplate
--        AND b.ColumnName = 'UM'
--        AND a.RecordType = @rectype
--        AND b.Form = @FormDetail

---- get detail columns
--SELECT  @Unitsid = a.Identifier
--FROM    IMTD a
--JOIN    DDUD b
--ON      a.Identifier = b.Identifier
--WHERE   a.ImportTemplate = @ImportTemplate
--        AND b.ColumnName = 'Units'
--        AND a.RecordType = @rectype
--        AND b.Form = @FormDetail

---- get detail columns
--SELECT  @UnitCostid = a.Identifier
--FROM    IMTD a
--JOIN    DDUD b
--ON      a.Identifier = b.Identifier
--WHERE   a.ImportTemplate = @ImportTemplate
--        AND b.ColumnName = 'UnitCost'
--        AND a.RecordType = @rectype
--        AND b.Form = @FormDetail

---- get detail columns
--SELECT  @ECMid = a.Identifier
--FROM    IMTD a
--JOIN    DDUD b
--ON      a.Identifier = b.Identifier
--WHERE   a.ImportTemplate = @ImportTemplate
--        AND b.ColumnName = 'ECM'
--        AND a.RecordType = @rectype
--        AND b.Form = @FormDetail

---- get detail columns
--SELECT  @UnitPriceid = a.Identifier
--FROM    IMTD a
--JOIN    DDUD b
--ON      a.Identifier = b.Identifier
--WHERE   a.ImportTemplate = @ImportTemplate
--        AND b.ColumnName = 'UnitPrice'
--        AND a.RecordType = @rectype
--        AND b.Form = @FormDetail

---- get detail columns
--SELECT  @PECMid = a.Identifier
--FROM    IMTD a
--JOIN    DDUD b
--ON      a.Identifier = b.Identifier
--WHERE   a.ImportTemplate = @ImportTemplate
--        AND b.ColumnName = 'PECM'
--        AND a.RecordType = @rectype
--        AND b.Form = @FormDetail


-- header ids

    DECLARE @headreckeyid INT
    SELECT  @headreckeyid = a.Identifier
    FROM    IMTD a
    JOIN    DDUD b
            ON a.Identifier = b.Identifier
    WHERE   a.ImportTemplate = @ImportTemplate
            AND b.ColumnName = 'RecKey'
            AND a.RecordType = @HeaderRecordType
            AND b.Form = @FormHeader


    SELECT  @headBatchIdid = a.Identifier
    FROM    IMTD a
    JOIN    DDUD b
            ON a.Identifier = b.Identifier
    WHERE   a.ImportTemplate = @ImportTemplate
            AND b.ColumnName = 'BatchId'
            AND a.RecordType = @HeaderRecordType
            AND b.Form = @FormHeader

    SELECT  @headBatchSeqid = a.Identifier
    FROM    IMTD a
    JOIN    DDUD b
            ON a.Identifier = b.Identifier
    WHERE   a.ImportTemplate = @ImportTemplate
            AND b.ColumnName = 'BatchSeq'
            AND a.RecordType = @HeaderRecordType
            AND b.Form = @FormHeader

    SELECT  @headCoid = a.Identifier
    FROM    IMTD a
    JOIN    DDUD b
            ON a.Identifier = b.Identifier
    WHERE   a.ImportTemplate = @ImportTemplate
            AND b.ColumnName = 'Co'
            AND a.RecordType = @HeaderRecordType
            AND b.Form = @FormHeader

    SELECT  @headKeyIDid = a.Identifier
    FROM    IMTD a
    JOIN    DDUD b
            ON a.Identifier = b.Identifier
    WHERE   a.ImportTemplate = @ImportTemplate
            AND b.ColumnName = 'RecKey'
            AND a.RecordType = @HeaderRecordType
            AND b.Form = @FormHeader

    SELECT  @headMatlGroupid = a.Identifier
    FROM    IMTD a
    JOIN    DDUD b
            ON a.Identifier = b.Identifier
    WHERE   a.ImportTemplate = @ImportTemplate
            AND b.ColumnName = 'MatlGroup'
            AND a.RecordType = @HeaderRecordType
            AND b.Form = @FormHeader


    SELECT  @headMthid = a.Identifier
    FROM    IMTD a
    JOIN    DDUD b
            ON a.Identifier = b.Identifier
    WHERE   a.ImportTemplate = @ImportTemplate
            AND b.ColumnName = 'Mth'
            AND a.RecordType = @HeaderRecordType
            AND b.Form = @FormHeader


	SELECT  @Coid = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail,'Co', @rectype, 'N')
	SELECT  @BatchId = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail,'Batch', @rectype, 'N')
	SELECT  @BatchSeqid = dbo.bfIMTemplateDefaults(@ImportTemplate,@FormDetail, 'BatchSeq',@rectype, 'N')
	SELECT  @Mthid = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail,'Mth', @rectype, 'N')
	SELECT  @MatlGroupid = dbo.bfIMTemplateDefaults(@ImportTemplate,@FormDetail, 'MatlGroup',@rectype, 'N')
	SELECT  @ECMid = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail,'ECM', @rectype, 'N');
	SELECT  @UMid = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail,'UM', @rectype, 'N')
	SELECT  @UnitCostid = dbo.bfIMTemplateDefaults(@ImportTemplate,@FormDetail, 'UnitCost',@rectype, 'N')
	SELECT  @Unitsid = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail,'Units', @rectype, 'N')
	SELECT  @UnitPriceid = dbo.bfIMTemplateDefaults(@ImportTemplate,@FormDetail, 'UnitPrice',@rectype, 'N')
    SELECT  @PECMid = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'PECM', @rectype, 'N');
    SELECT  @CompMatlid = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'CompMatl', @rectype, 'N')
    SELECT  @CompLocid = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'CompLoc', @rectype, 'N');

-- get header company
    IF @Coid IS NOT NULL 
        BEGIN
	 
            UPDATE  IMWE
            SET     UploadVal = Company
            FROM    dbo.IMWE
            JOIN    ( SELECT    Company = UploadVal
                               ,ImportTemplate
                               ,ImportId
                      FROM      IMWE WITH ( NOLOCK )
                      WHERE     IMWE.ImportTemplate = @ImportTemplate
                                AND IMWE.ImportId = @ImportId
                                AND IMWE.Identifier = @headCoid
                                AND IMWE.RecordType = @HeaderRecordType
                    ) AS hinfo
                    ON hinfo.ImportTemplate = IMWE.ImportTemplate
                       AND hinfo.ImportId = IMWE.ImportId
            WHERE   RecordType = @rectype
                    AND Identifier = @Coid
                    AND IMWE.ImportTemplate = @ImportTemplate
                    AND IMWE.ImportId = @ImportId
        END 
		
-- Batch

    IF ISNULL(@BatchId, 0) <> 0 
        BEGIN
            UPDATE  IMWE
            SET     UploadVal = Batch
            FROM    dbo.IMWE
            JOIN    ( SELECT    Batch = UploadVal
                               ,ImportTemplate
                               ,ImportId
                      FROM      IMWE WITH ( NOLOCK )
                      WHERE     IMWE.ImportTemplate = @ImportTemplate
                                AND IMWE.ImportId = @ImportId
                                AND IMWE.Identifier = @headBatchIdid
                                AND IMWE.RecordType = @HeaderRecordType
                    ) AS hinfo
                    ON hinfo.ImportTemplate = IMWE.ImportTemplate
                       AND hinfo.ImportId = IMWE.ImportId
            WHERE   RecordType = @rectype
                    AND Identifier = @BatchId
                    AND IMWE.ImportTemplate = @ImportTemplate
                    AND IMWE.ImportId = @ImportId
        END 

--BatchSeq

    IF ISNULL(@BatchSeqid, 0) <> 0 
        BEGIN
            UPDATE  IMWE
            SET     UploadVal = BatchSeq
            FROM    dbo.IMWE
            JOIN    ( SELECT    BatchSeq = UploadVal
                               ,ImportTemplate
                               ,ImportId
                      FROM      IMWE WITH ( NOLOCK )
                      WHERE     IMWE.ImportTemplate = @ImportTemplate
                                AND IMWE.ImportId = @ImportId
                                AND IMWE.Identifier = @headBatchSeqid
                                AND IMWE.RecordType = @HeaderRecordType
                    ) AS hinfo
                    ON hinfo.ImportTemplate = IMWE.ImportTemplate
                       AND hinfo.ImportId = IMWE.ImportId
            WHERE   RecordType = @rectype
                    AND Identifier = @BatchSeqid
                    AND IMWE.ImportTemplate = @ImportTemplate
                    AND IMWE.ImportId = @ImportId
        END 


    IF ISNULL(@Mthid, 0) <> 0 
        BEGIN
            UPDATE  IMWE
            SET     UploadVal = Mth
            FROM    dbo.IMWE
            JOIN    ( SELECT    Mth = UploadVal
                               ,ImportTemplate
                               ,ImportId
                      FROM      IMWE WITH ( NOLOCK )
                      WHERE     IMWE.ImportTemplate = @ImportTemplate
                                AND IMWE.ImportId = @ImportId
                                AND IMWE.Identifier = @headMthid
                                AND IMWE.RecordType = @HeaderRecordType
                    ) AS hinfo
                    ON hinfo.ImportTemplate = IMWE.ImportTemplate
                       AND hinfo.ImportId = IMWE.ImportId
            WHERE   RecordType = @rectype
                    AND Identifier = @Mthid
                    AND IMWE.ImportTemplate = @ImportTemplate
                    AND IMWE.ImportId = @ImportId
        END 

-- prod seq cant be null
    IF ISNULL(@ProdSeqid, 0) <> 0 
        BEGIN
            UPDATE  IMWE
            SET     UploadVal = RecordSeq
            FROM    dbo.IMWE
            WHERE   RecordType = @rectype
                    AND Identifier = @ProdSeqid
                    AND IMWE.ImportTemplate = @ImportTemplate
                    AND IMWE.ImportId = @ImportId
                    AND UploadVal IS NULL
        END 
/************************
-- MatlGroup Default
**************************/

    BEGIN;
        UPDATE  [dbo].[IMWE]
        SET     IMWE.UploadVal = bHQCO.MatlGroup  -- default value
        FROM    [dbo].[IMWE]
        JOIN    [dbo].[IMWE] CO
                ON CO.ImportTemplate = @ImportTemplate
                   AND CO.ImportId = @ImportId
                   AND CO.Identifier = @Coid
                   AND CO.RecordType = @rectype
                   AND CO.RecordSeq = IMWE.RecordSeq
        JOIN    [dbo].[bHQCO]
                ON bHQCO.HQCo = CO.UploadVal
        WHERE   IMWE.ImportTemplate = @ImportTemplate
                AND IMWE.ImportId = @ImportId
                AND IMWE.Identifier = @MatlGroupid
                AND IMWE.RecordType = @rectype
                AND ( ( ISNULL(@MatlGroupid, 0) <> 0
                        AND ( ISNULL(@OverwriteMatlGroup, 'Y') = 'Y' ) )
                      OR IMWE.UploadVal IS NULL )
    END;
		


/************************
-- ECM Default
**************************/

--BEGIN;
--    UPDATE  [dbo].[IMWE]
--    SET     IMWE.UploadVal = bHQMT.CostECM  -- default value  
--    FROM    [dbo].[IMWE]
--    JOIN    [dbo].[IMWE] MG
--    ON      MG.ImportTemplate = @ImportTemplate
--            AND MG.ImportId = @ImportId
--            AND MG.Identifier = @MatlGroupid
--            AND MG.RecordType = @rectype
--            AND MG.RecordSeq = IMWE.RecordSeq
--    JOIN    [dbo].[IMWE] FM
--    ON      FM.ImportTemplate = @ImportTemplate
--            AND FM.ImportId = @ImportId
--            AND FM.Identifier = @CompMatlid
--            AND FM.RecordType = @rectype
--            AND FM.RecordSeq = IMWE.RecordSeq
--    JOIN    [dbo].[bHQMT]
--    ON      bHQMT.MatlGroup = MG.UploadVal
--            AND bHQMT.Material = FM.UploadVal
--    WHERE   IMWE.ImportTemplate = @ImportTemplate
--            AND IMWE.ImportId = @ImportId
--            AND IMWE.Identifier = @ECMid
--            AND ISNULL(@ECMid, 0) <> 0
--            AND IMWE.RecordType = @rectype
--            AND ( ( @ECMid > 0
--            AND ISNULL(@OverwriteECM, 'Y') = 'Y' )
--            OR IMWE.UploadVal IS NULL );
--END;
	

/************************
-- UM Default
**************************/

    BEGIN;
        UPDATE  [dbo].[IMWE]
        SET     IMWE.UploadVal = bHQMT.StdUM  -- default value
        FROM    [dbo].[IMWE]
        JOIN    [dbo].[IMWE] MG
                ON MG.ImportTemplate = @ImportTemplate
                   AND MG.ImportId = @ImportId
                   AND MG.Identifier = @MatlGroupid
                   AND MG.RecordType = @rectype
                   AND MG.RecordSeq = IMWE.RecordSeq
        JOIN    [dbo].[IMWE] FM
                ON FM.ImportTemplate = @ImportTemplate
                   AND FM.ImportId = @ImportId
                   AND FM.Identifier = @CompMatlid
                   AND FM.RecordType = @rectype
                   AND FM.RecordSeq = IMWE.RecordSeq
        JOIN    [dbo].[bHQMT]
                ON bHQMT.MatlGroup = MG.UploadVal
                   AND bHQMT.Material = FM.UploadVal
        WHERE   IMWE.ImportTemplate = @ImportTemplate
                AND IMWE.ImportId = @ImportId
                AND IMWE.RecordType = @rectype
                AND IMWE.Identifier = @UMid	  --
                AND ( ( ISNULL(@UMid, 0) <> 0
                        AND ISNULL(@OverwriteUM, 'Y') = 'Y' )
                      OR ISNULL(IMWE.UploadVal, '') = '' )
    END;


/************************
-- UnitCost Default
**************************/

    BEGIN;
        UPDATE  [dbo].[IMWE]
        SET     IMWE.UploadVal = ISNULL(Costs.CostVal, bINMT.StdCost)  -- default value
        FROM    [dbo].[IMWE]
        JOIN    [dbo].[IMWE] MG
                ON MG.ImportTemplate = @ImportTemplate -- mat group
                   AND MG.ImportId = @ImportId
                   AND MG.Identifier = @MatlGroupid
                   AND MG.RecordType = @rectype
                   AND MG.RecordSeq = IMWE.RecordSeq
        JOIN    [dbo].[IMWE] FM
                ON FM.ImportTemplate = @ImportTemplate -- component mat
                   AND FM.ImportId = @ImportId
                   AND FM.Identifier = @CompMatlid
                   AND FM.RecordType = @rectype
                   AND FM.RecordSeq = IMWE.RecordSeq
        JOIN    [dbo].[IMWE] CM
                ON CM.ImportTemplate = @ImportTemplate -- co
                   AND CM.ImportId = @ImportId
                   AND CM.Identifier = @Coid
                   AND CM.RecordType = @rectype
                   AND CM.RecordSeq = IMWE.RecordSeq
        JOIN    [dbo].[IMWE] LM
                ON LM.ImportTemplate = @ImportTemplate -- location
                   AND LM.ImportId = @ImportId
                   AND LM.Identifier = @CompLocid
                   AND LM.RecordType = @rectype
                   AND LM.RecordSeq = IMWE.RecordSeq
        JOIN    [dbo].[bINMT]
                ON [bINMT].INCo = CM.UploadVal
                   AND [bINMT].Loc = LM.UploadVal
                   AND [bINMT].MatlGroup = MG.UploadVal
                   AND [bINMT].Material = FM.UploadVal
        JOIN    ( SELECT    bINMT.INCo
                           ,bINMT.Loc
                           ,bINMT.MatlGroup
                           ,bINMT.Material
                           ,CostVal = CASE COALESCE(bINLO.CostMethod,
                                                    dbo.bINLM.CostMethod,
                                                    bINCO.CostMethod, 1)
                                        WHEN 2 THEN bINMT.LastCost
                                        WHEN 3 THEN bINMT.StdCost
                                        ELSE bINMT.AvgCost
                                      END
                  FROM      bINMT
                  JOIN      bINCO
                            ON bINMT.INCo = bINCO.INCo
                  JOIN      bHQMT
                            ON bINMT.MatlGroup = bHQMT.MatlGroup
                               AND bINMT.Material = bHQMT.Material
                  LEFT OUTER JOIN bINLO
                            ON bINLO.INCo = bINMT.INCo
                               AND bINLO.Loc = bINMT.Loc
                               AND bINLO.MatlGroup = bINMT.MatlGroup
                               AND bINLO.Category = bHQMT.Category
                               AND bINLO.CostMethod IN ( 1, 2, 3 )
                  LEFT OUTER JOIN bINLM
                            ON bINLM.INCo = bINMT.INCo
                               AND bINLM.Loc = bINMT.Loc
                               AND bINLM.CostMethod IN ( 1, 2, 3 )
                ) AS Costs
                ON Costs.INCo = CM.UploadVal
                   AND Costs.Loc = LM.UploadVal
                   AND Costs.MatlGroup = MG.UploadVal
                   AND Costs.Material = FM.UploadVal
        WHERE   IMWE.ImportTemplate = @ImportTemplate
                AND IMWE.ImportId = @ImportId
                AND IMWE.Identifier = @UnitCostid
                AND IMWE.RecordType = @rectype
                AND ( ( ISNULL(@UnitCostid, 0) <> 0
                        AND ISNULL(@OverwriteUnitCost, 'Y') = 'Y' )
                      OR IMWE.UploadVal IS NULL )
    END;	

/************************
-- Cost ECM Default
**************************/

    BEGIN;
        UPDATE  [dbo].[IMWE]
        SET     IMWE.UploadVal = ISNULL(Costs.ECM, bINMT.StdECM)  -- default value
        FROM    [dbo].[IMWE]
        JOIN    [dbo].[IMWE] MG
                ON MG.ImportTemplate = @ImportTemplate -- mat group
                   AND MG.ImportId = @ImportId
                   AND MG.Identifier = @MatlGroupid
                   AND MG.RecordType = @rectype
                   AND MG.RecordSeq = IMWE.RecordSeq
        JOIN    [dbo].[IMWE] FM
                ON FM.ImportTemplate = @ImportTemplate -- component mat
                   AND FM.ImportId = @ImportId
                   AND FM.Identifier = @CompMatlid
                   AND FM.RecordType = @rectype
                   AND FM.RecordSeq = IMWE.RecordSeq
        JOIN    [dbo].[IMWE] CM
                ON CM.ImportTemplate = @ImportTemplate -- co
                   AND CM.ImportId = @ImportId
                   AND CM.Identifier = @Coid
                   AND CM.RecordType = @rectype
                   AND CM.RecordSeq = IMWE.RecordSeq
        JOIN    [dbo].[IMWE] LM
                ON LM.ImportTemplate = @ImportTemplate -- location
                   AND LM.ImportId = @ImportId
                   AND LM.Identifier = @CompLocid
                   AND LM.RecordType = @rectype
                   AND LM.RecordSeq = IMWE.RecordSeq
        JOIN    [dbo].[bINMT]
                ON [bINMT].INCo = CM.UploadVal
                   AND [bINMT].Loc = LM.UploadVal
                   AND [bINMT].MatlGroup = MG.UploadVal
                   AND [bINMT].Material = FM.UploadVal
        JOIN    ( SELECT    bINMT.INCo
                           ,bINMT.Loc
                           ,bINMT.MatlGroup
                           ,bINMT.Material
                           ,ECM = CASE COALESCE(bINLO.CostMethod,
                                                dbo.bINLM.CostMethod,
                                                bINCO.CostMethod, 1)
                                    WHEN 2 THEN bINMT.LastECM
                                    WHEN 3 THEN bINMT.StdECM
                                    ELSE bINMT.AvgECM
                                  END
                  FROM      bINMT
                  JOIN      bINCO
                            ON bINMT.INCo = bINCO.INCo
                  JOIN      bHQMT
                            ON bINMT.MatlGroup = bHQMT.MatlGroup
                               AND bINMT.Material = bHQMT.Material
                  LEFT OUTER JOIN bINLO
                            ON bINLO.INCo = bINMT.INCo
                               AND bINLO.Loc = bINMT.Loc
                               AND bINLO.MatlGroup = bINMT.MatlGroup
                               AND bINLO.Category = bHQMT.Category
                               AND bINLO.CostMethod IN ( 1, 2, 3 )
                  LEFT OUTER JOIN bINLM
                            ON bINLM.INCo = bINMT.INCo
                               AND bINLM.Loc = bINMT.Loc
                               AND bINLM.CostMethod IN ( 1, 2, 3 )
                ) AS Costs
                ON Costs.INCo = CM.UploadVal
                   AND Costs.Loc = LM.UploadVal
                   AND Costs.MatlGroup = MG.UploadVal
                   AND Costs.Material = FM.UploadVal
        WHERE   IMWE.ImportTemplate = @ImportTemplate
                AND IMWE.ImportId = @ImportId
                AND IMWE.Identifier = @ECMid
                AND IMWE.RecordType = @rectype
                AND ( ( ISNULL(@ECMid, 0) <> 0
                        AND ISNULL(@OverwriteECM, 'Y') = 'Y' )
                      OR IMWE.UploadVal IS NULL )
    END;			

/************************
-- Units Default
**************************/

    IF ISNULL(@Unitsid, 0) <> 0
        AND ( ISNULL(@OverwriteUnits, 'Y') = 'Y' ) 
        BEGIN;
            UPDATE  [dbo].[IMWE]
            SET     IMWE.UploadVal = '0'  -- default value
            WHERE   IMWE.ImportTemplate = @ImportTemplate
                    AND IMWE.ImportId = @ImportId
                    AND IMWE.Identifier = @Unitsid
                    AND IMWE.RecordType = @rectype
                    AND ( ( ISNULL(@Unitsid, 0) <> 0
                            AND ISNULL(@OverwriteUnits, 'Y') = 'Y' )
                          OR IMWE.UploadVal IS NULL )
        END;
	
/************************
-- UnitPrice Default
**************************/

    BEGIN
        UPDATE  [dbo].[IMWE]
        SET     IMWE.UploadVal = bHQMT.Cost  -- default value
        FROM    [dbo].[IMWE]
        JOIN    [dbo].[IMWE] MG
                ON MG.ImportTemplate = @ImportTemplate
                   AND MG.ImportId = @ImportId
                   AND MG.Identifier = @MatlGroupid
                   AND MG.RecordType = @rectype
                   AND MG.RecordSeq = IMWE.RecordSeq
        JOIN    [dbo].[IMWE] FM
                ON FM.ImportTemplate = @ImportTemplate
                   AND FM.ImportId = @ImportId
                   AND FM.Identifier = @CompMatlid
                   AND FM.RecordType = @rectype
                   AND FM.RecordSeq = IMWE.RecordSeq
        JOIN    [dbo].[bHQMT]
                ON bHQMT.MatlGroup = MG.UploadVal
                   AND bHQMT.Material = FM.UploadVal
        WHERE   IMWE.ImportTemplate = @ImportTemplate
                AND IMWE.ImportId = @ImportId
                AND IMWE.Identifier = @UnitPriceid
                AND IMWE.RecordType = @rectype
                AND ( ( ISNULL(@UnitPriceid, 0) <> 0
                        AND ISNULL(@OverwriteUnitPrice, 'Y') = 'Y' )
                      OR IMWE.UploadVal IS NULL )
    END;

/************************
-- PECM Default
**************************/
     select  IMWE.UploadVal , bHQMT.CostECM   
        FROM    [dbo].[IMWE]
        JOIN    [dbo].[IMWE] MG
                ON MG.ImportTemplate = @ImportTemplate
                   AND MG.ImportId = @ImportId
                   AND MG.Identifier = @MatlGroupid
                   AND MG.RecordType = @rectype
                   AND MG.RecordSeq = IMWE.RecordSeq
        JOIN    [dbo].[IMWE] FM
                ON FM.ImportTemplate = @ImportTemplate
                   AND FM.ImportId = @ImportId
                   AND FM.Identifier = @CompMatlid
                   AND FM.RecordType = @rectype
                   AND FM.RecordSeq = IMWE.RecordSeq
        JOIN    [dbo].[bHQMT]
                ON bHQMT.MatlGroup = MG.UploadVal
                   AND bHQMT.Material = FM.UploadVal
        WHERE   IMWE.ImportTemplate = @ImportTemplate
                AND IMWE.ImportId = @ImportId
                AND IMWE.Identifier = @PECMid
                AND IMWE.RecordType = @rectype  
                AND ( ( ISNULL(@PECMid, 0) <> 0
                        AND ISNULL(@OverwritePECM, 'Y') = 'Y' )
                      OR IMWE.UploadVal IS NULL );
                      
    BEGIN;
        UPDATE  [dbo].[IMWE]
        SET     IMWE.UploadVal = bHQMT.CostECM  -- default value  
        FROM    [dbo].[IMWE]
        JOIN    [dbo].[IMWE] MG
                ON MG.ImportTemplate = @ImportTemplate
                   AND MG.ImportId = @ImportId
                   AND MG.Identifier = @MatlGroupid
                   AND MG.RecordType = @rectype
                   AND MG.RecordSeq = IMWE.RecordSeq
        JOIN    [dbo].[IMWE] FM
                ON FM.ImportTemplate = @ImportTemplate
                   AND FM.ImportId = @ImportId
                   AND FM.Identifier = @CompMatlid
                   AND FM.RecordType = @rectype
                   AND FM.RecordSeq = IMWE.RecordSeq
        JOIN    [dbo].[bHQMT]
                ON bHQMT.MatlGroup = MG.UploadVal
                   AND bHQMT.Material = FM.UploadVal
        WHERE   IMWE.ImportTemplate = @ImportTemplate
                AND IMWE.ImportId = @ImportId
                AND IMWE.Identifier = @PECMid
                AND IMWE.RecordType = @rectype  
                AND ( ( ISNULL(@PECMid, 0) <> 0
                        AND ISNULL(@OverwritePECM, 'Y') = 'Y' )
                      OR IMWE.UploadVal IS NULL );
    END;
	

    bspexit:
    SELECT  @msg = ISNULL(@desc, 'Line') + CHAR(13) + CHAR(13)
            + '[bspIMViewpointDefaultsINPD]'

    RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsINPD] TO [public]
GO
