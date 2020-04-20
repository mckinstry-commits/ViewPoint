SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[brptJCCommReconcile] (@Company as tinyint)
   as
   /* author  Jim Emery 8/1/00 */
   /* used for reconciling committed costs */
   /* Issue 25908 add with (nolock) DW 11/05/04*/
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
   select SLIT.JCCo, SLIT.Job, SLIT.PhaseGroup, SLIT.Phase, SLIT.JCCType,SLIT.UM,TotalCmtdUnits=IsNull(sum(CurUnits),0),
         RemUnits=sum(case when Status<>2 then isnull(CurUnits,0)-isnull(InvUnits,0) else 0 end),
         TotalCmtdCost=IsNull(sum(CurCost),0),
         RemCost=sum(case when Status<>2 then isnull(CurCost,0)-isnull(InvCost,0) else 0 end),0,0,0,0,0,0,0,0
   from SLIT with(nolock)
   join SLHD with(nolock) on SLIT.SLCo=SLHD.SLCo and SLIT.SL=SLHD.SL
   where SLIT.JCCo=@Company 
   group by SLIT.JCCo, SLIT.Job, SLIT.PhaseGroup, SLIT.Phase, SLIT.JCCType,SLIT.UM
   
   -- insert PO info
   insert into #CommittedCompare
   select  POIT.PostToCo, POIT.Job, POIT.PhaseGroup, POIT.Phase, POIT.JCCType,POIT.UM,0,0,0,0,TotalCmtdUnits=IsNull(sum(CurUnits),0),
         RemUnits=sum(case when Status<>2 then isnull(CurUnits,0)-isnull(InvUnits,0) else 0 end),
         TotalCmtdCost=IsNull(sum(CurCost),0), 
         RemCost=sum(case when Status<>2 then isnull(CurCost,0)-isnull(InvCost,0) else 0 end ),0,0,0,0
   from POIT with(nolock)
   join POHD with(nolock) on POIT.POCo=POHD.POCo and POIT.PO=POHD.PO
   where POIT.Job is not null and PostToCo=@Company
   group by POIT.PostToCo, POIT.Job, POIT.PhaseGroup, POIT.Phase, POIT.JCCType,POIT.UM
   
   --insert JC info
   insert into #CommittedCompare
   select JCCo, Job, PhaseGroup, Phase, CostType,null,0,0,0,0,0,0,0,0,IsNull(sum(TotalCmtdUnits),0),IsNull(sum(RemainCmtdUnits),0),
   IsNull(sum(TotalCmtdCost),0), IsNull(sum(RemainCmtdCost),0) 
   from JCCP with(nolock)
   where JCCo=@Company and (TotalCmtdUnits<>0 or RemainCmtdUnits<>0 or TotalCmtdCost<>0 or RemainCmtdCost<>0)
   group by JCCo, Job, PhaseGroup, Phase, CostType
   set nocount off
   
   
   create table  #FixCommitted(
   JCCo tinyint null, Job char(10) null, PhaseGroup tinyint null, Phase varchar(14) null, CostType tinyint null)
   
   insert into #FixCommitted
   select JCCo, Job, PhaseGroup, Phase, CostType
   /* 
           SLTotalCmtdUnits=sum(SLTotalCmtdUnits),
   	SLRemUnits=sum(SLRemUnits),
           SLTotalCmtdCost=sum(SLTotalCmtdCost),
           SLRemCost=sum(SLRemCost),
   	POTotalCmtdUnits=sum(POTotalCmtdUnits),
   	PORemUnits=sum(PORemUnits),POTotalCmtdCost=sum(POTotalCmtdCost),PORemCost=sum(PORemCost),
   	JCTotalCmtdUnits=sum(JCTotalCmtdUnits),
   	JCRemUnits=sum(JCRemUnits),JCTotalCmtdCost=sum(JCTotalCmtdCost),JCRemCost=sum(JCRemCost) 
   */
   from #CommittedCompare with(nolock)
   group by JCCo, Job, PhaseGroup, Phase, CostType
   having sum(JCTotalCmtdUnits)<>sum(SLTotalCmtdUnits)+sum(POTotalCmtdUnits) or
      sum(JCRemUnits)<>sum(SLRemUnits)+sum(PORemUnits) or
      sum(JCTotalCmtdCost)<>sum(SLTotalCmtdCost)+sum(POTotalCmtdCost) or
      sum(JCRemCost)<>sum(SLRemCost)+sum(PORemCost)
   
   ---
   select a.JCCo, a.Job, a.PhaseGroup, a.Phase, a.CostType, b.Mth,  Source='JC',APTrans=0,SL='',PO='', Line=0,Status=0,c.UM,
   	JCTotalCmtdUnits=TotalCmtdUnits,JCTotalCmtdCost=TotalCmtdCost,
   	JCRemainCmtdUnits=RemainCmtdUnits,JCRemainCmtdCost=RemainCmtdCost,APUnits=0.00,APGrossAmt=0.00,TotCurUnits=0.00,
   	TotCurCost=0.00,RemCurUnits=0.00,RemCurCost=0.00, PORecvdUnits=0.00000, PORecvdCost=0.00
   from JCCP b with(nolock)
   join #FixCommitted a with(nolock) on a.JCCo=b.JCCo and a.Job=b.Job and a.PhaseGroup=b.PhaseGroup and a.Phase=b.Phase and a.CostType=b.CostType
   join JCCH c with(nolock) on a.JCCo=c.JCCo and a.Job=c.Job and a.PhaseGroup=c.PhaseGroup and a.Phase=c.Phase and a.CostType=c.CostType
   where TotalCmtdUnits<>0 or TotalCmtdCost<>0 or	RemainCmtdUnits<>0 or RemainCmtdCost<>0
   union
   select a.JCCo, a.Job, a.PhaseGroup, a.Phase, a.CostType, b.Mth, Source='AP',APTrans,'','',APLine,0, b.UM,
   0.00,0.00,0.00,0.00,APUnits=Units, APGrossAmt=GrossAmt,0.00,0.00,0.00,0.00, 0.0000, 0.00
   from APTL b with(nolock)
   join #FixCommitted a with(nolock) on a.JCCo=b.JCCo and a.Job=b.Job and a.PhaseGroup=b.PhaseGroup and a.Phase=b.Phase and a.CostType=b.JCCType
   
   union
   select a.JCCo, a.Job, a.PhaseGroup, a.Phase, a.CostType, PostedDate, Source='PO',APTrans=0,SL='',PO=b.PO, Line=POItem,d.Status,b.UM,
    0.00,0.00,0.00,0.00,0.00,0.00,
        CurUnits,CurCost,
        case when Status<>2 then isnull(CurUnits,0)-isnull(InvUnits,0) else 0 end,
        case when Status<>2 then isnull(CurCost,0)-isnull(InvCost,0) else 0 end , 
    0.00,0.00
   from POIT b with(nolock)
   join POHD d with(nolock) on b.POCo=d.POCo and b.PO=d.PO
   join #FixCommitted a with(nolock) on a.JCCo=b.PostToCo and a.Job=b.Job and a.PhaseGroup=b.PhaseGroup and a.Phase=b.Phase and a.CostType=b.JCCType
   
   union
   select b.PostToCo, b.Job, b.PhaseGroup, b.Phase, b.JCCType, RecvdDate , Source='PORD',APTrans=0,SL='',PO=b.PO,
    Line=e.POItem,d.Status,b.UM,
    0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,  0.00, 0.00,
    e.RecvdUnits, e.RecvdCost 
   from POIT b with(nolock)
   join POHD d with(nolock) on b.POCo=d.POCo and b.PO=d.PO
   join PORD e with(nolock) on e.POCo=d.POCo and e.PO=d.PO and e.POItem=b.POItem
   join #FixCommitted a with(nolock) on a.JCCo=b.PostToCo and a.Job=b.Job and a.PhaseGroup=b.PhaseGroup and a.Phase=b.Phase and a.CostType=b.JCCType
   
   union
   
   select a.JCCo, a.Job, a.PhaseGroup, a.Phase, a.CostType, null, Source='SL',APTrans=0,SL=b.SL,PO='', Line=SLItem,
        SLHD.Status,b.UM,0.00,0.00,0.00,0.00,0.00,0.00,
        CurUnits,CurCost,
        case when Status<>2 then isnull(CurUnits,0)-isnull(InvUnits,0) else 0 end,
        case when Status<>2 then isnull(CurCost,0)-isnull(InvCost,0) else 0 end ,
   0.00,0.00
   from SLIT b with(nolock)
   join SLHD with(nolock) on b.SLCo=SLHD.SLCo and b.SL=SLHD.SL
   join #FixCommitted a with(nolock) on a.JCCo=b.JCCo and a.Job=b.Job and a.PhaseGroup=b.PhaseGroup and a.Phase=b.Phase and a.CostType=b.JCCType

GO
GRANT EXECUTE ON  [dbo].[brptJCCommReconcile] TO [public]
GO
