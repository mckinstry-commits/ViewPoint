IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE type='U' AND name='mckPTOAccrualSettings')
BEGIN
	create TABLE mckPTOAccrualSettings
	(
		GroupIdentifier		VARCHAR(3)	NOT NULL
	,	UseIdentifier		VARCHAR(3)	NOT NULL
	,	EligibleWorkDays	INT			NOT NULL
	,	EligibleWorkHours	INT			NOT NULL
	,	AllowedGapInService	INT			NOT NULL
	,	AccrualRatePerSet	INT			NOT NULL
	,	AccrualSet			INT			NOT NULL
	,	MaxAccrual			INT			NOT null
	)

	INSERT mckPTOAccrualSettings SELECT '38','38',90,240,180,1,30,40
END