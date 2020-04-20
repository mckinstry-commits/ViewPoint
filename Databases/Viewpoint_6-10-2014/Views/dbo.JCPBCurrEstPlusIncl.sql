SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/******************************************
* Created By:	GF 01/19/2010 - issue #137604 use new view to calculate over/under with included co values.
*
*
*******************************************/

CREATE view [dbo].[JCPBCurrEstPlusIncl] as 
	select  JCPB.Co, JCPB.Mth, JCPB.BatchId, JCPB.BatchSeq,
			isnull(JCPB.IncludedCOs,0) + isnull(JCPB.CurrEstCost,0) as CurrEstPlusInclCosts,
			isnull(JCPB.IncludedUnits,0) + isnull(JCPB.CurrEstUnits,0) as CurrEstPlusInclUnits,
			isnull(JCPB.IncludedHours,0) + isnull(JCPB.CurrEstHours,0) as CurrEstPlusInclHours
From dbo.JCPB




GO
GRANT SELECT ON  [dbo].[JCPBCurrEstPlusIncl] TO [public]
GRANT INSERT ON  [dbo].[JCPBCurrEstPlusIncl] TO [public]
GRANT DELETE ON  [dbo].[JCPBCurrEstPlusIncl] TO [public]
GRANT UPDATE ON  [dbo].[JCPBCurrEstPlusIncl] TO [public]
GRANT SELECT ON  [dbo].[JCPBCurrEstPlusIncl] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCPBCurrEstPlusIncl] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCPBCurrEstPlusIncl] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCPBCurrEstPlusIncl] TO [Viewpoint]
GO
