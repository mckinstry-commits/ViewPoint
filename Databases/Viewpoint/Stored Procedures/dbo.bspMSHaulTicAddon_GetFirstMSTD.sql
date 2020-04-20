SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspMSHaulTicAddon_GetFirstMSTD]
    /***********************************************************
    *CREATED BY:	CMW 12/31/02
    *MODIFIED BY:	GF 03/21/2003 - issue 19080 added from location as input parameter
    *
    *
    *
    *USAGE:
    *	for MSHaulAddon form - gets static information for form header inputs
    *	issue 19080
    *
    *INPUT PARAMETERS:
    *	MSCo
    *	Mth
    *	BatchId
    *	Ticket
    *	FromLoc		Optional from location, may be null.
    *
    *OUTPUT PARAMETERS:
    *  @MSTrans     1st MS Transaction for given ticket,
    *  @FromLoc     Location for 1st transaction from given ticket,
    *	@errmsg      error message
    *
    *RETURN VALUE:
    *	0	success
    *	1	failure
    *****************************************************/ 
   (@msco as bCompany = null, @mth as bMonth = null, @ticket as bTic = null, @fromloc bLoc = null, 
    @mstrans bTrans = null output, @fromlocout bLoc = null output, @errmsg varchar(255) output)
   as
   --set nocount on
    
   declare @rcode int
   
   select @rcode = 0
    
   --validation for any null values
   if @msco is null
    	begin
    	select @errmsg = 'Missing Company!', @rcode = 1
    	goto bspexit
    	end
   
   if @mth is null
    	begin
    	select @errmsg = 'Missing Month!', @rcode = 1
    	goto bspexit
    	end
   
   if @ticket is null
    	begin
    	select @errmsg = 'Missing Ticket!', @rcode = 1
    	goto bspexit
    	end
   
   -- if missing @fromloc then get first MS transaction and location for ticket
   if isnull(@fromloc,'') = ''
   	begin
   	select @mstrans = min(MSTrans)
   	from bMSTD with (nolock) where MSCo=@msco and Mth=@mth and Ticket=@ticket
   	if @@rowcount = 0
   		begin
   		select @errmsg = 'No valid MS transaction for this Co/Month/Ticket.', @rcode = 1
   		goto bspexit
   		end
   
   	-- get from location for this MS trans
   	select @fromlocout = FromLoc
   	from bMSTD with (nolock) where MSCo=@msco and Mth=@mth and Ticket=@ticket and MSTrans=@mstrans
   	end
   	
   -- if from location passed in, get first MS transaction for from location and ticket
   if isnull(@fromloc,'') <> ''
   	begin
   	select @fromlocout = @fromloc
   	select @mstrans = min(MSTrans)
   	from bMSTD with (nolock) where MSCo=@msco and Mth=@mth and Ticket=@ticket and FromLoc=@fromloc
   	if @@rowcount = 0
   		begin
   		select @errmsg = 'No valid MS transaction for this Co/Month/Ticket/FromLoc.', @rcode = 1
   		goto bspexit
   		end
   	end
    
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSHaulTicAddon_GetFirstMSTD] TO [public]
GO
