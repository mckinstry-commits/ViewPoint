SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vspGLCloseSMInvoiceList]
   /**************************************************
   * Created:	GP 10/18/2011
   * Modified:	JVH 4/29/13 TFS-44860 Updated check to see if work completed is part of an invoice
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
AS
BEGIN
	SET NOCOUNT ON

	SELECT DISTINCT SMInvoiceListDetailLine.SMCo, SMInvoiceListDetailLine.BatchMonth, SMInvoiceListDetailLine.InvoiceNumber, SMInvoiceListDetailLine.InvoiceDate, SMInvoiceListDetailLine.WorkOrder, SMInvoiceListDetailLine.Scope, SMInvoiceListDetailLine.BillToARCustomer
	FROM dbo.SMInvoiceListDetailLine
	WHERE ChangesMade = 1 AND BatchMonth <= @mth AND (GLCo = @glco OR InvoicedGLCo = @glco)
END


GO
GRANT EXECUTE ON  [dbo].[vspGLCloseSMInvoiceList] TO [public]
GO
