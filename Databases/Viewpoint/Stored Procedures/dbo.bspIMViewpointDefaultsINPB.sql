SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsINPB]
/***********************************************************
* CREATED BY: JRE  3/28/2012

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

    DECLARE @rcode INT
       ,@recode INT
       ,@desc VARCHAR(120)
       ,@defaultvalue VARCHAR(30)

    DECLARE @ynActDate bYN
       ,@ynBatchId bYN
       ,@ynBatchSeq bYN
       ,@ynCo bYN
       ,@ynDescription bYN
       ,@ynECM bYN
       ,@ynFinMatl bYN
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
       ,@FinMatlid INT
       ,@KeyIDid INT
       ,@MatlGroupid INT
       ,@Mthid INT
       ,@ProdLocid INT
       ,@UMid INT
       ,@UniqueAttchIDid INT
       ,@UnitCostid INT
       ,@Unitsid INT

	
    SELECT  @ynActDate = 'N'
           ,@ynBatchId = 'N'
           ,@ynBatchSeq = 'N'
           ,@ynCo = 'N'
           ,@ynDescription = 'N'
           ,@ynECM = 'N'
           ,@ynFinMatl = 'N'
           ,@ynKeyID = 'N'
           ,@ynMatlGroup = 'N'
           ,@ynMth = 'N'
           ,@ynProdLoc = 'N'
           ,@ynUM = 'N'
           ,@ynUniqueAttchID = 'N'
           ,@ynUnitCost = 'N'
           ,@ynUnits = 'N'
 
    DECLARE @OverwriteActDate bYN
       ,@OverwriteCo bYN
       ,@OverwriteDescription bYN
       ,@OverwriteECM bYN
       ,@OverwriteCompMatl bYN
       ,@OverwriteMatlGroup bYN
       ,@OverwriteMth bYN
       ,@OverwriteProdLoc bYN
       ,@OverwriteUM bYN
       ,@OverwriteUnitCost bYN
       ,@OverwriteUnits bYN
       
    SELECT @rcode=0

/* Set Overwrite flags */ 
    SELECT  @OverwriteActDate = dbo.vfIMTemplateOverwrite(@ImportTemplate,
                                                          @Form, 'ActDate',
                                                          @rectype);
    SELECT  @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form,
                                                     'Co', @rectype);
    SELECT  @OverwriteDescription = dbo.vfIMTemplateOverwrite(@ImportTemplate,
                                                              @Form,
                                                              'Description',
                                                              @rectype);
    SELECT  @OverwriteECM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form,
                                                      'ECM', @rectype);
    SELECT  @OverwriteCompMatl = dbo.vfIMTemplateOverwrite(@ImportTemplate,
                                                           @Form, 'CompMatl',
                                                           @rectype);
    SELECT  @OverwriteMatlGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate,
                                                            @Form, 'MatlGroup',
                                                            @rectype);
    SELECT  @OverwriteMth = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form,
                                                      'Mth', @rectype);
    SELECT  @OverwriteProdLoc = dbo.vfIMTemplateOverwrite(@ImportTemplate,
                                                          @Form, 'ProdLoc',
                                                          @rectype);
    SELECT  @OverwriteUM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form,
                                                     'UM', @rectype);
    SELECT  @OverwriteUnitCost = dbo.vfIMTemplateOverwrite(@ImportTemplate,
                                                           @Form, 'UnitCost',
                                                           @rectype);
    SELECT  @OverwriteUnits = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form,
                                                        'Units', @rectype);
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

/****************************************************************************************
*																						*
*			RECORDS ALREADY EXIST IN THE IMWE TABLE FROM THE IMPORTED TEXTFILE			*
*																						*
*			All records with the same RecordSeq represent a single import record		*
*																						*
****************************************************************************************/

-- Check ImportTemplate detail for existence of columns to be defaulted Defaults
    SELECT  IMTD.DefaultValue
    FROM    IMTD
    WHERE   IMTD.ImportTemplate = @ImportTemplate
            AND IMTD.DefaultValue = '[Bidtek]'
            AND IMTD.RecordType = @rectype
    IF @@rowcount = 0 
        BEGIN
            SELECT  @desc = 'No Bidtek Defaults set up for ImportTemplate '
                    + @ImportTemplate + '.'
            GOTO bspexit
        END

/********* GET COLUMN IDENTIFIERS AND SET IMPORT DEFAULTS THAT APPLY TO ALL IMPORTED RECORDS EQUALLY **********/

	SELECT  @Coid = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Co',@rectype, 'N');
	SELECT  @UnitCostid = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UnitCost', @rectype, 'N');
	SELECT  @FinMatlid = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'FinMatl', @rectype, 'N');
	SELECT  @ProdLocid = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ProdLoc', @rectype, 'N');
	SELECT  @ActDateid = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form,'ActDate', @rectype, 'Y');
	SELECT  @MatlGroupid = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form,'MatlGroup', @rectype, 'N');
	SELECT  @UMid = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UM',@rectype, 'N');
	SELECT  @ECMid = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ECM',@rectype, 'N');
	SELECT  @Unitsid = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Units', @rectype, 'Y');
