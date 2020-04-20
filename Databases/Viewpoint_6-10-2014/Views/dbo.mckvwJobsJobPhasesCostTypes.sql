SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[mckvwJobsJobPhasesCostTypes]
AS
	select
		jobmaster.JCCo 
	,	jobmaster.Job
	,	REPLACE((cast(jobmaster.Job as CHAR(10)) + ':' + cast(jobmaster.JCCo as CHAR(3))),' ','0') as McKJobNo
	,	jobmaster.Description as JobDescription
	,	jobmaster.JobStatus
	,	CASE jobmaster.JobStatus
			WHEN 0 THEN 'Pending'
			WHEN 1 THEN 'Open'
			WHEN 2 THEN 'Soft Close'
			WHEN 3 THEN 'Hard Close'
			ELSE 'Unknown'
		end AS JobStatusDescription
	,	jobphases.PhaseGroup
	,	jobphases.Phase
	,	REPLACE(CAST(COALESCE(jobphases.Phase,'0000-0000-000000-000') AS CHAR(20)),' ','0') AS McKPhase
	,	COALESCE(jobphases.Description,'<Blank>') as JobPhaseDescription
	,	COALESCE(phasemaster.Description, '<Blank>') AS PhaseMasterDescription
	,	jobphases.ActiveYN AS PhaseActive
	,	jobphasecosttype.CostType AS  PhaseCostType
	,	costtype.Abbreviation AS PhaseCostTypeCode
	,	costtype.Description as PhaseCostTypeDescription
	, jobmaster.MailAddress
	, jobmaster.MailAddress2
	, jobmaster.MailCity
	, jobmaster.MailState
	, jobmaster.MailZip
	, jobmaster.JobPhone
	, jobmaster.ContactCode
	from
		dbo.JCJM jobmaster LEFT OUTER join
		dbo.JCJP jobphases on
			jobmaster.JCCo=jobphases.JCCo
		and jobmaster.Job=jobphases.Job LEFT OUTER JOIN
		dbo.JCPM phasemaster ON
			jobphases.PhaseGroup=phasemaster.PhaseGroup
		AND LEFT(jobphases.Phase,10) + '      -   '=phasemaster.Phase LEFT OUTER JOIN
		dbo.JCCH jobphasecosttype on
			jobphases.JCCo=jobphasecosttype.JCCo
		and jobphases.Job=jobphasecosttype.Job
		and jobphases.PhaseGroup=jobphasecosttype.PhaseGroup
		and jobphases.Phase=jobphasecosttype.Phase LEFT OUTER join
		dbo.JCCT costtype on
			jobphasecosttype.PhaseGroup=costtype.PhaseGroup
		and jobphasecosttype.CostType=costtype.CostType
GO
GRANT SELECT ON  [dbo].[mckvwJobsJobPhasesCostTypes] TO [public]
GRANT INSERT ON  [dbo].[mckvwJobsJobPhasesCostTypes] TO [public]
GRANT DELETE ON  [dbo].[mckvwJobsJobPhasesCostTypes] TO [public]
GRANT UPDATE ON  [dbo].[mckvwJobsJobPhasesCostTypes] TO [public]
GO
