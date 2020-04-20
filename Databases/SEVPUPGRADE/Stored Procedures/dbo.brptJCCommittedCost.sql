SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[brptJCCommittedCost] (@Company as tinyint)
   as
   /* author  Jim Emery 8/1/00 */
   /* used for reconciling committed costs */
   set nocount on
   create table #CommittedCompare(
   JCCo tinyint null,
   Job char(10) null,
   PhaseGroup tinyint null,
   Phase char(20) null,
   CostType tinyint null,
   UM char(3) null,
   SLTotalCmtdUnits decimal(16,5) null,
   SLRemUnits decimal(16,5) null,
   SLTotalCmtdCost decimal(16,2) null,
   SLRemCost decimal(16,2) null,
   POTotalCmtdUnits decimal(16,5) null,
   PORemUnits decimal(16,5) null,
   POTotalCmtdCost decimal(16,2) null,
   PORemCost decimal(16,2) null,
   JCTotalCmtdUnits decimal(16,5) null,
   JCRemUnits decimal(16,5) null,
   JCTotalCmtdCost decimal(16,2) null,
   JCRemCost decimal(16,2) null)
   
   -- insert SL info
   insert into #CommittedCompare
   select SLIT.JCCo, SLIT.Job, SLIT.PhaseGroup, SLIT.Phase, SLIT.JCCType,SLIT.UM,TotalCmtdUnits=sum(CurUnits),
         RemUnits=sum(case when Status<>2 then isnull(CurUnits,0)-isnull(InvUnits,0) else 0 end),
         TotalCmtdCost=sum(CurCost), 
         RemCost=sum(case when Status<>2 then isnull(CurCost,0)-isnull(InvCost,0) else 0 end),0,0,0,0,0,0,0,0
   from SLIT
   join SLHD on SLIT.SLCo=SLHD.SLCo and SLIT.SL=SLHD.SL
   where SLIT.JCCo=@Company 
   group by SLIT.JCCo, SLIT.Job, SLIT.PhaseGroup, SLIT.Phase, SLIT.JCCType,SLIT.UM
   
   -- insert PO info
   insert into #CommittedCompare
   select  POIT.PostToCo, POIT.Job, POIT.PhaseGroup, POIT.Phase, POIT.JCCType,POIT.UM,0,0,0,0,TotalCmtdUnits=sum(CurUnits),
         RemUnits=sum(case when Status<>2 then isnull(CurUnits,0)-isnull(InvUnits,0) else 0 end),
         TotalCmtdCost=sum(CurCost), 
         RemCost=sum(case when Status<>2 then isnull(CurCost,0)-isnull(InvCost,0) else 0 end ),0,0,0,0
   from POIT
   join POHD on POIT.POCo=POHD.POCo and POIT.PO=POHD.PO
   where POIT.Job is not null and PostToCo=@Company
   group by POIT.PostToCo, POIT.Job, POIT.PhaseGroup, POIT.Phase, POIT.JCCType,POIT.UM
   
   --insert JC info
   insert into #CommittedCompare
   select JCCo, Job, PhaseGroup, Phase, CostType,null,0,0,0,0,0,0,0,0,sum(TotalCmtdUnits),sum(RemainCmtdUnits),
   sum(TotalCmtdCost), sum(RemainCmtdCost) 
   from JCCP
   where JCCo=@Company and (TotalCmtdUnits<>0 or RemainCmtdUnits<>0 or TotalCmtdCost<>0 or RemainCmtdCost<>0)
   group by JCCo, Job, PhaseGroup, Phase, CostType
   set nocount off
   select JCCo, Job, PhaseGroup, Phase, CostType, SLTotalCmtdUnits=sum(SLTotalCmtdUnits),
   	SLRemUnits=sum(SLRemUnits),SLTotalCmtdCost=sum(SLTotalCmtdCost),SLRemCost=sum(SLRemCost),
   	POTotalCmtdUnits=sum(POTotalCmtdUnits),
   	PORemUnits=sum(PORemUnits),POTotalCmtdCost=sum(POTotalCmtdCost),PORemCost=sum(PORemCost),
   	JCTotalCmtdUnits=sum(JCTotalCmtdUnits),
   	JCRemUnits=sum(JCRemUnits),JCTotalCmtdCost=sum(JCTotalCmtdCost),JCRemCost=sum(JCRemCost) 
   from #CommittedCompare
   group by JCCo, Job, PhaseGroup, Phase, CostType

GO
GRANT EXECUTE ON  [dbo].[brptJCCommittedCost] TO [public]
GO