--SELECT @Mthid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Mth' , @rectype, 'Y')
		
    IF @Coid IS NOT NULL
        AND ( ISNULL(@OverwriteCo, 'Y') = 'Y' ) 
        BEGIN
            UPDATE  IMWE
            SET     IMWE.UploadVal = @Company
            WHERE   IMWE.ImportTemplate = @ImportTemplate
                    AND IMWE.ImportId = @ImportId
                    AND IMWE.Identifier = @Coid
                    AND IMWE.RecordType = @rectype
        END

    IF @Coid IS NOT NULL
        AND ( ISNULL(@OverwriteCo, 'Y') = 'N' ) 
        BEGIN
            UPDATE  IMWE
            SET     IMWE.UploadVal = @Company
            WHERE   IMWE.ImportTemplate = @ImportTemplate
                    AND IMWE.ImportId = @ImportId
                    AND IMWE.Identifier = @Coid
                    AND IMWE.RecordType = @rectype
                    AND IMWE.UploadVal IS NULL
        END
/************************
-- ActDate Default
**************************/

    IF ISNULL(@ActDateid, 0) <> 0
        AND ( ISNULL(@OverwriteActDate, 'Y') = 'Y' ) 
        BEGIN;
            UPDATE  [dbo].[IMWE]
            SET     IMWE.UploadVal = CONVERT(VARCHAR(8), GETDATE(), 1)  -- default value
            WHERE   IMWE.ImportTemplate = @ImportTemplate
                    AND IMWE.ImportId = @ImportId
                    AND IMWE.Identifier = @ActDateid
                    AND IMWE.RecordType = @rectype;
        END;
	
-- null value	
    IF ISNULL(@ActDateid, 0) <> 0
        AND ( ISNULL(@OverwriteActDate, 'Y') = 'N' ) 
        BEGIN;
            UPDATE  [dbo].[IMWE]
            SET     IMWE.UploadVal = CONVERT(VARCHAR(8), GETDATE(), 1)  -- default value
            WHERE   IMWE.ImportTemplate = @ImportTemplate
                    AND IMWE.ImportId = @ImportId
                    AND IMWE.Identifier = @ActDateid
                    AND IMWE.RecordType = @rectype
                    AND IMWE.UploadVal IS NULL;
        END;


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
                   AND FM.Identifier = @FinMatlid
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
                ON FM.ImportTemplate = @ImportTemplate -- finished mat
                   AND FM.ImportId = @ImportId
                   AND FM.Identifier = @FinMatlid
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
                   AND LM.Identifier = @ProdLocid
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
                AND ( ( ISNULL(@UnitCostid, 0) <> 0 AND ISNULL(@OverwriteUnitCost, 'Y') = 'Y' )
                      OR ISNULL(IMWE.UploadVal,'')=''
                    )
  
  

/************************
-- ECM Default
**************************/
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
                ON FM.ImportTemplate = @ImportTemplate -- finished mat
                   AND FM.ImportId = @ImportId
                   AND FM.Identifier = @FinMatlid
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
                   AND LM.Identifier = @ProdLocid
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
                AND ( ( ISNULL(@ECMid, 0) <> 0 AND ISNULL(@OverwriteECM, 'Y') = 'Y' )
                      OR ISNULL(IMWE.UploadVal,'')=''
                    )


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
-- Mth Default
**************************/

--if isnull(@Mthid,0) <> 0 AND (ISNULL(@OverwriteMth , 'Y') = 'Y')
--	BEGIN;
--	UPDATE [dbo].[IMWE]
--	SET IMWE.UploadVal = 'N'  -- default value
--	WHERE IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @Mthid
--		and IMWE.RecordType = @rectype;
--	END;
	
---- null value	
--if isnull(@Mthid,0) <> 0 AND (ISNULL(@OverwriteMth , 'Y') = 'N')
--	BEGIN;
--	UPDATE [dbo].[IMWE]
--	SET IMWE.UploadVal = 'N'   -- default value
--	WHERE IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId 
--		and IMWE.Identifier = @Mthid
--		and IMWE.RecordType = @rectype
--		AND IMWE.UploadVal IS NULL;
--	END;


   
    bspexit:
    SELECT  @msg = ISNULL(@desc, 'Header ') + CHAR(13) + CHAR(13)
            + '[bspIMViewpointDefaultsINPB]'

    RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsINPB] TO [public]
GO
