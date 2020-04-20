SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMPOItem    Script Date: 8/28/99 9:33:06 AM ******/
CREATE   proc [dbo].[bspPMPOItem]
/***********************************************************
 * CREATED BY	: CJW 12/18/97
 * MODIFIED BY	: LM 2/3/99, LM 3/25/99, LM 3/16/00
 *                GF 04/03/2001 - issue #12904
 *				GF 11/01/2006 - added output param for # of PMMF Sequences found for item.
 *				GF 09/04/2009 - issue #135429 set @pmmfum to @um after query
 *				GF 09/21/2009 - issue #135647 moved the set @pmmfum farther down in procedure.
 *				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
 *
 *
 * USAGE:
 * validates PO Item to insure that it is unique.  Checks POIT
 *
 * INPUT PARAMETERS
 * POCo      PO Co to validate against
 * PMCo      PM Company
 * Project   PM Project
 * Phase     PM Phase code assigned to item
 * CostType  PM CostType assigned to item
 * PO        PO to Validate
 * POItem    PO Item to Validate
 * RecordType Type of record being validated 'O' or 'C'
 * PMMFSeq   PM Material sequence of record
 * @material  PO Item material code
 *
 *
 * OUTPUT PARAMETERS
 * @um        PO Item UM
 * @poitemexists  Where does item exists (N - does not exist, S - exists in PO, P - exists in PM
 * @pounitcost - If item found, unit cost from POIT or PMMF
 * @poecm      - If item found, ECM from POIT or PMMF
 * @seqcount	# of PMMF sequences for POCo,PO,POItem
 * @taxtype		if item found, tax type from POIT or PMMF
 * @taxcode		If item found, tax code from POIT or PMMF
 * @msg
 *
 * RETURN VALUE
 *   0         success
 *   1         Failure  'if Fails THEN it fails.
 *****************************************************/
(@poco bCompany = 0, @pmco bCompany, @project bJob, @phase bPhase, @costtype bJCCType, @po varchar(30),
 @item bItem, @recordtype char(1), @pmmfseq int, @material bMatl, @um bUM output,
 @poitemexists char(1) output, @pounitcost bUnitCost output, @poecm bECM output, 
 @seqcount int = 0 output, @taxtype tinyint output, @taxcode bTaxCode output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @pomaterial bMatl, @pophase bPhase, @pocosttype bJCCType,
		@currseq int, @pmmfum bUM

select @rcode = 0, @msg = '', @poitemexists = 'N', @seqcount = 0, @pmmfum = @um

if @pmmfseq is null set @pmmfseq = -1

---- If the user is working on Original items and the item exists in POIT do not allow.
---- If the user is working on change orders and the Item already exists in POIT, then we need to default all other fields.
---- If the Item already exists in PMMF, then they cannot enter it again here.
---- If the Item does not exist, then it is ok, but we need to defualt the item type as original.

---- Added this because sometimes it was coming here without a phase
If @poco is null or @pmco is null or @project is null or @phase is null or @costtype is null
	begin
	goto bspexit
	end

---- check POIT first
Select @pophase=Phase, @pocosttype=JCCType, @pomaterial=Material, @msg=Description, @um=UM,
		@pounitcost=OrigUnitCost, @poecm=OrigECM, @taxtype=TaxType, @taxcode=TaxCode
from POIT with (nolock) where POCo=@poco and PO=@po and POItem=@item and PostToCo=@pmco
If @@rowcount <> 0
	begin
	set @poitemexists = 'S'
	If @recordtype = 'O'
           begin
           select @msg = 'Item already exists in POIT. ', @rcode = 1
           goto bspexit
           end
	if @phase <> @pophase or @costtype <> @pocosttype
           begin
           select @msg = 'Item already exists with different phase/cost type.', @rcode = 1
           goto bspexit
           end
	If isnull(@material,'') <> isnull(@pomaterial,'')
           begin
           select @msg = 'Item already exists with different material. ', @rcode = 1
           goto bspexit
           end
	end

if @@rowcount = 0 set @pmmfum = @um ---- #135429, 135647
---- get count of sequences in PM for POCo-PO-POItem-PMCo. if more than one only some fields can be changed in form
select @seqcount = count(*) from PMMF where POCo=@poco and PO=@po and POItem=@item and PMCo=@pmco
if @seqcount is null select @seqcount = 0
if not exists(select top 1 1 from PMMF where PMCo=@pmco and Project=@project and Seq=@pmmfseq)
	begin
	select @seqcount = @seqcount + 1
	end

---- if exists in POIT check for original in PMMF
if @poitemexists = 'S'
	begin
	select @msg=isnull(MtlDescription,''), @currseq=Seq
	from PMMF with (nolock) where POCo=@poco and PO=@po and POItem=@item and PMCo=@pmco and RecordType='O'
	end
else
	---- not in POIT try to find original in PMMF
   	begin
   	Select @pophase=Phase, @pocosttype=CostType, @msg=MtlDescription, @um=UM, @pomaterial=MaterialCode,
   			@pounitcost=UnitCost, @poecm=ECM, @currseq=Seq, @taxtype=TaxType, @taxcode=TaxCode
   	from PMMF with (nolock) where POCo=@poco and PO=@po and POItem=@item and PMCo=@pmco and RecordType='O'
   	end
---- if original found in PMMF check for differences
If @@rowcount <> 0
	begin
	select @poitemexists='P'
	If @phase <> @pophase or @costtype <> @pocosttype
		begin
		select @msg = 'Item already exists with different phase/cost type. ', @rcode = 1
		goto bspexit
		end
	If isnull(@material,'') <> isnull(@pomaterial,'')
		begin
		select @msg = 'Item already exists with different material. ', @rcode = 1
		goto bspexit
		end
	if @currseq <> isnull(@pmmfseq,'') and @recordtype = 'O'
		begin
		select @msg = 'Item already exists for this purchase order in PM. ', @rcode = 1
		goto bspexit
		end
	end
else
	begin
	select @msg=isnull(MtlDescription,'')
	from PMMF with (nolock) where POCo=@poco and PO=@po and POItem=@item and PMCo=@pmco and RecordType='C'
	end

---- check for duplicate with different assigned phase/costtype/um combination for original
if @recordtype = 'O' and @po is not null
	begin
	if exists(select 1 from PMMF with (nolock) where PMCo=@pmco and POCo=@poco and PO=@po
					and POItem=@item and Seq <> @pmmfseq and InterfaceDate is null and RecordType='O')
		begin
		select @poitemexists='P'
		---- check for duplicate item record with different phase/costtype/um combination
		if exists(select 1 from PMMF with (nolock) where PMCo=@pmco and POCo=@poco and PO=@po
					and POItem=@item and Seq <> @pmmfseq and InterfaceDate is null and RecordType='O'
    	 			and (Phase<>@phase or CostType<>@costtype or UM<>@pmmfum))
			begin
			set @msg = 'PO: ' + isnull(@po,'') + ' POItem: ' + convert(varchar(8),isnull(@item,0)) 
					+ ' - Multiple records set up for same item with different Phase/Cost Type/UM combination.'
			set @rcode = 1
			goto bspexit
			end
		goto bspexit
		end
	end

---- check for duplicate with different assigned phase/costtype/um combination for change order
if @recordtype in ('P','A') and @po is not null
	begin
	if exists(select 1 from PMMF with (nolock) where PMCo=@pmco and POCo=@poco and PO=@po
						and POItem=@item and Seq <> @pmmfseq and InterfaceDate is null and RecordType='C') ----and Project=@project)
		begin
		select @poitemexists='P'
		------ check for duplicate item record with different phase/costtype/um combination
		if exists(select 1 from PMMF with (nolock) where PMCo=@pmco and POCo=@poco and PO=@po
						and POItem=@item and Seq <> @pmmfseq and InterfaceDate is null and RecordType='C'
						and (Phase<>@phase or CostType<>@costtype or UM<>@pmmfum))
			begin
			set @msg = 'PO: ' + isnull(@po,'') + ' POItem: ' + convert(varchar(8),isnull(@item,0)) 
				+ ' - Multiple records set up for same item with different Phase/Cost Type/UM combination.'
			set @rcode = 1
			goto bspexit
			end
		---- get unit cost
		select @pounitcost=UnitCost, @poecm=ECM, @msg=isnull(MtlDescription,''), @um=UM, @taxtype=TaxType, @taxcode=TaxCode
		from PMMF with (nolock) where PMCo=@pmco and POCo=@poco and PO=@po and POItem=@item
		and Seq <> @pmmfseq and InterfaceDate is null and RecordType='C'
		goto bspexit
		end
	end



