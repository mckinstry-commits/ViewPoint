SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--drop proc brptEMMeterVsRev
CREATE       proc [dbo].[brptEMMeterVsRev]
(@emco bCompany, @begMth bMonth='01/01/1950', @endMth bMonth='01/01/2050', @begEquip varchar(10)='', @endEquip varchar(10)='zzzzzzzzzz', @MoDetails varchar(1)='Y')
 /*Created by:  11/11/99 Laurie Colter   'MR'=Meter Readings EMMR table   'RD'=Revenue Details EMRD*/ 
/* Modified by:  NF 11/11/04   Issue 25900 Added with(nolock) to the from and join statements 
*					TRL 05/13/10	  Issue 137147 replaced EMMR with brvEMMR
*
 */

as

create table #EMMeterVsRev
(EMCo  tinyint null,
RecordType  Varchar(2) null,
Mth  smalldatetime null,
Trans  int null,
BatchId  int null,
InUseBatchID  int null,
Source char(10) null,
Equipment    varchar(10) null,
EMGroup   tinyint null,
RevCode   varchar(10) null,
TransType  varchar(10) null,
RDPostDate   smalldatetime null,
RDActualDate   smalldatetime null,
JCCo  tinyint null,
Job  varchar(10) null,
PhaseGroup  tinyint null,
Phase  varchar(20) null,
JCCT  tinyint null,
PRCo   tinyint null,
Employee  numeric (6)  null,
GLCo  tinyint null,
RevGL  char(20) null,
ExpGLCompany  tinyint null,
ExpGLAcct  char(20) null,
Memo  varchar(30) null,
Category  varchar(10) null,
MeterTrans  int null,
RDOdoRead   numeric (12,2) null, 
RDPrevOdoRead  numeric (12,2) null,
RDHrRead  numeric (12,2) null,
RDPrevHrRead  numeric (12,2) null,
RDUnitMeasure   varchar(3) null,
RDWkUnits  numeric (12,2) null,
RDTimeUnitMeasure   varchar(3) null,
RDTimeUnits  numeric (12,2) null,
ActualUnits numeric(12,2)null,
RDDollars  numeric (12,2) null,
RDRevRate numeric (12,2) null,
RDUsedOnEquipCo   tinyint null,
RDUsedOnEquipGrp   tinyint null,
RDUsedOnEquipment   varchar(10) null,
RDUsedOnCompType   varchar(10) null,
RDUsedOnComp   varchar(10) null, 
CostTrans   int null,
CostCode  varchar(10) null,
CostType  tinyint null,
WorkOrder  varchar(10) null,
WOItem   smallint null,
MSCompany   tinyint null,
MSTrans   int null,
FromLocation   varchar(10) null,
CustomerGroup   tinyint null,
Customer   int null,
INCompany   tinyint null,
ToLocation   varchar(10) null,
SO   varchar(10) null,
SOItem  smallint null,
MRPostingDate   smalldatetime null,
MRReadingDate   smalldatetime null,
MRPrevHrMeter  numeric (12,2) null,
MRCurrHrMeter  numeric (12,2) null,
MRPrevTotalHrMeter  numeric (12,2) null,
MRCurrTotalHrMeter  numeric (12,2) null,
MRHours  numeric (12,2) null,
MRPrevOdo  numeric (12,2) null,
MRCurrOdo  numeric (12,2) null,
MRPrevTotalOdo  numeric (12,2) null,
MRCurrTotalOdo  numeric (12,2) null,
MRMiles  numeric (12,2) null)

set nocount off

/*Insert EMMR- Meter readings*/
insert into #EMMeterVsRev
(RecordType, EMCo, Mth, Trans, BatchId, InUseBatchID, Source, Equipment, MRPostingDate, MRReadingDate, 
MRPrevHrMeter, MRCurrHrMeter, MRPrevTotalHrMeter,MRCurrTotalHrMeter, MRHours, 
MRPrevOdo, MRCurrOdo, MRPrevTotalOdo, MRCurrTotalOdo,MRMiles)

Select 'MR',EMCo, ReadingDateMth, EMTrans, BatchId, InUseBatchID, Source,Equipment, PostingDate,ReadingDate, 
PreviousHourMeter = CurrentHourMeter-[Hours], CurrentHourMeter, PreviousTotalHourMeter=CurrentTotalHourMeter-[Hours], CurrentTotalHourMeter, [Hours], 
PreviousOdometer=CurrentOdometer-Miles, CurrentOdometer, PreviousTotalOdometer=CurrentTotalOdometer-Miles, CurrentTotalOdometer,Miles
From dbo.brvEMMR with(nolock)
where EMCo=@emco and Equipment>=@begEquip and Equipment<=@endEquip and ReadingDateMth>=@begMth and ReadingDateMth<=@endMth 

