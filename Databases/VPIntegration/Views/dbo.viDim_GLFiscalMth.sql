SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[viDim_GLFiscalMth]

/**************************************************
 * Alterd: DH 4/21/08
 * Modified: DH 5/22/08  Key field based on Row Number ID, which is by each distinct GLFP.Mth, GLFP.FiscalPd
 * Usage:  Dimension View returning GL Fiscal Periods based on the GLFP and GLFY tables.
 *          Used in SSAS Cubes. FiscalMthId used for joining this dimension to Fact tables in the Cubes.
 *
 ********************************************************/

as

With CurrentFiscalYear (GLCo, CurrentFiscalYear)

/*Returns current fiscal year from GLFY based on today's date.
  If getdate is outside the fiscal year, returns todays date without time stamp*/

as

(Select   bGLFY.GLCo
		,bGLFY.FYEMO
From bGLFY
Where getdate()>=BeginMth
                    and DATEADD(d,DATEDIFF(d,0,getdate()-day(getdate())+1),0) <= FYEMO)

/*,MaxFiscalYear (GLCo, MaxFiscalYear)

as

(Select	bGLFY.GLCo,
		max(bGLFY.FYEMO) 
	    From bGLFY
		Group By bGLFY.GLCo)*/

,FiscalPeriods (GLCo, Mth, FiscalPd, FYEMO, FiscalYearEndMthID, ShortYearDesc, CurrentFiscalYear)


as

(
  Select  bGLFP.GLCo
		 ,bGLFP.Mth
		 ,bGLFP.FiscalPd
         ,bGLFY.FYEMO
		 ,Cast( 
              cast(datediff(dd,'1/1/1950',bGLFY.FYEMO) as varchar)
              +(case when datediff(mm,bGLFY.BeginMth,bGLFY.FYEMO)<11 then '1' else '0' end)
		    as int) as FiscalYearEndMthID
		 ,case when datediff(mm,bGLFY.BeginMth,bGLFY.FYEMO)<11 then ' (Short Year)' else '' end as ShortYearDesc
		 ,isnull(CurrentFiscalYear,DATEADD(d,DATEDIFF(d,0,getdate()-day(getdate())+1),0))/*=case when CurrentFiscalYear is not null then CurrentFiscalYear else MaxFiscalYear end */
										/*Returns current fiscal year from GLFY based on today's date.
                                     If getdate is outside the fiscal year, returns todays date without
                                     time stamp*/
 
    From bGLFP With (NoLock)
    Join bGLFY With (NoLock) on bGLFY.GLCo=bGLFP.GLCo and bGLFP.Mth>=bGLFY.BeginMth and bGLFP.Mth<=bGLFY.FYEMO
    Left Join CurrentFiscalYear on CurrentFiscalYear.GLCo=bGLFP.GLCo
	--Left Join MaxFiscalYear on MaxFiscalYear.GLCo=bGLFP.GLCo

)

