SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




/*****************************************
* Created By: DANF 09/05/2006 
* Modfied By:	GF 01/08/2008 - issue #127060 changed percent complete to not use bPct.Also fixed
*				problems with unit cost calculations. cast as numeric(11,5)
*				GF 02/29/2008 - issue #126235 added JCCH.ProjNotes exists flag 'N' - null else 'Y'
*				GF 06/30/2008 - issue #128833 added JCCH.BuyOutYN Flag
*				GF 10/17/2008 - issue #130656 use base tables not views for performance.
*				GF 01/06/2009 - issue #131592
*				GF 01/12/2008 - issue #131764 fix for remaining values incorrect
*				GF 11/23/2009 - issue #136737 remaining cost incorrect when net zero
*				GP 12/08/2009 - issue #136955 increased numerics on percentages from (12,6) to (17,6)
*				GF 12/17/2009 - issue #137022 changed to show units, hours, costs percent complete as positive only
*				GF 01/19/2009 - issue #137604 use new view to calculate over/under with included co values.
*
*
*
* View of JC Projection Batch Calculations.
* This was created for 6.x and is used in JCProjections. 
*
*****************************************/

CREATE view [dbo].[JCPBCalculations] as
select  JCPB.Co, JCPB.Mth, JCPB.BatchId, JCPB.BatchSeq,

---- UNITS
---- percent complete units	#137022
ABS(CAST(CASE WHEN isnull(ProjFinalUnits,0) <> 0 and ABS(isnull(x.CurrEstPlusInclUnits,0)) + ABS(CASE JCUO.ProjMethod WHEN 2 THEN isnull(ActualCmtdUnits,0) ELSE isnull(ActualUnits,0) END) <> 0 THEN
	CASE
	WHEN ABS(isnull(x.CurrEstPlusInclUnits,0)) + ABS(CASE JCUO.ProjMethod WHEN 2 
	THEN isnull(ActualCmtdUnits,0) ELSE isnull(ActualUnits,0) END) > 0 and CASE JCUO.ProjMethod WHEN 2 
		THEN isnull(ActualCmtdUnits,0) ELSE isnull(ActualUnits,0) END / isnull(ProjFinalUnits,0) < 100 THEN
		CASE JCUO.ProjMethod WHEN 2 THEN isnull(ActualCmtdUnits,0) ELSE isnull(ActualUnits,0) END / isnull(ProjFinalUnits,0) * 100	
	ELSE
		9999.999999
	END		
ELSE
	0
END as numeric(17,6))) as PercentCompleteUnits,

---- over/under units
CASE WHEN isnull(ProjFinalUnits,0) <> 0
	 THEN isnull(ProjFinalUnits,0) - isnull(x.CurrEstPlusInclUnits,0)
	 ELSE - isnull(x.CurrEstPlusInclUnits,0)
	 END
as OverUnderUnits,

---- Remaining Units
CASE WHEN isnull(ProjFinalUnits,0) <> 0
	 THEN isnull(ProjFinalUnits,0) - case JCUO.ProjMethod when 2 then isnull(ActualCmtdUnits,0) else isnull(ActualUnits,0) end
	ELSE
		case JCUO.ProjMethod when 2 then -isnull(ActualCmtdUnits,0) else -isnull(ActualUnits,0) end
	END
as RemainUnits,

---- HOURS
---- percent complete hours #137022
ABS(CAST(CASE WHEN isnull(ProjFinalHrs,0) <> 0 THEN
	CASE
	WHEN isnull(ActualHours,0) = 0 then 0 
	WHEN ABS(isnull(ActualHours,0) / isnull(ProjFinalHrs,0)) < 100 THEN ABS(isnull(ActualHours,0) / isnull(ProjFinalHrs,0)) * 100
	ELSE
		9999.999999	
	END	
ELSE
	0
END
as numeric(17,6))) as PercentCompleteHours,

---- over/under hours
CASE WHEN isnull(ProjFinalHrs,0) <> 0
	 THEN isnull(ProjFinalHrs,0) - isnull(x.CurrEstPlusInclHours,0)
	 ELSE - isnull(x.CurrEstPlusInclHours,0)
	 END
as OverUnderHours,

