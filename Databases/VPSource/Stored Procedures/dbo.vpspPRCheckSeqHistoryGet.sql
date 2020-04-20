SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPRCheckSeqHistoryGet]
/************************************************************
* CREATED:     TRK 3/17/11
*
* USAGE:
*   Returns the PR Check Sequence History for a given PRCo and Employee
*	
*	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    PRCo, Employee        
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(@PRCo bCompany, @Employee bEmployee)
AS
	SET NOCOUNT ON;
SELECT PRCo
		,Employee
		,Earnings
		,Dedns				
		,[Hours]
		,PaidDate
		,PREndDate
		,PayMethod
		,case PayMethod when 'C' then 'Check' when 'E' then 'EFT' end as 'PayMethodDesc'
		,CMRef
		,Earnings - Dedns as PaidAmt
		,KeyID
		,UniqueAttchID
FROM PRSQ
WHERE PRCo = @PRCo 
		and Employee = @Employee 
		and PayMethod <> 'X' 
		and CMRef is not Null
ORDER BY PaidDate DESC

GO
GRANT EXECUTE ON  [dbo].[vpspPRCheckSeqHistoryGet] TO [VCSPortal]
GO
