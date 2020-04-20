SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMWIUniqueVal    Script Date: 8/28/99 9:35:22 AM ******/
CREATE  proc [dbo].[bspPMWIUniqueVal]
/*************************************
 * Created By:	GF 06/15/99
 * Modified By: GF 05/26/2006 - #27996 - 6.x changes
   *
   * Pass:
   *	PMCo, ImportId, Item, Sequence if applicable
   * Returns:
   *
   * Success returns:
   *	0 
   *
   * Error returns:
   *	1 and error message
   **************************************/
(@pmco bCompany = null, @importid varchar(10) = Null, @sequence int = Null, 
 @item bContractItem = Null, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @importid is null
       begin
       select @msg = 'ImportId is missing!', @rcode = 1
       goto bspexit
       end

if @item is null
       begin
       select @msg = 'Item is missing!', @rcode = 1
       goto bspexit
       end

if isnull(@sequence,0) = 0
	begin
	if exists (select 1 from bPMWI with (nolock) where PMCo=@pmco and ImportId=@importid and Item=@item)
		begin
		select @msg = 'Item already exists', @rcode=1
		end
	end
else
	begin
	if exists (select 1 from bPMWI with (nolock) where PMCo=@pmco and ImportId=@importid
					and Item=@item and Sequence <> @sequence) 
		begin
		select @msg = 'Item already exists', @rcode=1
		end
	end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMWIUniqueVal] TO [public]
GO
