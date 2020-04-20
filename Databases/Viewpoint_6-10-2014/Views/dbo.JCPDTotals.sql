SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
* Created By:	GF 04/09/2009
* Modfied By:
*
*
*
* View of JC Projection Batch Detail with JCCD Totals.
*
*****************************************/

CREATE view [dbo].[JCPDTotals] as
select  JCPD.Co, JCPD.Mth, JCPD.BatchId, JCPD.BatchSeq, JCPD.DetSeq,
----		JCPD.BudgetCode, JCPD.EMCo, JCPD.Equipment, JCPD.PRCo, JCPD.Craft,
----		JCPD.Class, JCPD.Employee,

---- JCPD.EMCo, JCPD.Equipment values from JCCD
---- actual equipment hours
CASE WHEN JCPD.EMCo is not null and JCPD.Equipment is not null
	 THEN sum(isnull(equip.ActualHours,0))
	 ELSE 0
	 END
as EquipmentActualHours,

---- actual equipment costs
CASE WHEN JCPD.EMCo is not null and JCPD.Equipment is not null
	 THEN sum(isnull(equip.ActualCost,0))
	 ELSE 0
	 END
as EquipmentActualCosts


From bJCPD JCPD with (nolock)
left join bJCCD equip with (nolock) on equip.JCCo=JCPD.Co and equip.Mth <= JCPD.Mth
and equip.Job=JCPD.Job and equip.PhaseGroup=JCPD.PhaseGroup and equip.Phase=JCPD.Phase
and equip.CostType=JCPD.CostType and equip.EMCo=JCPD.EMCo and equip.EMEquip=JCPD.Equipment
group by JCPD.Co, JCPD.Mth, JCPD.BatchId, JCPD.BatchSeq, JCPD.DetSeq, JCPD.EMCo, JCPD.Equipment




GO
GRANT SELECT ON  [dbo].[JCPDTotals] TO [public]
GRANT INSERT ON  [dbo].[JCPDTotals] TO [public]
GRANT DELETE ON  [dbo].[JCPDTotals] TO [public]
GRANT UPDATE ON  [dbo].[JCPDTotals] TO [public]
GRANT SELECT ON  [dbo].[JCPDTotals] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCPDTotals] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCPDTotals] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCPDTotals] TO [Viewpoint]
GO
