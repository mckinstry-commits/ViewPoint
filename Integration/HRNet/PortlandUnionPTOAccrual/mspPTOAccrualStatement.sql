

alter procedure mspPTOAccrualStatement
(
	@GroupIdentifier varchar(3) = '38'
,	@DoRefresh INT = 0
)
AS

SET NOCOUNT ON

DELETE FROM mckPTOAccrualSummary WHERE GroupIdentifier=@GroupIdentifier

-- Get Settings
DECLARE @UseIdentifier		varchar(3)
DECLARE @EligibleWorkDays	INT	
DECLARE @EligibleWorkHours	INT	
DECLARE @AccrualRatePerSet	INT	
DECLARE @AccrualSet			INT	
DECLARE @MaxAccrual			INT	
DECLARE @AllowedGapInService INT

SELECT 
	@UseIdentifier=UseIdentifier
,	@EligibleWorkDays=EligibleWorkDays
,	@EligibleWorkHours=EligibleWorkHours
,	@AccrualRatePerSet=AccrualRatePerSet
,	@AccrualSet=AccrualSet
,	@MaxAccrual=MaxAccrual
,	@AllowedGapInService=AllowedGapInService
FROM 
	mckPTOAccrualSettings
WHERE
	GroupIdentifier=@GroupIdentifier


--Set Variables

DECLARE @rcnt				INT
DECLARE @strhead			VARCHAR(200)
DECLARE @straccdetail		VARCHAR(200)
DECLARE @strusddetail		VARCHAR(200)
DECLARE @CONO				INT 
DECLARE @DVNO				INT
DECLARE @EENO				INT
DECLARE @EENM				VARCHAR(25)
DECLARE @DTHR				INT --Original Hire Date
DECLARE @DTBG				INT --Begin Date
DECLARE @DTTE				INT --Term Date
DECLARE @DTWK				INT --Last Worked Date

DECLARE @sqlDTHR			DATETIME --Original Hire Date
DECLARE @sqlDTBG			DATETIME --Begin Date
DECLARE @sqlDTTE			DATETIME --Term Date
DECLARE @sqlDTWK			DATETIME --Last Worked Date

DECLARE @EffectiveHireDate DATETIME
DECLARE @EmployedDays INT

DECLARE @tmpCurDate			INT
DECLARE @BenefitYear		CHAR(4)
DECLARE @AccumulatedHours	DECIMAL(18,3)
DECLARE @AccruedHours		DECIMAL(4,2)
DECLARE @UsedHours			DECIMAL(4,2)

DECLARE @hrMostRecentStartDate	DATETIME
DECLARE @hrEmployedDays			INT

SELECT @tmpCurDate = dbo.fnSqlToCmsDate(GETDATE())
SELECT @rcnt = 0



--SELECT * FROM cgcPRPTCHManualEntries
-- TODO:  Need to add attribute to identify CGC Fetched vs. Manual Entry (or maybe another table to use in a UNION statement)
IF NOT EXISTS ( SELECT 1 FROM sysobjects WHERE type='U' AND name='cgcPRPTCH')
BEGIN
	PRINT 'CREATE TABLE cgcPRPTCH'
	
	SELECT 
		tch.CHCONO, tch.CHDVNO, tch.CHEENO, tch.MNM25, tch.MDTHR, tch.MDTBG, tch.MDTTE, tch.MDTWK, tch.MSTAT,tch.CHRGHR,tch.CHOVHR,tch.CHOTHR,tch.CHOTTY,(tch.CHRGHR + tch.CHOVHR + tch.CHOTHR) AS CHTLHR, tch.CHDTWE, tch.CHUNNO , tch.CHCRNO
	INTO
		cgcPRPTCH 
	FROM 
		CMS.S1017192.BILLO.PRPTCHS tch 
END

