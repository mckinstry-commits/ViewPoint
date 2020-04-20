SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspMSIHAddVal]
   /*************************************
   * Created By:   GF 11/11/2000
   * Modified By:	GF 02/12/2002 - Issue #16179 - error validating customer
   *				GF 07/29/2003 - issue #21933 - speed improvements
   *
   * validates MS Invoice. Optional CustGroup,Customer,CustJob,CustPO
   *
   * Pass:
   *	MS Company, Month, BatchId, MS Invoice, CustGroup, Customer, CustJob, CustPO
   *
   * Success returns:
   *	0 and Description from bMSIH
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@msco bCompany = null, @xmth bMonth = null, @batchid bBatchID = null, @msinv varchar(10) = null,
    @xcustgroup bGroup = null, @xcustomer bCustomer = null, @xcustjob varchar(20) = null,
    @xcustpo varchar(20) = null, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @inusebatchid bBatchID, @mth bMonth, @custgroup bGroup, @customer bCustomer,
           @custjob varchar(20), @custpo varchar(20)
   
   select @rcode = 0
   
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
   
   if @batchid is null
       begin
       select @msg = 'Missing Batch ID', @rcode = 1
       goto bspexit
       end
   
   if @msinv is null
   	begin
   	select @msg = 'Missing MS Invoice number', @rcode = 1
   	goto bspexit
   	end
   
   -- validate Invoice in MSIH
   select @mth = Mth, @msg = Description, @custgroup = CustGroup, @customer = Customer,
   	   @custjob = CustJob, @custpo = CustPO, @inusebatchid = InUseBatchId
   from bMSIH with (nolock) where MSCo=@msco and MSInv=@msinv
   if @@rowcount = 0
       begin
       select @msg = 'Not a valid MS Invoice', @rcode = 1
       goto bspexit
       end
   if @mth <> @xmth
   	begin
   	select @msg = 'Must be added in the month originally posted ' + convert(varchar(2),datepart(month, @mth)) + '/' +
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
   
   -- valid invoice if no customer info
   if @xcustomer is null goto bspexit
   
   -- validate invoice for customer only values
   if @xcustjob is null and @xcustpo is null
       begin
       if @xcustgroup<>@custgroup or @xcustomer<>@customer
           begin
           select @msg = 'Not a valid MS Invoice for customer', @rcode = 1
           goto bspexit
           end
       goto bspexit
       end
   
   -- validate invoice for custjob and custpo
   if @xcustjob is not null and @xcustpo is not null
       begin
       if @xcustjob<>@custjob or @xcustpo<>@custpo
           begin
   		select @msg = 'Not a valid MS Invoice for Customer/Job/PO combination', @rcode = 1
           goto bspexit
   		end
       goto bspexit
       end
   
   -- validate invoice for custjob
   if @xcustjob is not null and @xcustpo is null
       begin
       if @xcustjob<>@custjob
           begin
   		select @msg = 'Not a valid MS Invoice for Customer/Job combination', @rcode = 1
           goto bspexit
   		end
       goto bspexit
       end
   
   -- validate invoice for custpo
   if @xcustjob is null and @xcustpo is not null
       begin
       if @xcustpo<>@custpo
           begin
   		select @msg = 'Not a valid MS Invoice for Customer/PO combination', @rcode = 1
           goto bspexit
   		end
       goto bspexit
       end
   
   
   
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSIHAddVal] TO [public]
GO
