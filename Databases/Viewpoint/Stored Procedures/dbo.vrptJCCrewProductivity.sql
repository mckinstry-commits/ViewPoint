SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/************************************************************************
* CREATED:	HH 10/31/11 - Initial version   
* MODIFIED: 
*
* Purpose of Stored Procedure:
*	Compute for each JCCD entry its EstCost, EstHours and EstUnits by JCCo,
*   Job, PhaseGroup, Phase and CostType
*
*  Notes:
*   
*************************************************************************/

CREATE PROCEDURE [dbo].[vrptJCCrewProductivity] 
	@JCCo int = 0,
	@BeginJob varchar(255) = '',
	@EndJob varchar(255) = 'zzzzzzzzzzzzzzz',
	@BeginCrew varchar(255) = '',
	@EndCrew varchar(255) = 'zzzzzzzzzzzzzzz',
	@BeginDate smalldatetime = NULL, 
	@EndDate smalldatetime = NULL
	
AS
IF @BeginDate IS NULL
BEGIN
	SELECT @BeginDate = '1950-01-01'
END
IF @EndDate IS NULL
BEGIN
	SELECT @EndDate = '2050-12-31'
END

/* Compute EstHours, EstUnits and EstCost independant from Crew */
SELECT	JCCo
		, Job
		, PhaseGroup
		, Phase
		, CostType
		, SUM(ISNULL(EstHours,0)) as AggregatedEstHours
		, SUM(ISNULL(EstUnits,0)) as AggregatedEstUnits
		, SUM(ISNULL(EstCost,0)) as AggregatedEstCost
INTO #AggregatedEstimates
FROM JCCD
WHERE JCCo = @JCCo 
		AND Job BETWEEN @BeginJob AND @EndJob
		AND ActualDate BETWEEN @BeginDate AND @EndDate
GROUP BY JCCo
		, Job
		, PhaseGroup
		, Phase
		, CostType

/* Result dataset: Join JCCD with Crew-independant EstHours, EstUnits and EstCost */
SELECT *
FROM 
JCCD j
LEFT OUTER JOIN #AggregatedEstimates ae
	ON j.JCCo = ae.JCCo
		AND j.Job = ae.Job
		AND j.PhaseGroup = ae.PhaseGroup
		AND j.Phase = ae.Phase
		AND j.CostType = ae.CostType
WHERE j.JCCo = @JCCo 
		AND j.Job BETWEEN @BeginJob AND @EndJob
		AND j.Crew BETWEEN @BeginCrew AND @EndCrew
		AND j.ActualDate BETWEEN @BeginDate AND @EndDate
ORDER BY j.JCCo,j.Job,j.PhaseGroup,j.Phase,j.CostType,j.ActualDate
GO
GRANT EXECUTE ON  [dbo].[vrptJCCrewProductivity] TO [public]
GO