---- remaining hours
CASE WHEN isnull(ProjFinalHrs,0) <> 0
	 THEN isnull(ProjFinalHrs,0) - isnull(ActualHours,0)
	ELSE
		- isnull(ActualHours,0)
	END
as RemainHours,


---- COSTS #137022
ABS(CAST(CASE WHEN isnull(ProjFinalCost,0) <> 0 THEN
	CASE
	when JCUO.ProjMethod = 2 and isnull(ActualCmtdCost,0) = 0 then 0
	when JCUO.ProjMethod <> 2 and isnull(ActualCost,0) = 0 then 0
	WHEN ABS(isnull(x.CurrEstPlusInclCosts,0)) + ABS(CASE JCUO.ProjMethod WHEN 2 THEN isnull(ActualCmtdCost,0) ELSE isnull(ActualCost,0) END) > 0 and CASE JCUO.ProjMethod WHEN 2 THEN isnull(ActualCmtdCost,0) ELSE isnull(ActualCost,0) END / isnull(ProjFinalCost,0) < 100 THEN
		CASE JCUO.ProjMethod WHEN 2 THEN isnull(ActualCmtdCost,0) ELSE isnull(ActualCost,0) END / isnull(ProjFinalCost,0) * 100	
	ELSE
		9999.999999
	END		
ELSE
	0
END as numeric(17,6))) as PercentCompleteCost,

---- over/under cost
CASE WHEN isnull(ProjFinalCost,0) <> 0
	 THEN isnull(ProjFinalCost,0) - isnull(x.CurrEstPlusInclCosts,0)
	 ELSE - isnull(x.CurrEstPlusInclCosts,0)
	 END
as OverUnderCost,

---- remaining cost #136737
case when isnull(ProjFinalCost,0) <> 0 then
	case when JCUO.ProjMethod = 2 and isnull(ActualCmtdCost,0) = 0 then isnull(ProjFinalCost,0)
		 when JCUO.ProjMethod <> 2 and isnull(ActualCost,0) = 0 then isnull(ProjFinalCost,0)
		 when JCUO.ProjMethod = 2 and isnull(ActualCmtdCost,0) <> 0 then isnull(ProjFinalCost,0) - isnull(ActualCmtdCost,0)
		 when JCUO.ProjMethod <> 2 and isnull(ActualCost,0) <> 0 then isnull(ProjFinalCost,0) - isnull(ActualCost,0)
		 end
else
	case JCUO.ProjMethod when 2 then -isnull(ActualCmtdCost,0) else -isnull(ActualCost,0) end
	end
as RemainCost,

--CASE WHEN isnull(ProjFinalCost,0) <> 0
--	 then isnull(ProjFinalCost,0) - case JCUO.ProjMethod when 2 then isnull(ActualCmtdCost,0) else isnull(ActualCost,0) end
--	 ELSE
--		case JCUO.ProjMethod when 2 then -isnull(ActualCmtdCost,0) else -isnull(ActualCost,0) end
--	 END
--as RemainCost,


---- UNIT COSTS
CAST(CASE WHEN isnull(x.CurrEstPlusInclUnits,0) <> 0 THEN ABS(isnull(x.CurrEstPlusInclCosts,0) / isnull(x.CurrEstPlusInclUnits,0)) ELSE 0 END as numeric(16,5))
as CurrentEstimatedUnitCost,

CAST(CASE WHEN isnull(ActualUnits,0) <> 0 THEN ABS(isnull(ActualCost,0) / isnull(ActualUnits,0)) ELSE 0 END as numeric(16,5))
as ActualUnitCost,

CAST(CASE WHEN isnull(PrevProjUnits,0) <> 0 THEN ABS(isnull(PrevProjCost,0) / isnull(PrevProjUnits,0)) ELSE 0 END as numeric(16,5))
as PreviousUnitCost,

CAST(CASE WHEN isnull(ForecastFinalUnits,0) <> 0 THEN ABS(isnull(ForecastFinalCost,0) / isnull(ForecastFinalUnits,0)) ELSE 0 END as numeric(16,5))
as ForecastUnitCost,

