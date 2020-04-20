SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************
  Purpose:  
	List Leave requests and associated approvers

	NOTE:
	This view was written remove the SQL from Crystal report
	PR Crew Timesheet Entry List and apply the Nolock option 
	in SQL Server to advoid data base contention issues.
		
  Maintenance Log:
	Coder	Date	Issue#	Description of Change
	CWirtz	2/20/08	125224	New
********************************************************************/
CREATE  view [dbo].[vrvHRLeaveApprovers]


 as


 SELECT 'Primary' as RecType,RequestApprover=HRAG.PriAppvr,RequestApproverLastName=HRRMPrimary.LastName,
		RequestApproverFirstName=HRRMPrimary.FirstName,RequestApproverMiddleName=HRRMPrimary.MiddleName,
		RequestApproverSortName=HRRMPrimary.SortName,HRES.HRCo,HRES.HRRef,HRES.Date,HRES.ScheduleCode,HRES.Seq,
		HRES.Hours,HRES.Status,HRES.RequesterComment,HRES.ApproverComment,HRES.Approver,HRCM.Type as HRCMType,
		HRCM.Description as HRCMDescription,HRCM.PTOTypeYN,HRCM.PRLeaveCode,HRRM.LastName as ResourceLastName,
		HRRM.FirstName as ResourceFirstName,HRRM.MiddleName as ResourceMiddleName,HRRM.SortName,HRAG.PTOAppvrGrp,
		HRAG.AppvrGrpDesc,HRAG.PriAppvr,HRAG.SecAppvr,HRRMPrimary.LastName as LastNamePrimary,
		HRRMPrimary.FirstName as FirstNamePrimary,HRRMPrimary.MiddleName as MiddleNamePrimary,
		HRRMSecondary.LastName as LastNameSecondary,HRRMSecondary.FirstName as FirtsNameSecondary,
		HRRMSecondary.MiddleName as MiddleNameSecondary,HQCO.Name
	from HRES HRES (Nolock)
	LEFT OUTER JOIN HRRM HRRM (Nolock) ON HRES.HRCo = HRRM.HRCo AND HRES.HRRef = HRRM.HRRef
	INNER JOIN HRCM HRCM (Nolock)ON HRES.HRCo =  HRCM.HRCo and HRES.ScheduleCode = HRCM.Code 
	LEFT OUTER JOIN HRAG HRAG (Nolock)ON HRRM.HRCo = HRAG.HRCo and HRRM.PTOAppvrGrp = HRAG.PTOAppvrGrp
	LEFT OUTER JOIN HRRM HRRMPrimary (Nolock)ON HRAG.HRCo = HRRMPrimary.HRCo AND HRAG.PriAppvr = HRRMPrimary.HRRef
	LEFT OUTER JOIN HRRM HRRMSecondary (Nolock)	ON HRAG.HRCo = HRRMSecondary.HRCo AND HRAG.SecAppvr = HRRMSecondary.HRRef
	LEFT OUTER JOIN HQCO HQCO (Nolock)ON HRES.HRCo= HQCO.HQCo


Union All

 SELECT 'Secondary' as RecType,RequestApprover=HRAG.SecAppvr,RequestApproverLastName=HRRMSecondary.LastName,
		RequestApproverFirstName=HRRMSecondary.FirstName,RequestApproverMiddleName=HRRMSecondary.MiddleName,
		RequestApproverSortName=HRRMSecondary.SortName,HRES.HRCo,HRES.HRRef as HRRef,HRES.Date,
		HRES.ScheduleCode,HRES.Seq,HRES.Hours,HRES.Status,HRES.RequesterComment,HRES.ApproverComment,
		HRES.Approver,HRCM.Type as HRCMType,HRCM.Description as HRCMDescription,HRCM.PTOTypeYN,
		HRCM.PRLeaveCode,HRRM.LastName as ResourceLastName,HRRM.FirstName as ResourceFirstName,
		HRRM.MiddleName as ResourceMiddleName,HRRM.SortName,HRAG.PTOAppvrGrp,HRAG.AppvrGrpDesc,HRAG.PriAppvr,HRAG.SecAppvr,
		HRRMPrimary.LastName as LastNamePrimary,HRRMPrimary.FirstName as FirstNamePrimary,
		HRRMPrimary.MiddleName as MiddleNamePrimary,HRRMSecondary.LastName as LastNameSecondary,
		HRRMSecondary.FirstName as FirtsNameSecondary,HRRMSecondary.MiddleName as MiddleNameSecondary,HQCO.Name
	from HRES HRES (Nolock)
	LEFT OUTER JOIN HRRM HRRM (Nolock)ON HRES.HRCo = HRRM.HRCo AND HRES.HRRef = HRRM.HRRef
	INNER JOIN HRCM HRCM (Nolock)ON HRES.HRCo =  HRCM.HRCo and HRES.ScheduleCode = HRCM.Code
	LEFT OUTER JOIN HRAG HRAG (Nolock)ON HRRM.HRCo = HRAG.HRCo and HRRM.PTOAppvrGrp = HRAG.PTOAppvrGrp
	INNER JOIN HRRM HRRMPrimary (Nolock)ON HRAG.HRCo = HRRMPrimary.HRCo AND HRAG.PriAppvr = HRRMPrimary.HRRef
	INNER JOIN HRRM HRRMSecondary (Nolock)ON HRAG.HRCo = HRRMSecondary.HRCo AND HRAG.SecAppvr = HRRMSecondary.HRRef
	LEFT OUTER JOIN HQCO HQCO (Nolock)ON HRES.HRCo= HQCO.HQCo

GO
GRANT SELECT ON  [dbo].[vrvHRLeaveApprovers] TO [public]
GRANT INSERT ON  [dbo].[vrvHRLeaveApprovers] TO [public]
GRANT DELETE ON  [dbo].[vrvHRLeaveApprovers] TO [public]
GRANT UPDATE ON  [dbo].[vrvHRLeaveApprovers] TO [public]
GRANT SELECT ON  [dbo].[vrvHRLeaveApprovers] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvHRLeaveApprovers] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvHRLeaveApprovers] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvHRLeaveApprovers] TO [Viewpoint]
GO
