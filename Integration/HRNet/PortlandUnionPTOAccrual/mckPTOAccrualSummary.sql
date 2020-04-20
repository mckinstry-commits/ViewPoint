/*
TODO:  Add column to accomodate carryover from previous year.
*/
DROP TABLE mckPTOAccrualSummary
IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE type='U' AND name='mckPTOAccrualSummary')
BEGIN
CREATE TABLE mckPTOAccrualSummary
(
	CompanyNumber		int				not null
,	EmployeeNumber		int				not null
,	EmployeeName		varchar(50)		not null
,	RunDate				datetime		not null
,	EffectiveWorkDays	int				null
,	EffectiveStartDate	datetime		null
,	GroupIdentifier		varchar(3)		not null
,	[Year]				char(4)			not null
,	EligibleStatus		varchar(30)		not null
,	AccumulatedHours	DECIMAL(18,3)	not null
,	AccruedPTOHours		DECIMAL(4,2)	not NULL
,	UsedPTOHours		DECIMAL(4,2)	not null
,	AvailablePTOHours	DECIMAL(4,2)	not null
)
END