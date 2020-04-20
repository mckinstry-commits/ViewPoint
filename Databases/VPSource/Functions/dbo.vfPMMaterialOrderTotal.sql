SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Gil Fox
-- Create date: 04/30/2010
-- Description:	returns PMMF information to use when display Material Orders
-- in PM Material Order Header
-- =============================================
CREATE FUNCTION [dbo].[vfPMMaterialOrderTotal] 
(	
	-- Add the parameters for the function here
	@Company int,
	@MaterialOrder varchar(30)
)
RETURNS TABLE 
AS
RETURN 
(
	---- select information from PMMF for the PMCo, Project, INCo, and MO
	select sum(c.Amount) as 'PMMOAmt',
    	   case when sum(c.Amount) is not null then 'Y' else 'N' end as PMMOExists
	from dbo.bPMMF c
	where c.INCo=@Company and c.MO=@MaterialOrder and c.SendFlag='Y'
	and c.MaterialOption='M' and c.InterfaceDate is null
	and ((c.RecordType='O' and c.ACO is null) or (c.RecordType='C' and (c.ACO is not null OR c.PCO is not null)))
)

GO
GRANT SELECT ON  [dbo].[vfPMMaterialOrderTotal] TO [public]
GO
