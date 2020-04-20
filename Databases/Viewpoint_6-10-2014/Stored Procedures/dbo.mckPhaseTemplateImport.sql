SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 2/7/2014
-- Description:	Used to import Phase Templates
/* @FileName parameter used to pass full path and file name to the BULK INSERT statement.
@Type = 1 for Phase Master/Template source load @Type = 2 for Phase Template Contents load. @Type = 3 for Column Headers
*/
-- =============================================
CREATE PROCEDURE [dbo].[mckPhaseTemplateImport] 
	-- Add the parameters for the stored procedure here
	@FileName nvarchar(MAX) = ''
	,@Type int = 0
	,@Company bCompany
	,@ReturnMessage VARCHAR(MAX) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @sql VARCHAR(MAX)=NULL
	, @PhaseGroup bGroup
	--, @Table VARCHAR(MAX) =  'Viewpoint.dbo.mckTEMPPhaseTemplateLoad'

	SELECT @PhaseGroup = PhaseGroup FROM HQCO WHERE HQCo = @Company
	IF @Type = 3
	GOTO tempfileDelete

	IF @Type = 1
	BEGIN
		SET @sql = ' BULK INSERT Viewpoint.dbo.mckTEMPPhaseLoad FROM ''' + @FileName + ''' WITH ( FIELDTERMINATOR =''\t'', ROWTERMINATOR =''\n'' )';
		EXEC(@sql);
		/**/
		-- Load phases and Descriptions to Variable Table and make format adjustments

		DECLARE @TEMPDescription TABLE (Phase VARCHAR(30), Description VARCHAR(70), RollupPhase VARCHAR(30))

		/*LOAD THE TEMP TABLE*/
		INSERT INTO @TEMPDescription
		SELECT Phase+'-      -   ', Description, RollupPhase+'-      -   '
		FROM dbo.mckTEMPPhaseLoad
		WHERE Phase NOT LIKE '%Phase Code%'
		--WHERE LEFT(Description,1)='"'-- AND RIGHT(Description,1)='"'

		/*DROP THE LEFT QUOTE*/
		UPDATE @TEMPDescription
		SET Description = RIGHT(Description, LEN(Description)-1)
		FROM @TEMPDescription
		WHERE LEFT(Description,1)='"'

		/*DROP THE RIGHT QUOTE*/
		UPDATE @TEMPDescription
		SET Description = LEFT(Description, LEN(Description)-1)
		FROM @TEMPDescription
		WHERE  RIGHT(Description,1)='"' --AND LEFT(Description,1)='"'

		/*REPLACE THE DOUBLE QUOTES IN THE MIDDLE WITH SINGLE QUOTE*/
		UPDATE @TEMPDescription
		SET Description = REPLACE(Description, '""', '"')

		UPDATE dbo.mckTEMPPhaseLoad
		SET Description = t.Description 
		, Phase = t.Phase,RollupPhase = t.RollupPhase
			FROM @TEMPDescription t WHERE LEFT(dbo.mckTEMPPhaseLoad.Phase,9) = LEFT(t.Phase,9)
		
		/*NULL OUT SPACE ONLY VALUES*/
		UPDATE dbo.mckTEMPPhaseLoad
		SET CT1 = NULL
		WHERE LEN(CT1) = 0
		UPDATE dbo.mckTEMPPhaseLoad
		SET CT2 = NULL
		WHERE LEN(CT2) = 0
		UPDATE dbo.mckTEMPPhaseLoad
		SET CT3 = NULL
		WHERE LEN(CT3) = 0
		UPDATE dbo.mckTEMPPhaseLoad
		SET CT4 = NULL
		WHERE LEN(CT4) = 0
		UPDATE dbo.mckTEMPPhaseLoad
		SET CT5 = NULL
		WHERE LEN(CT5) = 0

		SET @ReturnMessage = ISNULL(@ReturnMessage,'')+'1. mckTEMPPhaseLoad uploaded.'


		/*--Load Phase Headers From T1 - T24*/
		/*Pivot the Column Headers and Copy into dbo.mckTEMPPhaseTemplateHeaders*/
		INSERT INTO dbo.mckTEMPPhaseTemplateHeaders
		        ( ImportColumn, PhaseTemplateName )
		SELECT  LTRIM(RTRIM(Value)), Name
		FROM 
		(
			SELECT [Phase], [T1], [T2], [T3], [T4], [T5], [T6],[T7],[T8],[T9],[T10],[T11],[T12],[T13],[T14],[T15],[T16],[T17],[T18],[T19],[T20],[T21],[T22],[T23],[T24],[T25] 
			FROM dbo.mckTEMPPhaseLoad
			WHERE Phase NOT LIKE '%[0-9]%'
		) SRC
		UNPIVOT
			(
				Name FOR Value IN ([T1], [T2], [T3], [T4], [T5], [T6],[T7],[T8],[T9],[T10],[T11],[T12],[T13],[T14],[T15],[T16],[T17],[T18],[T19],[T20],[T21],[T22],[T23],[T24], [T25] )
			) AS unpvt;
		
		UPDATE dbo.mckTEMPPhaseTemplateHeaders
		SET ImportColumn = LTRIM(RTRIM(ImportColumn))

		SET @ReturnMessage = ISNULL(@ReturnMessage,'')+'2. Phase Template Headers, mckTEMPPhaseTemplateHeaders loaded.'
		--DELETE  FROM dbo.mckTEMPPhaseTemplateHeaders
		--SELECT * FROM dbo.mckTEMPPhaseLoad
		/*load Phase Template Contents into      */
		
		DECLARE @THead INT
		DECLARE @SQL nVARCHAR(max)
		SELECT @THead = 1

		SELECT @SQL ='INSERT INTO [dbo].[mckTEMPPhaseTemplate] (Phase, Header) SELECT t1.Phase, LTRIM(RTRIM(t1.Header)) FROM ('

		WHILE @THead <= 25
		BEGIN
	
			IF @THead < 25
			SELECT @SQL=@SQL+'SELECT ''T' + CAST(@THead AS VARCHAR(5)) + ''' AS Header, Phase FROM mckTEMPPhaseLoad '
					+	'WHERE T' + CAST(@THead AS VARCHAR(5)) + ' IS NOT NULL AND Phase NOT LIKE ''%[A-Z]%'' UNION '	
			ELSE
			SELECT @SQL=@SQL+'SELECT ''T' + CAST(@THead AS VARCHAR(5)) + ''' AS Header, Phase FROM mckTEMPPhaseLoad '
					+	'WHERE T' + CAST(@THead AS VARCHAR(5)) + ' IS NOT NULL AND Phase NOT LIKE ''%[A-Z]%'') t1'	



		SELECT @THead=@THead + 1
		END
		--PRINT @SQL
		EXEC sp_executesql  @statement=@SQL

	


		SET @ReturnMessage = @ReturnMessage + '3. Template Contents, [mckTEMPPhaseTemplate] Loaded'
		
		
		SET @ReturnMessage = @ReturnMessage + '4. Part one complete.  Rerun procedure with @Type = 2 to complete upload.'
		
		GOTO spexit
	END

	IF @Type = 2
	BEGIN

	SET @ReturnMessage = ''
		/*--Load JCPM with Master Phase Headers*/
		UPDATE pm
		SET Description= src.Description, udParentPhase=src.RollupPhase 
		FROM JCPM pm
		JOIN dbo.mckTEMPPhaseLoad src ON pm.PhaseGroup=@PhaseGroup AND pm.Phase=src.Phase
		
		SET @ReturnMessage = @ReturnMessage+'JCPM - Phases Master headers updated.  '

		INSERT INTO JCPM(PhaseGroup, Phase, Description, ProjMinPct, Notes, udParentPhase)
		SELECT @PhaseGroup , -- PhaseGroup - tinyint
          t.Phase  , -- Phase - bPhase
          LEFT(t.Description,60) , -- Description - bItemDesc
          0 , -- ProjMinPct - bPct
          '' , -- Notes - varchar(max)
          --NULL , -- UniqueAttchID - uniqueidentifier
          --'' , -- udSource - varchar(30)
          --'' , -- udConv - varchar(1)
          --'' , -- udCGCTable - varchar(10)
          --NULL  -- udCGCTableID - decimal
		   RollupPhase
        FROM dbo.mckTEMPPhaseLoad t
		WHERE NOT EXISTS (SELECT * FROM JCPM WHERE JCPM.PhaseGroup = @PhaseGroup AND JCPM.Phase = t.Phase)
			AND Phase NOT LIKE '%[A-Z]%'
		
		SET @ReturnMessage = @ReturnMessage + 'JCPM - New Phase Master headers inserted.  '

		/* --Load JCPC Phase Master Cost Types*/
				
		--DECLARE @PhaseGroup bGroup = 1
		DECLARE @CostTypes TABLE(PhaseGroup bGroup, Phase bPhase, CostType TINYINT)

		INSERT INTO @CostTypes
		SELECT @PhaseGroup, Phase, 1 FROM [dbo].[mckTEMPPhaseLoad]
		WHERE LTRIM(RTRIM(CT1)) IS NOT NULL AND Phase NOT LIKE '%[A-Z]%'
		UNION
		SELECT @PhaseGroup, Phase, 2  FROM [dbo].[mckTEMPPhaseLoad]
		WHERE LTRIM(RTRIM(CT2)) IS NOT NULL AND Phase NOT LIKE '%[A-Z]%'
		UNION
		SELECT @PhaseGroup, Phase, 3 FROM [dbo].[mckTEMPPhaseLoad]
		WHERE LTRIM(RTRIM(CT3)) IS NOT NULL AND Phase NOT LIKE '%[A-Z]%'
		UNION
		SELECT @PhaseGroup, Phase, 4 FROM [dbo].[mckTEMPPhaseLoad]
		WHERE LTRIM(RTRIM(CT4)) IS NOT NULL AND Phase NOT LIKE '%[A-Z]%'
		UNION
		SELECT @PhaseGroup, Phase, 5 FROM [dbo].[mckTEMPPhaseLoad]
		WHERE LTRIM(RTRIM(CT5)) IS NOT NULL AND Phase NOT LIKE '%[A-Z]%'

		INSERT INTO dbo.JCPC
        ( PhaseGroup ,
          Phase ,
          CostType ,
          BillFlag ,
          UM,
		  ItemUnitFlag
		  ,PhaseUnitFlag
        )
		SELECT PhaseGroup, Phase, CostType,'Y','LS','N' ,'N' 
		FROM @CostTypes tc
		WHERE NOT EXISTS(SELECT TOP 1 1 FROM JCPC cc WHERE cc.PhaseGroup = tc.PhaseGroup AND cc.Phase = tc.Phase AND cc.CostType = tc.CostType)
		
		SET @ReturnMessage = @ReturnMessage + 'JCPC - Phase Master Cost Types Inserted/Updated.  '

		/*Load Phase Template from TEMP tables*/
		
		UPDATE dbo.PMTH
		SET Description = LEFT(PhaseTemplateName,30)
		FROM dbo.mckTEMPPhaseTemplateHeaders
		WHERE Template = ImportColumn AND PMCo = @Company

		SET @ReturnMessage = @ReturnMessage + 'PMTH - Phase Master headers updated.  '
--DECLARE @Company TINYINT = 101
		INSERT INTO dbo.PMTH
		        ( PMCo ,
		          Template ,
		          Description ,
		          Notes ,
		          UniqueAttchID
		        )		
		SELECT @Company , -- PMCo - bCompany
		          LTRIM(RTRIM(h.ImportColumn)) , -- Template - varchar(10)
		          LEFT(h.PhaseTemplateName,30) , -- Description - bDesc
		          '' , -- Notes - varchar(max)
		          NULL  -- UniqueAttchID - uniqueidentifier
		    FROM dbo.mckTEMPPhaseTemplateHeaders h
			WHERE CONVERT(VARCHAR(3),@Company) + h.ImportColumn NOT IN(SELECT CONVERT(VARCHAR(3),PMCo)+Template FROM dbo.PMTH)

		SET @ReturnMessage = @ReturnMessage + 'PMTH - Phase Master headers inserted.  '


		DELETE FROM dbo.PMTP
		WHERE CONVERT(VARCHAR(30),PMCo)+Template IN (SELECT CONVERT(VARCHAR(30),@Company)+Header FROM dbo.mckTEMPPhaseTemplate)

		INSERT INTO dbo.PMTP
		        ( PMCo ,
		          Template ,
		          PhaseGroup ,
		          Phase ,
		          Description ,
		          Item ,
		          UniqueAttchID ,
		          SICode
		        )
		SELECT  @Company , -- PMCo - bCompany
		           LTRIM(RTRIM(cc.Header)), -- Template - varchar(10)
		          @PhaseGroup , -- PhaseGroup - tinyint
		          cc.Phase , -- Phase - bPhase
		          pp.Description , -- Description - bItemDesc
		          NULL , -- Item - bContractItem
		          NULL , -- UniqueAttchID - uniqueidentifier
		          ''  -- SICode - varchar(16)
				  --SELECT *
		    FROM dbo.mckTEMPPhaseTemplate cc
			JOIN dbo.mckTEMPPhaseLoad pp ON pp.Phase = cc.Phase
		
		SET @ReturnMessage = @ReturnMessage + 'PMTP - Phase Template contents updated.'
		
		
		/*CLEAR OUT ALL IMPORTED RECORDS*/
		tempfileDelete:
			DELETE 
			FROM dbo.mckTEMPPhaseLoad
			DELETE
			FROM dbo.mckTEMPPhaseTemplate
			DELETE 
			FROM dbo.mckTEMPPhaseTemplateHeaders

		IF @Type = 3
		SET @ReturnMessage = @ReturnMessage + 'Temp Tables cleared'

		PRINT @ReturnMessage
		GOTO spexit
	END
	--ELSE 
	
	

	
	--BULK INSERT Viewpoint.dbo.mckTEMPPhaseTemplateLoad
	--FROM @FileName
	--WITH (FIELDTERMINATOR = '\t',
	--	ROWTERMINATOR = '\n')

	--SELECT @FileName
	spexit:
	BEGIN
		SELECT @ReturnMessage
	END
END
GO
