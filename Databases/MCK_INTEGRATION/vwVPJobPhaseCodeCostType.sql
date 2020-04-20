USE [MCK_INTEGRATION]
GO

/****** Object:  View [dbo].[vwVPJobPhaseCodeCostType]    Script Date: 12/11/2014 9:42:58 AM ******/
DROP VIEW [dbo].[vwVPJobPhaseCodeCostType]
GO

CREATE view [dbo].[vwVPJobPhaseCodeCostType]
as
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
,	COALESCE(jobphases.Description,phasemaster.Description,jobphases.Phase) as JobPhaseDescription
,	COALESCE(phasemaster.Description, jobphases.Description, jobphases.Phase) AS PhaseMasterDescription
,	jobphasecosttype.ActiveYN AS PhaseActive
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
, jobmaster.udDateChanged as UpdatedDate
, isnull(jobphasecosttype.udDateChanged,jobphasecosttype.udDateCreated) as CreatedDate
, CASE
	WHEN jobphasecosttype.SourceStatus='J' THEN 'Y'
	WHEN jobphasecosttype.SourceStatus='I' AND jobphasecosttype.InterfaceDate IS NOT NULL THEN 'Y'
	ELSE 'N'
  END AS PhaseIsInterfacedYN
, jobphasecosttype.SourceStatus
, jobphasecosttype.InterfaceDate
from
	Viewpoint.dbo.JCJM jobmaster LEFT OUTER join
	Viewpoint.dbo.JCJP jobphases on
		jobmaster.JCCo=jobphases.JCCo
	and jobmaster.Job=jobphases.Job LEFT OUTER JOIN
	Viewpoint.dbo.JCPM phasemaster ON
		jobphases.PhaseGroup=phasemaster.PhaseGroup
	AND LEFT(jobphases.Phase,10)=LEFT(phasemaster.Phase,10) 
	LEFT OUTER JOIN
	Viewpoint.dbo.JCCH jobphasecosttype on
		jobphases.JCCo=jobphasecosttype.JCCo
	and jobphases.Job=jobphasecosttype.Job
	and jobphases.PhaseGroup=jobphasecosttype.PhaseGroup
	and jobphases.Phase=jobphasecosttype.Phase LEFT OUTER join
	Viewpoint.dbo.JCCT costtype on
		jobphasecosttype.PhaseGroup=costtype.PhaseGroup
	and jobphasecosttype.CostType=costtype.CostType	
where jobmaster.JCCo in ( 1,20,60)
go

GRANT SELECT ON [vwVPJobPhaseCodeCostType] TO PUBLIC
go