----Select @pophase=Phase, @pocosttype=CostType, @pomaterial=MaterialCode, @msg=MtlDescription, @um=UM,
----		@pounitcost=UnitCost, @poecm=ECM
----from PMMF with (nolock) where PMCo=@pmco and POCo=@poco and PO=@po and POItem=@item
----and RecordType='O' and Seq <> isnull(@pmmfseq,99999999)  ----and Project=@project
----If @@rowcount = 1
----	begin
----	if @recordtype = 'O'
----           begin
----           select @msg = 'Item already exists in PMMF.', @rcode=1
----           goto bspexit
----           end
----
----	if @phase <> @pophase or @costtype <> @pocosttype
----           begin
----           select @msg = 'Item already exists with different phase/cost type.', @rcode =1
----           goto bspexit
----           end
----
----	If isnull(@material,'') <> isnull(@pomaterial,'')
----           begin
----           select @msg = 'Item already exists with different material. ', @rcode = 1
----           goto bspexit
----           end
----   
----	select @poitemexists='P'
----	goto bspexit
----	end


----Select @pophase=Phase, @pocosttype=CostType, @pomaterial=MaterialCode, @msg=MtlDescription, @um=UM,
----          @pounitcost=UnitCost, @poecm=ECM
----from PMMF with (nolock) where PMCo=@pmco and POCo=@poco and PO=@po and POItem=@item
----and RecordType='C' and Seq <> isnull(@pmmfseq,99999999)
----If @@rowcount = 1
----	begin
----	if @phase <> @pophase or @costtype <> @pocosttype
----           begin
----           select @msg = 'Item already exists with different phase/cost type.', @rcode =1
----           goto bspexit
----           end
----
----	If isnull(@material,'') <> isnull(@pomaterial,'')
----           begin
----           select @msg = 'Item already exists with different material. ', @rcode = 1
----           goto bspexit
----           end
----
----	select @poitemexists='P'
----	goto bspexit
----	end





bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPOItem] TO [public]
GO
