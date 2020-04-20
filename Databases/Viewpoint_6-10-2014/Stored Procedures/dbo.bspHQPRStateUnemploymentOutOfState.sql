SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************/
CREATE    proc [dbo].[bspHQPRStateUnemploymentOutOfState]
/**********************************************
* Created By:  CHS	11/11/2013 
* Modified By:
*
* gathers out of states wage information.  
*
***********************************/
(@prco bCompany, @state bState, @quarter bDate)

AS
SET NOCOUNT ON
   		
   		SELECT ue.PRCo, ue.Employee, ue.Quarter, ue.GrossWages AS [OutofStateGrossWages], 
   			ue.SUIWages AS [OutofStateSUIWages], ue.ExcessWages AS [OutofStateExcessWages], 
   			ue.EligWages AS [OutofStateEligWages], ue.State AS [StateOutOfState]
   		FROM bPRUE ue
   		WHERE ue.PRCo = @prco 
   			AND ue.Quarter = @quarter 
   			AND ue.State <> @state

GO
GRANT EXECUTE ON  [dbo].[bspHQPRStateUnemploymentOutOfState] TO [public]
GO
