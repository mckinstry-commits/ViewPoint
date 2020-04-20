SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[mspUpdateHQTaxCodes]
(
	@TaxGroup tinyint = 1
,	@DateToProcess DATETIME = NULL
,	@StateToProcess VARCHAR(10) = null
)
AS

SET NOCOUNT ON 

-- Deactivate Tax Codes no longer in the source list.


/*

TODO: Error - Need to REWORK

UPDATE bHQTX SET udIsActive='N' 
WHERE 
	TaxGroup=@TaxGroup 
AND TaxCode IN ( SELECT DISTINCT TaxCode FROM [mvwTaxCodeImportSource] WHERE IsActive='N')

UPDATE bHQTX SET udIsActive='N' 
WHERE 
	TaxGroup=@TaxGroup 
AND TaxCode NOT IN (SELECT DISTINCT TaxCode FROM [mvwTaxCodeImportSource])
*/


DECLARE ttCur CURSOR FOR
SELECT [TaxCode]
      ,[ParentTaxCode]
      ,[McKCityId]
      ,[TaxCodeType]
      ,[z2t_ID]
      ,[ZipCode]
      ,[State]
      ,[County]
      ,[City]
      ,[Description]
      ,COALESCE([Rate],0.00) AS Rate
      ,[ReportingCode]
      ,[IsActive]
      ,[ManualEntry]
      ,[EffectiveDate]
 FROM [dbo].[mvwTaxCodeImportSource]
WHERE
	 [ManualEntry]='N'
AND	(@StateToProcess IS NULL OR [State]=@StateToProcess) AND (@DateToProcess IS NULL OR @DateToProcess=EffectiveDate)
ORDER BY 
	ParentTaxCode,[TaxCode]
FOR READ ONLY

DECLARE @rowcount		INT

DECLARE @TaxCode		VARCHAR(10)
DECLARE @ParentTaxCode	VARCHAR(10)
DECLARE @McKCityId		VARCHAR(6)
DECLARE @TaxCodeType	VARCHAR(20)
DECLARE @z2t_ID			int
DECLARE @ZipCode		VARCHAR(10)
DECLARE @State			VARCHAR(2)
DECLARE @County			VARCHAR(50)
DECLARE @City			VARCHAR(50)
DECLARE @Description	VARCHAR(255)
DECLARE @Rate			NUMERIC(18,3)
DECLARE @ReportingCode	VARCHAR(20)
DECLARE @IsActive		CHAR(1)
DECLARE @ManualEntry	CHAR(1)
DECLARE @EffectiveDate	datetime

SELECT @rowcount=0

OPEN ttCur
FETCH ttCur INTO
	@TaxCode	
,	@ParentTaxCode	
,	@McKCityId		
,	@TaxCodeType	
,	@z2t_ID			
,	@ZipCode	
,	@State			
,	@County			
,	@City			
,	@Description	
,	@Rate			
,	@ReportingCode	
,	@IsActive		
,	@ManualEntry	
,	@EffectiveDate	

