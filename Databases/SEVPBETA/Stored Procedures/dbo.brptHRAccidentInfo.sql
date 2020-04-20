SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* fixed the @baccident to be an int instead of a varchar(10) also changed the accident to   
   be an int instead of a varchar(10) in the ALTER  table for issue #19978.  E.T.  
   I changed everything back so now all accident numbers (@baccident, @eaccident and Accident  
   are varchar(10) from issue #19978 rejection.  E.T. */  
     
   CREATE                 proc [dbo].[brptHRAccidentInfo] (@hrco bCompany, @baccident varchar(10), @eaccident varchar(10), @bseq int, @eseq int, @types char(3),  
     @IncContacts varchar(1), @IncClaims varchar(1), @IncLostDays varchar(1), @IncResource varchar(1))  
     as  
     /* put claim contact in everywhere */  
     /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0   
                        fixed : notes fields. Issue #20721 */  
     /* Mod 09/09/03 E.T. - added HRAT.MSHAID and HRAT.MineName   
        and formated EmplStartTime to be in time format */  
     /* Mod 09/16/03 E.T. - added the following fields from HRAI :  
            EmergencyRoomYN, HospOvernightYN, JobExpyr, JobExpwk,  
            MineExpyr, MineExpwk, TotalExpyr, TotalExpwk   
        Mod 11/5/04 CR Added No Locks #25907  
        Mod 8/16/07 CR removed Witness1 & Witness2 fields(from HRAT) #122707  
     
    */   
     if @types is null or RTrim(@types)=''  
     begin  
      select @types=''  
     end  
       
     create table #hraccident(  
     HRCo   tinyint  null,   
     RecordType varchar(2) null,  
     Accident  varchar(10)  null,  
     AccSeq   int null,  
     HRRef  int null,  
     EMCo  tinyint null,  
     Equipment  varchar (10) null,  
     PreventableYN char (1) null,  
     IllnessInjury  char (1) null,  
     EmplStartTime smalldatetime null,--add 3/14/02 AA  
     IllnessType  char (1) null,  
     Type char (1) null,  
     FatalityYN  char (1) null,  
     HospitalYN  char (1) null,  
     Hospital  varchar (60) null,  
     HazMatYN  char (1) null,   
     MSDSYN  char (1) null,  
     ClaimCloseDate  smalldatetime null,  
     MSDSDesc  varchar (30) null,  
     DOTReportableYN  char (1) null,  
     AccidentCode  varchar (10) null,  
     Supervisor  varchar (20) null,  
     ProjManager  varchar (20) null,  
     ObjSubCause  varchar (60) null,  
     DeathDate  smalldatetime null,  
     AccidentType  char (1) null,  
     ThirdPartyName  varchar (20) null,  
     ThirdPartyAddress  varchar (60) null,  
     ThirdPartyCity  varchar (30) null,  
     ThirdPartyState  char (2) null,   
     ThirdPartyZip  varchar (12) null,  
     ThirdPartyPhone  varchar (20) null,  
     WorkersCompYN  char (1) null,  
     WorkerCompClaim  varchar (20) null,  
     ClaimEstimate  numeric (9,0)  null,  
     AttendingPhysician  varchar (10) null,  
     OSHALocation  varchar (20) null,  
     EmergencyRoomYN char (1) null,  
     HospOvernightYN char (1) null,  
     JobExpyr int null,  
     JobExpwk int null,  
     MineExpyr int null,  
     MineExpwk int null,  
     TotalExpyr int null,  
     TotalExpwk int null,  
     HRCLSeq int null,  
     HRADSeq int null,  
     HRACSeq int null,  
     HRALSeq int null,  
     ContactSeq int null,  
     CLDate smalldatetime null,  
     ClaimContact  varchar(10) null,  
     ClaimSeq  int  null,  
     Witness  char(1) null,  
     ClaimDate smalldatetime null,  
     ClaimCost numeric(12,2)  null,   
     ClaimDeductible numeric(12,2)  null,  
     PaidAmt numeric(12,2)  null,  
     ClaimFiledYN char (1)  null,  
     ClaimPaidYN  char (1)  null,  
     DaySeq smallint  null,  
     BeginDate smalldatetime  null,  
     EndDate  smalldatetime  null,  
     LostDays  smallint  null,  
     DaysType char (1) null,  
     BodyPart varchar(10) null,  
     InjuryType varchar(10) null,  
     ContLogNotes text null,  
     LostNotes text null,  
     AccClaimNotes text null,  
     MedFacility  Varchar (20) null,  
     HRCCCountry Varchar (2) null,  
     HRAICountry Varchar (2) null,  
     HRHICountry Varchar (2) null  
  
     )  
       
     /* get the HRAI records*/  
       
     begin  
     insert into #hraccident (  
     HRCo, RecordType, Accident, AccSeq, HRRef, EMCo, Equipment, PreventableYN, IllnessInjury,EmplStartTime, --add 3/14/02 AA   
     IllnessType, Type, FatalityYN, HospitalYN, Hospital, HazMatYN, MSDSYN, ClaimCloseDate, MSDSDesc,    
     DOTReportableYN,  AccidentCode, Supervisor, ProjManager, ObjSubCause, DeathDate,  AccidentType,    
     ThirdPartyName, ThirdPartyAddress, ThirdPartyCity, ThirdPartyState, ThirdPartyZip, ThirdPartyPhone,    
     WorkersCompYN, WorkerCompClaim, ClaimEstimate, AttendingPhysician, OSHALocation,  
     EmergencyRoomYN, HospOvernightYN, JobExpyr, JobExpwk, MineExpyr, MineExpwk,  TotalExpyr, TotalExpwk)  
     select  
     HRAI.HRCo, 'AI', HRAI.Accident, HRAI.Seq, HRAI.HRRef, HRAI.EMCo, HRAI.Equipment, HRAI.PreventableYN, HRAI.IllnessInjury,HRAI.EmplStartTime,--add 3/14/02 AA    
     HRAI.IllnessType, HRAI.Type, HRAI.FatalityYN, HRAI.HospitalYN, HRAI.Hospital, HRAI.HazMatYN, HRAI.MSDSYN, HRAI.ClaimCloseDate, HRAI.MSDSDesc,    
     HRAI.DOTReportableYN, HRAI.AccidentCode, HRAI.Supervisor, HRAI.ProjManager, HRAI.ObjSubCause, HRAI.DeathDate,   
     HRAI.AccidentType,    
     HRAI.ThirdPartyName, HRAI.ThirdPartyAddress, HRAI.ThirdPartyCity, HRAI.ThirdPartyState, HRAI.ThirdPartyZip, HRAI.ThirdPartyPhone,    
     HRAI.WorkersCompYN, HRAI.WorkerCompClaim, HRAI.ClaimEstimate, HRAI.AttendingPhysician, HRAI.OSHALocation,  
     HRAI.EmergencyRoomYN, HRAI.HospOvernightYN, HRAI.JobExpyr, HRAI.JobExpwk,   
     HRAI.MineExpyr, HRAI.MineExpwk, HRAI.TotalExpyr, HRAI.TotalExpwk  
       
     from HRAI with (NOLOCK)  
     where HRAI.HRCo=@hrco and HRAI.Accident between @baccident and @eaccident and HRAI.Seq between @bseq and @eseq  
     and HRAI.AccidentType = case when @types='' then HRAI.AccidentType else @types end  
     end  
       
     /* get the Accident Contact Log */  
     if @IncContacts='Y'   
     begin  
     insert into #hraccident (HRCLSeq, HRCo, RecordType, Accident, AccSeq, ContactSeq, CLDate,   
            ClaimContact, ClaimSeq, Witness, AccidentType,  ContLogNotes)  
     select  HRCL.Seq, HRCL.HRCo, 'CL', HRCL.Accident, HRCL.Seq, HRCL.ContactSeq, HRCL.Date, HRCL.ClaimContact,   
             HRCL.ClaimSeq, HRCL.Witness, HRAI.AccidentType,  HRCL.Notes  
     from HRCL with (NOLOCK)  
     join HRAI with (NOLOCK) on HRCL.HRCo=HRAI.HRCo and HRCL.Accident=HRAI.Accident and HRCL.Seq=HRAI.Seq  
     where HRCL.HRCo=@hrco and HRCL.Accident between @baccident and @eaccident and HRCL.Seq between @bseq and @eseq  
     and HRAI.AccidentType = case when @types='' then HRAI.AccidentType else @types end  
     end  
       
     /* get the Accident Claim Log*/  
     if @IncClaims='Y'  
     begin  
     insert into #hraccident (HRACSeq, HRCo, RecordType, Accident, AccSeq, ClaimSeq, ClaimDate, ClaimContact, ClaimCost, ClaimDeductible, PaidAmt, ClaimFiledYN,   
            ClaimPaidYN, MedFacility, AccClaimNotes, AccidentType)  
     select HRAC.Seq, HRAC.HRCo, 'AC', HRAC.Accident, HRAC.Seq, HRAC.ClaimSeq, HRAC.ClaimDate, HRAC.ClaimContact, HRAC.Cost, HRAC.Deductible, HRAC.PaidAmt,   
     HRAC.FiledYN, HRAC.PaidYN, HRAC.MedFacility, HRAC.Notes, HRAI.AccidentType  
     from HRAC with (NOLOCK)  
     join HRAI with (NOLOCK) on HRAC.HRCo=HRAI.HRCo and HRAC.Accident=HRAI.Accident and HRAC.Seq=HRAI.Seq  
     where HRAC.HRCo=@hrco and HRAC.Accident between @baccident and @eaccident and HRAC.Seq between @bseq and @eseq  
     and HRAI.AccidentType = case when @types='' then HRAI.AccidentType else @types end  
     end  
       
     /* get the Accident Lost Restricted Table*/  
     if @IncLostDays='Y'  
     begin  
     insert into #hraccident (HRALSeq, HRCo, RecordType,  Accident, AccSeq, DaySeq, BeginDate, EndDate, LostDays,  
             DaysType, LostNotes, AccidentType)  
     select HRAL.Seq, HRAL.HRCo, 'AL', HRAL.Accident, HRAL.Seq, HRAL.DaySeq, HRAL.BeginDate, HRAL.EndDate,   
         HRAL.Days, HRAL.Type, HRAL.Notes, HRAI.AccidentType    
     from HRAL with (NOLOCK)  
     join HRAI with (NOLOCK) on HRAL.HRCo=HRAI.HRCo and HRAL.Accident=HRAI.Accident and HRAL.Seq=HRAI.Seq  
     where HRAL.HRCo=@hrco and HRAL.Accident between @baccident and @eaccident and HRAL.Seq between @bseq and @eseq  
     and HRAI.AccidentType = case when @types='' then HRAI.AccidentType else @types end  
     end  
       
     /* get the Accident Resource Detail*/  
     if @IncResource='Y'  
     begin  
     insert into #hraccident (HRADSeq, HRCo, RecordType,  Accident, AccSeq, BodyPart,  InjuryType, AccidentType)  
     select HRAD.Seq, HRAD.HRCo, 'AD', HRAD.Accident, HRAD.Seq, HRAD.BodyPart, HRAD.InjuryType, HRAI.AccidentType  
     from HRAD with (NOLOCK)  
     join HRAI with (NOLOCK) on HRAD.HRCo=HRAI.HRCo and HRAD.Accident=HRAI.Accident and HRAD.Seq=HRAI.Seq  
     
     where HRAD.HRCo=@hrco and HRAD.Accident between @baccident and @eaccident and HRAD.Seq between @bseq and @eseq  
     and HRAI.AccidentType = case when @types='' then HRAI.AccidentType else @types end  
     end  
       
       
     select h.HRCo, h.RecordType, h.Accident, h.AccSeq, HRAT.AccidentDate,  AccidentTime=substring(convert(varchar(19),HRAT.AccidentTime),12,8),  
     HRAT.EmployerPremYN, HRAT.JobSiteYN, HRAT.JCCo, HRAT.Job, HRAT.PhaseGroup, HRAT.Phase, HRAT.ReportedBy, HRAT.DateReported,   
     TimeReported=substring(convert(varchar(19),HRAT.TimeReported),12,8), HRAT.Location, HRAT.ClosedDate,   
     CorrectiveActionTaken=HRAT.CorrectiveAction, HRAT.MSHAID, HRAT.MineName,  
     h.AccidentType, HRAI.HRRef, h.EMCo, h.Equipment, h.PreventableYN, h.Type, h.IllnessInjury, h.IllnessType, h.FatalityYN, h.DeathDate,   
     h.HospitalYN, h.Hospital, h.HazMatYN, h.MSDSYN, h.MSDSDesc, h.ClaimCloseDate, h.DOTReportableYN, h.AccidentCode, h.Supervisor,   
     h.ProjManager, h.ObjSubCause, Cause=HRAI.Cause, IllnessInjuryDesc=HRAI.IllnessInjuryDesc,  
     FirstAidDesc=HRAI.FirstAidDesc, Activity=HRAI.Activity, h.ThirdPartyName,   
     h.ThirdPartyAddress, h.ThirdPartyCity, h.ThirdPartyState, h.ThirdPartyZip, h.ThirdPartyPhone,   
     h.WorkersCompYN, h.WorkerCompClaim,    
     h.ClaimEstimate, h.AttendingPhysician,  h.OSHALocation,  
     h.EmergencyRoomYN, h.HospOvernightYN, h.JobExpyr, h.JobExpwk,   
     h.MineExpyr, h.MineExpwk, h.TotalExpyr, h.TotalExpwk,  
     h.HRCLSeq, h.ContactSeq, ContactLogDate=h.CLDate, h.ClaimContact, h.ClaimSeq, h.Witness,   
     h.HRADSeq, h.BodyPart, h.InjuryType, h.HRACSeq,  
     h.ClaimDate,  h.ClaimCost, h.ClaimDeductible, h.PaidAmt,   
     h.ClaimFiledYN, h.ClaimPaidYN, h.MedFacility,EmplStartTime=substring(convert(varchar(19),h.EmplStartTime),12,8),--add 3/14/02   
     h.HRALSeq, h.DaySeq, h.BeginDate, h.EndDate, Days=h.LostDays, h.DaysType,   
     ClaimContactName=HRCC.Name, HRCCAddress=HRCC.Address, HRCCCity=HRCC.City, HRCCState=HRCC.State,   
     HRCCZip=HRCC.Zip, HRCCPhone=HRCC.Phone,   
     HRCCFax=HRCC.Fax, HRCCEMail=HRCC.Email, HRCCWeb=HRCC.Web_Address,  
     h.Witness,AccidentCodeDesc=HRCM#.Description, BodyPartDesc=HRCM1.Description,-- AA 4/28/02  
     InjuryTypeDesc=HRCM2.Description, AttendingPhysicianDesc=HRCC1.Name,-- AA 4/28/02  
     -- hospital ---  
     HospAddress=HRHI.Address, HospCity=HRHI.City, HospState=HRHI.State,  
     HospZip=HRHI.Zip, HospPhone=HRHI.Phone, HospEmail=HRHI.Email,   
     HRRefLName=HRRM.LastName, HRRefFName=HRRM.FirstName,CompanyName=HQCO.Name,  
     -- parameters ---  
     IncludeContacts=@IncContacts, IncludeClaims=@IncClaims, IncludeLostDays=@IncLostDays,  
     IncludeBodyParts=@IncResource, AccidentTypes=@types,  
     HRCompany=@hrco, BeginAccident=@baccident, EndAccident=@eaccident,  
    BeginSeq=@bseq, EndSeq=@eseq,   
     -- Notes ---  
     AccNotes=HRAT.Notes, AccSeqNotes=HRAI.Notes,  h.ContLogNotes, h.AccClaimNotes, h.LostNotes,  
     ClaimContNotes=HRCC.Notes, HospNotes=HRHI.Notes, HRCCCountry = HRCC.Country, HRAICountry=HRAI.Country,  
     HRHICountry=HRHI.Country  
        
       
     From HRAT with (NOLOCK)  
     Join HQCO with (NOLOCK) on HRAT.HRCo=HQCO.HQCo  
     Left join #hraccident h on h.HRCo=HRAT.HRCo and h.Accident=HRAT.Accident  
     Left join HRAI with (NOLOCK) on h.HRCo=HRAI.HRCo and h.Accident=HRAI.Accident and h.AccSeq=HRAI.Seq  
     Left join HRRM with (NOLOCK) on HRAI.HRCo=HRRM.HRCo and HRRM.HRRef=HRAI.HRRef  
     Left join HRCC with (NOLOCK) on h.HRCo=HRCC.HRCo and h.ClaimContact=HRCC.ClaimContact  
     Left join HRCC HRCC1 with (NOLOCK) on h.HRCo=HRCC1.HRCo and h.AttendingPhysician=HRCC1.ClaimContact  -- AA 4/28/02  
     Left join HRCC WIT1HRCC with (NOLOCK) on HRAT.HRCo=WIT1HRCC.HRCo and HRAT.Witness1=WIT1HRCC.ClaimContact  
     Left join HRCC WIT2HRCC with (NOLOCK) on HRAT.HRCo=WIT2HRCC.HRCo and HRAT.Witness2=WIT2HRCC.ClaimContact  
     Left join HRHI with (NOLOCK) on HRHI.HRCo=HRAI.HRCo and HRHI.Hospital=HRAI.Hospital  
     Left join HRCM HRCM# with (NOLOCK) on h.HRCo=HRCM#.HRCo and h.AccidentCode=HRCM#.Code and HRCM#.Type='A' -- AA 4/28/02  
     Left join HRCM HRCM1 with (NOLOCK) on h.HRCo=HRCM1.HRCo and h.BodyPart=HRCM1.Code and HRCM1.Type='B' -- AA 4/28/02  
     Left join HRCM HRCM2 with (NOLOCK) on h.HRCo=HRCM2.HRCo and h.InjuryType=HRCM2.Code and HRCM2.Type='I' -- AA 4/28/02  
       
     Where  
     HRAT.HRCo=@hrco and HRAT.Accident between @baccident and @eaccident and   
     ((HRAI.Seq between @bseq and @eseq) or HRAI.Seq is null)   
     and isnull(HRAI.AccidentType,'') = case when @types='' then isnull(HRAI.AccidentType,'') else @types end  
GO
GRANT EXECUTE ON  [dbo].[brptHRAccidentInfo] TO [public]
GO