CAST(CASE WHEN isnull(ProjFinalCost,0) <> 0
	 THEN CASE WHEN isnull(ProjFinalUnits,0) <> 0 THEN ABS(isnull(ProjFinalCost,0) / isnull(ProjFinalUnits,0)) ELSE 1 END
	 END
as numeric(16,5)) as ProjectedFinalUnitCost,

---- percent complete unit cost
CAST(isnull(CASE WHEN ABS(x.CurrEstPlusInclUnits) + ABS(ActualUnits) <> 0 THEN
	CASE WHEN ProjFinalCost <> 0 THEN 
		CASE WHEN ABS(ActualCost/ProjFinalCost) < 100 THEN
				ABS(ActualCost/ProjFinalCost) * 100
		ELSE
			9999.999999
		END	
	END
END,0) as numeric(12,6)) as PercentCompleteUnitCost,

---- over/under unit cost
CAST(isnull(CASE WHEN ABS(x.CurrEstPlusInclCosts) + ABS(ActualCost) <> 0 THEN
	CASE 
	WHEN CASE WHEN ABS(x.CurrEstPlusInclUnits) + ABS(CASE JCUO.ProjMethod WHEN 2 THEN ActualCmtdUnits ELSE ActualUnits END) <> 0 THEN
			CASE WHEN ProjFinalUnits <> 0 THEN
				ProjFinalUnits - x.CurrEstPlusInclUnits
			ELSE	
				-x.CurrEstPlusInclUnits
			END -- OverUnderUnits
		END <> 0 THEN 
		ABS(CASE WHEN ABS(x.CurrEstPlusInclCosts) + ABS(ActualCost) <> 0 THEN
				CASE WHEN ProjFinalCost <> 0 THEN 
					ProjFinalCost - x.CurrEstPlusInclCosts
				ELSE 
					-x.CurrEstPlusInclCosts
				END
			END 
		/ CASE WHEN ABS(x.CurrEstPlusInclUnits) + ABS(CASE JCUO.ProjMethod WHEN 2 THEN ActualCmtdUnits ELSE ActualUnits END) <> 0 THEN
				CASE WHEN ProjFinalUnits <> 0 THEN
					ProjFinalUnits - x.CurrEstPlusInclUnits
				ELSE	
					-x.CurrEstPlusInclUnits
				END
		END)
	ELSE 
		0
	END
END,0) as numeric(16,5)) as OverUnderUnitCost,

---- remaining unit cost
CAST(isnull(CASE WHEN ABS(x.CurrEstPlusInclCosts) + ABS(ActualCost) <> 0 THEN
	CASE WHEN CASE WHEN ABS(x.CurrEstPlusInclUnits) + ABS(CASE JCUO.ProjMethod WHEN 2 THEN ActualCmtdUnits ELSE ActualUnits END) <> 0 THEN
							CASE WHEN ProjFinalUnits <> 0 THEN ProjFinalUnits - CASE JCUO.ProjMethod WHEN 2 THEN ActualCmtdUnits ELSE ActualUnits END 
								ELSE -CASE JCUO.ProjMethod WHEN 2 THEN ActualCmtdUnits ELSE ActualUnits END
							END
						END <> 0 THEN
		ABS(CASE WHEN ABS(x.CurrEstPlusInclCosts) + ABS(ActualCost) <> 0THEN
				CASE WHEN ProjFinalCost <> 0 THEN
					ProjFinalCost - ActualCost
				ELSE	
					-ActualCost
				END
			END -- Remaining Cost
		/ CASE WHEN ABS(x.CurrEstPlusInclUnits) + ABS(CASE JCUO.ProjMethod WHEN 2 THEN ActualCmtdUnits ELSE ActualUnits END) <> 0 THEN
							CASE WHEN ProjFinalUnits <> 0 THEN ProjFinalUnits - CASE JCUO.ProjMethod WHEN 2 THEN ActualCmtdUnits ELSE ActualUnits END 
								ELSE -CASE JCUO.ProjMethod WHEN 2 THEN ActualCmtdUnits ELSE ActualUnits END
							END
						END) -- Remaining Units
	ELSE	
		0
	END
END,0) as numeric(16,5)) as RemainUnitCost,

