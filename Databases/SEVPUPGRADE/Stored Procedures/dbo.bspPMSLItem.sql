SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPMSLItem    Script Date: 8/28/99 9:33:07 AM ******/
CREATE  proc [dbo].[bspPMSLItem]
/***********************************************************
 * Created By:	CJW 12/18/97
 * Modified By:	LM 1/10/99
 *				GF 05/05/2003 - issue #21045 need to check PMSL seq for original's to make
 *								sure not adding same item twice to a subcontract.
 *				GF 10/08/2003 - issue #22670 - added validation to check if PMSL record exists on
 *								another sequence for same SL and SL Item with different phase/CT/UM.
 *				GF 03/22/2004 - issue #23938 - added validation for change order PMSL records where
 *								SL and SLitem exists on another change order and has not been interfaced.
 *				GF 03/23/2004 - issue #24124 - loosen up validation to allow multiple CO records to SLItem
 *								not interfaced. Return unit cost for default.
 *				GF 09/09/2005 - issue #29803 use SLIT for defaults if item exists in both SLIT and PMSL
 *				GF 09/28/2006 - remove project from where clauses. Do not need can assign on different projects.
 *				GF 11/01/2006 - added output param for # of PMSL Sequences found for item.
 *				GF 09/19/2008 - issue #129811 tax on subcontracts
 *				GF 11/20/2008 - issue #131067 problem with null UM
 *				GF 06/28/2010 - issue #135813 SL expanded to 30 characters
 *				GF 11/02/2011 TK-09613 validate JCCo and Job to PMCo and Project
 *
 *					
 *
 * USAGE:
 * validates SL Item to insure that it is unique.
 *
 * @SLItemExists = 'N' - Item does not exist in PM or SL
 * @SLItemExists = 'S' - Item exists in SL.
 * @SLItemExists = 'P' - Item exists in PM but not in SL.
 *
 * INPUT PARAMETERS
 *   SLCo      		SLCo to validate against
 *   PMCo  			PMCo to validate
 *   Project		PM Project
 *   Phase			Phase
 *   CostType		CostType
 *   SL				SL to validate
 *   Item			SL Item to validate
 *   RecTypeFilter	PM Subcontract record type
 *   PMSLSeq		PMSL Sequence
 *	 TaxGroup
 *	 TaxType
 *	 TaxCode
 *
 * OUTPUT PARAMETERS
 *   @msg
 * RETURN VALUE
 *   0         success
 *   1         Failure  'if Fails THEN it fails.
 *****************************************************/
(@slco bCompany = 0, @pmco bCompany=0, @project bJob=null, @phase bPhase=null,
 @costtype bJCCType=null, @sl VARCHAR(30)=null, @item bItem = null, @rectypefilter char(1)=null,
 @pmslseq int = null, @itemtype tinyint output, @addon tinyint output, @addonpct bPct output,
 @um bUM output, @unitcost bUnitCost output, @wcretgpct bPct output, @smretpct bPct output,
 @SLItemExists char(1) output, @seqcount int = 0 output, @taxgroup bGroup output,
 @taxtype tinyint output, @taxcode bTaxCode output, @errmsg varchar(250) output,
 @msg varchar(250) output)
as
set nocount on

declare @rcode int, @slitphase bPhase, @slitcosttype bJCCType, @currseq int, @pmslum bUM,
		@SLIT_JCCo bCompany, @SLIT_Job bJob

select @rcode = 0, @msg = 'New Item', @SLItemExists='N', @pmslum = @um, @seqcount = 0

if @pmslseq is null set @pmslseq = -1

---- If the user is working on Orig items and the item exists in SLIT do not allow
---- If the user is working on change orders and the Item already exists in SLIT, then get defaults
---- If the Item exists in PMSL and has not been interfaced, then they cannot enter it again here
---- If the Item does not exist, then it is ok, but we need to default the item type as original.
select @itemtype=ItemType, @addon=Addon, @addonpct=AddonPct, @slitphase=Phase, @slitcosttype=JCCType,
		@msg=Description, @um=UM, @unitcost=CurUnitCost, @wcretgpct=WCRetPct, @smretpct=SMRetPct,
		@taxgroup=TaxGroup, @taxtype=TaxType, @taxcode=TaxCode,
		----TK-09613
		@SLIT_JCCo = JCCo, @SLIT_Job = Job
from dbo.SLIT with (nolock) where SLCo=@slco and SL=@sl and SLItem=@item ----and JCCo=@pmco and Job=@project
If @@rowcount <> 0 
	begin
	select @SLItemExists='S'
	If @rectypefilter = 'O'
		begin
		select @errmsg = 'Item already exists in SL. ', @rcode = 1
		goto bspexit
		end
	If @phase <> @slitphase or @costtype <> @slitcosttype
		begin
		select @errmsg = 'Item already exists with different phase/cost type. ', @rcode = 1
		goto bspexit
		END
		
	----TK-09613
	---- SL item must be in same JC company
	IF @SLIT_JCCo <> @pmco
		BEGIN
		SELECT @errmsg = 'Invalid subcontract item. Assigned to different JC Company.', @rcode=1
		GOTO bspexit
		END
	------ SL item must be in same job
	--IF @SLIT_Job <> @project
	--	BEGIN
	--	SELECT @errmsg = 'Invalid subcontract item. Assigned to different Project.', @rcode=1
	--	GOTO bspexit
	--	END
	
	end