IF @DoRefresh=1
BEGIN	
	
	DELETE FROM cgcPRPTCH WHERE (CAST(CHCRNO AS VARCHAR(3))=@GroupIdentifier OR CHOTTY = @UseIdentifier)
	--IF EXISTS ( SELECT 1 FROM sysobjects WHERE type='U' AND name='cgcPRPTCH')
	--BEGIN
	--PRINT 'DROP TABLE cgcPRPTCH'
	--DROP TABLE cgcPRPTCH
	--END

	INSERT
		cgcPRPTCH
	SELECT 
		tch.CHCONO, tch.CHDVNO, tch.CHEENO, tch.MNM25, tch.MDTHR, tch.MDTBG, tch.MDTTE, tch.MDTWK, tch.MSTAT,tch.CHRGHR,tch.CHOVHR,tch.CHOTHR,tch.CHOTTY,(tch.CHRGHR + tch.CHOVHR + tch.CHOTHR) AS CHTLHR, tch.CHDTWE, tch.CHUNNO , tch.CHCRNO
	FROM 
		CMS.S1017192.BILLO.PRPTCHS tch 
	WHERE
		(CAST(tch.CHCRNO AS VARCHAR(3))=@GroupIdentifier OR tch.CHOTTY = @UseIdentifier)
		
END

DECLARE empcur CURSOR FOR
select distinct tc.CHCONO, tc.CHDVNO, tc.CHEENO, tc.MNM25 --, tc.MDTHR, tc.MDTBG, tc.MDTTE, tc.MDTWK
FROM cgcPRPTCH_View tc
WHERE 
	tc.CHCONO in (1,20,60) 
AND tc.CHDVNO=0 
AND tc.MSTAT='A'	
--AND CHDTWE >= 20140101 
AND (CAST(tc.CHCRNO AS VARCHAR(3))=@GroupIdentifier OR tc.CHOTTY = @UseIdentifier)
ORDER BY 1,3
FOR READ ONLY

OPEN empcur
FETCH empcur INTO
	@CONO
,	@DVNO
,	@EENO
,	@EENM
--,	@DTHR
--,	@DTBG
--,	@DTTE
--,	@DTWK



WHILE @@fetch_status=0

