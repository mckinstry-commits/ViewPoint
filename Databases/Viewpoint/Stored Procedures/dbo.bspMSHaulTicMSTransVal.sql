SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[bspMSHaulTicMSTransVal]
    /***********************************************************
    *CREATED BY:	allenn 05/08/02
    *MODIFIED BY: 	allenn 06/25/02
    *				GF 07/11/2012 TK-16342 return haul phase from MSTD
    *
    *USAGE:
    *	for MSHaulAddon form - validates Ticket entered on form 
    *	
    *	issue 14178
    *
    *INPUT PARAMETERS:
    *	MSCo
    *	Mth
    *	MSTrans
    *	FromLoc
    *	Ticket
    *
    *OUTPUT PARAMETERS:
    *	@errmsg      error message
    *
    *RETURN VALUE:
    *	0	success
    *	1	failure
    *****************************************************/ 
    
    (@msco as bCompany, @mth as bMonth, @fromloc bLoc, @ticket bTic, @mstrans bTrans, 
     ----TK-16342
     @HaulPhase bPhase = NULL OUTPUT, @HaulCT bJCCType = NULL OUTPUT,
     @errmsg varchar(60) output)
    
    as
    
    --set nocount on
    
    declare @rcode int, @htype char(1)
    
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
    if @mstrans is null
    	begin
    	select @errmsg = 'Missing MS Transaction!', @rcode = 1
    	goto bspexit
    	end
    if @fromloc is null
    	begin
    	select @errmsg = 'Missing From Location!', @rcode = 1
    	goto bspexit
    	end
    if @ticket is null
    	begin
    	select @errmsg = 'Missing Ticket!', @rcode = 1
    	goto bspexit
    	end
    
    --check that a valid record exists
    select  @htype = HaulerType,
			----TK-16342
			@HaulPhase = HaulPhase,
			@HaulCT = HaulJCCType
    from bMSTD 
    where 
    	bMSTD.MSCo = @msco and
    	bMSTD.Mth = @mth and
    	bMSTD.FromLoc = @fromloc and
    	bMSTD.Ticket = @ticket and
    	bMSTD.MSTrans = @mstrans
    if @@rowcount = 0
    	begin
    	select @errmsg = 'Invalid MS Transaction!', @rcode = 1
    	goto bspexit
    	end
    
    if @htype='N'
    	begin
    	select @errmsg = 'Cannot make a Ticket Addon when Hauler Type equals none.', @rcode = 1
    	goto bspexit
    	end
    
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSHaulTicMSTransVal] TO [public]
GO
