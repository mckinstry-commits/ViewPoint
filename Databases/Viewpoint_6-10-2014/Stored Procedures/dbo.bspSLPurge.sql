SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspSLPurge    Script Date: 8/28/99 9:35:47 AM ******/
   CREATE     procedure [dbo].[bspSLPurge]
   /************************************************************************
    * Created : kf 6/16/97
    * Modified : EN 6/4/99
    *	     	  GR 7/22/99
    *			  MV 03/20/03 - #20533 set Purge flag to prevent HQ Auditing during delete
    *			  MV 07/21/04 - #24999 set purge flag for bSLCD
    *			DC 06/25/10 - #135813 - expand subcontract number
    *			JG 09/28/10 - TFS# 491 - Inclusion/Exclusion Purge
    *			GF 12/06/2011 TK-10598 Inclusion/Exclusion table name problem
	*			GF 11/18/2012 TK-19407 Claim purge
    *
    *
    * Called by the SL Purge program to delete a Subcontract and all of its
    * related detail.  Status must be 'closed', and Month Closed must be
    * equal to or earlier than the Last Month Closed in SubLedgers.
    *
    * Input parameters:
    *  @co         SL Company
    *  @mth        Selected month to purge SLs through
    *  @sl         Subconract to Purge
    *
    * Output parameters:
    *  @rcode      0 =  successful, 1 = failure
    *
    *************************************************************************/   
       @co bCompany, @mth bMonth, @sl VARCHAR(30), --bSL, DC #135813
       @errmsg varchar(255) output
   
   as
   
   declare @rcode int, @status tinyint, @mthclosed bMonth, @inusemth bMonth, @inusebatchid bBatchID
   
   set nocount on
   
   if @co is null
    	begin
    	select @errmsg = 'Missing SL Company!', @rcode = 1
    	goto bspexit
    	end
   if @mth is null
    	begin
    	select @errmsg = 'Missing month!', @rcode = 1   
    	goto bspexit
    	end
   if @sl is null
   		begin
   		select @errmsg = 'Missing Subcontract!', @rcode = 1
   		goto bspexit
   		end
   
   -- make some checks before purging
   select @status = Status, @mthclosed = MthClosed, @inusemth = InUseMth, @inusebatchid = InUseBatchId
   from bSLHD where SLCo=@co and SL=@sl
   if @@rowcount = 0
       begin
       select @errmsg = 'Invalid Subcontract# ' + @sl, @rcode = 1
       goto bspexit
       end
   if @status <> 2
   		begin
   		select @errmsg = 'Subcontract# ' + @sl + ' must have a (Closed) status!', @rcode = 1
   		goto bspexit
   		end
   if @mthclosed>@mth
   		begin
   		select @errmsg = 'Closed in a later month!', @rcode =1
   		goto bspexit
   		end
   if @inusebatchid is not null
       begin
       select @errmsg = 'Subcontract# ' + @sl + ' is currently in use by a Batch (Mth:' + convert(varchar(8),@inusemth)
           + ' Batch#: ' + convert(varchar(6),@inusebatchid) + ')', @rcode = 1
       goto bspexit
       end
   
   begin transaction
       -- set Purge flag to prevent HQ Auditing during delete
       update bSLHD set Purge='Y' where SLCo=@co and SL=@sl
       if @@error <> 0 goto purge_error
   	-- #20533
   	update bSLCT set PurgeYN='Y' where SLCo=@co and SL=@sl
       if @@error <> 0 goto purge_error
   	-- #24999
   	update bSLCD set PurgeYN='Y' where SLCo=@co and SL=@sl
       if @@error <> 0 goto purge_error
   
   	 -- delete SL from all related tables - must be done in this order
   	delete from bSLCD where SLCo=@co and SL=@sl
       if @@error <> 0 goto purge_error
   	delete from bSLCT where SLCo=@co and SL=@sl
       if @@error <> 0 goto purge_error

	----TK-19407
	DELETE FROM dbo.vSLClaimItemVariation WHERE SLCo = @co AND SL = @sl
	if @@error <> 0 goto purge_error
	DELETE FROM dbo.vSLClaimItem WHERE SLCo = @co AND SL = @sl
	if @@error <> 0 goto purge_error
	DELETE FROM dbo.vSLClaimHeader WHERE SLCo = @co AND SL = @sl
	if @@error <> 0 goto purge_error

    ----TK-10598
    delete from vSLInExclusions where Co=@co and SL=@sl -- JG TFS# 491
   	delete from bSLIT where SLCo=@co and SL=@sl
       if @@error <> 0 goto purge_error
   	delete from bSLHD where SLCo=@co and SL=@sl
       if @@error <> 0 goto purge_error
   commit transaction
   
   select @rcode = 0
   goto bspexit
   
   purge_error:
       rollback transaction
       select @rcode = 1
   
   bspexit:
   	return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspSLPurge] TO [public]
GO
