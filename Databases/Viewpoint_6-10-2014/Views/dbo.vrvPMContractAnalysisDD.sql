SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/*********************************************************************
 * Created By:	JH 1/22/10 - Initial version for customer 
 *				report PM Contract Analysis DD
 *
 * Modfied By:  #138909 HH 1/5/11 - No modification, created in VPDev640 
 *				for customer report PM Contract Analysis DD to 
 *				become Standard report in PM
 *              TK-06175 DH 6/20/11 Change BuyOut Committed and added BuyOutUnCmtd
 *
 *				D-02475 HH 7/12/11 Added BuyOutUnCmtd from PMOL Purchase 
 *				D-04862 HH 4/18/12 Removed GSTTax from APAmt :=  Sum(APTD.Amount) - Sum(APTD.GSTtaxAmt)
 *
 *	Used on PM Contract Analysis DD report
 *
 *********************************************************************/  


CREATE             View [dbo].[vrvPMContractAnalysisDD] as
   
  

/*Revenue*/
select JCIP.JCCo, JCIP.Contract, Job=b.Job, PhaseGroup=null,Phase=null, CostType=null,JCIP.Mth,
		JCIP.OrigContractAmt, JCIP.ContractAmt, JCIP.BilledAmt, JCIP.ReceivedAmt, JCIP.CurrentRetainAmt, JCIP.ProjDollars,
		ProjMth=(select isnull(min(i.Mth),'12/1/2050') 
					from JCIP i with (nolock)
    				where JCIP.JCCo=i.JCCo and JCIP.Contract=i.Contract and JCIP.Item=i.Item and (i.ProjDollars <>0 or i.ProjPlug='Y')),
		ActualHours=0, ActualUnits=0, ActualCost=0, 
		OrigEstHours=0, OrigEstUnits=0, OrigEstCost=0, CurrEstHours=0, CurrEstUnits=0, CurrEstCost=0, 
		ProjHours=0, ProjUnits=0, ProjCost=0, ForecastHours=0, ForecastUnits=0, ForecastCost=0, 
		TotalCmtdUnits=0, TotalCmtdCost=0, RemainCmtdUnits=0, RemainCmtdCost=0, RecvdNotInvcdUnits=0, RecvdNotInvcdCost=0,
		PCOType=null, PCO=null, PCOItem=null, ACO=null, ACOItem=null, 
		SendYN=Null, 
		COContUM=null, COContUnits=0.00, COContUP=0.00,
		COContAmt=0.00, COContEstHrs=0,
       	InterfacedDate='1/1/1950',Sort = 1,Description=null, APAmt=0.00, RetAPAmt=0.00, PaidMth='12/31/2050',UnappAP=0, 
		BuyOutEst=0.00, BuyOutCmtd=0.00, BuyOutUnCmtd=0.00
from JCIP With (NoLock)
	join brvJCContrMinJob b on JCIP.JCCo=b.JCCo and JCIP.Contract=b.Contract
       
union all
       
select JCCP.JCCo, JCJP.Contract, JCCP.Job, JCCP.PhaseGroup, JCCP.Phase, JCCP.CostType,JCCP.Mth,
	OrigContractAmt=0.00, ContractAmt=0.00, BilledAmt=0.00, ReceivedAmt=0.00, CurrentRetainAmt=0.00, ProjDollars=0.00,
	ProjMth=(select isnull(min(Mth),'12/1/2050') 
					from JCCP p with(nolock)
                              Join JCJP j with(nolock) on j.JCCo=p.JCCo and j.Job=p.Job and j.PhaseGroup=p.PhaseGroup and j.Phase=p.Phase
                    where j.JCCo=JCCP.JCCo and j.Contract=JCJP.Contract and j.Item=JCJP.Item and p.ProjCost<>0),
	JCCP.ActualHours, JCCP.ActualUnits, JCCP.ActualCost, 
	JCCP.OrigEstHours, JCCP.OrigEstUnits, JCCP.OrigEstCost, JCCP.CurrEstHours, JCCP.CurrEstUnits, JCCP.CurrEstCost, 
    JCCP.ProjHours, JCCP.ProjUnits, JCCP.ProjCost, JCCP.ForecastHours, JCCP.ForecastUnits, JCCP.ForecastCost, 
    JCCP.TotalCmtdUnits, JCCP.TotalCmtdCost, JCCP.RemainCmtdUnits, JCCP.RemainCmtdCost, JCCP.RecvdNotInvcdUnits, JCCP.RecvdNotInvcdCost,
	PCOType=null, PCO=null, PCOItem=null, ACO=null, ACOItem=null, 
	SendYN=Null, 
	COContUM=null, COContUnits=0.00, COContUP=0.00,
	COContAmt=0.00, COContEstHrs=0,
	InterfacedDate='1/1/1950',Sort = 1,Description=null, APAmt=0.00, RetAPAmt=0.00, PaidMth='12/31/2050',UnappAP=0,
	BuyOutEst=JCCP.OrigEstCost, BuyOutCmtd=0.00, BuyOutUnCmtd=0.00
