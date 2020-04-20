SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPCMRefValEFT    Script Date: 8/28/99 9:33:56 AM ******/
   
   CREATE proc [dbo].[bspAPCMRefValEFT]
   /***********************************************************
    * CREATED BY: SE 10/22/97
    * MODIFIED By : SE 10/22/97
    *			  MV 10/18/02 - 18878 quoted identifier cleanup
    *
    * USAGE:
    *   validates EFT CM Reference for EFT Download Program
    *   makes sure that it's not in use in this batch or in payment detail
    * 
    * INPUT PARAMETERS
    *   APCo      AP Co
    *   Mth       BatchMonth
    *   BatchId   BatchID
    *   CMCo      CM Co 
    *   CMAcct    CM Account
    *   CMRef     The reference    
    *   
    * OUTPUT PARAMETERS
    *   @msg     Error message if invalid, 
    * RETURN VALUE
    *   0 Success
    *   1 fail
    *****************************************************/ 
   
   (@apco bCompany, @mth bMonth, @batchid bBatchID, @cmco bCompany = 0, @cmacct bCMAcct=null, @cmref bCMRef, 
   	 @msg varchar(80) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @apco is null
   	begin
   	select @msg = 'Missing AP Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @cmco is null
   	begin
   	select @msg = 'Missing CM Company!', @rcode = 1
   	goto bspexit
   	end
   if @cmacct is null
   	begin
   	select @msg = 'Missing CM Account!', @rcode = 1
   	goto bspexit
   	end
   if @cmref is null
   	begin
   	select @msg = 'Missing CM Reference!', @rcode = 1
   	goto bspexit
   	end
   
   if exists (select * from bAPPB where PayMethod='E' and CMCo=@cmco and CMAcct=@cmacct 
             and CMRef=@cmref and not(Co=@apco and Mth=@mth and BatchId=@batchid))
      begin
        select @msg='Entries in the payment detail batch already exist for this EFT Reference!', @rcode=1
        goto bspexit
      end
   
   if exists(select * from bAPPD where PayMethod='E' and CMCo=@cmco and CMAcct=@cmacct 
             and CMRef=@cmref)
      begin
        select @msg='Entries in payment detail already exist for this EFT Reference!', @rcode=1
        goto bspexit
      end
   
   if exists(select * from bCMDT where CMTransType=4 and CMCo=@cmco and CMAcct=@cmacct 
             and CMRef=@cmref)
      begin
        select @msg='Entries in CM detail already exist for this EFT Reference!', @rcode=1
        goto bspexit
      end
   
   bspexit:
   
     return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPCMRefValEFT] TO [public]
GO
