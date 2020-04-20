SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspAPRLTotalGet]
      /********************************************************
      * CREATED BY: 	MV 07/07/05 
      * MODIFIED BY:	MV 08/01/08 - #128288 - VAT TaxTYpe	
      *              
      *
      * USAGE:
      * 	Retrieves totals for an AP Recurring Invoice
      *
      * INPUT PARAMETERS:
      *	@apco		AP Co#
      * @mth		month
      *	@invid		invoice id		
      *
      * OUTPUT PARAMETERS:
      *	@gross		Gross Invoice
      *    @freight	Freight
      *    @salestax	Sales Tax
      *    @retainage	Retainage
      *    @discount	Discount
      *	   @msg			Error message
      *
      * RETURN VALUE:
      * 	0 	    Success
      *	1 & message Failure
      *
      **********************************************************/
      	(@apco  bCompany,@vendorgroup bGroup, @vendor bVendor,
		@invid varchar(10), @gross bDollar = null output,@freight bDollar = null output,
		@salestax bDollar = null output,@retainage bDollar = null output,
		@discount bDollar = null output,@msg varchar(60) output)
      as
  
      set nocount on
   	declare @rcode int
    select @rcode = 0
    select @gross = 0, @freight = 0, @salestax = 0, @retainage = 0, @discount = 0
	
 if @apco is null
	begin
		select @msg = 'missing AP Company', @rcode =1
		goto bspexit
	end  
if @vendor is null
	begin
		select @msg = 'missing Vendor', @rcode =1
		goto bspexit
	end  
if @invid is null
	begin
		select @msg = 'missing Invoice Id', @rcode =1
		goto bspexit
	end  

 if @vendor is not null and @invid is not null
   	begin
       -- get amounts from APRL lines
       select @gross = isnull(sum(GrossAmt),0),
           @freight = isnull(sum(case MiscYN when 'Y' then MiscAmt else 0 end),0),
           @salestax = isnull(sum(case TaxType when 2 then 0 else TaxAmt end),0),
           @retainage = isnull(sum(Retainage),0),
           @discount = isnull(sum(Discount),0)
       from bAPRL
       where APCo = @apco and VendorGroup= @vendorgroup and Vendor=@vendor and InvId=@invid
	end
 
    
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPRLTotalGet] TO [public]
GO