--Production
CAST(isnull(Case JCUO.Production
	WHEN 0 THEN --Unit / Hour
		CASE WHEN ABS(x.CurrEstPlusInclUnits) + ABS (x.CurrEstPlusInclHours) <> 0  AND ABS (x.CurrEstPlusInclHours) <> 0 THEN
			ABS(x.CurrEstPlusInclUnits / x.CurrEstPlusInclHours)
		END
	WHEN 1 THEN -- Hour / Unit
		CASE WHEN ABS(x.CurrEstPlusInclUnits) + ABS (x.CurrEstPlusInclHours) <> 0 AND ABS(x.CurrEstPlusInclUnits) <> 0 THEN
			ABS(x.CurrEstPlusInclHours / x.CurrEstPlusInclUnits)
		END
	WHEN 2 THEN -- ManDays
		CASE WHEN ABS (x.CurrEstPlusInclHours) <> 0 THEN
			ABS(x.CurrEstPlusInclHours / CASE WHEN HrsPerManDay = 0 THEN 8 ELSE HrsPerManDay END )
		END
	WHEN 3 THEN -- Cost / Hour
		CASE WHEN ABS (x.CurrEstPlusInclCosts) + ABS (x.CurrEstPlusInclHours) <> 0 AND ABS (x.CurrEstPlusInclHours) <> 0 THEN
			ABS(x.CurrEstPlusInclCosts / x.CurrEstPlusInclHours)
		END
END,0) as numeric(16,5)) as CurrentEstimateProduction,

---- actual production
CAST(isnull(Case JCUO.Production
	WHEN 0 THEN --Unit / Hour
		CASE WHEN ABS(ActualUnits) + ABS (ActualHours) <> 0 AND ABS (ActualHours) <> 0 THEN
			ABS(ActualUnits / ActualHours)
		END
	WHEN 1 THEN -- Hour / Unit
		CASE WHEN ABS(ActualUnits) + ABS (ActualHours) <> 0 AND ABS(ActualUnits) <> 0 THEN
			ABS(ActualHours / ActualUnits)
		END

	WHEN 2 THEN -- ManDays
		CASE WHEN ABS (ActualHours) <> 0 THEN
			ABS(ActualHours / CASE WHEN HrsPerManDay = 0 THEN 8 ELSE HrsPerManDay END )
		END

	WHEN 3 THEN -- Cost / Hour
		CASE WHEN ABS (ActualCost) + ABS (ActualHours) <> 0 AND ABS (ActualHours) <> 0 THEN
			ABS(ActualCost / ActualHours)
		END

END,0) as numeric(16,5)) as ActualProduction,

---- previous production
CAST(isnull(Case JCUO.Production
	WHEN 0 THEN --Unit / Hour
		CASE WHEN ABS(PrevProjUnits) + ABS (PrevProjHours) <> 0 AND ABS (PrevProjHours) <> 0 THEN
			ABS(PrevProjUnits / PrevProjHours)
		END
	WHEN 1 THEN -- Hour / Unit
		CASE WHEN ABS(PrevProjUnits) + ABS (PrevProjHours) <> 0 AND ABS(PrevProjUnits) <> 0 THEN
			ABS(PrevProjHours / PrevProjUnits)
		END

	WHEN 2 THEN -- ManDays
		CASE WHEN ABS (PrevProjHours) <> 0 THEN
			ABS(PrevProjHours / CASE WHEN HrsPerManDay = 0 THEN 8 ELSE HrsPerManDay END )
		END

	WHEN 3 THEN -- Cost / Hour
		CASE WHEN ABS (PrevProjCost) + ABS (PrevProjHours) <> 0 AND ABS (PrevProjHours) <> 0 THEN
			ABS(PrevProjCost / PrevProjHours)
		END

END,0) as numeric(16,5)) as PreviousProduction,

