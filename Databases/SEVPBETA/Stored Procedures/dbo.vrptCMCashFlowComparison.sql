SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vrptCMCashFlowComparison]
	@BeginDate smalldatetime = NULL, 
	@EndDate smalldatetime = NULL, 
	@CMCompany int = NULL,
	@CMAcctList varchar(500) = NULL
AS

DECLARE @BeginDatePrevious smalldatetime
DECLARE @EndDatePrevious smalldatetime
DECLARE @APFloatGainLoss1 float
DECLARE @APFloatGainLoss2 float
DECLARE @PRFloatGainLoss1 float
DECLARE @PRFloatGainLoss2 float
DECLARE @OutstandindDepositGainLoss1 float
DECLARE @OutstandindDepositGainLoss2 float

SET @BeginDatePrevious = DATEADD(Month, -1, @BeginDate)
SET @EndDatePrevious = DATEADD(Month, -1, @EndDate)

CREATE TABLE #Result (
	APFloatGainLoss float,
	PRFloatGainLoss float,
	OutstandingDepositGainLoss float,
);

CREATE TABLE #CMCashFlow1 (
	CalendarDay smalldatetime,
	LineOfCredit numeric(12,2),
	OutstandingDeposit numeric(12,2),
	FloatAccount numeric(12,2),
	APFloat numeric(12,2),
	PRFloat numeric(12,2),
	ClearedDeposit numeric(12,2),
	Cash numeric(12,2)
);

CREATE TABLE #CMCashFlow2 (
	CalendarDay smalldatetime,
	LineOfCredit numeric(12,2),
	OutstandingDeposit numeric(12,2),
	FloatAccount numeric(12,2),
	APFloat numeric(12,2),
	PRFloat numeric(12,2),
	ClearedDeposit numeric(12,2),
	Cash numeric(12,2)
);


INSERT INTO #CMCashFlow1  
Exec vrptCMCashFlow @BeginDate,
@EndDate,
@CMCompany,
@CMAcctList

INSERT INTO #CMCashFlow2  
Exec vrptCMCashFlow @BeginDatePrevious,
@EndDatePrevious,
@CMCompany,
@CMAcctList

SELECT @APFloatGainLoss1 = SUM(APFloat)
FROM #CMCashFlow1 

SELECT @APFloatGainLoss2 = SUM(APFloat)
FROM #CMCashFlow2 

SELECT @PRFloatGainLoss1 = SUM(PRFloat)
FROM #CMCashFlow1 

SELECT @PRFloatGainLoss2 = SUM(PRFloat)
FROM #CMCashFlow2 

SELECT @OutstandindDepositGainLoss1 = SUM(OutstandingDeposit)
FROM #CMCashFlow1 

SELECT @OutstandindDepositGainLoss2 = SUM(OutstandingDeposit)
FROM #CMCashFlow2 

INSERT INTO #Result
VALUES (@APFloatGainLoss1 / NULLIF(@APFloatGainLoss2,0) * 100 - 100,
		@PRFloatGainLoss1 / NULLIF(@PRFloatGainLoss2,0) * 100 - 100,
		@OutstandindDepositGainLoss1 / NULLIF(@OutstandindDepositGainLoss2,0) * 100 - 100)

SELECT APFloatGainLoss,
		PRFloatGainLoss,
		OutstandingDepositGainLoss 
FROM #Result




GO
GRANT EXECUTE ON  [dbo].[vrptCMCashFlowComparison] TO [public]
GO
