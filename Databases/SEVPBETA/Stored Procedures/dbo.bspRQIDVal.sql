SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspRQIDVal    Script Date: 4/27/2004 8:19:26 AM ******/
     CREATE     proc [dbo].[bspRQIDVal]
     /************************************************
      * Created By: DC  4/27/04
      * Modified by: 
      *
      * 
      *
      * USED IN
      *    RQ Initialize
      *    
      *
      * PASS IN
      *   Company#
      *   RQID
      *   ValType	0 = Validate the RQID has NOT been used
      *		1 = Validate the RQID HAS been used
      *
      *
      * RETURNS
      *   0 on Success
      *   1 on ERROR and places error message in msg
     
      **********************************************************/
     	(@co bCompany = 0, @rqid bRQ, @valtype int, @msg varchar(255) output)
     as
     	set nocount on
     
     	declare @rcode int
     
     select @rcode = 0
     
    
    if @rqid is null
    	begin
    	select @msg = 'Missing RQ ID', @rcode = 1
    	goto bspexit
    	end
    
    if @co is null
    	begin
    	select @msg = 'Missing Company', @rcode = 1
    	goto bspexit
    	end
    
    if @valtype is null
    	begin
    	select @msg = 'Missing Validation Type', @rcode = 1
    	goto bspexit
    	end
    
    if @valtype = 0 
    	BEGIN
    	SELECT top 1 1 
    	FROM RQRH WITH (NOLOCK)
    	where RQCo = @co and RQID = @rqid
    	 if @@rowcount = 1
    	    begin
    	    select @msg = 'RQ ID exists.  Must enter a new RQ ID!', @rcode = 1
    	    goto bspexit
    	    end
     	END
    
    if @valtype = 1 
    	BEGIN
    	SELECT top 1 1 
    	FROM RQRH WITH (NOLOCK)
    	where RQCo = @co and RQID = @rqid
    	 if @@rowcount = 0
    	    begin
    	    select @msg = 'Not a valid RQ ID.  Enter an existing RQ ID!', @rcode = 1
    	    goto bspexit
    	    end
     	END
    
     
     bspexit:
        if @rcode<>0 select @msg=@msg + char(13) + char(10) + '[bspRQIDVal]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspRQIDVal] TO [public]
GO
