SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************
* CREATED BY:	GP 04/15/2011
* MODIFIED By:	GP 11/16/2011 - TK-09987 Changed SQL to sub select in order to avoid calculating
*								multiple PCO records into the total.
*				GP 11/18/2011 - TK-09987 Updated SQL to use CTE, sub select was miscalculating.
*
* USAGE:
*		Gets the sum of change in days for ACOs specified in vPMContractChangeOrderACO
*
* INPUT PARAMETERS
*		@PMCo bCompany = null,
*		@Contract bContract = null,
*		@ID smallint = null
*
*
* OUTPUT PARAMETERS
*		@ChangeInDays
*
* RETURN VALUE
*		0         success
*		1         Failure or nothing to format
*****************************************************/

CREATE FUNCTION [dbo].[vfPMContractChangeOrderChangeInDaysDefault]
(@PMCo bCompany = null, @Contract bContract = null, @ID smallint = null)

returns smallint
as

begin
	declare @ChangeInDays smallint;

	with CCO_CTE (PMCo, [Contract], ID, Project, ACO, PCOType, PCO, ChangeInDays)
	as
	(
		select a.PMCo, a.[Contract], a.ID, a.Project, a.ACO, a.PCOType, a.PCO, i.ChangeDays
		from dbo.PMContractChangeOrderACO a
		join dbo.PMOI i on i.PMCo=a.PMCo and i.Project=a.Project 
			and isnull(i.PCOType,'1')=isnull(a.PCOType,'1') and isnull(i.PCO,'1')=isnull(a.PCO,'1') 
			and i.ACO=a.ACO
		where a.PMCo = @PMCo and a.[Contract] = @Contract and a.ID = @ID
		group by a.PMCo, a.[Contract], a.ID, a.Project, a.ACO, a.PCOType, a.PCO, i.ChangeDays
	)

	select @ChangeInDays = isnull(sum(ChangeInDays), 0)
	from CCO_CTE
		
		
	exitfunction:	
		return isnull(@ChangeInDays, 0)

end

GO
GRANT EXECUTE ON  [dbo].[vfPMContractChangeOrderChangeInDaysDefault] TO [public]
GO
