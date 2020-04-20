SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspHRAccidentTrackingItemGet]
/************************************************************
* CREATED:     SDE 6/5/2006
* MODIFIED:    chs	9/28/06
*
* USAGE:
*   Returns the HR Resource Accident Tracking based on the HRCo and HRRef
*	Joins HRCM for Accident Description
*	Joins HRAT for Accident Details
*	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    HRCo, HRRef        
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(@HRCo bCompany, @HRRef int,
	@KeyID int = Null)
AS
	SET NOCOUNT ON;

select 
	a.HRCo, a.Accident, a.Seq, a.AccidentType, a.HRRef, 
	a.EMCo, a.Equipment, a.PreventableYN, a.Type, 
	a.IllnessInjury, a.IllnessType, a.FatalityYN, a.DeathDate, 
	a.HospitalYN, a.Hospital, a.HazMatYN, a.MSDSYN, 
	a.ClaimCloseDate, a.MSDSDesc, a.DOTReportableYN, a.AccidentCode, 
	a.Supervisor, a.ProjManager, a.ObjSubCause, 
	a.Cause, a.IllnessInjuryDesc, a.FirstAidDesc, a.Activity, 
	a.ThirdPartyName, a.ThirdPartyAddress, a.ThirdPartyCity, 
	a.ThirdPartyState, a.ThirdPartyZip, a.ThirdPartyPhone, 
	a.WorkersCompYN, a.WorkerCompClaim, a.Notes, a.ClaimEstimate, 
	a.AttendingPhysician, a.OSHALocation, a.EmergencyRoomYN, 
	a.HospOvernightYN, a.EmplStartTime, a.HistSeq, a.JobExpyr, 
	a.MineExpyr, a.TotalExpyr, a.JobExpwk, a.MineExpwk, 
	a.TotalExpwk, a.OSHA200Illness, 
	
	case a.Type 
		when 'O' then 'OSHA' 
		when 'M' then 'MSHA' 
		when 'F' then 'First Aid' 
		when 'N' then 'None' 
		end as 'AccidentTypeDesc',
	
	c.Description, 
	t.AccidentDate, t.AccidentTime, t.EmployerPremYN, t.JobSiteYN, 
	t.JCCo,t.Job, t.PhaseGroup, t.Phase, t.ReportedBy, 
	t.DateReported, t.TimeReported, t.Location, t.ClosedDate, 
	t.CorrectiveAction, t.Witness1, t.Witness2, 
	t.UniqueAttchID, t.MSHAID, t.MineName,
	
	substring(a.IllnessInjuryDesc, 1, 90) as 'IllnessInjuryDescTrunc',
	substring(a.Cause, 1, 90) as 'CauseTrunc',
	a.KeyID

from HRAI a with (nolock)
 	left join HRCM c with (nolock) on a.AccidentCode = c.Code and a.HRCo = c.HRCo and c.Type='A'
	left join HRAT t with (nolock) on a.HRCo = t.HRCo and a.Accident = t.Accident

where a.HRCo = @HRCo and a.HRRef = @HRRef --and a.AccidentType = 'R'
and a.KeyID = IsNull(@KeyID, a.KeyID)




GO
GRANT EXECUTE ON  [dbo].[vpspHRAccidentTrackingItemGet] TO [VCSPortal]
GO
