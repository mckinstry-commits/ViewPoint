USE [Viewpoint]
GO

DROP FUNCTION [dbo].[mfnStripNonAlphaNumeric]
go

create FUNCTION [dbo].[mfnStripNonAlphaNumeric] ( @stringValue VARCHAR(256) )
RETURNS VARCHAR(256)
	WITH SCHEMABINDING
BEGIN
	IF @stringValue IS NULL
	BEGIN
		RETURN NULL
	END
	
	DECLARE @newStringValue VARCHAR(256)
	DECLARE @place INT
	DECLARE @stringLength INT
	DECLARE @charValue INT
	
	SET @newStringValue = ''
	SET @stringLength = LEN(@stringValue)
	SET @place = 1
	
	WHILE @place <= @stringLength 
		BEGIN
			SET @charValue = ASCII(SUBSTRING(@stringValue, @place, 1))
			
			--Lower case letters range from 97-122 (decimal). 
			--Upper case letters range from 65-90 (decimal)
			--The numbers 0-9 range from 48-57 (decimal). 
			
			IF (@charValue BETWEEN 48 AND 57) OR (@charValue BETWEEN 64 AND 90) OR (@charValue BETWEEN 97 AND 122)
			BEGIN	
				SET @newStringValue = @newStringValue + CHAR(@charValue)
			END
			
			SET @place = @place + 1
		END
	IF LEN(@newStringValue) = 0 
	BEGIN
		RETURN NULL
	END
	
	RETURN @newStringValue
END

GO


--DROP TABLE mckGeographicLookup
--go

--CREATE TABLE mckGeographicLookup
--(
--	McKCityId		VARCHAR(6) NOT NULL
--,	ZipCode			VARCHAR(10) NOT NULL
--,	City			VARCHAR(50) NOT NULL
--,	PostOffice	    VARCHAR(50) NOT NULL
--,	County			VARCHAR(50) NOT NULL
--,	State			VARCHAR(2) NOT NULL
--,	IsActive		CHAR(1) NOT NULL DEFAULT('N')
--,	ManualEntry		CHAR(1) NOT NULL DEFAULT('Y')
--,	TaxRateEffectiveDate	DATETIME	NOT NULL DEFAULT(GETDATE())
--,	DateCreated		DATETIME NOT NULL DEFAULT(GETDATE())
--,	CreatedBy		VARCHAR(50) NOT NULL DEFAULT(SUSER_SNAME())
--,	DateModified	DATETIME NOT NULL DEFAULT(GETDATE())
--,	ModifiedBy		VARCHAR(50) NOT NULL DEFAULT(SUSER_SNAME())
--)

--go

--DROP INDEX budGeographicLookup.idxbudGeographicLookup_State
--DROP INDEX budGeographicLookup.idxbudGeographicLookup_City
--DROP INDEX budGeographicLookup.idxbudGeographicLookup_Match

--CREATE NONCLUSTERED INDEX idxbudGeographicLookup_State ON budGeographicLookup ([State],[ZipCode])
--CREATE NONCLUSTERED INDEX idxbudGeographicLookup_City ON budGeographicLookup ([City])
--CREATE NONCLUSTERED INDEX idxbudGeographicLookup_Match ON budGeographicLookup ([MatchString])
--CREATE NONCLUSTERED INDEX idxbHQTX_Match ON bHQTX ([MatchString])
--UPDATE budGeographicLookup SET MatchString=UPPER(dbo.mfnStripNonAlphaNumeric(State + ZipCode + City))

--DROP TRIGGER mtrIU_budGeographicLookup
--SELECT * FROM budGeographicLookup
--CREATE TRIGGER mtrIU_budGeographicLookup 
--   ON  dbo.budGeographicLookup
--   AFTER INSERT,UPDATE
--AS 
--BEGIN
--	-- SET NOCOUNT ON added to prevent extra result sets from
--	-- interfering with SELECT statements.
	
--	IF ( UPDATE([State]) OR UPDATE([City]) OR UPDATE([ZipCode]) )
--	BEGIN
--		update budGeographicLookup SET MatchString=UPPER(dbo.mfnStripNonAlphaNumeric(State + ZipCode + City)),DateModified=GETDATE(), ModifiedBy=SUSER_SNAME() 
--	END