from JCCP with(nolock)
       	join JCJP with(nolock) on JCCP.JCCo=JCJP.JCCo and JCCP.Job=JCJP.Job and
				JCCP.Phase=JCJP.Phase and JCCP.PhaseGroup=JCJP.PhaseGroup 

union all    

select PMOI.PMCo, PMOI.Contract, PMOI.Project, PhaseGroup=null,Phase=null, CostType=null, '1/1/1950',
		OrigContractAmt=0.00, ContractAmt=0.00, BilledAmt=0.00, ReceivedAmt=0.00, CurrentRetainAmt=0.00, ProjDollars=0.00, ProjMth='1/1/1950',
		null, null, null,
		null, null, null, null, null, null,
		null, null, null, null, null, null,
		null, null, null, null, null, null,
		PCOType=PMOI.PCOType, PCO=PMOI.PCO, PCOItem=PMOI.PCOItem, ACO=PMOI.ACO, ACOItem=PMOI.ACOItem, 
		SendYN=null, 
		COContUM=PMOI.UM, COContUnits=PMOI.Units, COContUP=PMOI.UnitPrice, 
		COContAmt=case when PMOI.ACO is not null then PMOI.ApprovedAmt else 
						case when PMOI.FixedAmountYN='Y' then FixedAmount else PMOI.PendingAmount end end,-- PMOL.EstCost, 
		COContEstHrs=0,
		InterfacedDate=isnull(PMOI.InterfacedDate,'12/31/2050'), Sort=2, PMOI.Description, APAmt=0.00, RetAPAmt=0.00, PaidMth='12/31/2050',
		UnappAP=0, BuyOutEst=0.00, BuyOutCmtd=0.00, BuyOutUnCmtd=0.00
from PMOI  with(nolock)


union all

/**AP Amount**/
Select JCJM.JCCo, JCJM.Contract, JCJM.Job, PhaseGroup=null, Phase=null, CostType=null, APTD.Mth,
		OrigContractAmt=0.00, ContractAmt=0.00, BilledAmt=0.00, ReceivedAmt=0.00, CurrentRetainAmt=0.00, ProjDollars=0.00, ProjMth='1/1/1950',
		ActualHours=0, ActualUnits=0, ActualCost=0, 
		OrigEstHours=0, OrigEstUnits=0, OrigEstCost=0, CurrEstHours=0, CurrEstUnits=0, CurrEstCost=0, 
		ProjHours=0, ProjUnits=0, ProjCost=0, ForecastHours=0, ForecastUnits=0, ForecastCost=0, 
		TotalCmtdUnits=0, TotalCmtdCost=0, RemainCmtdUnits=0, RemainCmtdCost=0, RecvdNotInvcdUnits=0, RecvdNotInvcdCost=0,
		PCOType=null, PCO=null, PCOItem=null, ACO=null, ACOItem=null, 
		SendYN=Null, 
		COContUM=null, COContUnits=0.00, COContUP=0.00,
		COContAmt=0.00, COContEstHrs=0,
		InterfacedDate='1/1/1950',Sort = 1,Description=null, 
		APAmt=Sum(APTD.Amount) - Sum(APTD.GSTtaxAmt), RetAPAmt=sum(case when APTD.PayType=APCO.RetPayType then APTD.Amount else 0 end),
		PaidMth=IsNull(PaidMth,'12/31/2050'), UnappAP=0, BuyOutEst=0.00, BuyOutCmtd=0.00, BuyOutUnCmtd=0.00
