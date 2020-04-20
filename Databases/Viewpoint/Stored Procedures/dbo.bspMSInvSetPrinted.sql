SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspMSInvSetPrinted]
   /***********************************************************
    * Created: GG 01/31/02
    * Modified: 
    *
    * Called from the MS Invoice Print form to flag invoices as printed.
    * Changes to printed invoices may be audited in bHQMA.  #14176
    *
    * INPUT PARAMETERS
    *   @co                 MS Co#
    *   @mth                Batch Month
    *   @batchid            Batch ID
    *   @order				 Sort order - 'C' = Customer#, 'S' = SortName, 'I' = Invoice      
    *   @begincust          Beginning Customer #
    *   @endcust            Ending Customer # 
    *   @begincustname      Beginning Customer Sort Name
    *   @endcustname        Ending Customer Sort Name
    *   @begininv    		 Beginning Invoice
    *   @endinv           	 Ending Invoice
    *   @cash     			 Include Cash Sale invoices ('Y', 'N')
    *
    * OUTPUT PARAMETERS
    *   @msg            success or error message
    *
    * RETURN VALUE
    *   0               success
    *   1               fail
    *****************************************************/
   	(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @order char(1) = null,
        @begincust bCustomer = null, @endcust bCustomer = null, @begincustname bSortName = null,
        @endcustname bSortName = null, @begininv varchar(10) = null, @endinv varchar(10) = null,
        @cash bYN = 'N', @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
    
   select @rcode = 0
   
   -- update Printed flag in MS Invoice Batch Header
   update bMSIB set PrintedYN = 'Y'
   from bMSIB b
   join bARCM c on c.CustGroup = b.CustGroup and c.Customer = b.Customer
   where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid
   	and ((@order = 'C' and b.Customer >= isnull(@begincust,0) and b.Customer <= isnull(@endcust,999999))
   		or (@order = 'S' and c.SortName >= isnull(@begincustname,'') and c.SortName <= isnull(@endcustname,'~~~~~~~'))
   		or (@order = 'I' and b.MSInv >= isnull(@begininv,'') and b.MSInv <= isnull(@endinv,'~~~~~~')))
   	and ((@cash = 'N' and b.PaymentType = 'A') or @cash = 'Y')
   
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSInvSetPrinted] TO [public]
GO
