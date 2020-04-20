SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[HRAITypeR]
AS
SELECT     TOP (100) PERCENT HRCo, Accident, Seq, AccidentType, HRRef, EMCo, Equipment, PreventableYN, Type, IllnessInjury, IllnessType, FatalityYN, 
                      DeathDate, HospitalYN, Hospital, HazMatYN, MSDSYN, ClaimCloseDate, MSDSDesc, DOTReportableYN, AccidentCode, Supervisor, ProjManager, 
                      ObjSubCause, Cause, IllnessInjuryDesc, FirstAidDesc, Activity, ThirdPartyName, ThirdPartyAddress, ThirdPartyCity, ThirdPartyState, ThirdPartyZip, 
                      ThirdPartyPhone, WorkersCompYN, WorkerCompClaim, Notes, ClaimEstimate, AttendingPhysician, OSHALocation, EmergencyRoomYN, 
                      HospOvernightYN, EmplStartTime, HistSeq, JobExpyr, MineExpyr, TotalExpyr, JobExpwk, MineExpwk, TotalExpwk, OSHA200Illness,UniqueAttchID, KeyID
FROM         dbo.bHRAI WITH (nolock)
WHERE     (AccidentType = 'R') AND (HRRef IS NOT NULL)
ORDER BY HRCo, Accident, HRRef


GO
GRANT SELECT ON  [dbo].[HRAITypeR] TO [public]
GRANT INSERT ON  [dbo].[HRAITypeR] TO [public]
GRANT DELETE ON  [dbo].[HRAITypeR] TO [public]
GRANT UPDATE ON  [dbo].[HRAITypeR] TO [public]
GO