WHILE @@fetch_status=0
BEGIN
	
	SELECT @rowcount=@rowcount+1
	PRINT
		CAST(@rowcount AS CHAR(10)) 
	+	CAST(COALESCE(@TaxCode,'<null>') + '/' + COALESCE(@ParentTaxCode,'<null>') + '/' + COALESCE(@McKCityId,'<null>') AS CHAR(30)) 
	+	convert(CHAR(20),@EffectiveDate,101)
	+	@Description

	IF ( @TaxCodeType='COMBINED' )
	BEGIN
		-- Do Header Records
		IF NOT EXISTS ( SELECT 1 FROM bHQTX WHERE TaxCode=@TaxCode AND TaxGroup=@TaxGroup )
		BEGIN
			PRINT '       ** Add Parent Tax Code Record  : ' + @TaxCode
			
			INSERT INTO bHQTX
			   (
				[TaxGroup]
			   ,[TaxCode]
			   ,[Description]
			   ,[MultiLevel]
			   ,[OldRate]
			   ,[NewRate]
			   ,[EffectiveDate]
			   ,[GLAcct]
			   ,[Phase]
			   ,[JCCostType]
			   ,[Notes]
			   ,[UniqueAttchID]
			   ,[ValueAdd]
			   ,[GST]
			   ,[ExpenseTax]
			   ,[InclGSTinPST]
			   ,[RetgGLAcct]
			   ,[DbtGLAcct]
			   ,[DbtRetgGLAcct]
			   ,[CrdRetgGSTGLAcct]
			   ,[udIsActive]
			   ,[udReportingCode]
			   ,[udCityId])
		 VALUES
			   (@TaxGroup
			   ,@TaxCode
			   ,left(@Description,30)
			   ,'Y'
			   ,null
			   ,null
			   ,null
			   ,'2540-   -    -      '
			   ,null
			   ,null
			   ,@Description 
			   ,null
			   ,'N'
			   ,'N'
			   ,'N'
			   ,'N'
			   ,null
			   ,null
			   ,null
			   ,NULL
			   ,'Y'
			   ,@ReportingCode
			   ,@McKCityId)
			
		END
		ELSE
		BEGIN
			PRINT '       ** Update Parent Tax Code Record : ' + @TaxCode
			UPDATE bHQTX  SET
				[Description]=left(@Description,30)
			,	[Notes]=@Description 
			,	[udIsActive]='Y'
			,	[udReportingCode]=@ReportingCode
			,	[udCityId]=@McKCityId			
			WHERE
				[TaxGroup]=@TaxGroup
			AND [TaxCode]=@TaxCode
		END
	END
	ELSE
	BEGIN
	
		IF NOT EXISTS ( SELECT 1 FROM bHQTX WHERE TaxCode=@TaxCode AND TaxGroup=@TaxGroup )
		BEGIN
			PRINT '       ** Add Child Tax Code Record  : ' + @TaxCode
			
			INSERT INTO dbo.HQTX
			   (
				[TaxGroup]
			   ,[TaxCode]
			   ,[Description]
			   ,[MultiLevel]
			   ,[OldRate]
			   ,[NewRate]
			   ,[EffectiveDate]
			   ,[GLAcct]
			   ,[Phase]
			   ,[JCCostType]
			   ,[Notes]
			   ,[UniqueAttchID]
			   ,[ValueAdd]
			   ,[GST]
			   ,[ExpenseTax]
			   ,[InclGSTinPST]
			   ,[RetgGLAcct]
			   ,[DbtGLAcct]
			   ,[DbtRetgGLAcct]
			   ,[CrdRetgGSTGLAcct]
			   ,[udIsActive]
			   ,[udReportingCode]
			   ,[udCityId])
		 VALUES
			   (@TaxGroup
			   ,@TaxCode
			   ,left(@Description,30)
			   ,'N'
			   ,null
			   ,@Rate/100
			   ,@EffectiveDate
			   ,'2540-   -    -      '
			   ,null
			   ,null
			   ,@Description 
			   ,null
			   ,'N'
			   ,'N'
			   ,'N'
			   ,'N'
			   ,null
			   ,null
			   ,null
			   ,NULL
			   ,'Y'
			   ,@ReportingCode
			   ,@McKCityId)
			   
			IF NOT EXISTS ( SELECT 1 FROM bHQTL WHERE [TaxLink]=@TaxCode AND [TaxCode]=@ParentTaxCode AND TaxGroup=@TaxGroup )   
			begin
			INSERT INTO bHQTL
			   ([TaxGroup]
			   ,[TaxCode]
			   ,[TaxLink]
			   ,[UniqueAttchID])
			VALUES
			   (@TaxGroup
			   ,@ParentTaxCode
			   ,@TaxCode 
			   ,null )  
			END    		
			
		END
		ELSE
		BEGIN
			PRINT '       ** Update Child Tax Code Record : ' + @TaxCode
			UPDATE bHQTX  SET
				[Description]=left(@Description,30)
			,	[OldRate]=[NewRate]
			,	[NewRate]=@Rate/100
			,	[EffectiveDate]=@EffectiveDate
			,	[Notes]=@Description 
			,	[udIsActive]='Y'
			,	[udReportingCode]=@ReportingCode
			,	[udCityId]=@McKCityId
			WHERE
				[TaxGroup]=@TaxGroup
			AND [TaxCode]=@TaxCode
			
			IF NOT EXISTS ( SELECT 1 FROM bHQTL WHERE [TaxLink]=@TaxCode AND [TaxCode]=@ParentTaxCode AND TaxGroup=@TaxGroup )   
			begin
			INSERT INTO bHQTL
			   ([TaxGroup]
			   ,[TaxCode]
			   ,[TaxLink]
			   ,[UniqueAttchID])
			VALUES
			   (@TaxGroup
			   ,@ParentTaxCode
			   ,@TaxCode 
			   ,null )  
			END    		
			--ELSE
			--BEGIN
			--UPDATE bHQTL SET
			--	[TaxCode]=@ParentTaxCode
			--WHERE
			--	[TaxGroup]=@TaxGroup
			--AND [TaxLink]=@TaxCode
			--AND [TaxCode] <> @ParentTaxCode
			--END
		END
			
	END	
	

	FETCH ttCur INTO
		@TaxCode	
	,	@ParentTaxCode	
	,	@McKCityId		
	,	@TaxCodeType	
	,	@z2t_ID			
	,	@ZipCode	
	,	@State			
	,	@County			
	,	@City			
	,	@Description	
	,	@Rate			
	,	@ReportingCode	
	,	@IsActive		
	,	@ManualEntry	
	,	@EffectiveDate	
END

CLOSE ttCur
DEALLOCATE ttCur




GO
