SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspARInvoiceHeaderGet]
/************************************************************
* CREATED:		5/15/07		CHS
* MODIFIED:		10/09/07	CHS
* MODIFIED:		12/20/07	CHS
* MODIFIED:		4/28/08		SDE
*
* USAGE:
*   Returns the AR Invoice Header
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    CustGroup, Customer
*
************************************************************/
(@CustGroup bGroup, @Customer bCustomer,
	@KeyID int = Null)

AS
	SET NOCOUNT ON;

SELECT
c.[Name] AS 'CompanyName',
h.ARCo, h.Mth, h.ARTrans, h.ARTransType, h.CustGroup, h.Customer, 
h.CustRef, h.CustPO, h.RecType, h.JCCo, h.Contract, 

j.Description as 'ContractDescription',

h.Invoice, 
h.CheckNo, h.Source, h.MSCo, h.TransDate, h.DueDate, h.DiscDate, 
h.CheckDate, h.Description, h.CMCo, h.CMAcct, h.CMDeposit, h.CreditAmt, 
h.PayTerms, h.AppliedMth, h.AppliedTrans, h.Invoiced, h.Paid, 
h.Retainage, h.DiscTaken, h.AmountDue, h.PayFullDate, h.PurgeFlag, 
h.EditTrans, h.BatchId, h.InUseBatchID, h.Notes, h.ReasonCode, 
h.ExcludeFC, h.FinanceChg, h.UniqueAttchID, 

isnull(h.Paid, 0) + isnull(h.DiscTaken, 0) as 'PaidDiscTaken',
h.KeyID

from ARTH h with (nolock)
	left join JCCM j with (nolock) on h.Contract = j.Contract and h.JCCo = j.JCCo
	left join HQCO c with (nolock) on h.ARCo = c.HQCo

where h.CustGroup = @CustGroup and h.Customer = @Customer and h.ARTransType = 'I' 
		and h.KeyID = IsNull(@KeyID, h.KeyID)



GO
GRANT EXECUTE ON  [dbo].[vpspARInvoiceHeaderGet] TO [VCSPortal]
GO