---- forecast production
CAST(isnull(Case JCUO.Production
	WHEN 0 THEN --Unit / Hour
		CASE WHEN ABS(ForecastFinalUnits) + ABS (ForecastFinalHrs) <> 0 AND ABS (ForecastFinalHrs) <> 0 THEN
			ABS(ForecastFinalUnits / ForecastFinalHrs)
		END
	WHEN 1 THEN -- Hour / Unit
		CASE WHEN ABS(ForecastFinalUnits) + ABS (ForecastFinalHrs) <> 0 AND ABS(ForecastFinalUnits) <> 0 THEN
			ABS(ForecastFinalHrs / ForecastFinalUnits)
		END

	WHEN 2 THEN -- ManDays
		CASE WHEN ABS (ForecastFinalHrs) <> 0 THEN
			ABS(ForecastFinalHrs / CASE WHEN HrsPerManDay = 0 THEN 8 ELSE HrsPerManDay END )
		END

	WHEN 3 THEN -- Cost / Hour
		CASE WHEN ABS (ForecastFinalCost) + ABS (ForecastFinalHrs) <> 0 AND ABS (ForecastFinalHrs) <> 0 THEN
			ABS(ForecastFinalCost / ForecastFinalHrs)
		END

END,0) as numeric(16,5)) as ForecastProduction,

---- projected final production
CAST(isnull(Case JCUO.Production
	WHEN 0 THEN --Unit / Hour
		CASE WHEN ABS(ProjFinalUnits) + ABS (ProjFinalHrs) <> 0 AND ABS (ProjFinalHrs) <> 0 THEN
			ABS(ProjFinalUnits / ProjFinalHrs)
		END
	WHEN 1 THEN -- Hour / Unit
		CASE WHEN ABS(ProjFinalUnits) + ABS (ProjFinalHrs) <> 0 AND ABS(ProjFinalUnits) <> 0 THEN
			ABS(ProjFinalHrs / ProjFinalUnits)
		END

	WHEN 2 THEN -- ManDays
		CASE WHEN ABS (ProjFinalHrs) <> 0 THEN
			ABS(ProjFinalHrs / CASE WHEN HrsPerManDay = 0 THEN 8 ELSE HrsPerManDay END )
		END

	WHEN 3 THEN -- Cost / Hour
		CASE WHEN ABS (ProjFinalCost) + ABS (ProjFinalHrs) <> 0 AND ABS (ProjFinalHrs) <> 0 THEN
			ABS(ProjFinalCost / ProjFinalHrs)
		END

END,0) as numeric(16,5)) as ProjectedFinalProduction,

---- percent complete production
CAST(isnull(Case JCUO.Production
	WHEN 0 THEN --Unit / Hour
		CASE WHEN  isnull(ProjFinalHrs,0) <> 0  and isnull(ProjFinalUnits,0) <> 0 THEN
			CASE WHEN ABS(ActualHours / ProjFinalHrs) < 100 THEN
				ABS(ActualHours / ProjFinalHrs) * 100
			ELSE
				9999.99999
			END
		END

	WHEN 1 THEN -- Hour / Unit
		CASE WHEN isnull(ProjFinalHrs,0) <> 0  and isnull(ProjFinalUnits,0) <> 0 THEN
			CASE WHEN ABS(ActualHours / ProjFinalHrs) < 100 THEN
				ABS(ActualHours / ProjFinalHrs) * 100
			ELSE
				9999.99999
			END
		END

	WHEN 2 THEN -- ManDays
		CASE WHEN isnull(ProjFinalHrs,0) <> 0  and isnull(ProjFinalUnits,0) <> 0 THEN
			CASE WHEN ABS(ActualHours / ProjFinalHrs) < 100 THEN
				ABS(ActualHours / ProjFinalHrs) * 100
			ELSE
				9999.99999
			END
		END

	WHEN 3 THEN -- Cost / Hour
		CASE WHEN isnull(ActualCost,0) <> 0 AND isnull(ProjFinalHrs,0) <> 0 THEN
			CASE WHEN ABS(ActualCost / ProjFinalHrs) < 100 THEN
				ABS(ActualCost / ProjFinalHrs) * 100
			ELSE
				9999.99999
			END
		END

END,0) as numeric(12,5)) as PercentCompleteProduction,

