SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






/*****************************************
* Created By:	DANF 08/14/2006
* Modfied By:	GF 09/29/2008 - issue #126236 changes to include in projections
*				GF 04/13/2010 - issue #139060 use approved month not approval date
*
*
* Provides a view of Future Change Orders from JC and PM for Revenue Projections.
*
*****************************************/
   
CREATE view [dbo].[JCFutureRevenueCO] as
	select JCIR.Co, JCIR.Contract, JCIR.Item, 
	ISNULL((select sum(isnull(Units,0)) from dbo.JCFutureJCCO j where j.Co = JCIR.Co and j.Cnt=JCIR.Contract
	----#139060
			and j.Item=JCIR.Item and j.ApprovedMonth> JCIR.Mth /*j.ApprovalDate>JCIR.ActualDate*/),0)+ISNULL((select sum(isnull(Units,0))
			from dbo.JCFuturePMCO p where p.Co = JCIR.Co and p.Cnt=JCIR.Contract 
			and p.Item=JCIR.Item),0) as [FutureUnits],
			
	----ISNULL((select sum(isnull(Units,0)) from dbo.JCFuturePMCO j where j.Co = JCIR.Co and j.Cnt=JCIR.Contract 
	----		and j.Item=JCIR.Item and j.ApprovalDate>JCIR.ActualDate),0)+ISNULL((select sum(isnull(Units,0)) 
	----		from dbo.JCFuturePMCO p where p.Co = JCIR.Co and p.Cnt=JCIR.Contract 
	----		and p.Item=JCIR.Item and p.ProjectionOption='C'),0) as [IncludedCOUnits],
	isnull((select sum(isnull(Units,0))
			from dbo.JCFuturePMCO p where p.Co = JCIR.Co and p.Cnt=JCIR.Contract 
			and p.Item=JCIR.Item and p.ProjectionOption='C'),0) as [IncludedCOUnits],
			
	ISNULL((select sum(isnull(Amt,0))   from dbo.JCFutureJCCO j where j.Co = JCIR.Co and j.Cnt=JCIR.Contract
	----#139060
			and j.Item=JCIR.Item and j.ApprovedMonth> JCIR.Mth /*j.ApprovalDate>JCIR.ActualDate*/),0)+ISNULL((select sum(isnull(Amt,0)) 
			from dbo.JCFuturePMCO p where p.Co = JCIR.Co and p.Cnt=JCIR.Contract 
			and p.Item=JCIR.Item),0) as [FutureAmount],
			
	----ISNULL((select sum(isnull(Amt,0))   from dbo.JCFuturePMCO j where j.Co = JCIR.Co and j.Cnt=JCIR.Contract 
	----		and j.Item=JCIR.Item and j.ApprovalDate>JCIR.ActualDate),0)+ISNULL((select sum(isnull(Amt,0)) 
	----		from dbo.JCFuturePMCO p where p.Co = JCIR.Co and p.Cnt=JCIR.Contract 
	----		and p.Item=JCIR.Item and p.ProjectionOption='C'),0) as [IncludedCOAmt]
	isnull((select sum(isnull(Amt,0))
			from dbo.JCFuturePMCO p where p.Co = JCIR.Co and p.Cnt=JCIR.Contract 
			and p.Item=JCIR.Item and p.ProjectionOption='C'),0) as [IncludedCOAmt]

from JCIR JCIR with (nolock)










GO
GRANT SELECT ON  [dbo].[JCFutureRevenueCO] TO [public]
GRANT INSERT ON  [dbo].[JCFutureRevenueCO] TO [public]
GRANT DELETE ON  [dbo].[JCFutureRevenueCO] TO [public]
GRANT UPDATE ON  [dbo].[JCFutureRevenueCO] TO [public]
GO
