SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspRQQuotePurge    Script Date: 8/28/99 9:35:26 AM ******/
   CREATE     procedure [dbo].[vspRQQuotePurge]
   /************************************************************************
    * Created : DC 01/13/2009 - #25782 - Need to create a RQ Entry purge / deletion form 
    * Modified : 
    *
    * Called by the PO Purge program to delete all windowed Quotes.
    *
    * Input parameters:
    *  @co         PO Company
    *
    * Output parameters:
    *  @rcode      0 =  successful, 1 = failure
    *
    *************************************************************************/   
   	@co bCompany, @errmsg varchar(255) output
   
   as
   
   declare @rcode int, @quote int
   
   set nocount on
   
   if @co is null
    	begin
    	select @errmsg = 'Missing PO Company!', @rcode = 1
    	goto vspexit
    	end
   		   
   begin transaction   
	--RQQR
	Delete bRQQR
	from bRQQR r
	where RQCo = @co and 
		not exists(select * from bRQRL where bRQRL.Quote = r.Quote and bRQRL.RQCo = @co)
	if @@error <> 0 goto purge_error

	--RQQL
	delete bRQQL
	from bRQQL l
	where not exists(select * from bRQRL where bRQRL.Quote = l.Quote and bRQRL.RQCo = @co)
	and l.RQCo = @co
	if @@error <> 0 goto purge_error
		   
	--RQQH
	delete bRQQH
	from bRQQH h
	where RQCo = @co and 
		not exists(select * from bRQRL where bRQRL.Quote = h.Quote and bRQRL.RQCo = @co)
	if @@error <> 0 goto purge_error
   

   commit transaction
   
   select @rcode = 0
   goto vspexit
   
   purge_error:
       rollback transaction
       select @rcode = 1
   
   vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspRQQuotePurge] TO [public]
GO