/*Insert EMRD - Revenue detail*/
insert into #EMMeterVsRev
(RecordType, EMCo, Mth, Trans, BatchId, InUseBatchID, Source, Equipment, EMGroup, RevCode, TransType, RDPostDate, RDActualDate, 
JCCo, Job, PhaseGroup, Phase, JCCT, PRCo, Employee, GLCo, RevGL, ExpGLCompany, ExpGLAcct, Memo, Category, MeterTrans, RDOdoRead, 
RDPrevOdoRead, RDHrRead, RDPrevHrRead, RDUnitMeasure, RDWkUnits, RDTimeUnitMeasure, RDTimeUnits,ActualUnits, RDDollars, RDRevRate, 
RDUsedOnEquipCo, RDUsedOnEquipGrp, RDUsedOnEquipment, RDUsedOnCompType, RDUsedOnComp, CostTrans, CostCode, CostType, 
WorkOrder, WOItem, MSCompany, MSTrans, FromLocation, CustomerGroup, Customer, INCompany, ToLocation)

Select 'RD', EMRD.EMCo, EMRD.Mth, EMRD.Trans, EMRD.BatchID, EMRD.InUseBatchID, EMRD.Source, EMRD.Equipment, EMRD.EMGroup, 
EMRD.RevCode, EMRD.TransType, EMRD.PostDate, EMRD.ActualDate, EMRD.JCCo, EMRD.Job, EMRD.PhaseGroup, EMRD.JCPhase, EMRD.JCCostType, 
EMRD.PRCo, EMRD.Employee, EMRD.GLCo, EMRD.RevGLAcct, EMRD.ExpGLCo, EMRD.ExpGLAcct, EMRD.Memo, EMRD.Category, EMRD.MeterTrans, 
EMRD.OdoReading, EMRD.PreviousOdoReading, EMRD.HourReading, EMRD.PreviousHourReading, EMRD.UM, EMRD.WorkUnits, EMRD.TimeUM, 
EMRD.TimeUnits,ActualTimeUnits = IsNull(EMRD.TimeUnits,0) * IsNull(EMRC.HrsPerTimeUM,0),
EMRD.Dollars, EMRD.RevRate, EMRD.UsedOnEquipCo, EMRD.UsedOnEquipGroup, EMRD.UsedOnEquipment, EMRD.UsedOnComponentType, 
EMRD.UsedOnComponent, EMRD.EMCostTrans, EMRD.EMCostCode, EMRD.EMCostType, EMRD.WorkOrder, EMRD.WOItem, EMRD.MSCo, EMRD.MSTrans,
EMRD.FromLoc, EMRD.CustGroup, EMRD.Customer, EMRD.INCo, EMRD.ToLoc
From dbo.EMRD with(nolock)
Inner Join dbo.EMRC with(nolock) On  EMRD.EMGroup = EMRC.EMGroup and EMRD.RevCode = EMRC.RevCode
where EMRD. EMCo=@emco and EMRD.Equipment>=@begEquip and EMRD.Equipment<=@endEquip 
and EMRD.Mth>=@begMth and EMRD.Mth<=@endMth and EMRC.Basis='H'

Select a.*, HQCO.HQCo, CompanyName=HQCO.Name, EMDescription=EMEM.Description, PRLastName=PREH.LastName, PRFirstName=PREH.FirstName, PRMidName=PREH.MidName,
JobDesc=JCJM.Description

From #EMMeterVsRev a with(nolock)
join dbo.HQCO with(nolock) on HQCO.HQCo =a.EMCo
join dbo.EMEM with(nolock) on EMEM.EMCo=a.EMCo and EMEM.Equipment =a.Equipment
left outer join dbo.PREH with(nolock) on PREH.PRCo=a.PRCo and PREH.Employee=a.Employee
left outer join dbo.JCJM with(nolock) on JCJM.JCCo=a.JCCo and JCJM.Job=a.Job
where a.EMCo=@emco and a.Mth >= @begMth and a.Mth<=@endMth and a.Equipment >= @begEquip and a.Equipment<= @endEquip

GO
GRANT EXECUTE ON  [dbo].[brptEMMeterVsRev] TO [public]
GO
