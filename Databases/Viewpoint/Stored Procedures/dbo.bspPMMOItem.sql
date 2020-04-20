SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspPMMOItem]
/***********************************************************
 * CREATED By:		GF 02/26/2002
 * MODIFIED By:		GF 11/20/2006 - added output param for # of PMMF Sequences found for item.
 *
 *
 * USAGE:
 * validates MO Item to insure that it is unique.  Checks INMI
 *
 * INPUT PARAMETERS
 * INCo      	PO Co to validate against
 * PMCo      	PM Company
 * Project   	PM Project
 * Phase     	PM Phase code assigned to item
 * CostType  	PM CostType assigned to item
 * MO        	MO to Validate
 * MOItem    	MO Item to Validate
 * RecordType	Type of record being validated 'O' or 'C'
 * PMMFSeq   	PM Material sequence of record
 * Material		PM Material
 *
 *
 * OUTPUT PARAMETERS
 * @um        		MO Item UM
 * @moitemexists	Where does item exists (N - does not exist, S - exists in MO, P - exists in PM
 * @mounitcost  	If item found, unit cost from INMI or PMMF
 * @moecm       	If item found, ECM from INMI or PMMF
 * @seqcount		# of PMMF sequences for INCo,MO,MOItem
 * @taxcode			If item found, tax code from INMI or PMMF
 * @location		if item found, location from INMI or PMMF
 * @msg
 *
 * RETURN VALUE
 *   0         success
 *   1         Failure  'if Fails THEN it fails.
 *****************************************************/
