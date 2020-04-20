USE [HRNET]
GO

ALTER PROCEDURE [mnepto].[mspRecalculateAccruals]
(
	@EmployeeNumber INT = NULL
,	@GroupIdentifier varchar(3) = null
,	@DoRefresh INT = 0
,	@SyncDNNAccount INT = 0	
,	@defaultDNNEmail varchar(100) = ''
,	@SimPriorYearRate decimal(5,2) = 0
)
AS

/*
	2014.05.20 - LWO - Altered to accomodate MaxAccrualUse in settings table.

*/
SET NOCOUNT ON

IF @defaultDNNEmail IS null
	SELECT @defaultDNNEmail = ''

DECLARE @emp_rcnt INT 
DECLARE @pmsg VARCHAR(MAX)

DECLARE @currYear int
DECLARE @prevYear int

SELECT @currYear = YEAR(GETDATE())
SELECT @prevYear = @currYear-1

DECLARE @GroupName VARCHAR(30)
DECLARE @UseIdentifier VARCHAR(3)

DECLARE @GroupEffectiveDate DATETIME
DECLARE @GroupEffectiveDate2 [numeric](8, 0)

DECLARE @EligibleWorkDays	INT	
DECLARE @EligibleWorkDaysLegacyWaiver CHAR(1)
DECLARE @EligibleWorkHours	INT	
DECLARE @EligibleWorkHoursAnnual	CHAR(1)	
DECLARE @AccrualRatePerSet	INT	
DECLARE @AccrualSet			INT	
DECLARE @MaxAccrual			INT	
DECLARE @MaxAccrualUse		INT	
DECLARE @AllowedGapInService INT

DECLARE @empcurCompanyNumber	int			
DECLARE @empcurEmployeeNumber	INT
DECLARE @empcurEmployeeName		VARCHAR(50)
DECLARE @empcurEffectiveStartDate DATETIME
DECLARE @empcurEmployedDays	INT
DECLARE @empcurReportedHours INT
DECLARE @empcurReportedHoursThisYear int
DECLARE @empcurReportedHoursLastYear int
DECLARE @empcurEligible CHAR(1)

SELECT @emp_rcnt = 0
-- Loop through each GroupIdentifier ( either the one supplied or All )

DECLARE tcur CURSOR FOR
SELECT
	GroupDescription
,	GroupIdentifier
,	UseIdentifier
,	EffectiveDate
,	EligibleWorkDays
,	EligibleWorkDaysLegacyWaiver
,	EligibleWorkHours
,	EligibleWorkHoursAnnual
,	AllowedGapInService
,	AccrualRatePerSet
,	AccrualSet
,	MaxAccrual
,	MaxAnnualUse
FROM 
	mnepto.AccrualSettings
WHERE
	(GroupIdentifier=@GroupIdentifier OR @GroupIdentifier IS NULL)
FOR READ ONLY

OPEN tcur
FETCH tcur INTO 
	@GroupName
,	@GroupIdentifier
,	@UseIdentifier
,	@GroupEffectiveDate
,	@EligibleWorkDays	
,	@EligibleWorkDaysLegacyWaiver
,	@EligibleWorkHours	
,	@EligibleWorkHoursAnnual
,	@AllowedGapInService 
,	@AccrualRatePerSet
,	@AccrualSet			
,	@MaxAccrual	
,	@MaxAccrualUse		
	
