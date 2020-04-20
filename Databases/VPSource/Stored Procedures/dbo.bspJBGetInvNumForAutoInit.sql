SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBGetInvNumForAutoInit Script Date: 8/28/99 9:32:34 AM ******/
     CREATE  proc [dbo].[bspJBGetInvNumForAutoInit]
     /***********************************************************
      * CREATED BY	: kb 3/15/00
      * MODIFIED BY :	TJL 03/16/04 - NO LONGER USED.  Replaced by bspJBGetLastInvoice
      *
      * USED IN:
      *
      * USAGE:
      *
      * INPUT PARAMETERS
      *
      * OUTPUT PARAMETERS
      *   @msg      error message if error occurs
      * RETURN VALUE
      *   0         success
      *   1         Failure
      *****************************************************/
   
         (@co bCompany, @arco bCompany, @invflag char(1), @assigninv bYN,
         @invoice varchar(10) output, @msg varchar(255) output)
     as
   
     set nocount on
   
     declare @rcode int,  @invoice_num int
   
     select @rcode =0
   
     if @assigninv = 'Y'
       Begin
       if @invflag = 'A'
       select @invoice = isnull(InvLastNum,0) from bARCO where ARCo = @arco
        else
       select @invoice = isnull(LastInvoice,0) from bJBCO where JBCo = @co
   
     if isnumeric(@invoice) >= 0
       select @invoice_num = @invoice
     else
       begin
       select @invoice = null
       goto bspexit
       end
   
     invloop:
     /* check if the invoice is already in use */
     select @invoice_num = @invoice_num + 1
   
     select @invoice = convert(varchar(10),@invoice_num)
   
     -- invoice should be right justified 10 chars */
     select @invoice = space(10 - datalength(@invoice)) + @invoice
   
     if exists(select * from bARTH where ARCo=@arco and Invoice=@invoice) or
      exists(select * from bARBH where Co=@arco and Invoice=@invoice) or
      exists(select * from bJBAR where Co=@co and Invoice=@invoice) or
      exists(select * from bJBIN where JBCo=@co and Invoice=@invoice)
        goto invloop
   
     if @invflag = 'A'
      update bARCO set InvLastNum = @invoice where ARCo = @arco
     else
      update bJBCO set LastInvoice = @invoice where JBCo = @co
   
     End
   
          bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBGetInvNumForAutoInit] TO [public]
GO
