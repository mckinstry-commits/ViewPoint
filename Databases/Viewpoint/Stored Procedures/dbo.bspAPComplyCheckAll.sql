SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[bspAPComplyCheckAll]
   /**********************************************************************
    * CREATED BY: MV 01/10/03
    * MODIFIED By : 
    *
    * USAGE:	Does compliance checking for all invoices. Works like PO or SL
    *	compliance checking but for all invoices at the vendor (header)level
    *	rather than PO or SL (line) level.
    * 
    * INPUT PARAMETERS
    *   @apco      	AP Co
    *	@vendorgroup	Vendor Group
    *   @vendor	 	Vendor being checked for compliance
    *	@invdate	 	Invoice Date
    *   
    * OUTPUT PARAMETERS
    *	@compliedyn CompliedYN flag
    *   @msg		  error message
    * RETURN VALUE
    *   0 Success
    *   1 fail
    **********************************************************************/ 
   
   (@apco bCompany, @vendorgroup bGroup, @vendor bVendor, @invdate bDate, @complied bYN output)
   	
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   
   if exists(select * from bAPVC v join bHQCP h on v.CompCode=h.CompCode
   	where v.APCo=@apco and v.VendorGroup=@vendorgroup and v.Vendor=@vendor and h.AllInvoiceYN='Y'
   	and v.Verify='Y' and ((CompType='D' and (ExpDate<@invdate or
   	ExpDate is null)) or (CompType='F' and (Complied='N' or Complied is null))))
   		begin
   		select @complied = 'N', @rcode = 1
   		end
   else
   	begin
   	select @complied = 'Y'
   	end
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPComplyCheckAll] TO [public]
GO