--	IF ( UPDATE([County]) OR UPDATE([IsActive]) OR UPDATE([ManualEntry]) OR UPDATE([PostOffice]) )
--	BEGIN
--		update budGeographicLookup SET DateModified=GETDATE(), ModifiedBy=SUSER_SNAME() 
--	END
	

--END
--GO

--drop TABLE Zip2TaxSourceTaxTable
--go

--CREATE TABLE Zip2TaxSourceTaxTable
--(
--	z2t_ID							INT				NOT null
--,	ZipCode							VARCHAR(10)		NOT NULL
--,	SalesTaxRate					NUMERIC(18,3)	NOT NULL DEFAULT 0.00
--,	RateState						NUMERIC(18,3)	NOT NULL DEFAULT 0.00
--,	ReportingCodeState				VARCHAR(20)		null
--,	RateCounty						NUMERIC(18,3)	NOT NULL DEFAULT 0.00
--,	ReportingCodeCounty				VARCHAR(20)		null
--,	RateCity						NUMERIC(18,3)	NOT NULL DEFAULT 0.00
--,	ReportingCodeCity				VARCHAR(20)		null
--,	RateSpecialDistrict				NUMERIC(18,3)	NOT NULL DEFAULT 0.00
--,	ReportingCodeSpecialDistrict	VARCHAR(20)		null
--,	City							VARCHAR(50)		null
--,	PostOffice						VARCHAR(50)		null
--,	[State]							CHAR(5)			NOT NULL	
--,	County							VARCHAR(50)		null
--,	ShippingTaxable					int				NOT NULL DEFAULT 0
--,	PrimaryRecord					varchar(20)		NOT NULL DEFAULT 0
--, MatchString						varchar(75)     null
--)
--GO

--SELECT * FROM Zip2TaxSourceTaxTable

DROP PROCEDURE mspSyncGeoLookupFromTaxSource
go

CREATE PROCEDURE mspSyncGeoLookupFromTaxSource
(
	@EffectiveDate DATETIME = null
)

AS

SET NOCOUNT ON

IF @EffectiveDate IS NULL
	SELECT @EffectiveDate=GETDATE()
	
-- Check for existing TaxCodes that are no longer in the supplied source data.
UPDATE udGeographicLookup SET IsActive='N'/*, TaxRateEffectiveDate=@EffectiveDate*/, DateModified=GETDATE(), ModifiedBy=SUSER_SNAME(), DateCreated=COALESCE(DateCreated,GETDATE()), CreatedBy=coalesce(CreatedBy,SUSER_SNAME())
WHERE ManualEntry = 'N' AND MatchString NOT IN (SELECT distinct MatchString FROM Zip2TaxSourceTaxTable gl )

PRINT CAST(@@rowcount AS CHAR(10)) + ' records marked inactive.'	

DECLARE zcur CURSOR FOR
SELECT DISTINCT
	ZipCode
,	City
,	County
,	State
,	PostOffice
,	MatchString
FROM
	dbo.Zip2TaxSourceTaxTable
ORDER BY
	State, ZipCode, City
FOR READ ONLY

DECLARE @ZipCode VARCHAR(10)
DECLARE	@City VARCHAR(50)
DECLARE	@County VARCHAR(50)
DECLARE	@State VARCHAR(2)
DECLARE	@PostOffice VARCHAR(50)
DECLARE @MatchString VARCHAR(75)

DECLARE @tmpMcKCityId VARCHAR(6)
DECLARE @tmpNextIncrementalNumber VARCHAR(5)

OPEN zcur
FETCH zcur INTO
	@ZipCode
,	@City
,	@County
,	@State
,	@PostOffice
,	@MatchString