---- over/under production
CAST(isnull(Case JCUO.Production
	WHEN 0 THEN --Unit / Hour
		CASE WHEN  isnull(CASE WHEN ABS(x.CurrEstPlusInclUnits) + ABS(CASE JCUO.ProjMethod WHEN 2 THEN ActualCmtdUnits ELSE ActualUnits END) <> 0 THEN
							CASE WHEN ProjFinalUnits <> 0 THEN
								ProjFinalUnits - x.CurrEstPlusInclUnits
							ELSE	
								-x.CurrEstPlusInclUnits
							END
						END,0) <> 0  and 
					isnull(CASE WHEN ABS(x.CurrEstPlusInclHours) + ABS(ActualHours) <> 0 THEN
								CASE WHEN ProjFinalHrs <> 0 THEN 
									ProjFinalHrs - x.CurrEstPlusInclHours
								ELSE 
									-x.CurrEstPlusInclHours
								END
							END,0) <> 0 THEN
			ABS(CASE WHEN ABS(x.CurrEstPlusInclUnits) + ABS(CASE JCUO.ProjMethod WHEN 2 THEN ActualCmtdUnits ELSE ActualUnits END) <> 0 THEN
					CASE WHEN ProjFinalUnits <> 0 THEN
						ProjFinalUnits - x.CurrEstPlusInclUnits
					ELSE	
						-x.CurrEstPlusInclUnits
					END
				END 
				/ 
				CASE WHEN ABS(x.CurrEstPlusInclHours) + ABS(ActualHours) <> 0 THEN
					CASE WHEN ProjFinalHrs <> 0 THEN 
						ProjFinalHrs - x.CurrEstPlusInclHours
					ELSE 
						-x.CurrEstPlusInclHours
					END
				END)
		END
	WHEN 1 THEN -- Hour / Unit
		CASE WHEN isnull(CASE WHEN ABS(x.CurrEstPlusInclUnits) + ABS(CASE JCUO.ProjMethod WHEN 2 THEN ActualCmtdUnits ELSE ActualUnits END) <> 0 THEN
							CASE WHEN ProjFinalUnits <> 0 THEN
								ProjFinalUnits - x.CurrEstPlusInclUnits
							ELSE	
								-x.CurrEstPlusInclUnits
							END
						END,0) <> 0  and 
				isnull(CASE WHEN ABS(x.CurrEstPlusInclHours) + ABS(ActualHours) <> 0 THEN
						CASE WHEN ProjFinalHrs <> 0 THEN 
							ProjFinalHrs - x.CurrEstPlusInclHours
						ELSE 
							-x.CurrEstPlusInclHours
						END
					END,0) <> 0 THEN
			ABS(CASE WHEN ABS(x.CurrEstPlusInclHours) + ABS(ActualHours) <> 0 THEN
					CASE WHEN ProjFinalHrs <> 0 THEN 
						ProjFinalHrs - x.CurrEstPlusInclHours
					ELSE 
						-x.CurrEstPlusInclHours
					END
				END 
				/ 
				CASE WHEN ABS(x.CurrEstPlusInclUnits) + ABS(CASE JCUO.ProjMethod WHEN 2 THEN ActualCmtdUnits ELSE ActualUnits END) <> 0 THEN
					CASE WHEN ProjFinalUnits <> 0 THEN
						ProjFinalUnits - x.CurrEstPlusInclUnits
					ELSE	
						-x.CurrEstPlusInclUnits
					END
				END)
		END

	WHEN 2 THEN -- ManDays
		CASE WHEN isnull(CASE WHEN ABS(x.CurrEstPlusInclHours) + ABS(ActualHours) <> 0 THEN
							CASE WHEN ProjFinalHrs <> 0 THEN 
								ProjFinalHrs - x.CurrEstPlusInclHours
							ELSE 
								-x.CurrEstPlusInclHours
							END
						END,0) <> 0  and 
				  isnull(ProjFinalUnits,0) <> 0 THEN
			ABS(CASE WHEN ABS(x.CurrEstPlusInclHours) + ABS(ActualHours) <> 0 THEN
					CASE WHEN ProjFinalHrs <> 0 THEN 
						ProjFinalHrs - x.CurrEstPlusInclHours
					ELSE 
						-x.CurrEstPlusInclHours
					END
				END 
				/ 
				CASE WHEN HrsPerManDay = 0 THEN 8 ELSE HrsPerManDay END)
		END

	WHEN 3 THEN -- Cost / Hour
		CASE WHEN isnull(ProjFinalCost,0) <> 0 AND 
				  isnull(CASE WHEN ABS(x.CurrEstPlusInclHours) + ABS(ActualHours) <> 0 THEN
							CASE WHEN ProjFinalHrs <> 0 THEN 
								ProjFinalHrs - x.CurrEstPlusInclHours
							ELSE 
								-x.CurrEstPlusInclHours
							END
						END,0) <> 0  THEN
			ABS(ProjFinalCost 
				/ 
				CASE WHEN ABS(x.CurrEstPlusInclHours) + ABS(ActualHours) <> 0 THEN
					CASE WHEN ProjFinalHrs <> 0 THEN 
						ProjFinalHrs - x.CurrEstPlusInclHours
					ELSE 
						-x.CurrEstPlusInclHours
					END
				END)
		END

END,0) as numeric(16,5)) as OverUnderProduction,

