SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspJBAR_PostMiscDist]
   /***********************************************************
   * CREATED BY  : bc 03/14/00
   * MODIFIED By : bc 12/28/00 - added error check for when a record is not successfully added into ARMD
   *     	bc 01/04/00 - retrieve artrans from JBIN
   *		TJL 11/20/02 - Issue #17278, Allow changes to bills in a closed month.
   *		TJL 09/20/03 - Issue #22126, Rewrite for Performance, added noLocks to this procedure.
   *		TJL 10/06/03 - Issue #17897, Corrected MiscDistCode references to datatype char(10) (Consistent w/AR and MS)
   *
   *
   * USAGE:  called from bspJBAR_Post for every sequence in JBAR,
   *         this bsp creates, updates or deletes ARMD records based on JBBM/JBMD
   *
   *
   * INPUT PARAMETERS
   *   JBCo        JB Co
   *   Month       Bill Month
   *   BatchId     Batch ID to validate
   *   BatchSeq    Batch Sequence
   *
   * OUTPUT PARAMETERS
   *   @errmsg     if something went wrong
   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/
   (@jbco bCompany, @mth bMonth, @batchid bBatchID, @seq int, @errmsg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @bmGroup bGroup, @bmCode char(10), @bmtranstype char(1), @bmDesc bDesc, @bmoldDesc bDesc,  
   	@bmAmt bDollar, @bmoldAmt bDollar, @bmDistDate bDate, @bmoldDistDate bDate,
   	@arCode char(10), @artrans bTrans, @arco bCompany, @custgroup bGroup, @billnum int,
   	@billmonth bMonth, @billdate bDate, @openJBBMcursor int, @openARMDcursor int
   
   select @rcode = 0, @openJBBMcursor = 0, @openARMDcursor = 0
   
   select @billmonth = r.BillMonth, @billnum = r.BillNumber, @custgroup = r.CustGroup, @billdate = r.TransDate,
   	@arco = o.ARCo
   from bJBAR r with (nolock)
   join bJCCO o with (nolock) on o.JCCo=r.Co
   where Co = @jbco and Mth = @mth and BatchId = @batchid  and BatchSeq = @seq
   
   select @artrans = ARTrans
   from bJBIN with (nolock)
   where JBCo = @jbco and BillMonth = @billmonth /*@mth*/ and BillNumber = @billnum
   
   /* Begin processing MiscDistCodes for this Batch Sequence */
   declare bcJBBM cursor local fast_forward for
   select CustGroup, MiscDistCode, BatchTransType, DistDate, Description, Amount, oldDistDate,
   	oldDescription, oldAmount
   from bJBBM with (nolock)
   where JBCo = @jbco and Mth=@mth and BatchId = @batchid and BatchSeq = @seq 
   
   open bcJBBM
   select @openJBBMcursor = 1
   	
   fetch next from bcJBBM into @bmGroup, @bmCode, @bmtranstype, @bmDistDate, @bmDesc, @bmAmt, @bmoldDistDate,
   		@bmoldDesc, @bmoldAmt
   while @@fetch_status = 0
    	begin
    	if @bmtranstype = 'A' and
       	not exists(select 1 from ARMD with (nolock) where ARCo = @arco and Mth = @billmonth /*@mth*/ and ARTrans = @artrans 
   			and CustGroup = @bmGroup and MiscDistCode = @bmCode)
      		begin
      		insert into bARMD(ARCo, ARTrans, CustGroup, Mth, MiscDistCode, DistDate, Description, Amount)
   		values (@arco, @artrans, @bmGroup, @billmonth /*Mth*/, @bmCode, @bmDistDate, @bmDesc, @bmAmt)
   
        	if @@rowcount <> 1
          		begin
          		select @errmsg = 'Error inserting record in ARMD', @rcode = 1
          		goto bspexit
          		end
      		end
   
    	if @bmtranstype = 'C' and ((@bmAmt - @bmoldAmt) <> 0 or isnull(@bmDesc,'') <> isnull(@bmoldDesc,'')
   				or isnull(@bmDistDate, '2079-06-06') <> isnull(@bmoldDistDate, '2079-06-06'))
      		begin
      		update bARMD
      		set Amount = Amount + (@bmAmt - @bmoldAmt), Description = @bmDesc, DistDate = @bmDistDate
      		where ARCo = @arco and Mth = @billmonth /*@mth*/ and ARTrans = @artrans and CustGroup = @bmGroup 
   			and MiscDistCode = @bmCode
      		if @@rowcount = 0
        		begin
      			insert into bARMD(ARCo, ARTrans, CustGroup, Mth, MiscDistCode, DistDate, Description, Amount)
   			values (@arco, @artrans, @bmGroup, @billmonth /*Mth*/, @bmCode, @bmDistDate, @bmDesc, @bmAmt)
   
          		if @@rowcount <> 1
            		begin
            		select @errmsg = 'Error inserting record in ARMD', @rcode = 1
            		goto bspexit
            		end
        		end
      		end
   
    	if @bmtranstype = 'D'
   
   
      		begin
      		delete bARMD
      		where ARCo = @arco and Mth = @billmonth /*@mth*/ and ARTrans = @artrans and CustGroup = @bmGroup 
   			and MiscDistCode = @bmCode
      		end
   
   	fetch next from bcJBBM into @bmGroup, @bmCode, @bmtranstype, @bmDistDate, @bmDesc, @bmAmt, @bmoldDistDate,
   		@bmoldDesc, @bmoldAmt
      	end
   
   /* if a line has been deleted out of JBMD it won't appear in JBBM, hence this double check */
   declare bcARMD cursor local fast_forward for
   select MiscDistCode
   from bARMD with (nolock)
   where ARCo = @arco and Mth = @billmonth /*@mth*/ and ARTrans = @artrans and CustGroup = @custgroup
   
   open bcARMD
   select @openARMDcursor = 1
   	
   fetch next from bcARMD into @arCode
   while @@fetch_status = 0
   	begin
     	if not exists(select 1 from bJBBM with (nolock) where JBCo = @jbco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq 
   				and CustGroup = @custgroup and MiscDistCode = @arCode)
          	begin
          	delete bARMD
          	where ARCo = @arco and Mth = @billmonth /*@mth*/ and ARTrans = @artrans and CustGroup = @custgroup 
   			and MiscDistCode = @arCode
          	end
   
   	fetch next from bcARMD into @arCode
   	end
   
   bspexit:
   
   if @openJBBMcursor = 1
   	begin
   	close bcJBBM
   	deallocate bcJBBM
   	select @openJBBMcursor = 0
   	end
   
   if @openARMDcursor = 1
   	begin
   	close bcARMD
   	deallocate bcARMD
   	select @openARMDcursor = 0
   	end
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBAR_PostMiscDist] TO [public]
GO
