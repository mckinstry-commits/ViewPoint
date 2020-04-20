SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[mspSyncGeoLookupFromTaxSource]
(
	@EffectiveDate DATETIME = null
)

AS

SET NOCOUNT ON

IF @EffectiveDate IS NULL
	SELECT @EffectiveDate=GETDATE()

--Update imported Zip2TaxSourceTaxTable to convert City names to usable values
UPDATE Zip2TaxSourceTaxTable
SET City=CASE 
			WHEN City LIKE '%' + PostOffice + '%' THEN REPLACE(REPLACE(REPLACE(City,'(',''),')',''),'Unincorporated','UI')
			ELSE REPLACE(REPLACE(REPLACE(PostOffice + ',' + City,'(',''),')',''),'Unincorporated','UI')
		 END  FROM Zip2TaxSourceTaxTable WHERE City LIKE '(%'
		 	
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

GO
