SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspJCContractItemGet]
/************************************************************
* CREATED:		02/06/07 CHS	
* MODIFIED:		06/07/07 CHS
*				12/05/11 JG		TK-10467 - Using Job to find contract instead of pulling in the contract
*
* USAGE:
*   Returns the Job Cost Contract Items
*	
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job
*   
************************************************************/
(@JCCo bCompany, @Job bJob)

AS

SET NOCOUNT ON;

DECLARE @Contract bContract

---- Pull Contract from Job
SELECT @Contract = [Contract]
FROM dbo.bJCJM
WHERE @JCCo = @JCCo
	AND Job = @Job

IF @Contract IS NOT NULL
BEGIN
	SELECT 
		i.KeyID, i.JCCo, i.Contract, 
		
		c. Description as 'ContractDescription',
		
		i.Item, i.Description, i.Department, i.TaxGroup, i.TaxCode, 
		i.UM, i.SIRegion, i.SICode, i.RetainPCT, 
				
		i.RetainPCT * 100 as 'RetainPCT100',
		
		i.OrigContractAmt, i.OrigContractUnits, 
		i.OrigUnitPrice, i.ContractAmt, i.ContractUnits, i.UnitPrice, i.BilledAmt, 
		i.BilledUnits, i.ReceivedAmt, i.CurrentRetainAmt, i.BillType, i.BillGroup, 
		i.BillDescription, i.BillOriginalUnits, i.BillOriginalAmt, i.BillCurrentUnits, 
		i.BillCurrentAmt, i.BillUnitPrice, i.Notes, i.InitSubs, i.UniqueAttchID, 
		i.StartMonth, i.MarkUpRate, i.ProjNotes, i.ProjPlug

	FROM JCCI i with (nolock)
		Left Join JCCM c with (nolock) on c.JCCo=i.JCCo and i.Contract=c.Contract

	WHERE @JCCo = i.JCCo and @Contract = i.Contract
END

GO
GRANT EXECUTE ON  [dbo].[vpspJCContractItemGet] TO [VCSPortal]
GO
