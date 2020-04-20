SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************************/
CREATE procedure [dbo].[bspMSTicTicketWarn]
/*************************************
 * Created By:   GF 07/12/2000
 * Modified By:	 GF 03/14/2002 - fix for invalid parameter for @seq. may come in 'NEW'
 *               JE 10/15/2004 - changed count(*) to if exists for perfomance Issue 25787
 *
 *
 * USAGE:   Returns a warning for a ticket in MSTicEntry
 *
 *
 * INPUT PARAMETERS
 *  MS Company
 *  From Location
 *  MS Ticket
 *  Month
 *  BatchID
 *  BatchSeq
 *
 * OUTPUT PARAMETERS
 *  @msg      ticket warning message
 * RETURN VALUE
 *   0         Success
 *   1         Failure
 *
 **************************************/
(@msco bCompany = null, @fromloc bLoc = null, @ticket varchar(10) = null,
 @mstrans bTrans = null, @mth bMonth = null, @batchid bBatchID = null,
 @seq varchar(10) = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @ticwarn tinyint, @validcnt int, @batchseq int

select @rcode = 0

if isnumeric(@seq) = 0
	goto bspexit
else
	begin
	select @batchseq = convert(int,@seq)
	select @ticwarn=TicWarn from MSCO with (nolock) where MSCo=@msco
	if @@rowcount = 0 goto bspexit

	---- ticket warning level set to 0 - no warning
	if @ticwarn = 0 goto bspexit

	if @mstrans = 0 select @mstrans = null

	---- ticket warning level set to 1 - Already exists within MS Company
	if @ticwarn = 1
		BEGIN
		if @mstrans is not null
			begin
			---- check ticket detail MSTD
			if exists(select top 1 1 from MSTD with (nolock) where MSCo=@msco and Ticket=@ticket and MSTrans<>@mstrans)
               begin
               select @msg = 'Warning, ticket already exists in MSTD!', @rcode = 1
               goto bspexit
               end
			---- check ticket batches MSTB
			if exists(select top 1 1 from MSTB with (nolock) where Co=@msco and Ticket=@ticket and MSTrans<>@mstrans)
               begin
               select @msg = 'Warning, ticket already exists in MSTB!', @rcode = 1
               goto bspexit
               end
           end
		else
			begin
			---- check ticket detail MSTD
			if exists(select top 1 1 from MSTD with (nolock) where MSCo=@msco and Ticket=@ticket)
				begin
				select @msg = 'Warning, ticket already exists in MSTD!', @rcode = 1
				goto bspexit
				end
			---- check other ticket batches MSTB
			if exists(select top 1 1 from MSTB with (nolock) where Co=@msco and Ticket=@ticket
							and BatchId<>@batchid)
				begin
				select @msg = 'Warning, ticket already exists in MSTB!', @rcode = 1
				goto bspexit
				end
			---- check current MSTB batch
			if exists(select top 1 1 from MSTB with (nolock) where Co=@msco and Mth=@mth
							and BatchId=@batchid and Ticket=@ticket and BatchSeq<>@batchseq)
               begin
               select @msg = 'Warning, ticket already exists in MSTB!', @rcode = 1
               goto bspexit
               end
           end
		END

	---- ticket warning level set to 2 - Already exists within MS Company and From Location
	if @ticwarn = 2
		BEGIN
		if @mstrans is not null
			begin
			---- check ticket detail MSTD
   			if exists(select top 1 1 from MSTD with (nolock) where MSCo=@msco and FromLoc=@fromloc
							and Ticket=@ticket and MSTrans<>@mstrans)
				begin
				select @msg = 'Warning, ticket already exists in MSTD!', @rcode = 1
				goto bspexit
				end
			---- check ticket batches MSTB
			if exists(select top 1 1 from MSTB with (nolock) where Co=@msco and FromLoc=@fromloc
							and Ticket=@ticket and MSTrans<>@mstrans)
				begin
				select @msg = 'Warning, ticket already exists in MSTB!', @rcode = 1
				goto bspexit
				end
			end
		else
			begin
			---- check ticket detail MSTD
			if exists(select top 1 1 from MSTD with (nolock) where MSCo=@msco and FromLoc=@fromloc
							and Ticket=@ticket)
				begin
				select @msg = 'Warning, ticket already exists in MSTD!', @rcode = 1
				goto bspexit
				end
			---- check other ticket batches MSTB
			if exists(select top 1 1 from MSTB with (nolock) where Co=@msco and FromLoc=@fromloc
							and Ticket=@ticket and BatchId<>@batchid)
				begin
				select @msg = 'Warning, ticket already exists in MSTB!', @rcode = 1
				goto bspexit
				end
			---- check current MSTB batch
			if exists(select top 1 1 from MSTB with (nolock) where Co=@msco and Mth=@mth and BatchId=@batchid
							and FromLoc=@fromloc and Ticket=@ticket and BatchSeq<>@batchseq)
				begin
				select @msg = 'Warning, ticket already exists in MSTB!', @rcode = 1
				goto bspexit
				end
			end
		END
	end



bspexit:
	if @rcode <> 0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTicTicketWarn] TO [public]
GO
