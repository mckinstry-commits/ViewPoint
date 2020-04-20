SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/************************************************/
CREATE proc [dbo].[vspPMSLCreateSLItem]
/***********************************************************
* Created By:	GF 03/18/2010 - issue #136053 - (AUS) pre-billing
* Modified By:	GF 06/28/2010 - issue #135813 SL expanded to 30 characters
*				GF 09/03/2010 - issue #141031 change to use date only function
*				MV 10/25/2011 - TK-09243 - added NULL param to bspHQTaxRateGetAll 
*				GF 09/17/2012 - TK-17969 use vspHQTaxRateGet for gst rate (single level)

*
*
* USAGE: Called from PM Subcontract Detail after insert or update to create a zero value Subcontract Item
* in SLIT for pre-billing. This item will be created with no original or current values the same as
* when done during interface or from SL Change Orders Add Item. This procedure is only called for
* subcontract change order detail when users answers yes to prompt.
*
*
* INPUT PARAMETERS
* @pmco			PM Company
* @project		PM Project
* @phasegroup	Phase Group
* @phase		Phase
* @costtype		Phase CostType
* @seq			PMSL Sequence
* 
*
* OUTPUT PARAMETERS
* @msg
* RETURN VALUE
* 0         success
* 1         Failure  'if Fails THEN it fails.
*****************************************************/
(@pmco bCompany = null, @project bJob = null, @pmsl_seq bigint = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @slco tinyint, @sl VARCHAR(30), @slitem smallint, @taxgroup bGroup,
		@taxcode bTaxCode, @glco tinyint, @itemtype tinyint, @itemdesc varchar(60),
		@contract bContract, @contractitem bContractItem, @department bDept, @glacct bGLAcct,
		@phasegroup bGroup, @phase bPhase, @costtype bJCCType, @vendorgroup bGroup,
		@um bUM, @wcretgpct bPct, @smretgpct bPct, @supplier bVendor, @taxtype tinyint,
		@errmsg varchar(255), @taxphase bPhase, @taxct bJCCType, @taxjcum bUM, @taxrate bRate,
		@taxamount bDollar, @valueadd varchar(1), @gstrate bRate, @pstrate bRate, @HQTXdebtGLAcct bGLAcct,
		@gsttaxamt bDollar, @psttaxamt bDollar, @actdate bDate, @activeyn varchar(1),
		@pmsl_notes varchar(max), @UnitCost bUnitCost

set @rcode = 0
set @msg = ''

---- set actual date
----#141031
SET @actdate = dbo.vfDateOnly()

---- exit if one of these conditions apply
if @pmco is null goto bspexit
if @project is null goto bspexit
if @pmsl_seq is null goto bspexit


---- get needed information from PMSL to create SL Item
select @slco=SLCo, @sl=SL, @slitem=SLItem, @vendorgroup=VendorGroup, @itemtype=SLItemType, @phasegroup=PhaseGroup,
		@phase=Phase, @costtype=CostType, @itemdesc=SLItemDescription, @um=UM, @wcretgpct=isnull(WCRetgPct,0),
		@smretgpct=isnull(SMRetgPct,0), @supplier=Supplier, @taxgroup=TaxGroup, @taxtype=TaxType, @taxcode=TaxCode,
		@pmsl_notes=Notes, @UnitCost=isnull(UnitCost,0)
from dbo.PMSL where PMCo=@pmco and Project=@project and Seq=@pmsl_seq
if @@rowcount = 0
	begin
	select @msg = 'Unable to get subcontracct detail to create SL Item.', @rcode = 1
	goto bspexit
	end

---- must be change order type
if @itemtype not in (1,2) goto bspexit
---- check tax type and tax code
if @taxtype is null and @taxcode is not null goto bspexit

---- get JC GL Company
select @glco=GLCo
from dbo.JCCO with (nolock) where JCCo=@pmco
if @@rowcount = 0
	begin
	select @msg = 'Unable to get JC GL Company to create SL Item.', @rcode = 1
	goto bspexit
	end

---- get GLAcct default
select @contract=Contract, @contractitem=Item
from dbo.JCJP with (nolock) where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase=@phase
select @department=Department
from dbo.JCCI with (nolock) where JCCo=@pmco and Contract=@contract and Item=@contractitem
select @glacct = null
exec @rcode = dbo.bspJCCAGlacctDflt @pmco, @project, @phasegroup, @phase, @costtype, 'N', @glacct output, @msg output
if @glacct is null
	begin
	select @msg = 'GL Account for Cost Type: ' + convert(varchar(3), @costtype) + ' may not be null', @rcode = 1
	goto bspexit
	end

---- validate Phase
exec @rcode = dbo.bspJCADDPHASE @pmco, @project, @phasegroup, @phase,'Y',null,@errmsg output
if @rcode <> 0
	begin
	select @msg = isnull(@errmsg,'') + ' Cannot add item to SLIT.', @rcode = 1
	goto bspexit
	end
    
---- validate Cost Type
exec @rcode = dbo.bspJCADDCOSTTYPE @jcco=@pmco,@job=@project,@phasegroup=@phasegroup,@phase=@phase,@costtype=@costtype,@um=@um,@override= 'P',@msg=@errmsg output
if @rcode<>0
	begin
	select @msg = isnull(@errmsg,'') + ' Cannot add item to SLIT.', @rcode = 1
	goto bspexit
	end
    
---- update active flag if needed
select @activeyn=ActiveYN
from dbo.JCCH with (nolock) where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@costtype
if @activeyn <> 'Y'
	begin
	update bJCCH set ActiveYN='Y'
	where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@costtype
	end




---- must have valid SL information
if @slco is null goto bspexit
if @sl is null goto bspexit
if @slitem is null goto bspexit


-- -- -- if tax code assigned, validate tax phase and cost type then calculate tax
---- ANY CHANGES MADE TO THIS ROUTINE NEED TO ALSO BE DONE IN bspPMSLACOInterface,
---- bspPMPOInterface, bspPMPOACOInterface, and bspPMInterface. The logic should
---- be similar between the procedures working with tax codes.
if @taxcode is null
	begin
	select @taxamount=0, @taxrate = 0, @gstrate = 0  --DC #130175
	end
else
	begin
	select @taxphase = null, @taxct = null
	---- validate Tax Code
	exec @rcode = bspPOTaxCodeVal @taxgroup, @taxcode, @taxtype, @taxphase output, @taxct output, @errmsg output
	if @rcode <> 0
		begin
		select @msg = isnull(@errmsg,'') + ' Cannot add item to SLIT.', @rcode = 1
		goto bspexit
		end
		
	---- validate Tax Phase if Job Type
	if @taxphase is null select @taxphase = @phase
	if @taxct is null select @taxct = @costtype
	---- validate tax phase - if does not exist try to add it
	exec @rcode = bspJCADDPHASE @pmco, @project, @phasegroup, @taxphase, 'Y', null, @errmsg output
	---- if phase/cost type does not exist in JCCH try to add it
	if not exists(select top 1 1 from bJCCH where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup
					and Phase=@taxphase and CostType=@taxct)
		begin
		-- -- -- insert cost header record
		insert into bJCCH (JCCo,Job,PhaseGroup,Phase,CostType,UM,BillFlag,ItemUnitFlag,PhaseUnitFlag,BuyOutYN,Plugged,ActiveYN,SourceStatus)
		select @pmco, @project, @phasegroup, @taxphase, @taxct, 'LS', 'C', 'N', 'N', 'N', 'N', 'Y', 'I'
		end
	---- validate Tax phase and Tax Cost Type
	exec @rcode = bspJobTypeVal @pmco, @phasegroup, @project, @taxphase, @taxct, @taxjcum output, @errmsg output
	if @rcode <> 0
		begin
		select @msg = 'Tax: ' + isnull(@errmsg,'') + ' Cannot add item to SLIT.', @rcode = 1
		goto bspexit
		end

	---- calculate tax
	select @taxrate = 0, @gstrate = 0, @pstrate = 0
	----DC #130175
	----TK-17969
	exec @rcode = dbo.vspHQTaxRateGet @taxgroup, @taxcode, @actdate, @valueadd output, @taxrate output, NULL, NULL, 
				@gstrate output, @pstrate output, null, null, @HQTXdebtGLAcct output, null, null, null, @msg output
	
	----DC #130175	
	if @gstrate = 0 and @pstrate = 0 and @valueadd = 'Y'
		begin
		---- We have an Intl VAT code being used as a Single Level Code
		if (select GST from bHQTX with (nolock) where TaxGroup = @taxgroup and TaxCode = @taxcode) = 'Y'
			begin
			select @gstrate = @taxrate
			end
		end
	end


---- insert into SLIT when item does not exists
if not exists(select top 1 1 from dbo.SLIT with (nolock) where SLCo=@slco and SL=@sl and SLItem=@slitem)
	begin
	---- insert SLIT 
	insert into SLIT(SLCo, SL, SLItem, ItemType, Addon, AddonPct,JCCo, Job, PhaseGroup, Phase, JCCType,
			Description, UM, GLCo, GLAcct, WCRetPct, SMRetPct, VendorGroup, Supplier,
			OrigUnits, OrigUnitCost, OrigCost, CurUnits, CurUnitCost, CurCost, StoredMatls, InvUnits, InvCost,
			TaxType, TaxCode, TaxGroup, OrigTax, CurTax, InvTax, Notes, JCCmtdTax, TaxRate, GSTRate)
	select @slco, @sl, @slitem, @itemtype, null, 0, @pmco, @project, @phasegroup, @phase, @costtype,
			@itemdesc, @um, @glco, @glacct, isnull(@wcretgpct,0), isnull(@smretgpct,0), @vendorgroup, @supplier, 0,
			CASE WHEN @itemtype = 1 then @UnitCost else 0 end, 0, 0, @UnitCost, 0, 0, 0, 0,
			@taxtype, @taxcode, @taxgroup, 0, 0, 0, @pmsl_notes, 0, @taxrate, @gstrate
	end



bspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMSLCreateSLItem] TO [public]
GO