BEGIN
	SELECT @rcnt = @rcnt + 1 

	-- GET EffectiveHireDate from HRNET.dbo.JOBDETAIL
	-- Most recent hire date where <=90 from term date
	
	
	SELECT @hrMostRecentStartDate = dbo.mfnEffectiveStartDate(@EENO,@AllowedGapInService)
	SELECT @hrEmployedDays=DATEDIFF(day,@hrMostRecentStartDate,GETDATE())
	
	/*
	--  CGC Logic Not needed -- Will use HR.net Job Detail for employment history)
	SELECT 
		@sqlDTHR = dbo.fnCmsToSqlDate(@DTHR) --Original Hire Date
	,	@sqlDTBG = dbo.fnCmsToSqlDate(@DTBG) --Begin Date
	,	@sqlDTTE = dbo.fnCmsToSqlDate(@DTTE) --Term Date
	,	@sqlDTWK = dbo.fnCmsToSqlDate(@DTWK) --Last Worked Date
	
	--SELECT DATEDIFF(DAY,
	IF DATEDIFF(day,@sqlDTBG,@sqlDTTE) <= @EligibleWorkDays
	BEGIN
		--IF @sqlDTHR < '1/1/2014'
		--	SELECT @EffectiveHireDate='1/1/2014', @EmployedDays=DATEDIFF(day,@sqlDTHR,'1/1/2014')
		--ELSE
			SELECT @EffectiveHireDate=@sqlDTHR, @EmployedDays=DATEDIFF(day,@sqlDTHR,GETDATE())
	END
	ELSE
	BEGIN
		--IF @sqlDTHR < '1/1/2014'
		--	SELECT @EffectiveHireDate='1/1/2014', @EmployedDays=DATEDIFF(day,@sqlDTBG,'1/1/2014')
		--ELSE
			SELECT @EffectiveHireDate=@sqlDTBG, @EmployedDays=DATEDIFF(day,@sqlDTBG,GETDATE())
			
		--SELECT @EffectiveHireDate=@sqlDTBG, @EmployedDays=DATEDIFF(day,@sqlDTBG,GETDATE())
	END
	*/
	
	SELECT @strhead= 
		CAST(@rcnt AS CHAR(10))
	+	CAST(CAST(@CONO AS VARCHAR(10)) + '.' + CAST(@EENO AS VARCHAR(10)) AS CHAR(15))
	+	CAST(@EENM AS CHAR(30))
	+	CAST(@tmpCurDate AS CHAR(10))
	--+	CAST(@DTBG AS CHAR(8)) + '/' + CAST(@DTTE AS CHAR(8)) + '/' + CAST(@DTHR AS CHAR(8)) + '    '
	--+	CAST(COALESCE(@EmployedDays,0) AS CHAR(10))
	--+	CAST(COALESCE(convert(VARCHAR(10),@EffectiveHireDate, 101),'??') AS CHAR(15))
	+	CAST(COALESCE(@hrEmployedDays,0) AS CHAR(10))
	+	CAST(COALESCE(convert(VARCHAR(10),@hrMostRecentStartDate, 101),'??') AS CHAR(15))
	
	--SELECT @AccumulatedHours=CHTLHR
	--FROM cgcPRPTCH 
	--WHERE CHCONO=@CONO AND CHDVNO=@DVNO AND CHEENO=@EENO AND CHCRNO=38
	--PRINT @strhead



	DECLARE acccur CURSOR FOR
	select 
		LEFT(CAST(tc2.CHDTWE AS char(8)),4) AS CHYEAR
	--,	CAST(tc2.CHUNNO AS CHAR(3)) AS CHUNNO
	,	CAST(SUM(tc2.CHTLHR) AS DECIMAL(18,3)) as CHTLHR 
	from 
		cgcPRPTCH_View tc2
	where 
		tc2.CHCONO=@CONO
	AND	tc2.CHDVNO=@DVNO
	AND	tc2.CHEENO=@EENO
	AND tc2.CHDTWE >= 20140101
	AND tc2.CHCRNO=@GroupIdentifier
	GROUP BY
		LEFT(CAST(tc2.CHDTWE AS char(8)),4) 
	--,	CAST(tc2.CHUNNO AS CHAR(3))
	order by 1,2
	FOR READ ONLY
	
	OPEN acccur
	FETCH acccur INTO
		@BenefitYear
	--,	@UnionNumber
	,	@AccumulatedHours
	
	WHILE @@fetch_status=0
	BEGIN	
		INSERT mckPTOAccrualSummary (
			CompanyNumber		--int				not null
		,	EmployeeNumber		--int				not null
		,	EmployeeName		--varchar(50)		not null
		,	RunDate				--datetime		not null
		,	EffectiveWorkDays	--int				null
		,	EffectiveStartDate	--datetime		null
		,	GroupIdentifier		--varchar(3)		not null
		,	[Year]				--char(4)			not null
		,	EligibleStatus		--varchar(30)		not null
		,	AccumulatedHours	--DECIMAL(18,3)	not null
		,	AccruedPTOHours		--DECIMAL(4,0)	not null
		,	UsedPTOHours		--DECIMAL(4,0)	not null
		,	AvailablePTOHours	--DECIMAL(4,0)	not NULL
		)
		VALUES (
			@CONO
		,	@EENO
		,	@EENM
		,	CAST(CONVERT(VARCHAR(10),GETDATE(),101) AS datetime)
		,	@hrEmployedDays
		,	@hrMostRecentStartDate
		,	@GroupIdentifier
		,	@BenefitYear
		,	'UNKNOWN'
		,	COALESCE(@AccumulatedHours,0)
		,	0 --COALESCE(@AccruedHours,0)
		,	0 --COALESCE(@UsedHours,0)
		,	0 --COALESCE(@AccruedHours,0) - COALESCE(@UsedHours,0)
		)
		
		IF (@AccumulatedHours >=240	)
		BEGIN
			--DECLARE @AccrualRatePerSet	INT	
			--DECLARE @AccrualSet			INT	
			SELECT @AccruedHours = ( CAST(@AccumulatedHours/@AccrualSet AS DECIMAL(2,0)) * @AccrualRatePerSet )
		end
		ELSE
		begin
			SELECT @AccruedHours = 0 --( CAST(@AccumulatedHours/@AccrualSet AS DECIMAL(2,0)) * @AccrualRatePerSet )
		end

		UPDATE mckPTOAccrualSummary SET
			AccruedPTOHours=COALESCE(@AccruedHours,0)
		WHERE
			CompanyNumber=@CONO
		AND EmployeeNumber=@EENO
		AND GroupIdentifier=@GroupIdentifier
		AND [Year]=@BenefitYear
			
		SELECT @straccdetail= 
			CAST('' AS CHAR(10))
		+	CAST('Acc:' + CAST(@GroupIdentifier AS VARCHAR(3)) AS CHAR(10))
		+	CAST(COALESCE(@BenefitYear,'9999') AS CHAR(10))
		--+	CAST(COALESCE(@UnionNumber,999) AS CHAR(10))
		+	CAST(COALESCE(@AccumulatedHours,0) AS CHAR(20))
		+	CAST(COALESCE(@AccruedHours,0) AS CHAR(20))		
						
		IF @hrEmployedDays >=@EligibleWorkDays AND @AccumulatedHours >=@EligibleWorkHours
		BEGIN		
			UPDATE mckPTOAccrualSummary SET
				EligibleStatus='ELIGIBLE'
			WHERE
				CompanyNumber=@CONO
			AND EmployeeNumber=@EENO
			AND GroupIdentifier=@GroupIdentifier
			AND [Year]=@BenefitYear
			
			SELECT @straccdetail=@straccdetail
			+	CAST('' AS CHAR(5))
			+	'ELIGIBLE [** '
			--+	CAST(CAST(@CONO AS VARCHAR(10)) + '.' + CAST(@EENO AS VARCHAR(10)) AS CHAR(15))
			--+	CAST(@EENM AS CHAR(30))
			+	CAST(COALESCE(@AccumulatedHours,0) AS CHAR(10))
			+	' = '
			+	CAST(COALESCE(@AccruedHours,0) AS CHAR(5))
			+   ' { @ ' + CAST(@AccrualRatePerSet AS VARCHAR(10)) + ' hour per ' + CAST(@AccrualSet AS VARCHAR(10)) + ' !> ' + CAST(@MaxAccrual AS VARCHAR(10)) + ' }'
			+	'**]'		
		END
		ELSE
		BEGIN		
			UPDATE mckPTOAccrualSummary SET
				EligibleStatus='INELIGIBLE'
			WHERE
				CompanyNumber=@CONO
			AND EmployeeNumber=@EENO
			AND GroupIdentifier=@GroupIdentifier
			AND [Year]=@BenefitYear
			
			SELECT @straccdetail=@straccdetail
			+	CAST('' AS CHAR(5))
			+	'INELIGIBLE [** '
			--+	CAST(CAST(@CONO AS VARCHAR(10)) + '.' + CAST(@EENO AS VARCHAR(10)) AS CHAR(15))
			--+	CAST(@EENM AS CHAR(30))
			+	CAST(COALESCE(@AccumulatedHours,0) AS CHAR(10))
			+	' = '
			+	CAST(COALESCE(@AccruedHours,0) AS CHAR(5))
			+   ' { @ ' + CAST(@AccrualRatePerSet AS VARCHAR(10)) + ' hour per ' + CAST(@AccrualSet AS VARCHAR(10)) + ' !> ' + CAST(@MaxAccrual AS VARCHAR(10)) + ' }'
			+	'**]'			
		END
		--PRINT ''

		PRINT @strhead + ' : ' + @straccdetail		
	
		 
		FETCH acccur INTO
			@BenefitYear
		--,	@UnionNumber
		,	@AccumulatedHours	
	END
	
	CLOSE acccur
	DEALLOCATE acccur

