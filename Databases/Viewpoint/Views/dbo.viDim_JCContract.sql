SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[viDim_JCContract]

/**************************************************
 * Alterd: DH 3/17/08
 * Modified:      
 * Usage:  Dimension View from Contract Master for use in SSAS Cubes. 
 *
 *
 ********************************************************/

as

select  bJCCM.KeyID as ContractID,
		bJCCO.KeyID as JCCoID,
	    bJCCM.JCCo,
		bHQCO.Name as CompanyName,
        bJCCM.Contract,
        bJCCM.Description,
        bJCCM.Contract+' '+isnull(bJCCM.Description,'') as ContractAndDescription,
		case when bJCCM.ContractStatus=1 then 'Open'
			 when bJCCM.ContractStatus=2 then 'Soft Closed'
			 when bJCCM.ContractStatus=3 then 'Closed'
			 when bJCCM.ContractStatus=0 then 'Pending'
		end as ContractStatus,
		bJCCM.BillState,
		bJCCM.BillCountry,
		datediff(mm,'1/1/1950',bJCCM.StartMonth) as ContractStartMonthID,
		bJCCM.StartMonth as ContractStartMonth,
		bJCCM.OriginalDays as ContractOriginalDays,
		bJCCM.CurrentDays as ContractCurrentDays,
		datediff(dd,'1/1/1950',bJCCM.ProjCloseDate) as ContractProjectedCloseDateID,
		bJCCM.ProjCloseDate as ContractProjectedCloseDate,
		datediff(dd,'1/1/1950',bJCCM.ActualCloseDate) as ContractActualCloseDateID,
		bJCCM.ActualCloseDate,
	    datediff(mm,'1/1/1950',bJCCM.MonthClosed) as MonthClosedID,
		bJCCM.MonthClosed,
		FiscalMthID as FiscalYearEndMonthClosedID,
        FiscalYrEndMthName as FiscalYearEndMonthClosedName,
		bJCCM.ArchitectName
From bJCCM With (NoLock)
Join bJCCO With (NoLock) on bJCCO.JCCo=bJCCM.JCCo
Left Join viDim_GLFiscalMth on  viDim_GLFiscalMth.GLCo=bJCCO.GLCo and viDim_GLFiscalMth.Mth=bJCCM.MonthClosed
Join bHQCO on bHQCO.HQCo=bJCCM.JCCo
Join vDDBICompanies on vDDBICompanies.Co=bJCCM.JCCo

GO
GRANT SELECT ON  [dbo].[viDim_JCContract] TO [public]
GRANT INSERT ON  [dbo].[viDim_JCContract] TO [public]
GRANT DELETE ON  [dbo].[viDim_JCContract] TO [public]
GRANT UPDATE ON  [dbo].[viDim_JCContract] TO [public]
GO
