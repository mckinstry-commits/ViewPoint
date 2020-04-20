ALTER procedure [dbo].[mspGetWIPData]
(
	@inCompany				tinyint
,	@inMonth				smalldatetime
,	@inContract				VARCHAR(10) --bContract
,	@inIsLocked				CHAR(1)		--bYN
,	@inExcludeWorkStream	varchar(255)
,	@inExcludeRevenueType	varchar(255)
)
AS
BEGIN

	--Check for GL Period Closing
	--IF NOT	EXISTS (SELECT IsMonthOpen from vfGLClosedMonths('GL',@inMonth) WHERE GLCo=@inCompany AND IsMonthOpen=1)
	--BEGIN
	--	RETURN -1
	--END
	--ELSE

	IF (@inMonth IS NOT NULL AND @inMonth >= '1/1/2015')
	BEGIN	
		EXEC dbo.mspWIPRevenue @inCompany,@inMonth,@inContract,@inExcludeRevenueType

		IF EXISTS (SELECT 1 FROM dbo.mckWipCostByJobData WHERE (JCCo=@inCompany OR @inCompany IS NULL) 
														   AND (ThroughMonth=@inMonth OR @inMonth IS NULL) 
														   AND (Contract=@inContract OR @inContract IS NULL)
														   AND RevenueType NOT IN (SELECT * FROM dbo.mfnSplitCsvParam(@inExcludeRevenueType)))
		BEGIN
			DELETE dbo.mckWipCostByJobData WHERE (JCCo=@inCompany OR @inCompany IS NULL) 
											 AND (ThroughMonth=@inMonth OR @inMonth IS NULL) 
											 AND (Contract=@inContract OR @inContract IS NULL)
											 AND RevenueType NOT IN (SELECT * FROM dbo.mfnSplitCsvParam(@inExcludeRevenueType))
		END
		INSERT dbo.mckWipCostByJobData SELECT * FROM dbo.mfnGetWIPCostByJob(@inCompany,@inMonth,@inContract,@inIsLocked,@inExcludeWorkStream,@inExcludeRevenueType)

		EXEC dbo.mspWIPCost @inCompany,@inMonth,@inContract,@inExcludeRevenueType	

		EXEC dbo.mspWIPArchive @inCompany,@inMonth,@inContract,@inExcludeRevenueType
	END	
END

-- Test Script
--EXEC [dbo].[mspGetWIPData] 1, '10/1/2014', null, null, null, 'M,A,C'	--4:18
--EXEC [dbo].[mspGetWIPData] 20, '10/1/2014', null, null, null, 'M,A,C'	--4:09
--EXEC [dbo].[mspGetWIPData] 1, '11/1/2014', null, null, null, 'M,A,C'	--4:11
--EXEC [dbo].[mspGetWIPData] 20, '11/1/2014', null, null, null, 'M,A,C'	--4:05
--EXEC [dbo].[mspGetWIPData] 1, '12/1/2014', null, null, null, 'M,A,C'	--4:35
--EXEC [dbo].[mspGetWIPData] 20, '12/1/2014', null, null, null, 'M,A,C'	--5:41
--EXEC [dbo].[mspGetWIPData] 1, '1/1/2015', null, null, null, null
--EXEC [dbo].[mspGetWIPData] 20, '1/1/2015', null, null, null, null
--EXEC [dbo].[mspGetWIPData] 60, '1/1/2015', null, null, null, null
--EXEC [dbo].[mspGetWIPData] 1, '2/1/2015', null, null, null, null
--EXEC [dbo].[mspGetWIPData] 20, '2/1/2015', null, null, null, null
--EXEC [dbo].[mspGetWIPData] 60, '2/1/2015', null, null, null, null

-- Execute
----truncate table mckWipRevenueData
----truncate table mckWipCostByJobData
----truncate table mckWipCostData
----truncate table mckWipArchive

----delete from mckWipRevenueData where JCCo=201
----delete from mckWipCostByJobData where JCCo=201
----delete from mckWipCostData where JCCo=201
----delete from mckWipArchive where JCCo=201

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
--,	@inCompany				= 1			--tinyint

--EXEC	[dbo].[mspGetWIPData]
--		@inCompany = @inCompany,
--		@inMonth = @inMonth,
--		@inContract = @inContract,
--		@inIsLocked = @inIsLocked,
--		@inExcludeWorkStream = @inExcludeWorkStream,
--		@inExcludeRevenueType = @inExcludeRevenueType
--GO