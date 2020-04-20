SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/*****************************************
* Created By:	GF 05/10/2009 - issue #133577
* Modfied By:
*
* Provides a view of Current Contract Values for Revenue Projections.
*
*****************************************/

CREATE view [dbo].[JCIPForJCIR] as
	select JCIR.Co, JCIR.Mth, JCIR.Contract, JCIR.Item,
		cast(isnull(sum(JCIP.ContractUnits),0) as numeric(20,2)) as CurrentUnits,
		cast(isnull(sum(JCIP.ContractAmt),0) as numeric(20,2)) as CurrentContract
from JCIR JCIR with (nolock)
left join JCIP JCIP with (nolock) on JCIP.JCCo=JCIR.Co and JCIP.Contract=JCIR.Contract and JCIP.Item=JCIR.Item and JCIP.Mth<=JCIR.Mth
group by JCIR.Co, JCIR.Mth, JCIR.Contract, JCIR.Item




GO
GRANT SELECT ON  [dbo].[JCIPForJCIR] TO [public]
GRANT INSERT ON  [dbo].[JCIPForJCIR] TO [public]
GRANT DELETE ON  [dbo].[JCIPForJCIR] TO [public]
GRANT UPDATE ON  [dbo].[JCIPForJCIR] TO [public]
GO
