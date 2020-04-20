DECLARE @co tinyint, @lockmth smalldatetime

DECLARE WIPLock CURSOR FOR
SELECT CompanyCode, MAX(LockMonth) FROM dbo.udWIPLockCalendar GROUP BY CompanyCode

OPEN WIPLock

FETCH NEXT FROM WIPLock
INTO @co, @lockmth

WHILE @@FETCH_STATUS = 0 
BEGIN
	DECLARE @month SMALLDATETIME
	SELECT	@month = CASE	WHEN DATEADD(MONTH, 1, dbo.mfnFirstOfMonth(@lockmth)) <= '12/1/2014' THEN '12/1/2014' 
							ELSE DATEADD(MONTH, 1, dbo.mfnFirstOfMonth(@lockmth))
					 END

	WHILE	@month <= dbo.mfnFirstOfMonth(getdate())
	BEGIN
		--PRINT CAST(@co AS CHAR(2)) + ' ' + CAST(@month AS VARCHAR(100))
		EXEC [dbo].[mspGetWIPData]  @co, @month, null, null, null, 'N'
		EXEC [dbo].[mckrptProjectReportRefresh] @month, @co
		
		SELECT @month = DATEADD(MONTH, 1, @month)
	END

	FETCH NEXT FROM WIPLock
	INTO @co, @lockmth
END

CLOSE WIPLock
DEALLOCATE WIPLock

--truncate table mckWipRevenueData
--truncate table mckWipCostByJobData
--truncate table mckWipCostData
--truncate table mckWipArchive

--delete from mckWipRevenueData where JCCo=201
--delete from mckWipCostByJobData where JCCo=201
--delete from mckWipCostData where JCCo=201
--delete from mckWipArchive where JCCo=201

--declare	@inCompany				TINYINT
--declare	@inMonth				SMALLDATETIME
--declare	@inContract				VARCHAR(10) --bContract
--declare	@inIsLocked				CHAR(1)		--bYN
--declare	@inExcludeWorkStream	VARCHAR(255)
--declare	@inExcludeRevenueType	VARCHAR(255)

--select
--	@inMonth				= '10/1/2014'	--smalldatetime
--,	@inContract				= null			--bContract.
--,	@inIsLocked				= NULL			--bYN 
--,	@inExcludeWorkStream	= NULL			--varchar(255)
--,	@inExcludeRevenueType	= 'N'			--varchar(255)
--,	@inCompany				= null			--tinyint

--EXEC	[dbo].[mspGetWIPData]
--		@inCompany = @inCompany,
--		@inMonth = @inMonth,
--		@inContract = @inContract,
--		@inIsLocked = @inIsLocked,
--		@inExcludeWorkStream = @inExcludeWorkStream,
--		@inExcludeRevenueType = @inExcludeRevenueType
--GO