--DECLARE @UseIdentifier		varchar(3)
--DECLARE @EligibleWorkDays	INT	
--DECLARE @EligibleWorkHours	INT	

	

UPDATE mckPTOAccrualSummary SET
	UsedPTOHours=t3.UsedHours
--,	AvailablePTOHours=t3.AvailableHours
FROM
(
SELECT
	t1.CHCONO AS CompanyNumber
,	t1.CHEENO AS EmployeeNumber
,	LEFT(CAST(t1.CHDTWE AS char(8)),4) AS [Year]
,	CAST(SUM(t1.CHOTHR) AS DECIMAL(18,3))AS UsedHours
--,	COALESCE(t2.AccruedPTOHours,0)-COALESCE(CAST(SUM(t1.CHOTHR) AS DECIMAL(18,3)),0) AS AvailableHours
FROM
	cgcPRPTCH t1 JOIN
	mckPTOAccrualSummary t2 ON
		t1.CHCONO=t2.CompanyNumber
	AND t1.CHEENO=t2.EmployeeNumber
	AND LEFT(CAST(t1.CHDTWE AS char(8)),4)=t2.[Year]
WHERE
	t1.CHDTWE >= 20140101
AND t1.CHOTTY = @UseIdentifier
GROUP BY
	t1.CHCONO
,	t1.CHEENO
,	LEFT(CAST(t1.CHDTWE AS char(8)),4)
,	t2.AccruedPTOHours
) t3
WHERE
	mckPTOAccrualSummary.CompanyNumber=t3.CompanyNumber
