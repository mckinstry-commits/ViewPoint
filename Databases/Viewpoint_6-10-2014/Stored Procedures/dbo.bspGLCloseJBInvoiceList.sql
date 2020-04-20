SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspGLCloseJBInvoiceList]
   /**************************************************
   * Created: GG 11/30/99
   * Modified:
   *
   * Usage:
   *   Called by GL Close Control form to list unprocessed
   *   JB Invoices prior to closing a month.
   *
   * Inputs:
   *   @glco       GL company
   *   @mth        Month to close
   *
   * Output:
   *   none
   *
   * Return:
   *   recordset of unprocessed JB Invoices
   **************************************************/
   	(@glco bCompany, @mth bMonth)
   as
   set nocount on
   
   select distinct j.JBCo, j.BillMonth, j.BillNumber, j.Contract, j.Customer
   from bJBIN j
   join bJCCO c on c.JCCo = j.JBCo
   join bARCO a on a.ARCo = c.ARCo
   where (c.GLCo = @glco or a.GLCo = @glco) and j.BillMonth <= @mth
       and j.InvStatus in ('A','C','D')
   
   return

GO
GRANT EXECUTE ON  [dbo].[bspGLCloseJBInvoiceList] TO [public]
GO