WHILE @@fetch_status=0
BEGIN

	SELECT @GroupEffectiveDate2 = CAST(CONVERT(CHAR(8),@GroupEffectiveDate,112) as [numeric](8, 0))
	
	SELECT @pmsg =
		CAST(@GroupName AS CHAR(31))
	+	CAST(@GroupIdentifier + '/' + @UseIdentifier AS CHAR(10))
	
	-- First Refresh TimeCardHistory
	IF @DoRefresh <> 0
	BEGIN
		PRINT 'REFRESHING SOURCE TIMECARD HISTORY DATA'
		
		PRINT 'REFRESHING PERSONNEL LIST'
		EXEC [mnepto].[mspSyncPersonnel] @EmployeeNumber
		
		DELETE 
			mnepto.TimeCardHistory 
		WHERE	
		(	GroupID = @GroupIdentifier 
		OR  OtherHoursType = @UseIdentifier )			
		AND (EmployeeNumber=@EmployeeNumber OR @EmployeeNumber IS NULL)
		AND CAST(LEFT(CAST(WeekEnding AS CHAR(8)),4) AS INT) IN (@currYear,@prevYear)
		
		print @pmsg + CAST(CAST(@@rowcount AS VARCHAR(10)) + ' rows deleted.' AS CHAR(40)) + CAST(COALESCE(CAST(@EmployeeNumber AS VARCHAR(10)),'') AS CHAR(10))
		
		INSERT [mnepto].[TimeCardHistory]
		(
			CompanyNumber	--int				NOT NULL 
		,	EmployeeNumber	--int				NOT NULL
		,	RegularHours	--[numeric](5, 2) NOT NULL
		,	OvertimeHours	--[numeric](5, 2) NOT NULL
		,	OtherHours		--[numeric](5, 2)	NOT NULL
		,	OtherHoursType	--[varchar](10)	NOT NULL
		--,	TotalHours AS [RegularHours]+[OvertimeHours]+[OtherHours]
		,	WeekEnding		--[numeric](8, 0) NOT NULL
		,	GroupID			--[numeric](2, 0) NOT NULL
		)
		SELECT 
			tch.CHCONO
		,	tch.CHEENO
		,	tch.CHRGHR
		,	tch.CHOVHR
		,	tch.CHOTHR
		,	tch.CHOTTY
		,	tch.CHDTWE
		,	tch.CHCRNO
		FROM 
			CMS.S1017192.BILLO.PRPTCHS tch 	
		WHERE
		(	tch.CHCRNO=@GroupIdentifier 
		OR  tch.CHOTTY=@UseIdentifier )
		AND (tch.CHEENO=@EmployeeNumber OR @EmployeeNumber IS NULL)
		AND CAST(tch.CHDTWE AS INT) >= CAST(@GroupEffectiveDate2 AS INT)
		AND CAST(LEFT(CAST(tch.CHDTWE AS CHAR(8)),4) AS INT) IN (@currYear,@prevYear)

		print @pmsg + CAST(CAST(@@rowcount AS VARCHAR(10)) + ' rows inserted. ' AS CHAR(40)) + CAST(COALESCE(CAST(@EmployeeNumber AS VARCHAR(10)),'') AS CHAR(10))
		PRINT ''
		
	END
	
	SELECT @emp_rcnt = 0
	
	-- GET AGGREGATED ENTRIES FROM VIEW FOR PROCESSING
	DECLARE empcur CURSOR FOR
	SELECT
		CompanyNumber, EmployeeNumber, EmployeeName
	FROM 
		mnepto.Personnel
	WHERE
		( EmployeeNumber = @EmployeeNumber OR @EmployeeNumber IS NULL )
	ORDER BY 
		CompanyNumber
	,	EmployeeNumber
	FOR READ ONLY


	OPEN empcur
	FETCH empcur INTO
		@empcurCompanyNumber
	,	@empcurEmployeeNumber	
	,	@empcurEmployeeName
	
	WHILE @@fetch_status=0
	BEGIN		
		SELECT @emp_rcnt = @emp_rcnt + 1
		-- Get Employee Effective Starting Date
		SELECT @empcurEffectiveStartDate = COALESCE(mnepto.mfnEffectiveStartDate(@empcurEmployeeNumber,@AllowedGapInService),GETDATE())
		SELECT @empcurEmployedDays=COALESCE(DATEDIFF(day,@empcurEffectiveStartDate,GETDATE()),0)
		
		
		--Reported Hours To Date
		SELECT @empcurReportedHours = COALESCE(SUM(TotalHours),0)
		FROM	
			mnepto.TimeCardAggregateView
		WHERE
			GroupId=@GroupIdentifier
		AND EmployeeNumber=@empcurEmployeeNumber
		AND CompanyNumber=@empcurCompanyNumber	
		AND WeekEnding >= @GroupEffectiveDate2		
		
		
		--Reported Hours This Year
		SELECT @empcurReportedHoursThisYear = COALESCE(SUM(TotalHours),0)
		FROM	
			mnepto.TimeCardAggregateView
		WHERE
			GroupId=@GroupIdentifier
		AND EmployeeNumber=@empcurEmployeeNumber
		AND CompanyNumber=@empcurCompanyNumber	
		AND WeekEnding >= 
			CASE
				WHEN CAST(CAST(@currYear AS VARCHAR(4)) + '0101' AS NUMERIC(8,0)) <= @GroupEffectiveDate2 THEN @GroupEffectiveDate2
				ELSE CAST(CAST(@currYear AS VARCHAR(4)) + '0101' AS NUMERIC(8,0)) 
			END
		AND WeekEnding <= CAST(CAST(@currYear AS VARCHAR(4)) + '1231' AS NUMERIC(8,0))
				
		--Reported Hours Last Year
		SELECT @empcurReportedHoursLastYear = COALESCE(SUM(TotalHours),0)
		FROM	
			mnepto.TimeCardAggregateView
		WHERE
			GroupId=@GroupIdentifier
		AND EmployeeNumber=@empcurEmployeeNumber
		AND CompanyNumber=@empcurCompanyNumber	
		AND WeekEnding >= CAST(CAST(@prevYear AS VARCHAR(4)) + '0101' AS NUMERIC(8,0)) AND WeekEnding <= CAST(CAST(@prevYear AS VARCHAR(4)) + '1231' AS NUMERIC(8,0))
		
		IF UPPER(@EligibleWorkHoursAnnual)='Y'
		BEGIN
			IF (@empcurReportedHoursThisYear >= @EligibleWorkHours) 
			BEGIN
				SELECT @empcurReportedHours = @empcurReportedHoursThisYear
			END
			IF (@empcurReportedHoursLastYear >= @EligibleWorkHours)
			BEGIN
				SELECT @empcurReportedHours = @empcurReportedHoursLastYear
			END
		END
		IF UPPER(@EligibleWorkDaysLegacyWaiver)='Y'
		begin
			IF @empcurEffectiveStartDate < @GroupEffectiveDate
			BEGIN
				SELECT @empcurEmployedDays = @EligibleWorkDays
			END		
		END
		
		IF @empcurEmployedDays >= @EligibleWorkDays AND @empcurReportedHours >= @EligibleWorkHours
		BEGIN
			SELECT @empcurEligible='E'
		END
		ELSE
		BEGIN
			SELECT @empcurEligible='I'
		END
		
				
		PRINT
			CAST(@emp_rcnt AS CHAR(8))
		+	CAST(CAST(@empcurCompanyNumber AS VARCHAR(5)) + '.' + CAST(@empcurEmployeeNumber	AS VARCHAR(10)) AS CHAR(30))
		+	CAST(coalesce(@empcurEligible,'X') AS CHAR(3))
		+	CAST(coalesce(@empcurEmployeeName,'Unknown') AS CHAR(55))	
		+	CONVERT(CHAR(10),COALESCE(@empcurEffectiveStartDate,GETDATE()),102) + ' = '
		+	CAST(COALESCE(@empcurEmployedDays,0) AS CHAR(8)) + ' : '
		+	CAST(COALESCE(@empcurReportedHours,0) AS CHAR(8))
		
		DELETE mnepto.AccrualSummary 
		WHERE
			GroupIdentifier =@GroupIdentifier
		AND EmployeeNumber = @empcurEmployeeNumber
		AND CompanyNumber = @empcurCompanyNumber 
				
		-- Record Current Accumulation of Hours
		INSERT mnepto.AccrualSummary
		        ( CompanyNumber ,
		          EmployeeNumber ,
		          Year ,
		          GroupIdentifier ,
		          EffectiveWorkDays ,
		          EffectiveStartDate ,
		          EligibleStatus ,
		          AccumulatedHours ,
		          PrevCarryOverPTOHours ,
		          AccruedPTOHours ,
		          UsedPTOHours ,
		          RunDate
		        )
		SELECT
			CompanyNumber
		,	EmployeeNumber
		,	Year
		,   GroupId	
		,	@empcurEmployedDays
		,	@empcurEffectiveStartDate
		,	@empcurEligible
		,	@empcurReportedHours
		,	0
		,	CASE 
				WHEN @MaxAccrual > 0 AND (@empcurReportedHours/@AccrualSet)*@AccrualRatePerSet > @MaxAccrual THEN @MaxAccrual
				ELSE (@empcurReportedHours/@AccrualSet)*@AccrualRatePerSet
			END
		,	0
		,	GETDATE()
		FROM	
			mnepto.TimeCardAggregateView
		WHERE
			GroupId=@GroupIdentifier
		AND EmployeeNumber = @empcurEmployeeNumber
		AND CompanyNumber = @empcurCompanyNumber
		GROUP BY
			CompanyNumber
		,	EmployeeNumber
		,   GroupId			
		,	Year
		
		IF @SimPriorYearRate <> 0
		BEGIN
		INSERT mnepto.AccrualSummary
		        ( CompanyNumber ,
		          EmployeeNumber ,
		          Year ,
		          GroupIdentifier ,
		          EffectiveWorkDays ,
		          EffectiveStartDate ,
		          EligibleStatus ,
		          AccumulatedHours ,
		          PrevCarryOverPTOHours ,
		          AccruedPTOHours ,
		          UsedPTOHours ,
		          RunDate
		        )
		SELECT
			CompanyNumber
		,	EmployeeNumber
		,	Year-1
		,   GroupId	
		,	@empcurEmployedDays
		,	@empcurEffectiveStartDate
		,	'I'
		,	@empcurReportedHours*@SimPriorYearRate
		,	0
		,	CASE 
				WHEN @MaxAccrual > 0 AND (((@empcurReportedHours*@SimPriorYearRate)/@AccrualSet)*@AccrualRatePerSet) > @MaxAccrual THEN @MaxAccrual
				ELSE ((@empcurReportedHours*@SimPriorYearRate)/@AccrualSet)*@AccrualRatePerSet
			END
		,	0
		,	GETDATE()
		FROM	
			mnepto.TimeCardAggregateView
		WHERE
			GroupId=@GroupIdentifier
		AND EmployeeNumber = @empcurEmployeeNumber
		AND CompanyNumber = @empcurCompanyNumber
		GROUP BY
			CompanyNumber
		,	EmployeeNumber
		,   GroupId			
		,	Year
		END

		--Add People with no submissions
		INSERT mnepto.AccrualSummary
        ( CompanyNumber ,
          EmployeeNumber ,
          Year ,
          GroupIdentifier ,
          EffectiveWorkDays ,
          EffectiveStartDate ,
          EligibleStatus ,
          AccumulatedHours ,
          PrevCarryOverPTOHours ,
          AccruedPTOHours ,
          UsedPTOHours ,
          RunDate
        )		
		SELECT
			@empcurCompanyNumber
		,	@empcurEmployeeNumber	
		,	@currYear
		,	@GroupIdentifier
		,	@empcurEmployedDays
		,	@empcurEffectiveStartDate
		,	@empcurEligible
		,	@empcurReportedHours
		,	0
		,	0
		,	0
		, GETDATE()
		FROM
			mnepto.Personnel p
		WHERE
			p.CompanyNumber=@empcurCompanyNumber
		AND p.EmployeeNumber=@empcurEmployeeNumber
		AND	CAST(@empcurCompanyNumber AS VARCHAR(10)) + '.' + CAST(@empcurEmployeeNumber AS VARCHAR(10)) + '.' + CAST(@GroupIdentifier AS VARCHAR(10))
		NOT IN ( 
			SELECT DISTINCT CAST(CompanyNumber AS VARCHAR(10)) + '.' + CAST(EmployeeNumber AS VARCHAR(10)) + '.' + CAST(GroupIdentifier AS VARCHAR(10)) 
			FROM mnepto.AccrualSummary 
		)
						
		--Update Current Used Hours
		
		UPDATE mnepto.AccrualSummary SET 
			UsedPTOHours=UsedHours
		FROM 
		(
		SELECT
			CompanyNumber
		,	EmployeeNumber
		,	Year
		,   GroupId	
		,	@empcurEmployedDays AS EmployedDays
		,	@empcurEffectiveStartDate AS EffectiveStartDate
		,	@empcurEligible AS Eligible		
		,	SUM(TotalHours) AS UsedHours
		,	GETDATE() AS RunDate
		FROM	
			mnepto.TimeCardAggregateView
		WHERE
			OtherHoursType= @UseIdentifier
		AND EmployeeNumber = @empcurEmployeeNumber
		AND CompanyNumber = @empcurCompanyNumber
		GROUP BY
			CompanyNumber
		,	EmployeeNumber
		,   GroupId			
		,	Year		
		) tblUsed
		WHERE
			mnepto.AccrualSummary.CompanyNumber=tblUsed.CompanyNumber
		AND mnepto.AccrualSummary.EmployeeNumber=tblUsed.EmployeeNumber
		AND mnepto.AccrualSummary.Year=tblUsed.YEAR
		AND mnepto.AccrualSummary.GroupIdentifier=@GroupIdentifier

		--SELECT * FROM mnepto.AccrualSummary WHERE EmployeeNumber=@empcurEmployeeNumber		
		UPDATE 	mnepto.AccrualSummary 
		SET PrevCarryOverPTOHours=
		COALESCE((
			SELECT (PrevCarryOverPTOHours+AccruedPTOHours)-UsedPTOHours 
			FROM mnepto.AccrualSummary
			WHERE GroupIdentifier=@GroupIdentifier
			AND EmployeeNumber = @empcurEmployeeNumber
			AND CompanyNumber = @empcurCompanyNumber
			AND Year=@prevYear
		),0)
		WHERE
			CompanyNumber=@empcurCompanyNumber
		AND EmployeeNumber=@empcurEmployeeNumber
		AND GroupIdentifier=@GroupIdentifier
		AND Year=@currYear

		--Check Max Accrual
		UPDATE mnepto.AccrualSummary
		SET AccruedPTOHours=
			CASE
				WHEN @MaxAccrual > 0 AND ( PrevCarryOverPTOHours + AccruedPTOHours ) > @MaxAccrual THEN @MaxAccrual-PrevCarryOverPTOHours
				ELSE AccruedPTOHours
		END
		
		-- Run based on on inputparamter.  Dont need to run on trigger fires or other action where the data has alredy been processed.
		-- Also used in debugging to only update data without doing DNN Account management.
		IF @SyncDNNAccount <> 0
		BEGIN
			PRINT 'Do DNN Sync'
			EXEC [mnepto].[mspSyncDNNAccounts] @empcurEmployeeNumber,@defaultDNNEmail,@SyncDNNAccount
		END
					
		FETCH empcur INTO
			@empcurCompanyNumber
		,	@empcurEmployeeNumber
		,	@empcurEmployeeName
	END
	
	CLOSE empcur
	DEALLOCATE empcur
		
	--SELECT
	--	p.CompanyNumber
	--,	p.EmployeeName
	--,	p.EmployeeExemptClassification	
	--,	tca.Year
	--,	tca.*
	--FROM 
	--	mnepto.Personnel p LEFT OUTER JOIN
	--	mnepto.TimeCardAggregateView tca ON
	--		p.CompanyNumber=tca.CompanyNumber
	--	AND p.EmployeeNumber=tca.EmployeeNumber
	--WHERE
	--(	tca.GroupId = @GroupIdentifier
	--OR  tca.OtherHoursType = @UseIdentifier )
	--AND	( p.EmployeeNumber=@EmployeeNumber OR @EmployeeNumber IS NULL )	
		

	FETCH tcur INTO 
		@GroupName
	,	@GroupIdentifier
	,	@UseIdentifier
	,	@GroupEffectiveDate
	,	@EligibleWorkDays	
	,	@EligibleWorkDaysLegacyWaiver
	,	@EligibleWorkHours	
	,	@EligibleWorkHoursAnnual
	,	@AllowedGapInService 
	,	@AccrualRatePerSet
	,	@AccrualSet			
	,	@MaxAccrual	
	,	@MaxAccrualUse

