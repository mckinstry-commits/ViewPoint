SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspPMSLItemValCheck]
/***********************************************************
* Created By:	GF 10/07/2003
* Modified By:	GF 06/28/2010 - issue #135813 SL expanded to 30 characters
*
*
* USAGE:
* Gets the next sequential SubCo number. Gets max(subco) from PMSL
* for the subcontract and item type is 1, 2 or 4.
* Then gets the max(SLChangeOrder) from SLCD for the subcontract
* and item type is 1, 2 or 4. Returns value plus one.
*
* INPUT PARAMETERS
*   pmco, project, slco, sl, slitemtype
*
* OUTPUT PARAMETERS
*   SubCo   next sequential subco
*   msg     description, or error message
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@pmco bCompany = null, @project bJob = null, @slco bCompany = null, @sl VARCHAR(30) = null,
@slitem bItem = null, @seq int = null, @vendor bVendor = null, @recordtype varchar(1) = null, 
@phase bPhase = null, @costtype bJCCType = null, @pmslum bUM = null, @errmsg varchar(255) = null output)
as
set nocount on

declare @rcode int

select @rcode = 0
   
   -- check for duplicate with different assigned phase/costtype/um combination
   if @recordtype = 'O' and @sl is not null
   	begin
   	-- check for duplicate item record with different phase/costtype/um combination
   	if exists(select 1 from bPMSL with (nolock) where PMCo=@pmco and Project=@project and SLCo=@slco
   		and Vendor=@vendor and SL=@sl and SLItem=@slitem and Seq<>@seq and InterfaceDate is null
   		and RecordType='O' and (Phase<>@phase or CostType<>@costtype or UM<>@pmslum))
   		begin
   		set @errmsg = 'SL: ' + isnull(@sl,'') + ' SLItem: ' + convert(varchar(8),isnull(@slitem,0)) 
   					+ ' - Multiple records set up for same item with different Phase/CostType/UM combination.'
   		set @rcode = 1
   	    goto bspexit
   	    end
   	end
   
   
   if @recordtype = 'C' and @sl is not null
   	begin
   	-- check for duplicate item record with different phase/costtype/um combination
   	if exists(select 1 from bPMSL with (nolock) where PMCo=@pmco and Project=@project and SLCo=@slco
   		and Vendor=@vendor and SL=@sl and SLItem=@slitem and Seq<>@seq and InterfaceDate is null
   		and RecordType='C' and (Phase<>@phase or CostType<>@costtype or UM<>@pmslum))
   		begin
   		set @errmsg = 'SL: ' + isnull(@sl,'') + ' SLItem: ' + convert(varchar(8),isnull(@slitem,0)) 
   					+ ' - Multiple records set up for same item with different Phase/CostType/UM combination.'
   		set @rcode = 1
   	    goto bspexit
   	    end
   	end
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   bspexit:
       if @rcode<>0 select @errmsg = isnull(@errmsg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMSLItemValCheck] TO [public]
GO