(@inco bCompany = 0, @pmco bCompany, @project bJob, @phase bPhase, @costtype bJCCType,
 @mo varchar(10), @item bItem, @recordtype char(1), @pmmfseq int, @material bMatl,
 @um bUM output, @moitemexists char(1) output, @mounitcost bUnitCost output, @moecm bECM output,
 @seqcount int = 0 output, @taxcode bTaxCode output, @location bLoc output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @momaterial bMatl, @mophase bPhase, @mocosttype bJCCType,
		@currseq int, @pmmfum bUM

select @rcode = 0, @msg = '', @moitemexists = 'N', @seqcount = 0, @pmmfum=@um

if @pmmfseq is null set @pmmfseq = -1

---- If the user is working on Original items and the item exists in POIT do not allow.
---- If the user is working on change orders and the Item already exists in POIT, then we need to default all other fields.
---- If the Item already exists in PMMF, then they cannot enter it again here.
---- If the Item does not exist, then it is ok, but we need to defualt the item type as original.

---- Added this because sometimes it was coming here without a phase
If @inco is null or @pmco is null or @project is null or @phase is null or @costtype is null
	begin
	goto bspexit
	end


---- check INMI first
Select @mophase=Phase, @mocosttype=JCCType, @momaterial=Material, @msg=Description, @um=UM,
          @mounitcost=UnitPrice, @moecm=ECM, @taxcode=TaxCode, @location=Loc
from INMI with (nolock) where INCo=@inco and MO=@mo and MOItem=@item and JCCo=@pmco and Job=@project
If @@rowcount = 1
	begin
	select @moitemexists = 'S'
	If @recordtype = 'O'
           begin
           select @msg = 'Item already exists in INMI. ', @rcode = 1
           goto bspexit
           end
	if @phase <> @mophase or @costtype <> @mocosttype
           begin
           select @msg = 'Item already exists with different phase/cost type.', @rcode = 1
           goto bspexit
           end
	If isnull(@material,'') <> isnull(@momaterial,'')
           begin
           select @msg = 'Item already exists with different material. ', @rcode = 1
           goto bspexit
           end
	end

---- get count of sequences in PM for SLCo-SL-SLItem-PMCo. if more than one only some fields can be changed in form
select @seqcount = count(*) from PMMF where INCo=@inco and MO=@mo and MOItem=@item and PMCo=@pmco and Project=@project
if @seqcount is null select @seqcount = 0
if not exists(select top 1 1 from PMMF where PMCo=@pmco and Project=@project and Seq=@pmmfseq)
	begin
	select @seqcount = @seqcount + 1
	end

---- if exists in INMI check for original in PMMF
if @moitemexists = 'S'
	begin
	select @msg=isnull(MtlDescription,''), @currseq=Seq
	from PMMF with (nolock) where INCo=@inco and MO=@mo and MOItem=@item and PMCo=@pmco and Project=@project and RecordType='O'
	end
else
	---- not in INMI try to find original in PMMF
   	begin
   	Select @mophase=Phase, @mocosttype=CostType, @msg=MtlDescription, @um=UM, @momaterial=MaterialCode,
			@mounitcost=UnitCost, @moecm=ECM, @currseq=Seq, @taxcode=TaxCode, @location=Location
   	from PMMF with (nolock) where INCo=@inco and MO=@mo and MOItem=@item and PMCo=@pmco and Project=@project and RecordType='O'
   	end
---- if original found in PMMF check for differences
If @@rowcount <> 0
	begin
	select @moitemexists='P'
	If @phase <> @mophase or @costtype <> @mocosttype
		begin
		select @msg = 'Item already exists with different phase/cost type. ', @rcode = 1
		goto bspexit
		end
	If isnull(@material,'') <> isnull(@momaterial,'')
		begin
		select @msg = 'Item already exists with different material. ', @rcode = 1
		goto bspexit
		end
	if @currseq <> isnull(@pmmfseq,'') and @recordtype = 'O'
		begin
		select @msg = 'Item already exists for this material order in PM. ', @rcode = 1
		goto bspexit
		end
	end
else
	begin
	select @msg=isnull(MtlDescription,'')
	from PMMF with (nolock) where INCo=@inco and MO=@mo and MOItem=@item and PMCo=@pmco and Project=@project and RecordType='C'
	end

---- check for duplicate with different assigned phase/costtype/um combination for original
if @recordtype = 'O' and @mo is not null
	begin
	if exists(select 1 from PMMF with (nolock) where PMCo=@pmco and Project=@project and INCo=@inco and MO=@mo
					and MOItem=@item and Seq <> @pmmfseq and InterfaceDate is null and RecordType='O')
		begin
		select @moitemexists='P'
		---- check for duplicate item record with different phase/costtype/um combination
		if exists(select 1 from PMMF with (nolock) where PMCo=@pmco and Project=@project and INCo=@inco and MO=@mo
					and MOItem=@item and Seq <> @pmmfseq and InterfaceDate is null and RecordType='O'
    	 			and (Phase<>@phase or CostType<>@costtype or UM<>@pmmfum))
			begin
			set @msg = 'MO: ' + isnull(@mo,'') + ' MOItem: ' + convert(varchar(8),isnull(@item,0)) 
					+ ' - Multiple records set up for same item with different Phase/Cost Type/UM combination.'
			set @rcode = 1
			goto bspexit
			end
		goto bspexit
		end
	end

---- check for duplicate with different assigned phase/costtype/um combination for change order
if @recordtype in ('P','A') and @mo is not null
	begin
	if exists(select 1 from PMMF with (nolock) where PMCo=@pmco and Project=@project and INCo=@inco and MO=@mo
						and MOItem=@item and Seq <> @pmmfseq and InterfaceDate is null and RecordType='C')
		begin
		select @moitemexists='P'
		------ check for duplicate item record with different phase/costtype/um combination
		if exists(select 1 from PMMF with (nolock) where PMCo=@pmco and Project=@project and INCo=@inco and MO=@mo
						and MOItem=@item and Seq <> @pmmfseq and InterfaceDate is null and RecordType='C'
						and (Phase<>@phase or CostType<>@costtype or UM<>@pmmfum))
			begin
			set @msg = 'MO: ' + isnull(@mo,'') + ' MOItem: ' + convert(varchar(8),isnull(@item,0)) 
				+ ' - Multiple records set up for same item with different Phase/Cost Type/UM combination.'
			set @rcode = 1
			goto bspexit
			end
		---- get information
		select @mounitcost=UnitCost, @moecm=ECM, @msg=isnull(MtlDescription,''), @um=UM, @taxcode=TaxCode, @location=Location
		from PMMF with (nolock) where PMCo=@pmco and Project=@project and INCo=@inco and MO=@mo and MOItem=@item
		and Seq <> @pmmfseq and InterfaceDate is null and RecordType='C'
		goto bspexit
		end
	end




----if @moitemexists = 'S' goto bspexit
----
----
----Select @mophase=Phase, @mocosttype=CostType, @momaterial=MaterialCode, @msg=MtlDescription, @um=UM,
----          @mounitcost=UnitCost, @moecm=ECM
----from PMMF with (nolock) where PMCo=@pmco and Project=@project and INCo=@inco and MO=@mo and MOItem=@item
----and RecordType='O' and Seq <> isnull(@pmmfseq,99999999)
----If @@rowcount = 1
----	begin
----	if @recordtype = 'O'
----           begin
----           select @msg = 'Item already exists in PMMF.', @rcode=1
----           goto bspexit
----           end
----   
----	if @phase <> @mophase or @costtype <> @mocosttype
----           begin
----           select @msg = 'Item already exists with different phase/cost type.', @rcode =1
----           goto bspexit
----           end
----   
----	If isnull(@material,'') <> isnull(@momaterial,'')
----           begin
----           select @msg = 'Item already exists with different material. ', @rcode = 1
----           goto bspexit
----           end
----   
----	select @moitemexists='P'
----	goto bspexit
----	end
----
----
----Select @mophase=Phase, @mocosttype=CostType, @momaterial=MaterialCode, @msg=MtlDescription, @um=UM,
----          @mounitcost=UnitCost, @moecm=ECM
----from PMMF with (nolock) where PMCo=@pmco and Project=@project and INCo=@inco and MO=@mo and MOItem=@item
----and RecordType='C' and Seq <> isnull(@pmmfseq,99999999)
----If @@rowcount = 1
----	begin
----	if @phase <> @mophase or @costtype <> @mocosttype
----           begin
----           select @msg = 'Item already exists with different phase/cost type.', @rcode =1
----           goto bspexit
----           end
----   
----	If isnull(@material,'') <> isnull(@momaterial,'')
----           begin
----           select @msg = 'Item already exists with different material. ', @rcode = 1
----           goto bspexit
----           end
----   
----	select @moitemexists='P'
----	goto bspexit
----	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMMOItem] TO [public]
GO