END 

CLOSE tcur
DEALLOCATE tcur


SELECT * FROM mnepto.AccrualSummary 
WHERE
	(GroupIdentifier=@GroupIdentifier OR @GroupIdentifier IS NULL)
AND (EmployeeNumber=@EmployeeNumber OR @EmployeeNumber IS NULL)
ORDER BY 1,2

GO


EXEC [mnepto].mspRecalculateAccruals
	@EmployeeNumber = null
,	@GroupIdentifier ='66'
,	@DoRefresh = 0
,	@SyncDNNAccount =0
,	@defaultDNNEmail = ''
,	@SimPriorYearRate=0
GO



/*
DECLARE @loop int
DECLARE @sdtwe SMALLDATETIME
DECLARE @dtwe NUMERIC(8,0)
DECLARE @hrs  int
SELECT @sdtwe='6/1/2014', @loop = 1, @hrs = 0

WHILE @loop <=20
begin

SELECT 
	@dtwe = CAST(CONVERT(VARCHAR(8),DATEADD(day,(@loop * 7),@sdtwe),112) AS NUMERIC(8,0))
,	@hrs = CASE (@loop % 5 )
			WHEN 0 THEN 10 
			ELSE 15
		   END

PRINT @dtwe
INSERT mnepto.TimeCardManualEntries (CompanyNumber,EmployeeNumber,EmployeeName,WeekEnding,GroupID,RegularHours,OvertimeHours,OtherHours,OtherHoursType,InitialLoad)
SELECT 1,68221,'BILL OREBAUGH',@dtwe,66,@hrs,0,0,'',0

SELECT @loop=@loop+1
END


INSERT mnepto.TimeCardManualEntries (CompanyNumber,EmployeeNumber,EmployeeName,WeekEnding,GroupID,RegularHours,OvertimeHours,OtherHours,OtherHoursType,InitialLoad)
SELECT 1,68221,'BILL OREBAUGH',20140418,66,40,0,0,'',0

--DELETE mnepto.TimeCardManualEntries WHERE EmployeeNumber=68221

select CAST(CONVERT(VARCHAR(8),DATEADD(day,(1 * 7),'6/1/2014'),112) AS NUMERIC(8,0))

*/