WHILE @@fetch_status=0
BEGIN	

	IF EXISTS ( SELECT 1 FROM udGeographicLookup WHERE MatchString=@MatchString)
	BEGIN
		PRINT
			CAST(@State + '/'
		+	@ZipCode + '/'
		+	@City AS CHAR(30))
		+	'City Exists - Update as appopriate'


		
		UPDATE udGeographicLookup
		SET
			PostOffice=@PostOffice, County=@County, IsActive='Y',TaxRateEffectiveDate=@EffectiveDate, DateModified=GETDATE(), ModifiedBy=SUSER_SNAME(), DateCreated=COALESCE(DateCreated,GETDATE()), CreatedBy=coalesce(CreatedBy,SUSER_SNAME())
		WHERE
			MatchString=@MatchString
		AND ManualEntry='N'
		AND ( PostOffice <> @PostOffice OR County <> @County OR IsActive <> 'Y')
		
	END
	ELSE
	BEGIN
		PRINT 'City Missing - Add new entry'
		-- Get next incremental number for  the state
		SELECT @tmpMcKCityId = MAX(McKCityId) FROM udGeographicLookup WHERE State=@State
		IF @tmpMcKCityId IS NULL
		BEGIN
			SELECT @tmpMcKCityId=@State+'0001'
		END
		ELSE
		begin
			SELECT @tmpNextIncrementalNumber=CAST(CAST(RIGHT(@tmpMcKCityId,4) AS INT)+1 AS VARCHAR(4))
			SELECT @tmpMcKCityId=@State+REPLICATE('0',4-LEN(@tmpNextIncrementalNumber)) + @tmpNextIncrementalNumber
		END
		
		PRINT
			CAST(@State + '/'
		+	@ZipCode + '/'
		+	@City AS CHAR(30))
		+	'City Missing - Add new entry : ' + @tmpMcKCityId

		INSERT udGeographicLookup (McKCityId,ZipCode,City,PostOffice,County,State, IsActive, ManualEntry, TaxRateEffectiveDate, DateModified, ModifiedBy, DateCreated, CreatedBy, MatchString)
		select @tmpMcKCityId,@ZipCode,@City,@PostOffice,@County,@State, 'Y','N',@EffectiveDate,GETDATE(),SUSER_SNAME(),GETDATE(),SUSER_SNAME(),@MatchString
		
	END
	
	SELECT 
		@tmpNextIncrementalNumber=NULL
	,	@tmpMcKCityId = NULL
	
	FETCH zcur INTO
		@ZipCode
	,	@City
	,	@County
	,	@State
	,	@PostOffice
	,   @MatchString

END

CLOSE zcur
DEALLOCATE zcur		

go


DROP VIEW mvwTaxCodeImportSource
go

