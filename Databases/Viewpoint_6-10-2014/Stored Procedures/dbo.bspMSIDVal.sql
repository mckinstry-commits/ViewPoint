SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspMSIDVal]
   /***********************************************************
   * Created By:   GF 11/16/2000
   * Modified By:  GF 03/05/2001
   *				GG 02/01/02 - #14177 - added input param for CheckNo restriction
   *				GF 07/29/2003 - issue #21933 - speed improvements.
   *
   * Called from the MS Invoice Edit form to validate a
   * MSTrans to add to invoice.
   *
   * INPUT PARAMETERS
   *   @co                 MS Co#
   *   @mth                Batch Month
   *   @batchid            Batch ID
   *   @batchseq           Batch Seq
   *   @xmstrans           MSTrans restriction
   *   @xcustgroup         Customer Group restriction
   *   @xcustomer          Customer restriction
   *   @xcustjob           CustJob restriction
   *   @xcustpo            CustPO restriction
   *   @xpaymenttype       Payment Type restriction
   *	@xcheckno			Check # restriction
   *   @xlocgroup          Location Group restriction
   *   @xloc               Location restriction
   *   @xrectype           Invoice receivable type
   *
   * OUTPUT PARAMETERS
   *   @ticket, @custjob, @custpo, @msidsaledate, @saledate, @msidfromloc, @fromloc,
   *   @matlgroup, @material, @um, @units, @unitprice, @ecm, @haultotal, @taxtotal,
   *   @invtotal, @disctotal
   *   @msg            success or error message
   *
   * RETURN VALUE
   *   0               success
   *   1               fail
   *****************************************************/
   (@co bCompany = null, 
    @mth bMonth = null, 
	@batchid bBatchID = null,
	@batchseq bTrans = null,
    @xmstrans bTrans = null,
	@xcustgroup bGroup = null,
	@xcustomer bCustomer = null,
    @xcustjob varchar(20) = null,
	@xcustpo varchar(20) = null,
	@xpaymenttype char(1) = null,
    @xcheckno bCMRef = null,
	@xlocgroup bGroup = null,
	@xloc bLoc = null,
	@xrectype tinyint,
    @mstrans bTrans output,
	@ticket bTic output,
	@custjob varchar(20) output,
	@custpo varchar(20) output,
    @msidsaledate bDate output,
	@saledate bDate output,
	@msidfromloc bLoc output,
    @fromloc bLoc output,
	@matlgroup bGroup output,
	@material bMatl output,
	@um bUM output,
    @units bUnits output,
	@unitprice bUnitCost output,
	@ecm bECM output, 
	@haultotal bDollar output,
    @taxtotal bDollar output,
	@invtotal bDollar output,
	@disctotal bDollar output,
    @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @status tinyint, @datesort bYN, @locsort bYN, @saletype char(1),
           @custgroup bGroup, @customer bCustomer, @paymenttype char(1), @locgroup bGroup,
           @void bYN, @hold bYN, @msinv varchar(10), @inusebatchid bBatchID, @matltotal bDollar,
           @discoff bDollar, @taxdisc bDollar, @arcmrectype tinyint, @inlmrectype tinyint,
           @inlorectype tinyint, @rectype tinyint, @category varchar(10), @autoapply bYN, @checkno bCMRef
   
   select @rcode = 0

   -- validate HQ Batch
   exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, 'MS Invoice', 'MSIB', @msg output, @status output
   if @rcode <> 0 
   begin
		goto bspexit
	end
   
	if @status <> 0     -- must be open
    begin
       select @msg = 'Invalid Batch status - must be Open!', @rcode = 1
       goto bspexit
    end
   
   -- get MS company info
   select @datesort=DateSort, @locsort=LocSort, @autoapply = AutoApplyCash from bMSCO with (nolock) where MSCo = @co
   if @@rowcount = 0
   begin
       select @msg = 'Missing MS Company!', @rcode = 1
       goto bspexit
    end
   
   -- get MSTD detail
   select @mstrans=MSTrans, @saledate=SaleDate, @fromloc=FromLoc, @ticket=Ticket, @saletype=SaleType,
          @custgroup=CustGroup, @customer=Customer, @custjob=CustJob, @custpo=CustPO,
          @paymenttype=PaymentType, @checkno = CheckNo, @matlgroup=MatlGroup, @material=Material,
   	   @um=UM, @units=isnull(MatlUnits,0), @unitprice=isnull(UnitPrice,0), @ecm=ECM,
          @haultotal=isnull(HaulTotal,0), @matltotal=isnull(MatlTotal,0),
          @taxtotal=isnull(TaxTotal,0), @discoff=isnull(DiscOff,0), @taxdisc=isnull(TaxDisc,0),
          @void=Void, @hold=Hold, @msinv=MSInv, @inusebatchid=InUseBatchId
   from bMSTD with (nolock) 
   where MSCo = @co and Mth=@mth and MSTrans=@xmstrans
   if @@rowcount = 0
   begin
       select @msg = 'Invalid MS Transaction', @rcode = 1
       goto bspexit
   end
   
   -- check restrictions
   if @saletype in ('J','I')
   begin
		select @msg = 'Invalid, Transaction sale type must be (C)ustomer', @rcode = 1
       goto bspexit
   end

   if @xcustgroup <> @custgroup
   begin
       select @msg = 'Invalid, Transaction has different customer group', @rcode = 1
       goto bspexit
   end

   if @xcustomer <> @xcustomer
   begin
       select @msg = 'Invalid, Transaction has different customer', @rcode = 1
       goto bspexit
   end

   if isnull(@xcustjob,@custjob) <> @custjob
   begin
       select @msg = 'Invalid, Transaction has different customer job', @rcode = 1
       goto bspexit
   end

   if isnull(@xcustpo,@custpo) <> @custpo
   begin
       select @msg = 'Invalid, Transaction has different customer PO', @rcode = 1
       goto bspexit
   end

   if isnull(@xloc,@fromloc) <> @fromloc
   begin
       select @msg = 'Invalid, Transaction has different from location', @rcode = 1
       goto bspexit
   end

   -- check Location Group restriction
   select @locgroup=LocGroup from bINLM with (nolock) where INCo=@co and Loc=@fromloc

   if isnull(@xlocgroup,@locgroup) <> @locgroup
   begin
       select @msg = 'Invalid, Transaction has different location group', @rcode = 1
       goto bspexit
   end

   if @xpaymenttype <> @paymenttype
   begin
       select @msg = 'Invalid, Transaction has different payment type', @rcode = 1
       goto bspexit
   end

   if @hold = 'Y'
   begin
       select @msg = 'Invalid, Transaction is on hold', @rcode = 1
       goto bspexit
   end

   if @void = 'Y'
   begin
       select @msg = 'Invalid, Transaction is voided', @rcode = 1
       goto bspexit
   end

   if @msinv is not null
   begin
       select @msg = 'Invalid, Transaction is on invoice ' + @msinv, @rcode = 1
       goto bspexit
   end

   if @inusebatchid is not null
   begin
       select @msg = 'Invalid, Transaction is in use by batch ' + convert(varchar(10), @inusebatchid)
       goto bspexit
   end

   -- verify Check #s 
   if @autoapply = 'Y' and isnull(@xcheckno,'') <> isnull(@checkno,'')
   	begin
	   	select @msg = 'Invalid, Transaction has different Check #', @rcode = 1
   		goto bspexit
   	end
	
	begin    
		-- get ARCM receivable type
		select @arcmrectype=RecType from bARCM with (nolock) where CustGroup=@custgroup and Customer=@customer
	end

	begin
		-- get INLM receivable type
		select @inlmrectype=RecType  from bINLM with (nolock) where INCo=@co and Loc=@fromloc
	End

   -- get INLO receivable type
   select @category = Category from bHQMT with (nolock) 
   where MatlGroup = @matlgroup and Material = @material
   if @@rowcount <> 0
   begin
       select @inlorectype = RecType
       from bINLO with (nolock) where INCo=@co and Loc=@fromloc and MatlGroup=@matlgroup and Category=@category
   end
   
   -- assign Receivable Type for this transaction
   select @rectype = isnull(isnull(@inlorectype,@inlmrectype),@arcmrectype)
   if @rectype <> @xrectype
   begin
       select @msg = 'Invalid, transaction receivable type - ' + convert(varchar(1),isnull(@rectype,'')) + ' must match invoice receivable type - ' + convert(varchar(1),@xrectype) + ' .', @rcode = 1
       goto bspexit
   end
   
   -- check if valid to add transaction to invoice batch header
   if not exists(select 1 from bMSIB with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid 
   			and BatchSeq = @batchseq and Void = 'N' and Interfaced = 'N' and InterCoInv = 'N')
    begin
       select @msg = 'Invalid, cannot add tranaction to invoice batch header', @rcode = 1
       goto bspexit
    end
   
   -- assign Batch Detail Sale Date and Loc based on MS Co Sort options
   select @msidsaledate = null, @msidfromloc = null
   if @datesort = 'Y' 
   begin
		select @msidsaledate = @saledate
   end

   if @locsort = 'Y' 
   begin
		select @msidfromloc = @fromloc	
	end


	begin
		-- assign total amounts
		select @invtotal = isnull(@haultotal,0) + isnull(@matltotal,0) + isnull(@taxtotal,0)
   end
	
	begin
		select @disctotal = isnull(@discoff,0) + isnull(@taxdisc,0)
	end
   
   
   
   bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSIDVal] TO [public]
GO