from JCJM with(nolock)
		join APTL with(nolock) on APTL.JCCo=JCJM.JCCo and APTL.Job=JCJM.Job
    	join APTD with(nolock) on APTD.APCo=APTL.APCo and APTD.Mth=APTL.Mth and APTD.APTrans=APTL.APTrans and APTL.APLine=APTD.APLine
    	join JCCM e with(nolock) on JCJM.JCCo = e.JCCo and JCJM.Contract = e.Contract
    	join (select JCCo, Contract,Job=Min(Job),ProjectMgr=Min(ProjectMgr)  
				from JCJM  with(nolock)
				group by JCCo,Contract ) 
				as JM 
				on e.JCCo = JM.JCCo and e.Contract = JM.Contract 
	join APCO with(nolock) on APTL.APCo=APCO.APCo
group by JCJM.JCCo, JCJM.Contract,APTD.Mth,JCJM.Job,APTD.PaidMth
    


union all

/**Unapproved AP Amount**/
Select JCJM.JCCo, JCJM.Contract, JCJM.Job, PhaseGroup=null, Phase=null, CostType=null, APUL.UIMth,
		OrigContractAmt=0.00, ContractAmt=0.00, BilledAmt=0.00, ReceivedAmt=0.00, CurrentRetainAmt=0.00, ProjDollars=0.00, ProjMth='1/1/1950',
		ActualHours=0, ActualUnits=0, ActualCost=0, 
		OrigEstHours=0, OrigEstUnits=0, OrigEstCost=0, CurrEstHours=0, CurrEstUnits=0, CurrEstCost=0, 
		ProjHours=0, ProjUnits=0, ProjCost=0, ForecastHours=0, ForecastUnits=0, ForecastCost=0, 
		TotalCmtdUnits=0, TotalCmtdCost=0, RemainCmtdUnits=0, RemainCmtdCost=0, RecvdNotInvcdUnits=0, RecvdNotInvcdCost=0,
		PCOType=null, PCO=null, PCOItem=null, ACO=null, ACOItem=null, 
		SendYN=Null, 
		COContUM=null, COContUnits=0.00, COContUP=0.00,
		COContAmt=0.00, COContEstHrs=0,
		InterfacedDate='1/1/1950',Sort = 1,Description=null, 
		APAmt=0, RetAPAmt=0,
		PaidMth='12/1/2050', UnappAP=sum(APUL.GrossAmt)+
					isnull(sum(case when APUL.TaxType in (1,3) then APUL.TaxAmt else 0 end),0)
					+isnull(sum(case when APUL.MiscYN = 'Y' then APUL.MiscAmt else 0 end),0), BuyOutEst=0.00, BuyOutCmtd=0.00, BuyOutUnCmtd=0.00
from JCJM with(nolock)
		join APUL with(nolock) on APUL.JCCo=JCJM.JCCo and APUL.Job=JCJM.Job
    	join JCCM e with(nolock) on JCJM.JCCo = e.JCCo and JCJM.Contract = e.Contract
    	join (select JCCo, Contract,Job=Min(Job),ProjectMgr=Min(ProjectMgr)  
				from JCJM  with(nolock)
				group by JCCo,Contract ) 
				as JM 
				on e.JCCo = JM.JCCo and e.Contract = JM.Contract 
group by JCJM.JCCo, JCJM.Contract,APUL.UIMth,JCJM.Job


union all

--Buyout Amounts - Approved CO's
select PMOL.PMCo, JCJM.Contract, PMOL.Project, PMOL.PhaseGroup, PMOL.Phase, PMOL.CostType, Mth='1/1/1950',
		OrigContractAmt=0.00, ContractAmt=0.00, BilledAmt=0.00, ReceivedAmt=0.00, CurrentRetainAmt=0.00, ProjDollars=0.00, ProjMth='1/1/1950',
		ActualHours=0, ActualUnits=0, ActualCost=0, 
		OrigEstHours=0, OrigEstUnits=0, OrigEstCost=0, CurrEstHours=0, CurrEstUnits=0, CurrEstCost=0, 
		ProjHours=0, ProjUnits=0, ProjCost=0, ForecastHours=0, ForecastUnits=0, ForecastCost=0, 
		TotalCmtdUnits=0, TotalCmtdCost=0, RemainCmtdUnits=0, RemainCmtdCost=0, RecvdNotInvcdUnits=0, RecvdNotInvcdCost=0,
		PCOType=null, PCO=null, PCOItem=null, ACO=null, ACOItem=null, 
		SendYN=Null, 
		COContUM=null, COContUnits=0.00, COContUP=0.00,
		COContAmt=0.00, COContEstHrs=0,
		InterfacedDate='1/1/1950',Sort = 1,Description=null, 
		APAmt=0, RetAPAmt=0,
		PaidMth='12/1/2050', UnappAP=0.00,
        BuyOutEst=sum(PMOL.EstCost), BuyOutCmtd=0.00, BuyOutUnCmtd=0.00
