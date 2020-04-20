SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMWItemVal    Script Date: 8/28/99 9:35:23 AM ******/
CREATE proc [dbo].[bspPMWItemVal]
/*************************************
   * validates PMWI Item
 * Modified By:	GF 05/26/2006 - #27996 - 6.x changes
   *
   * Pass:
   *	PMCo, PM Import Id, Item
   *
   * Success returns:
   *	0 and Description
   *
   * Error returns:
   *	1 and error message
   **************************************/
(@pmco bCompany = null, @importid varchar(10) = null, @item bContractItem = null, @msg varchar(255) output)
as 
set nocount on

declare @rcode int

select @rcode = 0

if @pmco is null
	begin
	select @msg = 'Missing PM Company', @rcode = 1
	goto bspexit
	end

if @importid is null
      begin
      select @msg='Missing Import Id', @rcode=1
      end

if @item is null
      begin
      select @msg='Missing Item', @rcode=1
      end

select distinct @msg=Description from bPMWI where PMCo=@pmco and ImportId=@importid and Item=@item
if @@rowcount = 0
	begin
	select @msg='Invalid Item', @rcode=1
	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMWItemVal] TO [public]
GO
