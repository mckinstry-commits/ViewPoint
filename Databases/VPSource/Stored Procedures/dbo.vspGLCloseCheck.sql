SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspGLCloseCheck]
/**********************************************************************
* Created: GG 07/17/06
* Modified: 
*
* Used by GL Close Month to check for remaining batches, invoices, billings,
*	etc. that need to be posted prior to closing the month.
*
* Inputs:
*   @glco         	GL Co#
*   @mth        	Batch month
*   @ledger		   	GL or subledger close 
*
* Ouput:
*	resultsets of unposted batches, unprocessed AP prepaids, unapproved AP invoices, etc.
*
**********************************************************************/
	@glco bCompany = null, @mth bMonth = null, @ledger varchar(2) = null 
    
as
set nocount on
    

-- check for unposted batches
exec bspGLCloseBatchList @glco, @mth, @ledger

-- check for unprocessed AP prepaid transactions
exec bspGLCloseAPPrepaidList @glco, @mth

-- check for unapproved AP invoices - warning only
exec bspGLCloseAPUnapprovedList @glco, @mth

-- check for unposted JB invoices
exec bspGLCloseJBInvoiceList @glco, @mth

-- check for uninterfaced PR Pay Periods
exec bspGLClosePRPayPdsList @glco, @mth

-- check for uninvoiced MS tickets
exec bspGLCloseMSInvList @glco, @mth

-- check for unprocessed MS Hauler payments
exec bspGLCloseMSHaulList @glco, @mth

-- check for uniprocessed MS intercompany invoices
exec bspGLCloseMSIntercoInvList @glco, @mth


vbspexit:
    return
GO
GRANT EXECUTE ON  [dbo].[vspGLCloseCheck] TO [public]
GO