from PMOL with(nolock)
		join JCJM with(nolock) on PMOL.PMCo=JCJM.JCCo and PMOL.Project=JCJM.Job
where PMOL.ACO is not null
group by PMOL.PMCo,  JCJM.Contract, PMOL.Project, PMOL.PhaseGroup, PMOL.Phase, PMOL.CostType

union all

--Uncommited Amount - Pending Change Orders
select PMOL.PMCo, JCJM.Contract, PMOL.Project, PMOL.PhaseGroup, PMOL.Phase, PMOL.CostType, Mth='1/1/1950',
		OrigContractAmt=0.00, ContractAmt=0.00, BilledAmt=0.00, ReceivedAmt=0.00, CurrentRetainAmt=0.00, ProjDollars=0.00, ProjMth='1/1/1950',
		ActualHours=0, ActualUnits=0, ActualCost=0, 
		OrigEstHours=0, OrigEstUnits=0, OrigEstCost=0, CurrEstHours=0, CurrEstUnits=0, CurrEstCost=0, 
		ProjHours=0, ProjUnits=0, ProjCost=0, ForecastHours=0, ForecastUnits=0, ForecastCost=0, 
		TotalCmtdUnits=0, TotalCmtdCost=0, RemainCmtdUnits=0, RemainCmtdCost=0, RecvdNotInvcdUnits=0, RecvdNotInvcdCost=0,
		PCOType=null, PCO=null, PCOItem=null, ACO=null, ACOItem=null, 
		SendYN=Null, 
		COContUM=null, COContUnits=0.00, COContUP=0.00,
		COContAmt=0.00, COContEstHrs=0,
		InterfacedDate='1/1/1950',Sort = 1,Description=null, 
		APAmt=0, RetAPAmt=0,
		PaidMth='12/1/2050', UnappAP=0.00,
        BuyOutEst=0, BuyOutCmtd=0.00, BuyOutUnCmtd=sum(case when PMOL.Subcontract is null and PMOL.PO is null 
				and PMOL.ACO is NULL and PMOL.PCO is not NULL and PMSC.IncludeInProj in ( 'Y', 'C' )  
					then PMOL.PurchaseAmt else 0 end)
 from PMOL with(nolock)
	join JCJM with(nolock) on PMOL.PMCo=JCJM.JCCo and PMOL.Project=JCJM.Job
	JOIN PMOI with(nolock) ON PMOI.PMCo = PMOL.PMCo 
						 AND PMOI.Project = PMOL.Project 
						 AND isnull(PMOI.PCOType,'') = isnull(PMOL.PCOType,'')
						 AND isnull(PMOI.PCO,'') = isnull(PMOL.PCO,'')
						 AND isnull(PMOI.PCOItem,'') = isnull(PMOL.PCOItem,'')
						 AND isnull(PMOI.ACO,'') = isnull(PMOL.ACO,'')
						 AND isnull(PMOI.ACOItem,'') = isnull(PMOL.ACOItem,'')
	LEFT JOIN PMSC 
          on PMSC.Status = PMOI.Status   
group by PMOL.PMCo,  JCJM.Contract, PMOL.Project, PMOL.PhaseGroup, PMOL.Phase, PMOL.CostType


union all
   
