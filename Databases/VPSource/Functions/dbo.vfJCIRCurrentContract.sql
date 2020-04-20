SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[vfJCIRCurrentContract](@Company int, @Mth smalldatetime, @Contract varchar(30), @Item varchar(30))
RETURNS TABLE
AS
/********************************************
* Created By:	GF 04/20/2010 - issue #139161
* Modified By:
*
* returns projected revenue and untis for a contract and item for use in JCIRTotals - JC Revenue Projections.
*
********************************************/


RETURN (SELECT cast(isnull(sum(c.ContractUnits),0) as numeric(20,2)) as CurrentUnits,
			   cast(isnull(sum(c.ContractAmt),0)   as numeric(20,2)) as CurrentContract   
			FROM dbo.bJCIP c with (nolock)
			where c.JCCo=@Company and c.Contract=@Contract and c.Item=@Item and c.Mth<=@Mth)

GO
GRANT SELECT ON  [dbo].[vfJCIRCurrentContract] TO [public]
GO
