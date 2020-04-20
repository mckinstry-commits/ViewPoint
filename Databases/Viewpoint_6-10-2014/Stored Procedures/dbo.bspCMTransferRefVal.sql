SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspCMTransferRefVal    Script Date: 8/28/99 9:34:18 AM ******/
   
   CREATE  proc [dbo].[bspCMTransferRefVal]
   /***********************************************************
    * CREATED BY: SE   8/20/97
    * MODIFIED By : SE 8/20/97
    *              GG 01/17/01 - fixed CMRef validation logic on existing trans
    *
    * USAGE:
    *   validates CM Reference to see if it's unique for a transfer
    *   Transfers are unique because the reference will go to 2 seperate companies
    *   and or accounts so we have to chack both the from and the to.
    *   pass in CM Company, Reference, and both from and To accounts
    *   returns CM ErrMsg if any, otherwise nothing
    *
    * INPUT PARAMETERS
    *   @cmco              CM Co
    *   @mth               Month of batch
    *   @batchid           Batch ID
    *   @batchseq          Seq of current line so we don't mistake same entry
    *   @cmtransfertrans   CM transfer Transaction so we don't mistake current entry
    *   @cmref             CM Reference to validate
    *   @fromcmco          Transfer From CM Company
    *   @fromact           Transfer From CM Acct
    *   @tocmco            Transfer To CM Company
    *   @tocmacct          Transfer To CM Acct
    *
    * OUTPUT PARAMETERS
    *   @msg     Error message if invalid,
    *
    * RETURN VALUE
    *   0 Success
    *   1 fail
    *****************************************************/
   
   	@cmco bCompany, @mth bMonth, @batchid bBatchID,
   	@batchseq int, @cmtransfertrans bTrans,
   	@cmref bCMRef, @fromcmco bCompany, @fromacct bCMAcct,
   	@tocmco bCompany, @tocmacct bCMAcct, @msg varchar(100) output
   as
   
   set nocount on
   
   declare @rcode int,@dtmth bMonth, @dttrans bTrans, @numrows int
   
   select @rcode = 0
   
   
   /* check for unique CM Reference */
   if @cmtransfertrans is null
   	/* no CM transfer transaction was passed, must be a new entry - check for unique CM Reference in CM Detail */
   	begin
   	select @dttrans = CMTransferTrans, @dtmth = Mth
   		from bCMDT
        		where CMCo = @fromcmco and CMAcct = @fromacct and CMTransType=3
        		      and CMRef = @cmref
           select @numrows=@@rowcount
           if @numrows = 0
              begin
     	    select @dttrans = CMTransferTrans, @dtmth = Mth
   		from bCMDT
        		where CMCo = @tocmco and CMAcct = @tocmacct and CMTransType=3
   
        		      and CMRef = @cmref
               select @numrows=@@rowcount
              end
   	end
   else
   	/* CM trans check for unique CM Reference in CM Detail */
   	begin
   	 select @dttrans = CMTransferTrans, @dtmth = Mth
   		from bCMDT
        		where CMCo = @tocmco and CMAcct = @tocmacct and CMTransType = 3
           	and CMRef = @cmref and (CMTransferTrans <> @cmtransfertrans or Mth <> @mth)
            select @numrows=@@rowcount
   	 if @numrows = 0
   	    begin
     	     select @dttrans = CMTransferTrans, @dtmth = Mth
   		from bCMDT
        		where CMCo = @tocmco and CMAcct = @tocmacct and CMTransType = 3
           	and CMRef = @cmref and (CMTransferTrans <> @cmtransfertrans or Mth <> @mth)
               select @numrows=@@rowcount
              end
   
   	end
   
   
   if @numrows <> 0
   	begin
   	select @msg = 'Reference already exists on Transfer Transaction ' + convert(varchar(8),@dttrans) +
   	' In '+ DATENAME(month,@dtmth) + ' of ' + DATENAME(year,@dtmth), @rcode = 1
   
   	goto bspexit
   	end
   
   
   /* if BatchId passed, check for uniqueness within the current batch */
   if @batchid is not null
   	begin
          	if exists(select * from bCMTB
           	where Co = @cmco and Mth = @mth and BatchId = @batchid and BatchSeq <> @batchseq
   		and ((FromCMCo = @fromcmco and FromCMAcct = @fromacct and CMRef = @cmref) or
   		    (FromCMCo = @tocmco and FromCMAcct = @tocmacct and CMRef = @cmref) or
   		    (ToCMCo = @tocmco and ToCMAcct = @tocmacct and CMRef = @cmref) or
   		    (ToCMCo = @fromcmco and ToCMAcct = @fromacct and CMRef = @cmref)))
   		begin
   	   	select @msg = 'Reference already exists in this batch.' , @rcode = 1
   	   	goto bspexit
   	  	end
          	end
   
   /* CM Reference is unique */
   select @msg = 'Valid'
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMTransferRefVal] TO [public]
GO