---- get count of sequences in PM for SLCo-SL-SLItem-PMCo. if more than one only some fields can be changed in form
select @seqcount = count(*) from dbo.PMSL where SLCo=@slco and SL=@sl and SLItem=@item and PMCo=@pmco
if @seqcount is null select @seqcount = 0
if not exists(select top 1 1 from dbo.PMSL where PMCo=@pmco and Project=@project and Seq=@pmslseq)
	begin
	select @seqcount = @seqcount + 1
	end

---- if exists in SLIT check for original in PMSL
if @SLItemExists = 'S'
	begin
	select @msg=isnull(SLItemDescription,''), @currseq=Seq
	from dbo.PMSL with (nolock) where SLCo=@slco and SL=@sl and SLItem=@item and PMCo=@pmco and RecordType='O' ----and Project=@project
	end
else
	---- not in SLIT try to find original in PMSL
   	begin
   	Select @itemtype=SLItemType, @addon=SLAddon, @addonpct=SLAddonPct, @slitphase=Phase, @slitcosttype=CostType,
   			@msg=isnull(SLItemDescription,''), @um=UM, @unitcost=UnitCost, @wcretgpct=WCRetgPct, 
   			@smretpct=SMRetgPct, @currseq=Seq, @taxgroup=TaxGroup, @taxtype=@taxtype, @taxcode=TaxCode,
   			----TK-09613
			@SLIT_Job = Project
   	from dbo.PMSL with (nolock) where SLCo=@slco and SL=@sl and SLItem=@item and PMCo=@pmco and RecordType='O' ----and Project=@project
   	end
---- if original found in PMSL check for differences
If @@rowcount <> 0
	begin
	select @SLItemExists='P'
	If @phase <> @slitphase or @costtype <> @slitcosttype
		begin
		select @errmsg = 'Item already exists with different phase/cost type. ', @rcode = 1
		goto bspexit
		end
	if @currseq <> isnull(@pmslseq,'') and @rectypefilter = 'O'
		begin
		select @errmsg = 'Item already exists for this subcontract in PM. ', @rcode = 1
		goto bspexit
		end
	---- TK-09613
	---- SL item must be in same job
	--IF @SLIT_Job <> @project
	--	BEGIN
	--	SELECT @errmsg = 'Invalid subcontract item. Assigned to different Project.', @rcode=1
	--	GOTO bspexit
	--	END
	end
else
	begin
	select @msg=isnull(SLItemDescription,'')
	from dbo.PMSL with (nolock) where SLCo=@slco and SL=@sl and SLItem=@item and PMCo=@pmco and RecordType='C' ----and Project=@project
	end

---- get count of PMSL sequences for the SL/SLITEM
----select @seqcount = select count(*) from PMSL with (nolock) where SLCo=@slco and SL=@sl and SLItem=@item and PMCo=@pmco
----if @seqcount is null select @seqcount = 0

---- check for duplicate with different assigned phase/costtype/um combination for original
if @rectypefilter = 'O' and @sl is not null
	begin
	if exists(select 1 from dbo.PMSL with (nolock) where PMCo=@pmco and SLCo=@slco and SL=@sl
					and SLItem=@item and Seq <> @pmslseq and InterfaceDate is null and RecordType='O') ----and Project=@project )
		begin
		select @SLItemExists='P'
		---- check for duplicate item record with different phase/costtype/um combination
		if exists(select 1 from dbo.PMSL with (nolock) where PMCo=@pmco and SLCo=@slco and SL=@sl
					and SLItem=@item and Seq <> @pmslseq and InterfaceDate is null and RecordType='O'
    	 			and (Phase<>@phase or CostType<>@costtype or UM <> isnull(@pmslum,UM))) ----and Project=@project)
			begin
			set @errmsg = 'SL: ' + isnull(@sl,'') + ' SLItem: ' + convert(varchar(8),isnull(@item,0)) 
					+ ' - Multiple records set up for same item with different Phase/Cost Type/UM combination.'
			set @rcode = 1
			goto bspexit
			end
		goto bspexit
		end
	end


---- check for duplicate with different assigned phase/costtype/um combination for change order
if @rectypefilter in ('P','A') and @sl is not null
	begin
	if exists(select 1 from dbo.PMSL with (nolock) where PMCo=@pmco and SLCo=@slco and SL=@sl
						and SLItem=@item and Seq <> @pmslseq and InterfaceDate is null and RecordType='C') ----and Project=@project)
		begin
		select @SLItemExists='P'
		------ check for duplicate item record with different phase/costtype/um combination
		if exists(select 1 from dbo.PMSL with (nolock) where PMCo=@pmco and SLCo=@slco and SL=@sl
						and SLItem=@item and Seq <> @pmslseq and InterfaceDate is null and RecordType='C'
						and (Phase<>@phase or CostType<>@costtype or UM <> isnull(@pmslum,UM))) ----and Project=@project)
			begin
			set @errmsg = 'SL: ' + isnull(@sl,'') + ' SLItem: ' + convert(varchar(8),isnull(@item,0)) 
				+ ' - Multiple records set up for same item with different Phase/Cost Type/UM combination.'
			set @rcode = 1
			goto bspexit
			end
		---- get unit cost and percentages
		select @itemtype=SLItemType, @unitcost=UnitCost, @wcretgpct=WCRetgPct, @smretpct=SMRetgPct,
				@msg=isnull(SLItemDescription,''), @um=UM, @taxgroup=TaxGroup, @taxtype=TaxType,
				@taxcode=TaxCode
		from dbo.PMSL with (nolock) where PMCo=@pmco and SLCo=@slco and SL=@sl and SLItem=@item
		and Seq <> @pmslseq and InterfaceDate is null and RecordType='C' ----and Project=@project 
		goto bspexit
		end
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMSLItem] TO [public]
GO