AND mckPTOAccrualSummary.EmployeeNumber=t3.EmployeeNumber
AND mckPTOAccrualSummary.[Year]=t3.[Year]

UPDATE mckPTOAccrualSummary SET AvailablePTOHours=AccruedPTOHours-UsedPTOHours	--DECIMAL(4,0)	not NULL

		

	DECLARE usedcur CURSOR FOR
	
	select 
		LEFT(CAST(tc2.CHDTWE AS char(8)),4) AS CHYEAR
	--,	CAST(tc2.CHUNNO AS CHAR(3)) AS CHUNNO
	,	CAST(SUM(tc2.CHOTHR) AS DECIMAL(18,3)) as CHTLHR 
	from 
		cgcPRPTCH_View tc2
	where 
		tc2.CHCONO=@CONO
	AND	tc2.CHDVNO=@DVNO
	AND	tc2.CHEENO=@EENO
	AND tc2.CHDTWE >= 20140101
	AND tc2.CHOTTY = @UseIdentifier
	GROUP BY
		LEFT(CAST(tc2.CHDTWE AS char(8)),4) 
	--,	CAST(tc2.CHUNNO AS CHAR(3))
	order by 1,2
	FOR READ ONLY
	
	OPEN usedcur
	FETCH usedcur INTO
		@BenefitYear
	--,	@UnionNumber
	,	@UsedHours
	
	WHILE @@fetch_status=0
	BEGIN
		
		select @strusddetail =
			CAST('' AS CHAR(5))
		+	CAST('Used:' + CAST(@UseIdentifier AS VARCHAR(3)) AS CHAR(10))
		+	CAST(COALESCE(@BenefitYear,'9999') AS CHAR(10))
		--+	CAST(COALESCE(@UnionNumber,999) AS CHAR(10))
		+	CAST(COALESCE(@AccruedHours,0) AS CHAR(20))
		+	CAST(COALESCE(@UsedHours,0) AS CHAR(20))
				
		IF (@EmployedDays>=@EligibleWorkDays OR @hrEmployedDays >=@EligibleWorkDays) AND @AccumulatedHours >=@EligibleWorkHours
		begin
			SELECT @strusddetail=@strusddetail
			+	CAST('' AS CHAR(5))
			+	'[**'
			+	CAST(CAST(@CONO AS VARCHAR(10)) + '.' + CAST(@EENO AS VARCHAR(10)) AS CHAR(15))
			+	CAST(@EENM AS CHAR(30))
			+	CAST(COALESCE(@UsedHours,0) AS CHAR(20))
			+	CAST(COALESCE(@AccruedHours,0) AS CHAR(20))
			+	'**]'
		--PRINT ''
		PRINT @strhead + ' : ' + @strusddetail	
		END
		
		UPDATE mckPTOAccrualSummary SET
			UsedPTOHours=COALESCE(@UsedHours,0)		--DECIMAL(4,0)	not null
		,	AvailablePTOHours=COALESCE(AccruedPTOHours,0)-COALESCE(@UsedHours,0)	--DECIMAL(4,0)	not NULL
		WHERE
			CompanyNumber=@CONO
		AND EmployeeNumber=@EENO
		AND GroupIdentifier=@GroupIdentifier
		AND [Year]=@BenefitYear
		
		--select @UsedHours=0,@AccruedHours=0
		
		FETCH usedcur INTO
			@BenefitYear
		--,	@UnionNumber
		,	@AccumulatedHours	
	END
	
	CLOSE usedcur
	DEALLOCATE usedcur

	FETCH empcur INTO
		@CONO
	,	@DVNO
	,	@EENO
	,	@EENM
	--,	@DTHR
	--,	@DTBG
	--,	@DTTE
	--,	@DTWK	