---- remaining production
CAST(isnull(Case JCUO.Production
	WHEN 0 THEN --Unit / Hour
		CASE WHEN  isnull(CASE WHEN ABS(x.CurrEstPlusInclUnits) + ABS(CASE JCUO.ProjMethod WHEN 2 THEN ActualCmtdUnits ELSE ActualUnits END) <> 0 THEN
							CASE WHEN ProjFinalUnits <> 0 THEN ProjFinalUnits - CASE JCUO.ProjMethod WHEN 2 THEN ActualCmtdUnits ELSE ActualUnits END 
								ELSE -CASE JCUO.ProjMethod WHEN 2 THEN ActualCmtdUnits ELSE ActualUnits END
							END
						END,0) <> 0  and 
					isnull(CASE WHEN ABS(x.CurrEstPlusInclHours) + ABS(ActualHours) <> 0 THEN
							CASE WHEN ProjFinalHrs <> 0 THEN
								ProjFinalHrs - ActualHours
							ELSE	
								-ActualHours
							END
						END,0) <> 0 THEN
			ABS(CASE WHEN ABS(x.CurrEstPlusInclUnits) + ABS(CASE JCUO.ProjMethod WHEN 2 THEN ActualCmtdUnits ELSE ActualUnits END) <> 0 THEN
					CASE WHEN ProjFinalUnits <> 0 THEN ProjFinalUnits - CASE JCUO.ProjMethod WHEN 2 THEN ActualCmtdUnits ELSE ActualUnits END 
					ELSE -CASE JCUO.ProjMethod WHEN 2 THEN ActualCmtdUnits ELSE ActualUnits END
					END
				END 
				/ 
				CASE WHEN ABS(x.CurrEstPlusInclHours) + ABS(ActualHours) <> 0 THEN
					CASE WHEN ProjFinalHrs <> 0 THEN
						ProjFinalHrs - ActualHours
					ELSE	
						-ActualHours
					END
				END)
		END
	WHEN 1 THEN -- Hour / Unit
		CASE WHEN isnull(CASE WHEN ABS(x.CurrEstPlusInclUnits) + ABS(CASE JCUO.ProjMethod WHEN 2 THEN ActualCmtdUnits ELSE ActualUnits END) <> 0 THEN
							CASE WHEN ProjFinalUnits <> 0 THEN ProjFinalUnits - CASE JCUO.ProjMethod WHEN 2 THEN ActualCmtdUnits ELSE ActualUnits END 
							ELSE -CASE JCUO.ProjMethod WHEN 2 THEN ActualCmtdUnits ELSE ActualUnits END
							END
						END,0) <> 0  and 
					isnull(CASE WHEN ABS(x.CurrEstPlusInclHours) + ABS(ActualHours) <> 0 THEN
							CASE WHEN ProjFinalHrs <> 0 THEN
								ProjFinalHrs - ActualHours
							ELSE	
								-ActualHours
							END
						END,0) <> 0 THEN
			ABS(CASE WHEN ABS(x.CurrEstPlusInclHours) + ABS(ActualHours) <> 0 THEN
					CASE WHEN ProjFinalHrs <> 0 THEN
						ProjFinalHrs - ActualHours
					ELSE	
						-ActualHours
					END
				END 
				/ 
				CASE WHEN ABS(x.CurrEstPlusInclUnits) + ABS(CASE JCUO.ProjMethod WHEN 2 THEN ActualCmtdUnits ELSE ActualUnits END) <> 0 THEN
					CASE WHEN ProjFinalUnits <> 0 THEN ProjFinalUnits - CASE JCUO.ProjMethod WHEN 2 THEN ActualCmtdUnits ELSE ActualUnits END 
					ELSE -CASE JCUO.ProjMethod WHEN 2 THEN ActualCmtdUnits ELSE ActualUnits END
					END
				END)
		END

	WHEN 2 THEN -- ManDays
		CASE WHEN isnull(CASE WHEN ABS(x.CurrEstPlusInclHours) + ABS(ActualHours) <> 0 THEN
							CASE WHEN ProjFinalHrs <> 0 THEN
								ProjFinalHrs - ActualHours
							ELSE	
								-ActualHours
							END
						END,0) <> 0 THEN
			ABS(CASE WHEN ABS(x.CurrEstPlusInclHours) + ABS(ActualHours) <> 0 THEN
					CASE WHEN ProjFinalHrs <> 0 THEN
						ProjFinalHrs - ActualHours
					ELSE	
						-ActualHours
					END
				END 
			/ CASE WHEN HrsPerManDay = 0 THEN 8 ELSE HrsPerManDay END)
		END

	WHEN 3 THEN -- Cost / Hour
		CASE WHEN isnull(CASE WHEN ABS(x.CurrEstPlusInclCosts) + ABS(ActualCost) <> 0 THEN
							CASE WHEN ProjFinalCost <> 0 THEN
								ProjFinalCost - ActualCost
							ELSE	
								-ActualCost
							END
						END,0) <> 0 
				  AND 
				  isnull(CASE WHEN ABS(x.CurrEstPlusInclHours) + ABS(ActualHours) <> 0 THEN
							CASE WHEN ProjFinalHrs <> 0 THEN
								ProjFinalHrs - ActualHours
							ELSE	
								-ActualHours
							END
						END,0) <> 0  THEN
			ABS(CASE WHEN ABS(x.CurrEstPlusInclCosts) + ABS(ActualCost) <> 0THEN
					CASE WHEN ProjFinalCost <> 0 THEN
						ProjFinalCost - ActualCost
					ELSE	
						-ActualCost
					END
				END 
				/ 
				CASE WHEN ABS(x.CurrEstPlusInclHours) + ABS(ActualHours) <> 0 THEN
					CASE WHEN ProjFinalHrs <> 0 THEN
						ProjFinalHrs - ActualHours
					ELSE	
						-ActualHours
					END
				END)
		END

END,0) as numeric(16,5)) as RemainingProduction,