CREATE VIEW mvwTaxCodeImportSource
AS
SELECT gl.McKCityId AS TaxCode, NULL AS ParentTaxCode, gl.McKCityId, 'COMBINED' AS TaxCodeType, ts.z2t_ID, gl.ZipCode, gl.State, gl.County, gl.City, COALESCE(gl.City,'') + ' (' + COALESCE(gl.County,'') + '), ' + COALESCE(gl.State,'') + ' ' + COALESCE(gl.ZipCode,'') AS Description, COALESCE(ts.SalesTaxRate,0.00) AS Rate, '' AS ReportingCode, (SELECT IsActive FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS IsActive, (SELECT ManualEntry FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS ManualEntry, TaxRateEffectiveDate AS EffectiveDate  
FROM 
	udGeographicLookup gl LEFT OUTER JOIN
	Zip2TaxSourceTaxTable ts ON
		ts.MatchString=gl.MatchString
UNION ALL
SELECT gl.McKCityId+'_S' AS TaxCode, gl.McKCityId AS ParentTaxCode, gl.McKCityId, 'STATE' AS TaxCodeType ,ts.z2t_ID, gl.ZipCode, gl.State, gl.County, gl.City, COALESCE(gl.City,'') + ' (' + COALESCE(gl.County,'') + '), ' + COALESCE(gl.State,'') + ' ' + COALESCE(gl.ZipCode,'') AS Description, COALESCE(ts.RateState,0.00) AS Rate, ts.ReportingCodeState AS ReportingCode, (SELECT IsActive FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS IsActive, (SELECT ManualEntry FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS ManualEntry, TaxRateEffectiveDate AS EffectiveDate    
FROM 
	udGeographicLookup gl LEFT OUTER JOIN
	Zip2TaxSourceTaxTable ts ON
		ts.MatchString=gl.MatchString
WHERE
	ts.RateState <> 0 --OR ts.RateState IS null
UNION ALL
SELECT gl.McKCityId+'_N' AS TaxCode, gl.McKCityId AS ParentTaxCode, gl.McKCityId, 'COUNTY' AS TaxCodeType, ts.z2t_ID, gl.ZipCode, gl.State, gl.County, gl.City, COALESCE(gl.City,'') + ' (' + COALESCE(gl.County,'') + '), ' + COALESCE(gl.State,'') + ' ' + COALESCE(gl.ZipCode,'') AS Description, COALESCE(ts.RateCounty,0.00) AS Rate, ts.ReportingCodeCounty AS ReportingCode,(SELECT IsActive FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS IsActive, (SELECT ManualEntry FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS ManualEntry, TaxRateEffectiveDate AS EffectiveDate   
FROM 
	udGeographicLookup gl LEFT OUTER JOIN
	Zip2TaxSourceTaxTable ts ON
		ts.MatchString=gl.MatchString
WHERE
	ts.RateCounty <> 0 --OR ts.RateCounty IS null
UNION ALL	
SELECT gl.McKCityId+'_C' AS TaxCode, gl.McKCityId AS ParentTaxCode, gl.McKCityId, 'CITY' AS TaxCodeType, ts.z2t_ID, gl.ZipCode, gl.State, gl.County, gl.City, COALESCE(gl.City,'') + ' (' + COALESCE(gl.County,'') + '), ' + COALESCE(gl.State,'') + ' ' + COALESCE(gl.ZipCode,'') AS Description, COALESCE(ts.RateCity,0.00) AS Rate, ts.ReportingCodeCity AS ReportingCode, (SELECT IsActive FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS IsActive, (SELECT ManualEntry FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS ManualEntry, TaxRateEffectiveDate AS EffectiveDate  
FROM 
	udGeographicLookup gl  LEFT OUTER JOIN
	Zip2TaxSourceTaxTable ts ON
		ts.MatchString=gl.MatchString
WHERE
	ts.RateCity <> 0 --OR ts.RateCity IS null
UNION ALL
SELECT gl.McKCityId+'_P' AS TaxCode, gl.McKCityId AS ParentTaxCode, gl.McKCityId, 'SPECIAL' AS TaxCodeType, ts.z2t_ID, gl.ZipCode, gl.State, gl.County, gl.City, COALESCE(gl.City,'') + ' (' + COALESCE(gl.County,'') + '), ' + COALESCE(gl.State,'') + ' ' + COALESCE(gl.ZipCode,'') AS Description, COALESCE(ts.RateSpecialDistrict,0.00) AS Rate, ts.ReportingCodeSpecialDistrict AS ReportingCode, (SELECT IsActive FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS IsActive, (SELECT ManualEntry FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS ManualEntry, TaxRateEffectiveDate AS EffectiveDate  
FROM 
	udGeographicLookup gl LEFT OUTER JOIN
	Zip2TaxSourceTaxTable ts ON
		ts.MatchString=gl.MatchString
WHERE
	ts.RateSpecialDistrict <> 0	--OR ts.RateSpecialDistrict IS null
GO



--INSERT dbo.Zip2TaxSourceTaxTable
--SELECT * FROM dbo.Zip2TaxSourceTaxTable WHERE McKCityId='WA1128'

--	DELETE Zip2TaxSourceTaxTable WHERE ZipCode  = '60002'

--UPDATE dbo.budGeographicLookup SET IsActive='Y' WHERE IsActive<>'Y'
--EXEC mspSyncGeoLookupFromTaxSource '2/1/2014'
--SELECT * FROM mvwTaxCodeImportSource WHERE McKCityId='WA1128' AND ManualEntry='N' ORDER BY TaxCode
--SELECT * FROM mvwTaxCodeImportSource WHERE McKCityId='WA1129' AND ManualEntry='N' ORDER BY TaxCode


--SELECT * FROM udGeographicLookup WHERE State='IL'
--SELECT * FROM Zip2TaxSourceTaxTable WHERE State='IL'
--SELECT * FROM mvwTaxCodeImportSource WHERE State='IL'

DROP PROCEDURE mspUpdateHQTaxCodes
go

CREATE PROCEDURE mspUpdateHQTaxCodes
(
	@TaxGroup tinyint = 1
,	@DateToProcess DATETIME = NULL
,	@StateToProcess VARCHAR(10) = null
)
AS

SET NOCOUNT ON 

-- Deactivate Tax Codes no longer in the source list.

UPDATE bHQTX SET udIsActive='N' 
WHERE 
	TaxGroup=@TaxGroup 
AND 
(
	(TaxCode IN ( SELECT DISTINCT TaxCode FROM [mvwTaxCodeImportSource] WHERE IsActive='N'))
OR  (TaxCode NOT IN (SELECT DISTINCT TaxCode FROM [mvwTaxCodeImportSource]))
)

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
      ,COALESCE([Rate],0.00)
      ,[ReportingCode]
      ,[IsActive]
      ,[ManualEntry]
      ,[EffectiveDate]
 FROM [dbo].[mvwTaxCodeImportSource]
WHERE
	 [ManualEntry]='N'
AND	(@StateToProcess IS NULL OR [State]=@StateToProcess) AND (@DateToProcess IS NULL OR @DateToProcess=EffectiveDate)
ORDER BY 
	[TaxCode]
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
			   ,@Description + ' ' + @TaxCode
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
			,	[Notes]=@Description + ' ' + @TaxCode
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
			   ,@Rate
			   ,@EffectiveDate
			   ,'2540-   -    -      '
			   ,null
			   ,null
			   ,@Description + ' ' + @ParentTaxCode
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
		ELSE
		BEGIN
			PRINT '       ** Update Child Tax Code Record : ' + @TaxCode
			UPDATE bHQTX  SET
				[Description]=left(@Description,30)
			,	[OldRate]=[NewRate]
			,	[NewRate]=@Rate
			,	[EffectiveDate]=@EffectiveDate
			,	[Notes]=@Description + ' ' + @ParentTaxCode
			,	[udIsActive]='Y'
			,	[udReportingCode]=@ReportingCode
			,	[udCityId]=@McKCityId
			WHERE
				[TaxGroup]=@TaxGroup
			AND [TaxCode]=@TaxCode
			
			UPDATE bHQTL SET
				[TaxCode]=@ParentTaxCode
			WHERE
				[TaxGroup]=@TaxGroup
			AND [TaxLink]=@TaxCode
			AND [TaxCode] <> @ParentTaxCode
			
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

--EXEC mspUpdateHQTaxCodes 101, NULL, 'WA'


--DECLARE tc CURSOR FOR
--SELECT TaxCode
--from dbo.bHQTX
--ORDER BY TaxCode
--FOR READ ONLY

--DECLARE @k bTaxCode
--DECLARE @cnt INT

--OPEN tc
--FETCH tc INTO @k

--WHILE @@fetch_status=0
--BEGIN
--	DELETE bHQTL WHERE TaxCode=@k OR TaxLink=@k
--	SELECT @cnt=@@rowcount
	
--	DELETE bHQTX WHERE TaxCode=@k
--	SELECT @cnt=@cnt+ @@ROWCOUNT
	
--	PRINT @k + ' ' + CAST(@cnt AS VARCHAR(10)) + ' records deleted.'

--	FETCH tc INTO @k
--END
--CLOSE tc
--DEALLOCATE tc
--GO

--TRUNCATE TABLE budGeographicLookup
--truncate TABLE bHQTL
--truncate TABLE bHQTX

--UPDATE Zip2TaxSourceTaxTable
--	SET City=CASE 
--		WHEN City LIKE '%' + PostOffice + '%' THEN REPLACE(REPLACE(REPLACE(City,'(',''),')',''),'Unincorporated','UI')
--		ELSE REPLACE(REPLACE(REPLACE(PostOffice + ',' + City,'(',''),')',''),'Unincorporated','UI')
--END  FROM Zip2TaxSourceTaxTable WHERE City LIKE '(%'

--SELECT * FROM Zip2TaxSourceTaxTable WHERE City LIKE '(%'

--UPDATE Zip2TaxSourceTaxTable SET MatchString=UPPER(dbo.mfnStripNonAlphaNumeric(State + ZipCode + City))

--EXEC mspSyncGeoLookupFromTaxSource '2/1/2014'

--UPDATE budGeographicLookup SET MatchString=UPPER(dbo.mfnStripNonAlphaNumeric(State + ZipCode + City))

--EXEC mspSyncGeoLookupFromTaxSource '2/1/2014'
--EXEC mspUpdateHQTaxCodes 101, NULL, null

--SELECT * FROM budGeographicLookup
--SELECT * FROM Zip2TaxSourceTaxTable
--CHECK MATCH Strings IN tables
--ReRun GeoLookup Sync - Test
--Run Tax UPDATE - Test

--CHECK

--Rerun entire cycle