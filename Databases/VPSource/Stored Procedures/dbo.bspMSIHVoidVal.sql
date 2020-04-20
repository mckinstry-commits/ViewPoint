SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***************************************/
CREATE proc [dbo].[bspMSIHVoidVal]
/*************************************
   * Created By:   GF 11/11/2000
   * Modified By:	GG 11/13/00	- added InUseBatchId and Void validation
   *				GF 07/29/2003 - issue #21933 - speed improvements
   *
   * Validates MS Invoice for void
   *
   * Input:
   *	@msco	    MS co#
   *	@xmth	    Batch Month
   *	@batchid	Batch ID#
   *	@msinv	    Invoice
   *
   * Output:
   *   	@custname		Customer Name
   *   	@custjob		Customer Job
   *   	@custpo		    Customer PO
   *   	@invdate		Invoice Date
   *   	@duedate		Invoice Due Date
   *   	@invtotal		Invoice Total
   *	@msg			Description
   *
   * Return:
   *	0 = success, 1 = error w/message
   **************************************/
   (@msco bCompany = null, @xmth bMonth = null, @batchid bBatchID = null, @msinv varchar(10) = null,
    @custname bDesc output, @custjob varchar(20) output, @custpo varchar(20) output,
    @invdate bDate output, @duedate bDate output, @invtotal bDollar output, 
	@customer bCustomer output, @msg varchar(255) output)
as
set nocount on
   
   declare @rcode int, @custgroup bGroup, @mth bMonth, @void bYN, @inusebatchid bBatchID
   
   select @rcode = 0, @invtotal = 0
   
   if @msco is null
   	begin
   	select @msg = 'Missing MS Company number', @rcode = 1
   	goto bspexit
   	end
   if @xmth is null
       begin
       select @msg = 'Missing Invoice month', @rcode = 1
       goto bspexit
       end
   if @msinv is null
   	begin
   	select @msg = 'Missing MS Invoice number', @rcode = 1
   	goto bspexit
   	end
   
   -- -- -- validate Invoice in MSIH
   select @mth = Mth, @msg = Description, @custgroup = CustGroup, @customer = Customer,
   	@custjob = CustJob, @custpo = CustPO, @invdate = InvDate, @duedate = DueDate,
   	@inusebatchid = InUseBatchId, @void = Void
   from bMSIH with (nolock) 
   where MSCo = @msco and MSInv = @msinv
   if @@rowcount = 0
       begin
       select @msg = 'Not a valid MS Invoice', @rcode = 1
       goto bspexit
       end
   if @mth <> @xmth
   	begin
   	select @msg = 'Must be voided in the month originally posted ' + convert(varchar(2),datepart(month, @mth)) + '/' +
   		      substring(convert(varchar(4),datepart(year, @mth)),3,4), @rcode = 1
   	goto bspexit
   	end
   if @inusebatchid = @batchid
   	begin
   	select @msg = 'Invoice already in use by this Batch.', @rcode = 1
   	goto bspexit
   	end
   if @inusebatchid is not null
   	begin
   	select @msg = 'Invoice already in use by Batch #' + convert(varchar(6),isnull(@inusebatchid,'')), @rcode = 1
   	goto bspexit
   	end
   if @void = 'Y'
   	begin
   	select @msg = 'Invoice has already been voided.',@rcode = 1
   	goto bspexit
   	end
   
   -- -- -- get Customer name
   select @custname = Name from bARCM with (nolock) where CustGroup = @custgroup and Customer = @customer
   
   -- -- -- get Invoice total
   select @invtotal = isnull(sum(MatlTotal),0) + isnull(sum(HaulTotal),0) + isnull(sum(TaxTotal),0)
   	- isnull(sum(DiscOff),0) - isnull(sum(TaxDisc),0)
   from bMSTD with (nolock) 
   where MSCo = @msco and Mth = @mth and MSInv = @msinv






bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'') 
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSIHVoidVal] TO [public]
GO