END

CLOSE empcur
DEALLOCATE empcur

SELECT * FROM mckPTOAccrualSummary ORDER BY EmployeeNumber 
go

EXEC mspPTOAccrualStatement 38,1




--select 
--	CHCONO
--,	CHDVNO
--,	tc.CHEENO
--,	tc.CHCRNO
--,	tc.CHUNNO
--,	LEFT(CAST(tc.CHDTWE AS VARCHAR(8)),4) AS CHYEAR
--,	SUM(tc.CHRGHR) AS CHRGHR
--,	SUM(tc.CHOVHR) AS CHOVHR
--,	SUM(tc.CHOTHR) AS CHOTHR
--,	tc.CHOTTY
--,	SUM((tc.CHRGHR + tc.CHOVHR + tc.CHOTHR)) as CHTLHR 
--from 
--	CMS.S1017192.CMSFIL.PRPTCH tc
--where 
--		tc.CHCONO=1
--AND	tc.CHDVNO=0
--AND	tc.CHEENO=68221
--AND	tc.CHDTWE >= 20140101 
--AND (	tc.CHCRNO=38
--OR	tc.CHOTTY='PX') 
--GROUP BY
--	tc.CHCONO
--,	tc.CHDVNO
--,	tc.CHEENO
--,	tc.CHCRNO
--,	tc.CHUNNO
--,	LEFT(CAST(tc.CHDTWE AS VARCHAR(8)),4)
--,	tc.CHOTTY
----order by 1,3,4



--select 
--		CAST(LEFT(CAST(tc.CHDTWE AS VARCHAR(8)),4) AS INT) AS CHYEAR
--	,	tc.CHUNNO
--	,	SUM((tc.CHRGHR + tc.CHOVHR + tc.CHOTHR)) as CHTLHR 
--	from 
--		CMS.S1017192.BILLO.MCKACCRUALROSTER tc
--	where 
--		tc.CHCONO=1
--	AND	tc.CHDVNO=0
--	AND	tc.CHEENO=190
--	AND tc.CHCRNO=38
--	GROUP BY
--		tc.CHUNNO
--	,	CAST(LEFT(CAST(tc.CHDTWE AS VARCHAR(8)),4) AS INT)
--	order by 1,2
	
	
--SELECT CHCONO, CHEENO, SUM((CHRGHR + CHOVHR + CHOTHR))
--	FROM CMS.S1017192.BILLO.MCKACCRUALROSTER 
--	WHERE CHCONO=1 AND CHDVNO=0 AND CHCRNO=38
--	GROUP BY CHCONO,CHEENO
		