select PMMF.PMCo, JCJM.Contract, PMMF.Project, PMMF.PhaseGroup, PMMF.Phase, PMMF.CostType, Mth='1/1/1950',
	OrigContractAmt=0.00, ContractAmt=0.00, BilledAmt=0.00, ReceivedAmt=0.00, CurrentRetainAmt=0.00, ProjDollars=0.00, ProjMth='1/1/1950',
	ActualHours=0, ActualUnits=0, ActualCost=0, 
	OrigEstHours=0, OrigEstUnits=0, OrigEstCost=0, CurrEstHours=0, CurrEstUnits=0, CurrEstCost=0, 
	ProjHours=0, ProjUnits=0, ProjCost=0, ForecastHours=0, ForecastUnits=0, ForecastCost=0, 
	TotalCmtdUnits=0, TotalCmtdCost=0, RemainCmtdUnits=0, RemainCmtdCost=0, RecvdNotInvcdUnits=0, RecvdNotInvcdCost=0,
	PCOType=null, PCO=null, PCOItem=null, ACO=null, ACOItem=null, 
	SendYN=Null, 
	COContUM=null, COContUnits=0.00, COContUP=0.00,
	COContAmt=0.00, COContEstHrs=0,
	InterfacedDate='1/1/1950',Sort = 1,Description=null, 
	APAmt=0, RetAPAmt=0,
	PaidMth='12/1/2050', UnappAP=0.00,
    BuyOutEst=0.00, 
    /*Committed = Assigned to a PO (PO is not null) on an (O)riginal RecordType
                        or PO is not null on an Approved Change Order (ACO is not null)*/
    BuyOutCmtd=(case when PMMF.PCO is not NULL and PMMF.ACO is NULL 
								then 0 
							 when PMMF.PO is not NULL and PMMF.RecordType='O'
								then PMMF.Amount	
							  when PMMF.PO is not NULL and PMMF.ACO is not NULL
								then PMMF.Amount
							  else 0	
						 end),
	/*Uncommitted = PO is unassigned on (O)riginal RecordType
                          or PO unassigned on an ACO
                          or PMMF entry exists on a pending change order with a status to be
                          displayed or calculated in Projections
           */                          				
	BuyOutUnCmtd=(case when PMMF.PCO is NULL AND PMMF.PO is NULL
									then PMMF.Amount
								when PMMF.PCO is not NULL and PMSC.IncludeInProj in ( 'Y', 'C' ) 
										and PMMF.PO is not NULL
									then PMMF.Amount	
								when PMMF.ACO is not NULL and PMMF.PO is NULL
									then PMMF.Amount
						  else 0
						  end)           		 
from PMMF with(nolock)
	join JCJM with(nolock) on PMMF.PMCo=JCJM.JCCo and PMMF.Project=JCJM.Job
	LEFT JOIN PMOI 
          ON PMOI.PMCo = PMMF.PMCo 
             AND PMOI.Project = PMMF.Project 
             AND isnull(PMOI.PCOType,'') = isnull(PMMF.PCOType,'')
             AND isnull(PMOI.PCO,'') = isnull(PMMF.PCO,'')
             AND isnull(PMOI.PCOItem,'') = isnull(PMMF.PCOItem,'')
             AND isnull(PMOI.ACO,'') = isnull(PMMF.ACO,'')
             AND isnull(PMOI.ACOItem,'') = isnull(PMMF.ACOItem,'')
   LEFT JOIN PMSC 
          on PMSC.Status = PMOI.Status
	
where PMMF.MaterialOption = 'P' 

union all 

select PMMF.PMCo, JCJM.Contract, PMMF.Project, PMMF.PhaseGroup, PMMF.Phase, PMMF.CostType, Mth='1/1/1950',
	OrigContractAmt=0.00, ContractAmt=0.00, BilledAmt=0.00, ReceivedAmt=0.00, CurrentRetainAmt=0.00, ProjDollars=0.00, ProjMth='1/1/1950',
	ActualHours=0, ActualUnits=0, ActualCost=0, 
	OrigEstHours=0, OrigEstUnits=0, OrigEstCost=0, CurrEstHours=0, CurrEstUnits=0, CurrEstCost=0, 
	ProjHours=0, ProjUnits=0, ProjCost=0, ForecastHours=0, ForecastUnits=0, ForecastCost=0, 
	TotalCmtdUnits=0, TotalCmtdCost=0, RemainCmtdUnits=0, RemainCmtdCost=0, RecvdNotInvcdUnits=0, RecvdNotInvcdCost=0,
	PCOType=null, PCO=null, PCOItem=null, ACO=null, ACOItem=null, 
	SendYN=Null, 
	COContUM=null, COContUnits=0.00, COContUP=0.00,
	COContAmt=0.00, COContEstHrs=0,
	InterfacedDate='1/1/1950',Sort = 1,Description=null, 
	APAmt=0, RetAPAmt=0,
	PaidMth='12/1/2050', UnappAP=0.00,
    BuyOutEst=0, BuyOutCmtd=sum(PMMF.Amount), BuyOutUnCmtd=0.00