Select   FiscalPeriods.GLCo
		,bGLCO.KeyID as GLCoID
		,bHQCO.Name as GLCompanyName
		,FiscalPeriods.Mth
        ,FiscalPeriods.FiscalPd
		,Month(FiscalPeriods.Mth) as FiscalMonthNumber
        ,Left(datename(m,FiscalPeriods.Mth),3)/*+' '+datename(yy,FiscalPeriods.Mth)*/ as FiscalMthName
	    ,Left(datename(m,FiscalPeriods.Mth),3) +' '+datename(yy,FiscalPeriods.Mth) as FiscalMthNameandYear
        ,case when FiscalPeriods.FiscalPd between 1 and 3 then cast(cast(FiscalPeriods.FiscalYearEndMthID as varchar) +'1' as int)
			  when FiscalPeriods.FiscalPd between 4 and 6 then cast(cast(FiscalPeriods.FiscalYearEndMthID as varchar) +'2' as int)
			  when FiscalPeriods.FiscalPd between 7 and 9 then cast(cast(FiscalPeriods.FiscalYearEndMthID as varchar) +'3' as int)
			  when FiscalPeriods.FiscalPd between 10 and 12 then cast(cast(FiscalPeriods.FiscalYearEndMthID as varchar) +'4' as int)
		 end 
         as FiscalQtrID
	    ,case when FiscalPeriods.FiscalPd between 1 and 3 then 1
              when FiscalPeriods.FiscalPd between 4 and 6 then 2
              when FiscalPeriods.FiscalPd between 7 and 9 then 3
              when FiscalPeriods.FiscalPd between 10 and 12 then 4
         end as FiscalQtr
		,case when FiscalPeriods.FiscalPd between 1 and 3 then 'Q'+ cast(1 as char(1))
              when FiscalPeriods.FiscalPd between 4 and 6 then 'Q'+ cast(2 as char(1))
              when FiscalPeriods.FiscalPd between 7 and 9 then 'Q'+ cast(3 as char(1))
              when FiscalPeriods.FiscalPd between 10 and 12 then 'Q'+ cast(4 as char(1))
         end as FiscalQtrShortName

        ,(case when FiscalPeriods.FiscalPd between 1 and 3 then 'Q'+ cast(1 as char(1))+' '+cast(DATEPART(yy,FiscalPeriods.FYEMO) as varchar)
              when FiscalPeriods.FiscalPd between 4 and 6 then 'Q'+ cast(2 as char(1))+' '+cast(DATEPART(yy,FiscalPeriods.FYEMO) as varchar)
              when FiscalPeriods.FiscalPd between 7 and 9 then 'Q'+ cast(3 as char(1))+' '+cast(DATEPART(yy,FiscalPeriods.FYEMO) as varchar)
              when FiscalPeriods.FiscalPd between 10 and 12 then 'Q'+ cast(4 as char(1))+' '+cast(DATEPART(yy,FiscalPeriods.FYEMO) as varchar)
         end)+FiscalPeriods.ShortYearDesc
		/*+(case when DateDiff(year, FYEMO, CurrentFiscalYear) > 2 
			   then ' ('+Left(datename(m,FiscalPeriods.FYEMO),3)+' Fiscal)'
		       else FiscalPeriods.ShortYearDesc end)*/ as FiscalQtrShortNameWithYear
		,Year(FiscalPeriods.FYEMO) as FiscalYrNumber
        ,FiscalPeriods.FYEMO as FiscalYrEndMth
		,FiscalPeriods.FiscalYearEndMthID
        ,Left(datename(m,FiscalPeriods.FYEMO),3)+' '+datename(yy, FiscalPeriods.FYEMO)+FiscalPeriods.ShortYearDesc as FiscalYrEndMthName
        ,CurrentFiscalYear
		,case when DateDiff(year, FYEMO, CurrentFiscalYear)<=2 
                   --and DateDiff(year, FYEMO, CurrentFiscalYear)<=2
             	then 2--FiscalPeriods.FiscalYearEndMthID
              else 
				   1
			 end as FiscalYearEndMthLast3ID 
		,case when DateDiff(year, FYEMO, CurrentFiscalYear)<=2 
                   --and DateDiff(year, FYEMO, CurrentFiscalYear)<=2
              then FYEMO
              else Null
              end as FiscalYrEndMthLast3 /*Return FYEMO if within three years of current fiscal year*/
        ,case when DateDiff(year, FYEMO, CurrentFiscalYear)<=2 
                   --and DateDiff(year, FYEMO, CurrentFiscalYear)<=2
              then 
				 'Last Three Fiscal Years'
                 --Left(datename(m,FiscalPeriods.FYEMO),3)+' '+datename(yy, FiscalPeriods.FYEMO) + FiscalPeriods.ShortYearDesc
              else 'All Prior Years' end
              as FiscalYrEndMthLast3Name
        --,datediff(mm,'1/1/1950',FiscalPeriods.Mth) as FiscalMthID
        --,Row_Number() Over (Order By FiscalPeriods.GLCo, FiscalPeriods.Mth, FiscalPeriods.FiscalPd) as FiscalMthID
        ,isnull(Cast(cast(FiscalPeriods.GLCo as varchar(3))+cast(Datediff(dd,'1/1/1950',FiscalPeriods.Mth) as varchar(10)) as int),0) as FiscalMthID
		,cast(cast(FiscalPeriods.FiscalYearEndMthID as varchar)+right('0'+cast(Month(FiscalPeriods.Mth) as varchar),2) as int) as FiscalMthOfYearID
From FiscalPeriods With (NoLock)
Join bGLCO With (NoLock) on bGLCO.GLCo=FiscalPeriods.GLCo
Join bHQCO With (NoLock) on bHQCO.HQCo=FiscalPeriods.GLCo


union all

/*Place holder record for Null Fiscal Years, set FiscalMthID to 0*/

Select   Null as GLCo,
		 Null as GLCoID,
		 Null as GLCompanyName,
		 Null as Mth,
         Null as FiscalPd,
		 Null as FiscalMthNumber,
         Null as FiscalMthName,
		 Null as FiscalMthNameandYear,
		 0 as FiscalQtrID,
         Null as FiscalQtr,
		 Null as FiscalQtrShortName,
		 Null as FiscalQtrShortNameWithYear,
         Null as FiscalYrNumber,
         Null as FiscalYrEndMth,
		 0 as FiscalYearEndMthID,
         Null as FiscalYrEndMthName,
         Null CurrentFiscalYear,
		 Null as FiscalYearEndMthLast3ID,
		 Null as FiscalYrEndMthLast3, 
         'Unassigned' as FiscalYrEndMthLast3Name,
         0 as FiscalMthID,
		 Null as FiscalMthOfYearID

/****** Object:  View [dbo].[viFact_JCDetail]    Script Date: 05/07/2009 14:53:30 ******/

GO
GRANT SELECT ON  [dbo].[viDim_GLFiscalMth] TO [public]
GRANT INSERT ON  [dbo].[viDim_GLFiscalMth] TO [public]
GRANT DELETE ON  [dbo].[viDim_GLFiscalMth] TO [public]
GRANT UPDATE ON  [dbo].[viDim_GLFiscalMth] TO [public]
GO