---- notes check box flag
Case when JCCH.ProjNotes is null then 'N' else 'Y' end as Notes,
JCCH.BuyOutYN as BuyOutFlag

From bJCPB JCPB with (nolock)

join bJCJM JCJM with (nolock) on JCJM.JCCo=JCPB.Co and JCJM.Job=JCPB.Job
join bJCCH JCCH with (nolock) on JCCH.JCCo=JCPB.Co and JCCH.Job=JCPB.Job
and JCCH.PhaseGroup=JCPB.PhaseGroup and JCCH.Phase=JCPB.Phase and JCCH.CostType=JCPB.CostType
join bJCUO JCUO with (nolock) on JCUO.JCCo=JCPB.Co and JCUO.Form = 'JCProjection' and JCUO.UserName = SUSER_SNAME()
join dbo.JCPBCurrEstPlusIncl x with (nolock) on x.Co=JCPB.Co and x.Mth=JCPB.Mth and x.BatchId=JCPB.BatchId and x.BatchSeq=JCPB.BatchSeq





















GO
GRANT SELECT ON  [dbo].[JCPBCalculations] TO [public]
GRANT INSERT ON  [dbo].[JCPBCalculations] TO [public]
GRANT DELETE ON  [dbo].[JCPBCalculations] TO [public]
GRANT UPDATE ON  [dbo].[JCPBCalculations] TO [public]
GRANT SELECT ON  [dbo].[JCPBCalculations] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCPBCalculations] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCPBCalculations] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCPBCalculations] TO [Viewpoint]
GO