from PMMF with(nolock)
	join JCJM with(nolock) on PMMF.PMCo=JCJM.JCCo and PMMF.Project=JCJM.Job
where  MaterialOption = 'M' and MO is not null 
group by PMMF.PMCo, JCJM.Contract, PMMF.Project, PMMF.PhaseGroup, PMMF.Phase, PMMF.CostType
   
union all 

select PMSL.PMCo, JCJM.Contract, PMSL.Project, PMSL.PhaseGroup, PMSL.Phase, PMSL.CostType, Mth='1/1/1950',
	OrigContractAmt=0.00, ContractAmt=0.00, BilledAmt=0.00, ReceivedAmt=0.00, CurrentRetainAmt=0.00, ProjDollars=0.00, ProjMth='1/1/1950',
	ActualHours=0, ActualUnits=0, ActualCost=0, 
	OrigEstHours=0, OrigEstUnits=0, OrigEstCost=0, CurrEstHours=0, CurrEstUnits=0, CurrEstCost=0, 
	ProjHours=0, ProjUnits=0, ProjCost=0, ForecastHours=0, ForecastUnits=0, ForecastCost=0, 
	TotalCmtdUnits=0, TotalCmtdCost=0, RemainCmtdUnits=0, RemainCmtdCost=0, RecvdNotInvcdUnits=0, RecvdNotInvcdCost=0,
	PCOType=null, PCO=null, PCOItem=null, ACO=null, ACOItem=null, 
	SendYN=Null, 
	COContUM=null, COContUnits=0.00, COContUP=0.00,
	COContAmt=0.00, COContEstHrs=0,
	InterfacedDate='1/1/1950',Sort = 1,Description=null, 
	APAmt=0, RetAPAmt=0,
	PaidMth='12/1/2050', UnappAP=0.00,
    BuyOutEst=0, 
    /*Committed = Assigned to a SL (SL is not null) on an (O)riginal RecordType
                        or SL is not null on an Approved Change Order (ACO is not null)*/
    BuyOutCmtd=(case when PMSL.PCO is not NULL and PMSL.ACO is NULL 
								then 0 
							 when PMSL.SL is not NULL and PMSL.RecordType='O'
								then PMSL.Amount	
							  when PMSL.SL is not NULL and PMSL.ACO is not NULL
								then PMSL.Amount
							  else 0	
						 end),
          /*Uncommitted = SL is unassigned on (O)riginal RecordType
                          or SL unassigned on an ACO
                          or PMSL entry exists on a pending change order with a status to be
                          displayed or calculated in Projections
           */                   
           BuyOutUnCmtd=(case when PMSL.PCO is NULL and PMSL.SL is NULL 
									then PMSL.Amount
								when PMSL.PCO is not NULL and PMSC.IncludeInProj in ( 'Y', 'C' ) 
										and PMSL.SL is not NULL
									then PMSL.Amount
								when PMSL.ACO is not NULL and PMSL.SL is NULL
									then PMSL.Amount
						  else 0
						  end)       						 
from PMSL with(nolock)
	join JCJM with(nolock) on PMSL.PMCo=JCJM.JCCo and PMSL.Project=JCJM.Job
	LEFT JOIN PMOI 
          ON PMOI.PMCo = PMSL.PMCo 
             AND PMOI.Project = PMSL.Project 
             AND isnull(PMOI.PCOType,'') = isnull(PMSL.PCOType,'')
             AND isnull(PMOI.PCO,'') = isnull(PMSL.PCO,'')
             AND isnull(PMOI.PCOItem,'') = isnull(PMSL.PCOItem,'')
             AND isnull(PMOI.ACO,'') = isnull(PMSL.ACO,'')
             AND isnull(PMOI.ACOItem,'') = isnull(PMSL.ACOItem,'')
   LEFT JOIN PMSC 
          on PMSC.Status = PMOI.Status




GO
GRANT SELECT ON  [dbo].[vrvPMContractAnalysisDD] TO [public]
GRANT INSERT ON  [dbo].[vrvPMContractAnalysisDD] TO [public]
GRANT DELETE ON  [dbo].[vrvPMContractAnalysisDD] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMContractAnalysisDD] TO [public]
GRANT SELECT ON  [dbo].[vrvPMContractAnalysisDD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPMContractAnalysisDD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPMContractAnalysisDD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPMContractAnalysisDD] TO [Viewpoint]
GO
