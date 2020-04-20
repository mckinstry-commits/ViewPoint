SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspRQQuoteQouteIDVal    Script Date: 8/25/2004 1:45:01 PM ******/
     CREATE      proc [dbo].[bspRQQuoteQouteIDVal]
     /************************************************
      * Created By: DC  8/24/04
      * Modified by: 
      *
      * 
      *
      * USED IN
      *    RQ Quote Initialize
      *    
      *
      * PASS IN
      *   RQ Company#
      *   Quote ID
      *   
      *
      *
      * RETURNS
      *   0 on Success
      *   1 on ERROR and places error message in msg
     
      **********************************************************/
     	(@co bCompany = 0, @quoteid bCompany, @msg varchar(255) output)
     as
     	set nocount on
     
     	declare @rcode int
     
     select @rcode = 0
     
    if @co is null
    	begin
    	select @msg = 'Missing RQ Company', @rcode = 1
    	goto bspexit
    	end
    
    if @quoteid is null
    	begin
    	select @msg = 'Missing Quote ID', @rcode = 1
    	goto bspexit
    	end
    
    
    SELECT TOP 1 1 
    FROM RQQH h WITH (NOLOCK)
    where h.RQCo=@co AND h.Quote = @quoteid
     if @@rowcount = 0
        begin
        select @msg = 'Not a valid Quote ID.  Enter an existing Quote ID!', @rcode = 1
        goto bspexit
        end
     
     bspexit:
        if @rcode<>0 select @msg=@msg + char(13) + char(10) + '[bspRQQuoteQouteIDVal]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspRQQuoteQouteIDVal] TO [public]
GO
