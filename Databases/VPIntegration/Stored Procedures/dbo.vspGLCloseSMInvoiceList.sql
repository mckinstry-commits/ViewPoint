SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vspGLCloseSMInvoiceList]
   /**************************************************
   * Created:	GP 10/18/2011
   * Modified:
   *
   * Usage:
   *   Called by GL Close Control form to list unprocessed
   *   SM Invoices prior to closing a month.
   *
   * Inputs:
   *   @glco       GL company
   *   @mth        Month to close
   *
   * Output:
   *   none
   *
   * Return:
   *   recordset of unprocessed SM Invoices
   **************************************************/
   	(@glco bCompany, @mth bMonth)
   as
   set nocount on
          
	select distinct sm.SMCo, sm.BatchMonth, sm.Invoice, sm.InvoiceDate, wc.WorkOrder, wc.Scope, sm.BillToARCustomer 
	from dbo.SMInvoice sm 
	join dbo.SMWorkCompleted wc on wc.SMInvoiceID = sm.SMInvoiceID
	where wc.GLCo = @glco and sm.BatchMonth <= @mth and sm.Invoiced = 0
        
   return

GO
GRANT EXECUTE ON  [dbo].[vspGLCloseSMInvoiceList] TO [public]
GO
