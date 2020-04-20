SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************/
CREATE proc [dbo].[bspMSHaulTicVal]
/***********************************************************
   *CREATED BY:	allenn 05/06/02
   *MODIFIED BY: 	allenn 05/08/02
   *
   *USAGE:
   *	for MSHaulAddon form - validates Ticket entered on form 
   *	
   *	issue 14178
   *
   *INPUT PARAMETERS:
   *	MSCo
   *	Mth
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
(@msco as bCompany, @mth as bMonth, @fromloc bLoc, @ticket bTic, 
 @errmsg varchar(60) output)
as
----set nocount on

declare @rcode int

select @rcode = 0

---- validation for any null values
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

/*if @fromloc is null
   	begin
   	select @errmsg = 'Missing From Location!', @rcode = 1
   	goto bspexit
   	end*/

if @ticket is null
   	begin
   	select @errmsg = 'Missing Ticket!', @rcode = 1
   	goto bspexit
   	end

---- check that a valid record exists
if not exists(select * from MSTD with (nolock) where MSCo=@msco and Mth=@mth and Ticket=@ticket)
   	begin
   	select @errmsg = 'Invalid Ticket!', @rcode = 1
   	goto bspexit
   	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSHaulTicVal] TO [public]
GO
