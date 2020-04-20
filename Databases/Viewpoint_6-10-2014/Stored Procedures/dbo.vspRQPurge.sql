SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspRQPurge    Script Date: 8/28/99 9:35:26 AM ******/
CREATE     procedure [dbo].[vspRQPurge]
/************************************************************************
* Created :		DC 01/08/2009 - #25782 - Need to create a RQ Entry purge / deletion form 
* Modified :	 
*
* Called by the PO Purge program to delete a RQ and all of its
* related detail.  All of the RQ Lines must have a Status = 'Completed'
*
* Input parameters:
*  @co         PO Company
*  @mth        Selected month to purge POs through
*  @rq         RQ to Purge
*
* Output parameters:
*  @rcode      0 =  successful, 1 = failure
*
*************************************************************************/   
   	@co bCompany, @mth bMonth, @rqid bRQ, @errmsg varchar(255) output
   
	as
   
	declare @rcode int, @recdate bMonth
   
	set nocount on
   
	IF @co is null
		begin
		select @errmsg = 'Missing PO Company!', @rcode = 1
		goto vspexit
		end
	IF @mth is null
		begin
		select @errmsg = 'Missing month!', @rcode = 1
		goto vspexit
		end
	IF @rqid is null
		begin
		select @errmsg = 'Missing Requisition ID!', @rcode = 1
		goto vspexit
		end
   
	-- make some checks before purging
	--make sure the RecDate is equal to or less then the purge thur date
	select @recdate = RecDate
	from bRQRH 
	Where RQCo = @co and RQID = @rqid
	IF @recdate > @mth
		begin
		select @errmsg = 'Completed in a later month!', @rcode =1
		goto vspexit
		end       
	
	--set the ByPassTriggers flag
	UPDATE bRQRL
	SET ByPassTriggers = 'Y'
	WHERE RQCo=@co and RQID=@rqid		   
			   
	begin transaction   		
		-- delete RQ from all related tables - must be done in this order
		delete from bRQRR where RQCo=@co and RQID=@rqid
		IF @@error <> 0 goto purge_error
   		delete from bRQRL where RQCo=@co and RQID=@rqid
   		IF @@error <> 0 goto purge_error
		delete from bRQRH where RQCo=@co and RQID=@rqid
		IF @@error <> 0 goto purge_error		
   
	commit transaction

	--set the ByPassTriggers flag
	UPDATE bRQRL
	SET ByPassTriggers = 'N'
	WHERE RQCo=@co and RQID=@rqid		   
	   
	select @rcode = 0
	goto vspexit
   
	purge_error:
		rollback transaction		
		--set the ByPassTriggers flag
		UPDATE bRQRL
		SET ByPassTriggers = 'N'
		WHERE RQCo=@co and RQID=@rqid		   
		select @rcode = 1
   
   vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspRQPurge] TO [public]
GO
