--CREATE FUNCTION [dbo].[fnSqlToCmsDate] (@sqldate  datetime)  
--RETURNS decimal(8,0)
--AS  
--BEGIN 

--declare @retStrDate decimal(8,0)

--select @retStrDate = cast(convert(varchar(8),@sqldate,112) as decimal(8,0))

--return @retStrDate
--END


--GO


--CREATE FUNCTION [dbo].[fnCmsToSqlDate] (@cmsdate  decimal(8,0))  
--RETURNS datetime
--AS  
--BEGIN 

--declare @retStrDate char(10)

--if @cmsdate >= 19010101 and @cmsdate < 99991232 and @cmsdate <> 404040404
--begin

--declare @strDate char(8)


--declare @year char(4)
--declare @month char(2)
--declare @day char(2)

--select @strDate = cast(@cmsdate as char(8))
--select @year = substring(@strDate,1,4)
--select @month = substring(@strDate,5,2)
--select @day = substring(@strDate,7,2)

--select @retStrDate = @month + '/' + @day + '/' + @year

--end

--else
--	select @retStrDate = null

--return cast(@retStrDate as datetime)
--end

--GO

alter FUNCTION mfnEffectiveStartDate
(
	@EENO		INT
,	@Days		INT = 180
)
RETURNS  DATETIME
AS
BEGIN
	DECLARE @PeopleId	UNIQUEIDENTIFIER
	DECLARE @EffectiveStartDate DATETIME
	DECLARE @sdate DATETIME
	DECLARE @edate DATETIME
	
	SELECT @PeopleId=PEOPLE_ID FROM PEOPLE WHERE REFERENCENUMBER=CAST(@EENO AS VARCHAR(10))
	SELECT @EffectiveStartDate = MAX(EFFECTIVEDATE) FROM dbo.JOBDETAIL WHERE PEOPLE_ID=@PeopleId AND ENDDATE IS null
	
	DECLARE dtcur CURSOR FOR
	SELECT
		EFFECTIVEDATE
	,	ENDDATE
	FROM 
		dbo.JOBDETAIL
	WHERE
		PEOPLE_ID=@PeopleId
	ORDER BY
		EFFECTIVEDATE DESC
	FOR READ ONLY
	
	OPEN dtcur
	FETCH dtcur INTO
		@sdate
	,	@edate
	
	WHILE @@fetch_status=0
	BEGIN 
		IF @edate IS NOT NULL AND (DATEDIFF(day,@EffectiveStartDate,@edate) <= @Days)
		BEGIN
			SELECT @EffectiveStartDate=@sdate
		END

		FETCH dtcur INTO
			@sdate
		,	@edate	
	END 
	
	CLOSE dtcur
	DEALLOCATE dtcur
	
		
	--SELECT @EffectiveStartDate = GETDATE()
	
	RETURN @EffectiveStartDate	
END

go