SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCContractLastMthActivity] 
   /**************************************************
   * Created: DANF 10/06/2006
   * Modified: 
   *
   * Provides a view of the last months of activity for the JC Contract Close.
   *
   ***************************************************/
   as

  Select	JCCM.JCCo, JCCM.Contract, null as Job, JCCM.ContractStatus,
			(Select max(JCIP.Mth) from JCIP with (nolock) 
				where JCIP.JCCo= JCCM.JCCo and JCIP.Contract= JCCM.Contract and 
				(isnull(JCIP.OrigContractAmt,0) <> 0 or isnull(JCIP.OrigContractUnits,0) <> 0 or 
				isnull(JCIP.ContractAmt,0) <> 0 or isnull(JCIP.ContractUnits,0) <> 0 or 
				isnull(JCIP.BilledAmt,0) <> 0 or isnull(JCIP.CurrentRetainAmt,0) <> 0 or isnull(JCIP.BilledTax,0) <> 0)) as lstMthRevenue,
			(Select max(JCIP.Mth) from JCIP with (nolock) 
				where JCIP.JCCo= JCCM.JCCo and JCIP.Contract= JCCM.Contract and isnull(JCIP.OrigContractUnits,0) <> 0 ) as lstMthOrigContractUnits,
			(Select max(JCIP.Mth) from JCIP with (nolock) 
				where JCIP.JCCo= JCCM.JCCo and JCIP.Contract= JCCM.Contract and isnull(JCIP.OrigContractAmt,0) <> 0 ) as lstMthOrigContractAmount,
			(Select max(JCIP.Mth) from JCIP with (nolock) 
				where JCIP.JCCo= JCCM.JCCo and JCIP.Contract= JCCM.Contract and isnull(JCIP.ContractAmt,0) <> 0 ) as lstMthContractAmount,
			(Select max(JCIP.Mth) from JCIP with (nolock) 
				where JCIP.JCCo= JCCM.JCCo and JCIP.Contract= JCCM.Contract and isnull(JCIP.ContractUnits,0) <> 0 ) as lstMthContractUnits,
			(Select max(JCIP.Mth) from JCIP with (nolock) 
				where JCIP.JCCo= JCCM.JCCo and JCIP.Contract= JCCM.Contract and isnull(JCIP.BilledTax,0) <> 0 ) as lstMthBilledTax,
			(Select max(JCIP.Mth) from JCIP with (nolock) 
				where JCIP.JCCo= JCCM.JCCo and JCIP.Contract= JCCM.Contract and isnull(JCIP.BilledAmt,0) <> 0 ) as lstMthBilledAmount,
			(Select max(JCIP.Mth) from JCIP with (nolock) 
				where JCIP.JCCo= JCCM.JCCo and JCIP.Contract= JCCM.Contract and isnull(JCIP.CurrentRetainAmt,0) <> 0 ) as lstMthCurrentRetainageAmount,
			(Select max(JCCP.Mth) from JCCP with (nolock), JCJM with (nolock) where 
				JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job
				and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract and 
				(isnull(JCCP.ActualHours,0) <> 0 or isnull(JCCP.ActualUnits,0) <> 0 or isnull(JCCP.ActualCost,0) <> 0 or 
				isnull(JCCP.OrigEstHours,0) <> 0 or isnull(JCCP.OrigEstUnits,0) <> 0 or isnull(JCCP.OrigEstCost,0) <> 0 or 
				isnull(JCCP.CurrEstHours,0) <> 0 or isnull(JCCP.CurrEstUnits,0) <> 0 or isnull(JCCP.CurrEstCost,0) <> 0 or 
				isnull(JCCP.ProjHours,0) <> 0 or isnull(JCCP.ProjUnits,0) <> 0 or isnull(JCCP.ProjCost,0) <> 0 or 
				isnull(JCCP.ForecastHours,0) <> 0 or isnull(JCCP.ForecastUnits,0) <> 0 or isnull(JCCP.ForecastCost,0) <> 0 or 
				isnull(JCCP.TotalCmtdUnits,0) <> 0 or isnull(JCCP.TotalCmtdCost,0) <> 0 or isnull(JCCP.RemainCmtdUnits,0) <> 0 or 
				isnull(JCCP.RemainCmtdCost,0) <> 0 or isnull(JCCP.RecvdNotInvcdUnits,0) <> 0 or isnull(JCCP.RecvdNotInvcdCost,0) <> 0 )) as lstMthCost,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract 
				 where isnull(JCCP.ActualHours,0) <> 0 ) as lstMthActualHours,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract 
				 where isnull(JCCP.ActualUnits,0) <> 0 ) as lstMthActualUnits,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract 
				 where isnull(JCCP.ActualCost,0) <> 0 ) as lstMthActualCost,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract 
				 where isnull(JCCP.OrigEstHours,0) <> 0 ) as lstMthOrigHours,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract 
				 where isnull(JCCP.OrigEstUnits,0) <> 0 ) as lstMthOrigUnits,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract 
				 where isnull(JCCP.OrigEstCost,0) <> 0 ) as lstMthOrigCost,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract 
				 where isnull(JCCP.CurrEstHours,0) <> 0 ) as lstMthCurrEstHours,
			(Select max(JCCP.Mth) from JCCP with (nolock) 
				  join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract 
				 where isnull(JCCP.CurrEstUnits,0) <> 0 ) as lstMthCurrEstUnits,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract 
				 where isnull(JCCP.CurrEstCost,0) <> 0 ) as lstMthCurrEstCost,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract 
				 where isnull(JCCP.ProjHours,0) <> 0 ) as lstMthProjHours,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract 
				 where isnull(JCCP.ProjUnits,0) <> 0 ) as lstMthProjUnits,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract 
				 where isnull(JCCP.ProjCost,0) <> 0 ) as lstMthProjCost,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract 
				 where isnull(JCCP.ForecastHours,0) <> 0 ) as lstMthForecastHours,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract 
				 where isnull(JCCP.ForecastUnits,0) <> 0 ) as lstMthForecastUnits,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract 
				 where isnull(JCCP.ForecastCost,0) <> 0 ) as lstMthForecastCost,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract 
				 where isnull(JCCP.TotalCmtdUnits,0) <> 0 ) as lstMthTotalCmtdUnits,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract 
				 where isnull(JCCP.TotalCmtdCost,0) <> 0 ) as lstMthTotalCmtdCost,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract 
				 where isnull(JCCP.RemainCmtdUnits,0) <> 0 ) as lstMthRemainCmtdUnits,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract 
				 where isnull(JCCP.RemainCmtdCost,0) <> 0 ) as lstMthRemainCmtdCost,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract 
				 where isnull(JCCP.RecvdNotInvcdUnits,0) <> 0 ) as lstMthRecvdNotInvcdUnits,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract 
				 where isnull(JCCP.RecvdNotInvcdCost,0) <> 0 ) as lstMthRecvdNotInvcdCost
			from JCCM with (nolock)
 UNION
		Select	JCCM.JCCo, JCCM.Contract, JCJM.Job, JCCM.ContractStatus,
			(Select max(JCIP.Mth) from JCIP with (nolock) 
				where JCIP.JCCo= JCCM.JCCo and JCIP.Contract= JCCM.Contract and 
				(isnull(JCIP.OrigContractAmt,0) <> 0 or isnull(JCIP.OrigContractUnits,0) <> 0 or 
				isnull(JCIP.ContractAmt,0) <> 0 or isnull(JCIP.ContractUnits,0) <> 0 or 
				isnull(JCIP.BilledAmt,0) <> 0 or isnull(JCIP.CurrentRetainAmt,0) <> 0 or isnull(JCIP.BilledTax,0) <> 0)) as lstMthRevenue,
			(Select max(JCIP.Mth) from JCIP with (nolock) 
				where JCIP.JCCo= JCCM.JCCo and JCIP.Contract= JCCM.Contract and isnull(JCIP.OrigContractUnits,0) <> 0 ) as lstMthOrigContractUnits,
			(Select max(JCIP.Mth) from JCIP with (nolock) 
				where JCIP.JCCo= JCCM.JCCo and JCIP.Contract= JCCM.Contract and isnull(JCIP.OrigContractAmt,0) <> 0 ) as lstMthOrigContractAmount,
			(Select max(JCIP.Mth) from JCIP with (nolock) 
				where JCIP.JCCo= JCCM.JCCo and JCIP.Contract= JCCM.Contract and isnull(JCIP.ContractAmt,0) <> 0 ) as lstMthContractAmount,
			(Select max(JCIP.Mth) from JCIP with (nolock) 
				where JCIP.JCCo= JCCM.JCCo and JCIP.Contract= JCCM.Contract and isnull(JCIP.ContractUnits,0) <> 0 ) as lstMthContractUnits,
			(Select max(JCIP.Mth) from JCIP with (nolock) 
				where JCIP.JCCo= JCCM.JCCo and JCIP.Contract= JCCM.Contract and isnull(JCIP.BilledTax,0) <> 0 ) as lstMthBilledTax,
			(Select max(JCIP.Mth) from JCIP with (nolock) 
				where JCIP.JCCo= JCCM.JCCo and JCIP.Contract= JCCM.Contract and isnull(JCIP.BilledAmt,0) <> 0 ) as lstMthBilledAmount,
			(Select max(JCIP.Mth) from JCIP with (nolock) 
				where JCIP.JCCo= JCCM.JCCo and JCIP.Contract= JCCM.Contract and isnull(JCIP.CurrentRetainAmt,0) <> 0 ) as lstMthCurrentRetainageAmount,
			(Select max(JCCP.Mth) from JCCP with (nolock), JCJM with (nolock) where 
				JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job
				and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract and 
				(isnull(JCCP.ActualHours,0) <> 0 or isnull(JCCP.ActualUnits,0) <> 0 or isnull(JCCP.ActualCost,0) <> 0 or 
				isnull(JCCP.OrigEstHours,0) <> 0 or isnull(JCCP.OrigEstUnits,0) <> 0 or isnull(JCCP.OrigEstCost,0) <> 0 or 
				isnull(JCCP.CurrEstHours,0) <> 0 or isnull(JCCP.CurrEstUnits,0) <> 0 or isnull(JCCP.CurrEstCost,0) <> 0 or 
				isnull(JCCP.ProjHours,0) <> 0 or isnull(JCCP.ProjUnits,0) <> 0 or isnull(JCCP.ProjCost,0) <> 0 or 
				isnull(JCCP.ForecastHours,0) <> 0 or isnull(JCCP.ForecastUnits,0) <> 0 or isnull(JCCP.ForecastCost,0) <> 0 or 
				isnull(JCCP.TotalCmtdUnits,0) <> 0 or isnull(JCCP.TotalCmtdCost,0) <> 0 or isnull(JCCP.RemainCmtdUnits,0) <> 0 or 
				isnull(JCCP.RemainCmtdCost,0) <> 0 or isnull(JCCP.RecvdNotInvcdUnits,0) <> 0 or isnull(JCCP.RecvdNotInvcdCost,0) <> 0 )) as lstMthCost,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  where JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract and isnull(JCCP.ActualHours,0) <> 0 ) as lstMthActualHours,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  where JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract and isnull(JCCP.ActualUnits,0) <> 0 ) as lstMthActualUnits,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  where JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract and isnull(JCCP.ActualCost,0) <> 0 ) as lstMthActualCost,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  where JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract and isnull(JCCP.OrigEstHours,0) <> 0 ) as lstMthOrigHours,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  where JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract and isnull(JCCP.OrigEstUnits,0) <> 0 ) as lstMthOrigUnits,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  where JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract and isnull(JCCP.OrigEstCost,0) <> 0 ) as lstMthOrigCost,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  where JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract and isnull(JCCP.CurrEstHours,0) <> 0 ) as lstMthCurrEstHours,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  where JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract and isnull(JCCP.CurrEstUnits,0) <> 0 ) as lstMthCurrEstUnits,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  where JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract and isnull(JCCP.CurrEstCost,0) <> 0 ) as lstMthCurrEstCost,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  where JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract and isnull(JCCP.ProjHours,0) <> 0 ) as lstMthProjHours,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  where JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract and isnull(JCCP.ProjUnits,0) <> 0 ) as lstMthProjUnits,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  where JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract and isnull(JCCP.ProjCost,0) <> 0 ) as lstMthProjCost,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  where JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract and isnull(JCCP.ForecastHours,0) <> 0 ) as lstMthForecastHours,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  where JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract and isnull(JCCP.ForecastUnits,0) <> 0 ) as lstMthForecastUnits,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  where JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract and isnull(JCCP.ForecastCost,0) <> 0 ) as lstMthForecastCost,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  where JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract and isnull(JCCP.TotalCmtdUnits,0) <> 0 ) as lstMthTotalCmtdUnits,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  where JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract and isnull(JCCP.TotalCmtdCost,0) <> 0 ) as lstMthTotalCmtdCost,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  where JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract and isnull(JCCP.RemainCmtdUnits,0) <> 0 ) as lstMthRemainCmtdUnits,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  where JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract and isnull(JCCP.RemainCmtdCost,0) <> 0 ) as lstMthRemainCmtdCost,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  where JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract and isnull(JCCP.RecvdNotInvcdUnits,0) <> 0 ) as lstMthRecvdNotInvcdUnits,
			(Select max(JCCP.Mth) from JCCP with (nolock)
				  where JCCP.JCCo=JCJM.JCCo and JCCP.Job=JCJM.Job and JCJM.JCCo= JCCM.JCCo and JCJM.Contract= JCCM.Contract and isnull(JCCP.RecvdNotInvcdCost,0) <> 0 ) as lstMthRecvdNotInvcdCost
			from JCJM with (nolock)
			left join JCCM with (nolock) on JCCM.JCCo=JCJM.JCCo and JCCM.Contract=JCJM.Contract

GO
GRANT SELECT ON  [dbo].[JCContractLastMthActivity] TO [public]
GRANT INSERT ON  [dbo].[JCContractLastMthActivity] TO [public]
GRANT DELETE ON  [dbo].[JCContractLastMthActivity] TO [public]
GRANT UPDATE ON  [dbo].[JCContractLastMthActivity] TO [public]
GO
