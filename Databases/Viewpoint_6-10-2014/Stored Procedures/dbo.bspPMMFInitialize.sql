SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*************************************/
CREATE proc [dbo].[bspPMMFInitialize]
/*************************************
 * Created By:	GF 02/11/2002
 * Modified By:	GF 02/24/2004 - issue #23804 - check AutoPO and AutoMO to make sure active in PO and IN
 *				GF 08/23/2004 - issue #25482 - added intialize for requisition into RQ module
 *				GF 11/22/2004 - issue #26274 check PMCO.RQInUse flag for requisitions
 *				GF 12/20/2004 - issue #21540 use new PMCo flags when initializing PO/MO's
 *				GF 12/20/2004 - issue #26533 write out vendor group to bRQRL from bPMMF
 *				GF 12/20/2004 - issue #26535 write out job ship address fields to bRQRL
 *				GF 01/05/2004 - issue #26675 problem with getting max(PO) when creating project/seq and
 *								trim trailing spaces for PMMF.PO is 'N'.
 *				GF 06/27/2005 - issue #29121 more problems with getting max(PO) with len of PO to compare to.
 *				GF 10/21/2005 - issue #30146 completely re-wrote getting max(PO) when using project/seq.
 *				GF 10/19/2006 - issue #120899 use PMCO.POStartSeq or PMCO.MOStartSeq when no PO's or MO's exist for project.
 *				GF 06/27/2007 - issue #124931 after PO created add leading spaces if format is right justified and length less than 10
 *				GF 01/11/2008 - issue #126706 was not checking ACO and PCO correctly, so did not initialize.   
 *				GF 03/12/2008 - issue #127076 added country to RQRL    
 *				GP 07/21/2009 - issue #129666 added call to vspPMMFOpenPOGet
 *				GP 07/30/2009 - issue #129667 added MtlDescription default when flag in PMCO is checked
 *				GF 11/10/2009 - issue #136525 - MO initialize not working with group by location option
 *				GF 01/04/2010 - issue #137291 PO Initialize not working correctly after 129666 change.
 *				GF 11/05/2010 - issue #141031
 *				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
 *				GP 7/29/2011 - TK-07143 changed @PO from varchar(10) to varchar(30)
 *				gf 08/13/2011 - TK-07189 allow for rec type = 'X' PCO approval
*				TRL 12/06/2013 - 64937	Expanded @polength to 30
 *
 *
 *
 * Pass this a Project and it will initialize PO's, MO'S, or Quotes for PM Materials
 *
 * Pass:
 *   PMCO          PM Company
 *   Project       Project
 *   Record Type   O = original, P = Pending CO, A = Approved CO
 *   PCOType       Pending CO Type
 *   CO            Change Order
 *   COItem        Change Order Item
 *
 * Returns:
 *
 *      MSG if Error
 *
 * Success returns:
 *	0 on Success, 1 on ERROR
 *
 * Error returns:
 *	1 and error message
 **************************************/
 (@pmco bCompany, @project bJob, @rectype char(1)=null, @pcotype bDocument=null, @co bACO=null,
  @coitem bACOItem=null, @pmmfseqlist varchar(2000) = '', @msg varchar(255) output)
 as
 set nocount on
  
 declare @rcode int, @retcode int, @validcnt int, @pono varchar(1), @mono varchar(1), @posigpartjob bYN,
  		@povalidpartjob varchar(30), @movalidpartjob varchar(30),
  		@pocharsproject tinyint, @pocharsvendor tinyint, @mocharsproject tinyint,
  		@sigcharspo smallint, @sigcharsmo smallint, @vendor bVendor,
  		@seq int, @poprojectpart bProject, @moprojectpart bProject, @vendorpart varchar(30),
  		@po varchar(30), @mo varchar(10), @locationpart varchar(30), @apco bCompany, @poitem bItem, @moitem bItem,
  		@formattedpo varchar(30), @formattedmo varchar(10), @tmppo varchar(30), @tmpmo varchar(10),
  		@materialoption varchar(1), @poseqlen int, @moseqlen int, @mseqpo int, @mseqmo int,
  		@paddedstring varchar(60), @poitemfrompm bItem, @moitemfrompm bItem, @tmpseq varchar(30),
  		@tmpproject varchar(30), @actcharspo smallint, @actcharsmo smallint, @matlgroup bGroup,
  		@material bMatl, @msco bCompany, @inco bCompany, @um bUM, @fromloc bLoc, @quote varchar(10),
  		@units bUnits, @unitprice bUnitCost, @ecm bECM, @amount bDollar, @location bLoc,
  		@msqdup bUnitCost, @msqdecm bECM, @factor smallint, @autoquote bYN, @newquote varchar(10),
  		@openmocursor tinyint, @groupbyloc bYN, @inmo varchar(10), @validloc int, @rq_count int,
  		@openrqcursor tinyint, @reqdate bDate, @mtldescription bItemDesc, @rqline bItem,
  		@formattedrq varchar(10), @phasegroup bGroup, @phase bPhase, @costtype bJCCType,
  		@inputlength varchar(10), @rq_mask varchar(30), @po_mask varchar(30), @tmp_rq int, @rqinuse bYN,
  		@autorq bYN, @lastrq varchar(10), @pocreate bYN, @mocreate bYN, @inmo_approved bYN,
 		@vendorgroup bGroup, @shipaddress varchar(60), @shipcity varchar(30), @shipstate varchar(4),
 		@shipzip bZip, @shipaddress2 varchar(60), @tmppo1 varchar(30), @i int, @value varchar(1),
		@tmpseq1 varchar(10), @postartseq smallint, @mostartseq smallint, @tmpvalue varchar(30),
		@po_inputmask varchar(30), @cotype bDocType, @pco bACO, @pcoitem bACOItem, @aco bACO, 
		@acoitem bACOItem, @shipcountry varchar(2), @poaddorigopen varchar(1),
		@poaddchgopen varchar(1), @MatlPhaseDesc bYN, @maxPOSeqLen varchar(29)

select @rcode = 0, @openmocursor = 0, @openrqcursor = 0

select @cotype = @pcotype, @pcotype = null, @maxPOSeqLen = '00000000000000000000000000000'

---- Check for required parameters
if @pmco is null
	begin
	select @msg = 'Missing PM Company!', @rcode = 1
	goto bspexit
	end

if @project is null
	begin
	select @msg = 'Missing PM Project!', @rcode = 1
	goto bspexit
	end

---- TK-07189
if @rectype <> 'O' and @rectype <> 'P' and @rectype <> 'A' and @rectype <> 'X'
	begin
	select @msg = 'Missing Record Type!', @rcode = 1
	goto bspexit
	end

---- get the mask for bRQ
select @rq_mask=InputMask, @inputlength = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = 'bRQ'
if isnull(@rq_mask,'') = '' select @rq_mask = 'L'
if isnull(@inputlength,'') = '' select @inputlength = '10'
if @rq_mask in ('R','L')
	begin
	select @rq_mask = @inputlength + @rq_mask + 'N'
	end

---- get the mask for bPO
select @po_mask=InputMask, @inputlength = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = 'bPO'
if isnull(@po_mask,'') = '' select @po_mask = 'L'
----select @po_mask = 'R'
select @po_inputmask = @po_mask
if isnull(@inputlength,'') = '' select @inputlength = '10'
if @po_mask in ('R','L')
	begin
	select @po_mask = @inputlength + @po_mask + 'N'
	end

---- Initial local variable assignments
select @apco=p.APCo, @pono=p.PONo, @posigpartjob=p.POSigPartJob,
 		@sigcharspo=p.SigCharsPO, @sigcharsmo=p.SigCharsMO, @pocharsproject=p.POCharsProject,
  		@pocharsvendor=p.POCharsVendor, @poseqlen=p.POSeqLen, @mono=p.MONo,
  		@mocharsproject=p.MOCharsProject, @moseqlen=p.MOSeqLen,
  		@groupbyloc=p.MOGroupByLoc, @rqinuse=p.RQInUse, @pocreate=p.POCreate, @mocreate=p.MOCreate,
		@postartseq=p.POStartSeq, @mostartseq=p.MOStartSeq, @poaddorigopen=p.POAddOrigOpen,
		@poaddchgopen=p.POAddChgOpen, @MatlPhaseDesc=p.MatlPhaseDesc
from HQCO h with (nolock) join bPMCO p with (nolock) on h.HQCo=p.APCo where p.PMCo=@pmco

---- check significant characters of job, if null or zero then not valid.
if @sigcharspo is null or @sigcharspo = 0 select @posigpartjob = 'N'

---- set valid part Job
if @posigpartjob = 'Y'
	begin
	if @sigcharspo > len(@project) select @sigcharspo = len(@project)
	select @povalidpartjob = substring(@project,1,@sigcharspo)
	end
else
	begin
	select @povalidpartjob = @project, @sigcharspo = len(@project)
	end

select @tmpproject = rtrim(ltrim(@povalidpartjob)), @actcharspo = len(@tmpproject)

---- no significant part job for MO's currently
select @movalidpartjob = @project, @sigcharsmo = len(@project)

select @tmpproject = rtrim(ltrim(@movalidpartjob)), @actcharsmo = len(@tmpproject)

---- get rid of leading spaces
select @poprojectpart = substring(ltrim(@project),1,@pocharsproject)
select @moprojectpart = substring(ltrim(@project),1,@mocharsproject)
select @poitemfrompm = 0, @poitem = 1, @mseqpo = 1

---- get job information
select @shipaddress=ShipAddress, @shipcity=ShipCity, @shipstate=ShipState,
 		@shipzip=ShipZip, @shipaddress2=ShipAddress2, @shipcountry=ShipCountry
from JCJM with (nolock) where JCCo=@pmco and Job=@project


/***************************************************************
 * PURCHASE ORDERS: pseudo cursor to spin through unassigned (P)
***************************************************************/

---- spin through vendors
select @vendor = null
if @rectype = 'O'
  	begin
  	select @vendor = min(f.Vendor) from bPMMF f WITH (NOLOCK)
  	where f.PMCo = @pmco and f.Project = @project and isnull(f.PO,'')='' and f.MaterialOption = 'P'
  	and isnull(f.PCOType,'')='' and isnull(f.PCO,'')='' and isnull(f.PCOItem,'')='' and isnull(f.ACO,'')=''
  	and isnull(f.ACOItem,'')='' and f.Vendor is not null
  	end
if @rectype = 'P'
  	begin
  	select @vendor = min(f.Vendor) from bPMMF f WITH (NOLOCK)
  	where f.PMCo = @pmco and f.Project = @project and isnull(f.PO,'')='' and f.MaterialOption = 'P'
	and f.Vendor is not null ----and f.PCOType=@pcotype and f.PCO=@co and f.PCOItem=@coitem 
  	END
---- TK-07189
if @rectype IN ('A','X')
  	begin
  	select @vendor = min(f.Vendor) from bPMMF f WITH (NOLOCK)
  	where f.PMCo = @pmco and f.Project = @project and isnull(f.PO,'')='' and f.MaterialOption = 'P'
	and f.Vendor is not null   ---- and f.ACO=@co and f.ACOItem=@coitem 
  	end

while @vendor is not null        -- outer loop
BEGIN
if @rectype = 'O'
  	begin
  	select @seq = min(f.Seq) from bPMMF f WITH (NOLOCK)
  	where f.PMCo = @pmco and f.Project = @project and isnull(f.PO,'')='' and f.MaterialOption = 'P'
  	and isnull(f.PCOType,'')='' and isnull(f.PCO,'')='' and isnull(f.PCOItem,'')=''
  	and isnull(f.ACO,'')='' and isnull(f.ACOItem,'')='' and f.Vendor=@vendor and f.Seq is not null
  	end
if @rectype = 'P'
  	begin
  	select @seq = min(f.Seq) from bPMMF f WITH (NOLOCK)
  	where f.PMCo = @pmco and f.Project = @project and isnull(f.PO,'')='' and f.MaterialOption = 'P'
	and f.Vendor=@vendor and f.Seq is not null	---- and f.PCOType=@pcotype and f.PCO=@co and f.PCOItem=@coitem 
  	END
---- TK-07189
if @rectype IN ('A','X')
  	begin
  	select @seq = min(f.Seq) from bPMMF f WITH (NOLOCK)
  	where f.PMCo = @pmco and f.Project = @project and isnull(f.PO,'')='' and f.MaterialOption = 'P'
	and f.Vendor=@vendor and f.Seq is not null   	----and f.ACO=@co and f.ACOItem=@coitem 
  	end

---- pseudo cursor to spin through unassigned materials
while @seq is not null
BEGIN
	select @materialoption=f.MaterialOption, @pcotype=PCOType, @pco=PCO, @pcoitem=PCOItem,
			@aco=ACO, @acoitem=ACOItem, @vendorgroup=VendorGroup, 
			@phasegroup=PhaseGroup, @phase=Phase, @mtldescription=MtlDescription
	from bPMMF f WITH (NOLOCK) where f.PMCo=@pmco and f.Project=@project and f.Seq=@seq
	if @materialoption <> 'P' goto GetNextPOSeq

	---- if initalizing selected sequences check sequence list to the sequence, if not in list goto next
	if isnull(@pmmfseqlist,'') <> ''
		begin
		if charindex(';' + convert(varchar(8),@seq) + ';', @pmmfseqlist) = 0 goto GetNextPOSeq
		end

	---- if @rectype = 'P' pending change order PMMF data must match CO data if we are
	---- restricting to a selected PCO and PCO Item
	if @rectype = 'P'
		begin
		---- pending values must exist
		if isnull(@pcotype,'') = '' goto GetNextPOSeq
		if isnull(@pco,'') = '' goto GetNextPOSeq
		if isnull(@pcoitem,'') = '' goto GetNextPOSeq
		---- ACO and ACO item must be empty
		if isnull(@aco,'') <> '' goto GetNextPOSeq
		if isnull(@acoitem,'') <> '' goto GetNextPOSeq
		---- pending values must equal restrictions
		if isnull(@cotype,'') <> ''
			begin
			if isnull(@pcotype,'') <> isnull(@cotype,'') goto GetNextPOSeq
			if isnull(@pco,'') <> isnull(@co,'') goto GetNextPOSeq
			if isnull(@pcoitem,'') <> isnull(@coitem,'') goto GetNextPOSeq
			end
		end

	---- if @rectype = 'A' approved change order PMSL data must match CO data if we are
	---- restricting to a selected ACO and ACO Item
	----TK-07189
	if @rectype IN ('A','X')
		begin
		------ approved values must exist
		if isnull(@aco,'') = '' goto GetNextPOSeq
		if isnull(@acoitem,'') = '' goto GetNextPOSeq
		------ approved values must equal restrictions
		if isnull(@co,'') <> ''
			begin
			if isnull(@aco,'') <> isnull(@co,'') goto GetNextPOSeq
			if isnull(@acoitem,'') <> isnull(@coitem,'') goto GetNextPOSeq
			end
		end

      	---- if we are building the PO by seq, then we need to retreive the last seq
  		---- used to build the last PO number, then add one to it
  		select @tmppo = null, @tmppo1 = null
      	if @pono='P'
			begin
			if exists(select 1 from bPMMF WITH (NOLOCK) where POCo=@apco and PMCo=@pmco
               		and substring(Project,1,@sigcharspo)=@povalidpartjob and PO is not null) 
			or
				exists(select 1 from bPOHD with (nolock) where POCo=@apco and JCCo=@pmco
					and substring(Job,1,@sigcharspo)=@povalidpartjob)
          		begin
				-- -- -- max from PMMF
           		select @tmppo = max(PO) from bPMMF WITH (NOLOCK)
           		where POCo=@apco and PMCo=@pmco and substring(Project,1,@sigcharspo)=@povalidpartjob
				and substring(PO,1,len(@poprojectpart)) = @poprojectpart
				and datalength(rtrim(PO)) = len(@poprojectpart) + @poseqlen
				-- -- -- max from POHD
           		select @tmppo1 = max(PO) from bPOHD WITH (NOLOCK)
           		where POCo=@apco and JCCo=@pmco and substring(Job,1,@sigcharspo)=@povalidpartjob
				and substring(PO,1,len(@poprojectpart)) = @poprojectpart
				and datalength(rtrim(PO)) = len(@poprojectpart) + @poseqlen
				-- -- -- now use highest to get next sequence
				if isnull(@tmppo,'') <> '' and isnull(@tmppo1,'') = '' select @tmppo1 = @tmppo
				if isnull(@tmppo1,'') <> '' and isnull(@tmppo,'') = '' select @tmppo = @tmppo1
				if @tmppo1 > @tmppo select @tmppo = @tmppo1
            	-- -- -- now parse out the seq part by using company definitions
           		select @tmpseq = substring(reverse(rtrim(@tmppo)),1, @poseqlen), @i = 1, @tmpseq1 = ''
				while @i <= len(@tmpseq)
				begin
					select @value = substring(@tmpseq,@i,1)
					if @value not in ('0','1','2','3','4','5','6','7','8','9')
						select @i = len(@tmpseq)
					else
						select @tmpseq1 = @tmpseq1 + @value
					
					select @i = @i + 1
				end
			---- check if numeric
			if isnumeric(@tmpseq1) = 1 select @mseqpo = convert(int,reverse(@tmpseq1)+1)
			end
		else
			begin
			---- no purchase orders exist for project so use the @postartseq if there is one
			if @postartseq is not null select @mseqpo = @postartseq
			end
		end

	SET @maxPOSeqLen = LEFT (@maxPOSeqLen,@poseqlen)

	---- convert Vendor based on Co parameters
	select @vendorpart = reverse(substring(reverse('0000000000000000000' + ltrim(str(@vendor))),1,@pocharsvendor))
	---- need to pad the seq with leading zeros to the amount specified in company file @SLSeqLen
	select @paddedstring = reverse(substring(reverse(@maxPOSeqLen + ltrim(str(@mseqpo))),1,@poseqlen))
	select @formattedpo = null
 
-- Need to see if there are any PO'S set up already for this vendor.
-- This must be done in two parts depending on how the PO is being created.
-- If creating using the project/seq (P) or auto-seq (A) then consider PO status.
-- Remember that the PO is added to POHD in the PMMF triggers.
-- issue #21540 - enhancement to use the approved flag in POHD header when checking PO status
if @pono in ('P','A')
   	BEGIN
   		
	IF @pocreate = 'Y'
	 	---- when @pocreate = 'Y' consider all pending PO's requardless of approved flag
		begin
		----#137291
		select @formattedpo = max(PO) from dbo.POHD WITH (NOLOCK)
		where POCo=@apco and JCCo=@pmco and Vendor=@vendor and substring(Job,1,@sigcharspo)=@povalidpartjob and Status = 3
		if @@rowcount = 0 select @formattedpo = null
		END
   	
   	---- 129666
	if @formattedpo is null
		begin
		---- original material records
		if @poaddorigopen = 'Y' and @rectype = 'O'
			begin
			exec dbo.vspPMMFOpenPOGet @apco, @pmco, @vendorgroup, @vendor, @project, @formattedpo output, @msg output
			end
		---- change order material records
		if @poaddchgopen = 'Y' and @rectype in ('P','A','X')
			begin
			exec dbo.vspPMMFOpenPOGet @apco, @pmco, @vendorgroup, @vendor, @project, @formattedpo output, @msg output
			end
		end
		
	if @pocreate = 'N'
		begin
		---- when @pocreate = 'N' do not consider approved pending PO's
		select @formattedpo = max(PO) from dbo.POHD WITH (NOLOCK)
		where POCo=@apco and JCCo=@pmco and Vendor=@vendor and substring(Job,1,@sigcharspo)=@povalidpartjob and Status = 3 and Approved = 'N'
		if @@rowcount = 0 select @formattedpo = null
		end
	end
           	

  		
       	if @pono in ('V')
         	begin
           	select @formattedpo = max(PO) from POHD WITH (NOLOCK)
           	where POCo=@apco and JCCo=@pmco and Vendor=@vendor and substring(Job,1,@sigcharspo)=@povalidpartjob
           	if @@rowcount = 0 select @formattedpo = null
           	end
  
       	---- If no valid PO found then build using appropiate format
       	if @formattedpo is null
           	begin
  			if @pono = 'A'
  				begin
  				-- check bPOCO to see if auto-numbering on
  				if not exists(select POCo from bPOCO where POCo=@apco and AutoPO='Y')
  					begin
  					select @msg = 'PO initialize is using auto-numbering, but auto-numbering is not set up in PO Company!', @rcode = 1
  					goto bspexit
  					end
  				end
  
			---- format PO
           	if @pono = 'A'
  				begin
  				exec dbo.bspPOHDNextPO @apco, @po output
  				if isnull(@po,'') = ''
  					begin
  					select @msg = 'Error occurred getting next PO number from PO using auto-numbering!', @rcode = 1
  					goto bspexit
  					end
  				end

			select @formattedpo = case @pono
					---- when it is project/vendor format
					when 'V' then rtrim(@poprojectpart) + rtrim(@vendorpart)
					---- when it is project/seq format
					when 'P' then rtrim(@poprojectpart) + @paddedstring
					---- when it is auto-seq format
					when 'A' then @po end

			---- for format options 'V' or 'P' and 'R' justified check length and add leading spaces
			if @po_inputmask = 'R' and datalength(@formattedpo) < 10
				begin
				if @pono = 'V' or @pono = 'P'
					begin
					select @tmpvalue = reverse(space(10-datalength(@formattedpo)) + ltrim(@formattedpo))
					select @formattedpo=reverse(substring(@tmpvalue,1,10))
					end
				end
			end

		---- check if the PO is already set up under a different project
       	if exists(select 1 from POHD WITH (NOLOCK) where POCo=@apco and JCCo=@pmco and PO=@formattedpo
                   		and substring(Job,1,@sigcharspo)<>@povalidpartjob)
           	begin
           	select @msg = 'One or more POs are already set up under a different project.', @rcode = 1
           	goto GetNextPOSeq
           	end
  
       	---- check if the PO is already set up under a different vendor
       	if exists(select 1 from POHD WITH (NOLOCK) where POCo=@apco and JCCo=@pmco and PO=@formattedpo and Vendor<>@vendor)
           	begin
           	select @msg = 'One or more POs are already set up under a different vendor.', @rcode = 1
           	goto GetNextPOSeq
           	end
  
       	---- Now check for items in POIT and PMSL, take the max
       	---- if the PO already exists then we need to start the seqs there
       	if exists(select 1 from POHD WITH (NOLOCK) where POCo=@apco and PO=@formattedpo)
           	begin
           	select @poitem = isnull(max(POItem),0)+1
           	from POIT where POCo=@apco and PO=@formattedpo
           	end
  
       	---- get the next PO item from PMMF
       	if exists(select 1 from PMMF WITH (NOLOCK) where PMCo=@pmco and POCo=@apco and PO=@formattedpo)
           	begin
           	select @poitemfrompm = isnull(max(POItem),0)+1
           	from PMMF WITH (NOLOCK) where PMCo=@pmco and POCo=@apco and PO=@formattedpo
           	end
  
       	---- take the max of the two
		if @poitemfrompm is null select @poitemfrompm = 0
		if @poitem is null select @poitem = 1
		if @poitemfrompm > @poitem select @poitem = @poitemfrompm
  
		-- 129667 added MtlDescription default when flag in PMCO is checked
		if @mtldescription is null and @MatlPhaseDesc = 'Y'
		begin
			select @mtldescription=Description from dbo.JCJP with (nolock) 
			where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase=@phase
		end
  
		---- update PMMF with formatted PO and item.
		begin transaction
		update PMMF set PO = @formattedpo, POItem = @poitem, MtlDescription = @mtldescription
		where PMCo = @pmco and Project = @project and Seq = @seq
		if @@rowcount = 0
			begin
			select @msg = 'Error Updating PMMF', @rcode=1
			rollback transaction
			goto bspexit
			end
  
		commit transaction
  
  
GetNextPOSeq:
if @rectype = 'O'
	begin
	select @seq = min(Seq) from bPMMF f WITH (NOLOCK)
	where f.PMCo=@pmco and f.Project=@project and isnull(f.PO,'')='' and f.MaterialOption = 'P'
	and isnull(f.PCOType,'')='' and isnull(f.PCO,'')='' and isnull(f.PCOItem,'')='' and isnull(f.ACO,'')=''
	and isnull(f.ACOItem,'')='' and f.Vendor=@vendor  and f.Seq>@seq
	if @@rowcount = 0 select @seq = null
	end
if @rectype = 'P'
	begin
	select @seq = min(Seq) from bPMMF f WITH (NOLOCK)
	where f.PMCo=@pmco and f.Project=@project and isnull(f.PO,'')='' and f.MaterialOption = 'P'
	and f.Vendor=@vendor and f.Seq>@seq 	----and f.PCOType=@pcotype and f.PCO=@co and f.PCOItem=@coitem 
	if @@rowcount = 0 select @seq = null
	END
----TK-07189
if @rectype IN ('A','X')
	begin
	select @seq = min(Seq) from bPMMF f WITH (NOLOCK)
	where f.PMCo=@pmco and f.Project=@project and isnull(f.PO,'')='' and f.MaterialOption = 'P'
	and f.Vendor=@vendor and f.Seq>@seq 	----and f.ACO=@co and f.ACOItem=@coitem 
	if @@rowcount = 0 select @seq = null
	end
END -- inner loop

GetNextVendor:
select @mseqpo = @mseqpo + 1, @mseqmo = @mseqmo + 1
select @poitemfrompm = 0, @moitemfrompm = 0
select @poitem = 1, @moitem = 1

if @rectype = 'O'
	begin
	select @vendor = min(Vendor) from bPMMF f WITH (NOLOCK)
	where f.PMCo=@pmco and f.Project=@project and isnull(f.PO,'')='' and f.MaterialOption = 'P'
	and isnull(f.PCOType,'')='' and isnull(f.PCO,'')='' and isnull(f.PCOItem,'')='' and isnull(f.ACO,'')=''
	and isnull(f.ACOItem,'')='' and f.Vendor>@vendor
	if @@rowcount = 0 select @vendor = null
	end
if @rectype = 'P'
	begin
	select @vendor = min(Vendor) from bPMMF f WITH (NOLOCK)
	where f.PMCo=@pmco and f.Project=@project and isnull(f.PO,'')='' and f.MaterialOption = 'P'
	and f.Vendor>@vendor 	----and f.PCOType=@pcotype and f.PCO=@co and f.PCOItem=@coitem 
	if @@rowcount = 0 select @vendor = null
	END
----TK-07189
if @rectype IN ('A','X')
	begin
	select @vendor = min(Vendor) from bPMMF f WITH (NOLOCK)
	where f.PMCo=@pmco and f.Project=@project and isnull(f.PO,'')='' and f.MaterialOption = 'P'
	and f.Vendor>@vendor 	----and f.ACO=@co and f.ACOItem=@coitem 
	if @@rowcount = 0 select @vendor = null
	end
END -- outer loop
  
  
  
/***************************************************************
 * MATERIAL ORDERS: cursor to spin through unassigned (M)
***************************************************************/

----TK-07189 RECTYPE = 'X' from PCO approval and we only handle PO
IF @rectype = 'X' GOTO  bspexit

declare @count int

if @rectype = 'O'
	BEGIN
	-- create a cursor to process Original materials from PMMF
	declare bcPMMF_MO cursor LOCAL FAST_FORWARD for
	select Seq, MaterialGroup, MaterialCode, MaterialOption, INCo, Location, Units, UM, UnitCost,
			ECM, Amount, PCOType, PCO, PCOItem, ACO, ACOItem, PhaseGroup, Phase, MtlDescription
	from PMMF
	where PMCo=@pmco and Project=@project and MaterialOption='M' and isnull(MO,'')=''
	and isnull(PCOType,'')='' and isnull(PCO,'')='' and isnull(PCOItem,'')='' and isnull(ACO,'')=''
	and isnull(ACOItem,'')='' and INCo is not null and Location is not null
	Group By INCo, Location, Seq, MaterialGroup, MaterialCode, MaterialOption, Units, UM, UnitCost,
				ECM, Amount, PCOType, PCO, PCOItem, ACO, ACOItem, PhaseGroup, Phase, MtlDescription
	END
if @rectype = 'P'
	BEGIN
	-- create a cursor to process Pending Change Order materials from PMMF
	declare bcPMMF_MO cursor LOCAL FAST_FORWARD for
	select Seq, MaterialGroup, MaterialCode, MaterialOption, INCo, Location, Units, UM, UnitCost,
			ECM, Amount, PCOType, PCO, PCOItem, ACO, ACOItem, PhaseGroup, Phase, MtlDescription
	from PMMF
	where PMCo=@pmco and Project=@project and MaterialOption='M' and isnull(MO,'')='' 
	and INCo is not null and Location is not null 	----and PCOType=@pcotype and PCO=@co and PCOItem=@coitem 
	Group By INCo, Location, Seq, MaterialGroup, MaterialCode, MaterialOption, Units, UM, UnitCost,
			ECM, Amount, PCOType, PCO, PCOItem, ACO, ACOItem, PhaseGroup, Phase, MtlDescription
	END
	
if @rectype = 'A'
	BEGIN
	-- create a cursor to process approved Change Order materials from PMMF
	declare bcPMMF_MO cursor LOCAL FAST_FORWARD for
	select Seq, MaterialGroup, MaterialCode, MaterialOption, INCo, Location, Units, UM, UnitCost,
			ECM, Amount, PCOType, PCO, PCOItem, ACO, ACOItem, PhaseGroup, Phase, MtlDescription
	from bPMMF
	where PMCo = @pmco and Project = @project and MaterialOption='M' and isnull(MO,'')='' 
	and INCo is not null and Location is not null 	----and ACO=@co and ACOItem=@coitem 
	Group By INCo, Location, Seq, MaterialGroup, MaterialCode, MaterialOption, Units, UM, UnitCost,
			ECM, Amount, PCOType, PCO, PCOItem, ACO, ACOItem, PhaseGroup, Phase, MtlDescription
	END

-- open cursor
open bcPMMF_MO
select @openmocursor = 1
set @count = 0

-- loop through all materials in bcPMMF_MO cursor
mo_cursor_loop:
fetch next from bcPMMF_MO into @seq, @matlgroup, @material, @materialoption, @inco, @location,
				@units, @um, @unitprice, @ecm, @amount, @pcotype, @pco, @pcoitem, @aco, @acoitem, 
				@phasegroup, @phase, @mtldescription


if @@fetch_status <> 0 goto MO_end

---- check if valid
if isnull(@inco,0)=0 or isnull(@material,'')='' or isnull(@location,'') = '' goto mo_cursor_loop
if @materialoption <> 'M' goto mo_cursor_loop

---- if initalizing selected sequences check sequence list to the sequence, if not in list goto next
if isnull(@pmmfseqlist,'') <> ''
	begin
	if charindex(';' + convert(varchar(8),@seq) + ';', @pmmfseqlist) = 0 goto mo_cursor_loop
	end 

---- if @rectype = 'P' pending change order PMMF data must match CO data if we are
---- restricting to a selected PCO and PCO Item
if @rectype = 'P'
	begin
	---- pending values must exist
	if isnull(@pcotype,'') = '' goto mo_cursor_loop
	if isnull(@pco,'') = '' goto mo_cursor_loop
	if isnull(@pcoitem,'') = '' goto mo_cursor_loop
	---- ACO and ACO item must be empty
	if isnull(@aco,'') <> '' goto mo_cursor_loop
	if isnull(@acoitem,'') <> '' goto mo_cursor_loop
	---- pending values must equal restrictions
	if isnull(@cotype,'') <> ''
		begin
		if isnull(@pcotype,'') <> isnull(@cotype,'') goto mo_cursor_loop
		if isnull(@pco,'') <> isnull(@co,'') goto mo_cursor_loop
		if isnull(@pcoitem,'') <> isnull(@coitem,'') goto mo_cursor_loop
		end
	end

---- if @rectype = 'A' approved change order PMSL data must match CO data if we are
---- restricting to a selected ACO and ACO Item
if @rectype = 'A'
	begin
	------ approved values must exist
	if isnull(@aco,'') = '' goto mo_cursor_loop
	if isnull(@acoitem,'') = '' goto mo_cursor_loop
	------ approved values must equal restrictions
	if isnull(@co,'') <> ''
		begin
		if isnull(@aco,'') <> isnull(@co,'') goto mo_cursor_loop
		if isnull(@acoitem,'') <> isnull(@coitem,'') goto mo_cursor_loop
		end
	end

-- reset initialize values
select @moitemfrompm = 0, @moitem = 1, @mseqmo = 1
  
---- if we are building the MO by seq, then we need to retrieve the last seq
---- used to build the last MO number, then add one to it
---- #136525
select @tmpmo = null
if @mono='P' and exists(select 1 from bPMMF WITH (NOLOCK) where INCo=@inco and PMCo=@pmco
		and substring(Project,1,@sigcharsmo)=@movalidpartjob and MO is not null)
	begin
	select @tmpmo = max(MO) from bPMMF WITH (NOLOCK)
	where INCo=@inco and PMCo=@pmco and substring(Project,1,@sigcharsmo)=@movalidpartjob
	and MO is not null and substring(Project,1,@sigcharsmo)=@movalidpartjob
	-- now parse out the seq part by using company definitions
	select @tmpseq = substring(reverse(rtrim(@tmpmo)),1, @moseqlen), @i = 1, @tmpseq1 = ''
	-- check if numeric
	if isnumeric(@tmpseq) = 1 select @mseqmo = convert(int,reverse(@tmpseq)+1)
	end
else
	begin
	---- no material orders exist for project so use the @mostartseq if there is one
	if @mostartseq is not null select @mseqmo = @mostartseq
	end

---- need to pad the seq with leading zeros to the amount specified in company file @POSeqLen
select @paddedstring = reverse(substring(reverse('0000000000000000000' + ltrim(str(@mseqmo))),1,@moseqlen))
select @formattedmo = null

---- Need to see if there are any MO'S set up already meeting the PM company criteria.
---- MO must match JC company, Job and have a status of pending
---- Remember that the MO is added to INMO in the PMMF triggers.
---- issue #21540 - enhancement to use the approved flag in POHD header when checking PO status
if @groupbyloc = 'N'
  	begin
 	if @mocreate = 'N'
 		-- -- -- when @mocreate = 'N' do not consider approved pending MO's
 		begin
 		-- do not consider location when looking for MO
 		select @formattedmo = max(MO) from dbo.INMO WITH (NOLOCK)
 		where INCo=@inco and JCCo=@pmco and substring(Job,1,@sigcharsmo)=@movalidpartjob
 		and Status = 3 and Approved = 'N'
 		if @@rowcount = 0 select @formattedmo = null
 		end
 	else
 		-- -- -- when @mocreate = 'Y' consider all pending MO's requardless of approved flag
 		begin
  		-- do not consider location when looking for MO
  		select @formattedmo = max(MO) from dbo.INMO WITH (NOLOCK)
  		where INCo=@inco and JCCo=@pmco and substring(Job,1,@sigcharsmo)=@movalidpartjob
  		and Status = 3 and Approved = 'Y'
  		if @@rowcount = 0 select @formattedmo = null
 		end
 	end


-- 129667 added MtlDescription default when flag in PMCO is checked
if @mtldescription is null and @MatlPhaseDesc = 'Y'
begin
	select @mtldescription=Description from dbo.JCJP with (nolock) 
	where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase=@phase
end

if @groupbyloc = 'Y'
	BEGIN
  	-- check first to see if any MO meet base criteria - use the @mocreate flag in check
 	if @mocreate = 'N'
 		begin
  		select @validcnt = count(*) from bINMO WITH (NOLOCK)
  		where INCo=@inco and JCCo=@pmco and substring(Job,1,@sigcharsmo)=@movalidpartjob and Approved = 'N' and Status=3
  		if @validcnt = 0 goto Create_MO
 		end
 	else
 		begin
  		select @validcnt = count(*) from bINMO WITH (NOLOCK)
  		where INCo=@inco and JCCo=@pmco and substring(Job,1,@sigcharsmo)=@movalidpartjob and Status=3
  		if @validcnt = 0 goto Create_MO
 		end
 		

  	-- spin through each MO in INMO that meets criteria. For each MO check 
  	-- MO Item locations (INMI) that match the material location (PMMF)
  	select @inmo = min(MO) from bINMO with (NOLOCK)
  	where INCo=@inco and JCCo=@pmco and substring(Job,1,@sigcharsmo)=@movalidpartjob and Status = 3
  	while @inmo is not null
  	begin
 		---- check approved flag in INMO if @mocreate = 'N' then approved flag must not be 'Y'
 		select @inmo_approved = Approved from bINMO with (nolock) where INCo=@inco and MO=@inmo
 		if @mocreate = 'N' and @inmo_approved = 'Y' goto NEXT_MO
 
 --IF @pocreate = 'Y'
-- 	-- -- -- when @pocreate = 'Y' consider all pending PO's requardless of approved flag
--	begin
--	select @formattedpo = max(PO) from POHD WITH (NOLOCK)
--	where POCo=@apco and JCCo=@pmco and Vendor=@vendor and substring(Job,1,@sigcharspo)=@povalidpartjob
--	and Status = 3 AND Approved = 'Y'
--	if @@rowcount = 0 select @formattedpo = null
--	END

--if @pocreate = 'N'
--	begin
--	 -- -- when @pocreate = 'N' do not consider approved pending PO's
--	select @formattedpo = max(PO) from POHD WITH (NOLOCK)
--	where POCo=@apco and JCCo=@pmco and Vendor=@vendor and substring(Job,1,@sigcharspo)=@povalidpartjob
--	and Status = 3 and Approved = 'N'
--	if @@rowcount = 0 select @formattedpo = null
--	end

  		-- check INMI first, possible no items exist yet in INMI
  		if exists(select INCo from bINMI WITH (NOLOCK) where INCo=@inco and MO=@inmo)
  			begin
  			select @validcnt = 0, @validloc = 0
  			select @validcnt = count(*) from bINMI WITH (NOLOCK) where INCo=@inco and MO=@inmo
  			select @validloc = count(*) from bINMI WITH (NOLOCK) where INCo=@inco and MO=@inmo and Loc=@location
  			-- if counts do not match then not a valid MO. Skip to next MO
  			if @validcnt <> @validloc goto NEXT_MO
  			end
  	
  		-- check PMMF last, possible items exist only here
  		if exists(select INCo from bPMMF WITH (NOLOCK) where INCo=@inco and MO=@inmo)
  			begin
  			select @validcnt = 0, @validloc = 0
  			select @validcnt = count(*) from bPMMF WITH (NOLOCK) where INCo=@inco and MO=@inmo
  			select @validloc = count(*) from bPMMF WITH (NOLOCK) where INCo=@inco and MO=@inmo and Location=@location
  			-- if counts match then a valid MO
  			if @validcnt = @validloc
  				begin
  				select @formattedmo = @inmo
  				goto Create_MO
  				end
  			end
  
  	-- next MO
  	NEXT_MO:
  	select @inmo = min(MO) from bINMO WITH (NOLOCK)
  	where INCo=@inco and JCCo=@pmco and substring(Job,1,@sigcharsmo)=@movalidpartjob and Status=3 and MO>@inmo
  	if @@rowcount = 0 select @inmo = null
  	end
  END
  
  
  
Create_MO:

---- If no valid MO found then build using appropiate format
if @formattedmo is null
  	begin
  	if @mono = 'A'
  		begin
  		-- check bINCO to see if auto-numbering on
  		if not exists(select INCo from bINCO where INCo=@inco and AutoMO='Y')
  			begin
  			select @msg = 'MO initialize is using auto-numbering, but auto-numbering is not set up in IN Company!', @rcode = 1
  			goto bspexit
  			end
  		end
  
  	-- format MO
  	if @mono = 'A'
  		begin
  		exec dbo.bspINMONextMO @inco, @mo output
  		if isnull(@mo,'') = ''
  			begin
  			select @msg = 'Error occurred getting next MO number from IN using auto-numbering!', @rcode = 1
  			goto bspexit
  			end
  		end
  
  	select @formattedmo = case @mono
  	-- when it is project/seq format
  	when 'P' then rtrim(@moprojectpart) + @paddedstring
  	-- when it is auto-seq format
  	when 'A' then @mo end
  	end

	-- skip if no MO
	if isnull(@formattedmo,'') = '' goto mo_cursor_loop
  

	-- check if the MO is already set up under a different project
	if exists(select top 1 1 from bINMO WITH (NOLOCK) where INCo=@inco and JCCo=@pmco and MO=@formattedmo
			   and substring(Job,1,@sigcharsmo)<>@movalidpartjob)
		begin
		select @msg = 'One or more MOs are already set up under a different project.', @rcode = 1
		goto mo_cursor_loop
		end
  
	-- Now check for items in INMI and PMMF take the max
	-- if the MO already exists then we need to start the sequences there
	if exists(select 1 from bINMO WITH (NOLOCK) where INCo=@inco and MO=@formattedmo)
		begin
		select @moitem = isnull(max(MOItem),0)+1
		from bINMI WITH (NOLOCK) where INCo=@inco and MO=@formattedmo
		end

	-- get the next MO item from PMMF
	if exists(select 1 from bPMMF WITH (NOLOCK) where PMCo=@pmco and INCo=@inco and MO=@formattedmo)
		begin
		select @moitemfrompm = isnull(max(MOItem),0)+1
		from bPMMF WITH (NOLOCK) where PMCo=@pmco and INCo=@inco and MO=@formattedmo
		end

	-- take the max of the two
	if @moitemfrompm is null select @moitemfrompm = 0
	if @moitem is null select @moitem = 1
	if @moitemfrompm > @moitem select @moitem = @moitemfrompm

	-- update PMMF with formatted MO and item.
	begin transaction
	update bPMMF set MO = @formattedmo, MOItem = @moitem, MtlDescription = @mtldescription
	where PMCo = @pmco and Project = @project and Seq = @seq
	if @@rowcount = 0
	begin
	select @msg = 'Error Updating PMMF', @rcode=1
	rollback transaction
	goto bspexit
end

commit transaction

goto mo_cursor_loop


MO_end:
	if @openmocursor = 1
		begin
		close bcPMMF_MO
		deallocate bcPMMF_MO
		select @openmocursor = 0
		end
  
  
/***************************************************************
 * QUOTES: pseudo cursor to spin through unassigned (Q)
 ***************************************************************/

QuoteType:
if @rectype = 'O'
  	begin
  	select @seq = min(Seq) from bPMMF f WITH (NOLOCK)
  	where f.PMCo = @pmco and f.Project = @project and isnull(f.Quote,'')='' and f.MaterialOption='Q'
  	and isnull(f.PCOType,'')='' and isnull(f.PCO,'')='' and isnull(f.PCOItem,'')='' and isnull(f.ACO,'')=''
  	and isnull(f.ACOItem,'')=''
  	end
  
if @rectype = 'P'
      begin
      select @seq = min(Seq) from bPMMF f WITH (NOLOCK)
      where f.PMCo = @pmco and f.Project = @project and isnull(f.Quote,'')='' and f.MaterialOption='Q'
      ----and f.PCOType=@pcotype and f.PCO=@co and f.PCOItem=@coitem
      end
  
if @rectype = 'A'
      begin
      select @seq = min(Seq) from bPMMF f WITH (NOLOCK)
      where f.PMCo = @pmco and f.Project = @project and isnull(f.Quote,'')='' and f.MaterialOption='Q'
      ----and f.ACO=@co and f.ACOItem=@coitem
      end


-- pseudo cursor for quotes - loop
while @seq is not null
BEGIN
  	select @matlgroup=MaterialGroup, @material=MaterialCode, @materialoption=MaterialOption, @msco=MSCo,
  		   @location=Location, @units=Units, @um=UM, @unitprice=UnitCost, @ecm=ECM, @amount=Amount,
		   @pcotype=PCOType, @pco=PCO, @pcoitem=PCOItem, @aco=ACO, @acoitem=ACOItem
  	from bPMMF f WITH (NOLOCK) where f.PMCo=@pmco and f.Project=@project and f.Seq=@seq
  	if isnull(@msco,0)=0 or isnull(@material,'')='' or isnull(@location,'') = '' goto GetNextQuoteSeq
  	if @materialoption <> 'Q' goto GetNextQuoteSeq

	---- if initalizing selected sequences check sequence list to the sequence, if not in list goto next
	if isnull(@pmmfseqlist,'') <> ''
		begin
		if charindex(';' + convert(varchar(8),@seq) + ';', @pmmfseqlist) = 0 goto GetNextQuoteSeq
		end

	---- if @rectype = 'P' pending change order PMMF data must match CO data if we are
	---- restricting to a selected PCO and PCO Item
	if @rectype = 'P'
		begin
		---- pending values must exist
		if isnull(@pcotype,'') = '' goto GetNextQuoteSeq
		if isnull(@pco,'') = '' goto GetNextQuoteSeq
		if isnull(@pcoitem,'') = '' goto GetNextQuoteSeq
		---- ACO and ACO item must be empty
		if isnull(@aco,'') <> '' goto GetNextQuoteSeq
		if isnull(@acoitem,'') <> '' goto GetNextQuoteSeq
		---- pending values must equal restrictions
		if isnull(@cotype,'') <> ''
			begin
			if isnull(@pcotype,'') <> isnull(@cotype,'') goto GetNextQuoteSeq
			if isnull(@pco,'') <> isnull(@co,'') goto GetNextQuoteSeq
			if isnull(@pcoitem,'') <> isnull(@coitem,'') goto GetNextQuoteSeq
			end
		end

	---- if @rectype = 'A' approved change order PMSL data must match CO data if we are
	---- restricting to a selected ACO and ACO Item
	if @rectype = 'A'
		begin
		------ approved values must exist
		if isnull(@aco,'') = '' goto GetNextQuoteSeq
		if isnull(@acoitem,'') = '' goto GetNextQuoteSeq
		------ approved values must equal restrictions
		if isnull(@co,'') <> ''
			begin
			if isnull(@aco,'') <> isnull(@co,'') goto GetNextQuoteSeq
			if isnull(@acoitem,'') <> isnull(@coitem,'') goto GetNextQuoteSeq
			end
		end

  	-- first check to see if a quote exists for MSCo, QuoteType, JCCo, Job. Only one quote allowed per JCCo, Job
  	select @quote=Quote from bMSQH WITH (NOLOCK)
  	where MSCo=@msco and QuoteType='J' and JCCo=@pmco and Job=@project
  	if @@rowcount <> 0
  		begin
  		-- check Quote Detail for exact match, if found need to update pricing also
  		select @msqdup=UnitPrice, @msqdecm=ECM
  		from bMSQD WITH (NOLOCK) where MSCo=@msco and Quote=@quote and FromLoc=@location and MatlGroup=@matlgroup
  		and Material=@material and UM=@um
  		if @@rowcount = 1
  			begin
  			-- calculate Amount, update bPMMF
  			select @factor = case @msqdecm when 'M' then 1000 when 'C' then 100 else 1 end
  			select @amount = (@units * @msqdup) / @factor
  			begin transaction
  			Update bPMMF set Quote=@quote, UnitCost=@msqdup, ECM=@msqdecm, Amount=@amount
  			where PMCo=@pmco and Project=@project and Seq=@seq
  			if @@rowcount = 0
  				begin
  				select @msg = 'Error Updating PMMF', @rcode=1
  				rollback transaction
  				goto bspexit
  				end
  			commit transaction
  			end
  		else
  			begin
  			begin transaction
  			Update bPMMF set Quote=@quote
  			where PMCo=@pmco and Project=@project and Seq=@seq
  			if @@rowcount = 0
  				begin
  				select @msg = 'Error Updating PMMF', @rcode=1
  				rollback transaction
  				goto bspexit
  				end
  			commit transaction
  			end
  
  		goto GetNextQuoteSeq
  		end
  
  	-- check MSCo for auto sequence quote
  	select @autoquote=AutoQuote from bMSCO WITH (NOLOCK) where MSCo=@msco
  	if @@rowcount <> 0 and @autoquote = 'Y'
  		begin
  		select @newquote = null
  		exec @retcode = bspMSGetNextQuote @msco, @newquote output
  		if isnull(@newquote,'') <> ''
  			begin
  			begin transaction
  			-- update bPMMF with new quote
  			update bPMMF set Quote=@newquote
  			where PMCo=@pmco and Project=@project and Seq=@seq
  			if @@rowcount = 0 
  				begin
              	select @msg = 'Error Updating PMMF', @rcode=1
              	rollback transaction
 
              	goto bspexit
              	end
  			commit transaction
  			end
  		end
  
  
GetNextQuoteSeq:
if @rectype = 'O'
	begin
	select @seq = min(Seq) from bPMMF f WITH (NOLOCK)
	where f.PMCo=@pmco and f.Project=@project and isnull(f.Quote,'')='' and f.MaterialOption='Q'
	and isnull(f.PCOType,'')='' and isnull(f.PCO,'')='' and isnull(f.PCOItem,'')='' and isnull(f.ACO,'')=''
	and isnull(f.ACOItem,'')='' and f.Seq>@seq
	if @@rowcount = 0 select @seq = null
	end
if @rectype = 'P'
	begin
	select @seq = min(Seq) from bPMMF f WITH (NOLOCK)
	where f.PMCo=@pmco and f.Project=@project and isnull(f.Quote,'')='' and f.MaterialOption='Q'
	and f.Seq>@seq 	----and f.PCOType=@pcotype and f.PCO=@co and f.PCOItem=@coitem 
	if @@rowcount = 0 select @seq = null
	end
if @rectype = 'A'
	begin
	select @seq = min(Seq) from bPMMF f WITH (NOLOCK)
	where f.PMCo=@pmco and f.Project=@project and isnull(f.Quote,'')='' and f.MaterialOption='Q'
	and f.Seq>@seq	----and f.ACO=@co and f.ACOItem=@coitem 
	if @@rowcount = 0 select @seq = null
	end
END -- end loop




/***************************************************************
* REQUISITIONS: pseudo cursor to spin through unassigned (R)
***************************************************************/

if @rqinuse <> 'Y' goto bspexit

-- -- -- initialize RQ values
set @formattedrq = null
-- -- -- check RQCo for using last RQ
select @autorq = AutoRQ from bPOCO with (nolock) where POCo=@apco
if @@rowcount = 0
	begin
	select @msg = 'RQ Company not found!', @rcode = 1
	goto bspexit
	end

if @rectype = 'O'
	BEGIN
	-- create a cursor to process Original materials from PMMF
	declare bcPMMF_RQ cursor LOCAL FAST_FORWARD for
	select Seq, MaterialGroup, MaterialCode, PhaseGroup, Phase, CostType, MaterialOption, 
			Units, UM, UnitCost, ECM, Amount, ReqDate, MtlDescription, VendorGroup,
			PCOType, PCO, PCOItem, ACO, ACOItem
	from bPMMF
	where PMCo=@pmco and Project=@project and MaterialOption='R' and isnull(RequisitionNum,'') = '' and SendFlag='Y'
	and isnull(PCOType,'')='' and isnull(PCO,'')='' and isnull(PCOItem,'')='' and isnull(ACO,'')='' and isnull(ACOItem,'')=''
	Group By Seq, MaterialGroup, MaterialCode, PhaseGroup, Phase, CostType, MaterialOption, Units, UM,
			UnitCost, ECM, Amount, ReqDate, MtlDescription, VendorGroup, PCOType, PCO, PCOItem, ACO, ACOItem
	END
if @rectype = 'P'
	BEGIN
	-- create a cursor to process Pending Change Order materials from PMMF
	declare bcPMMF_RQ cursor LOCAL FAST_FORWARD for
	select Seq, MaterialGroup, MaterialCode, PhaseGroup, Phase, CostType, MaterialOption, 
			Units, UM, UnitCost, ECM, Amount, ReqDate, MtlDescription, VendorGroup,
			PCOType, PCO, PCOItem, ACO, ACOItem
	from bPMMF
	where PMCo=@pmco and Project=@project and MaterialOption='R' and isnull(RequisitionNum,'') = ''
	and SendFlag='Y' ----and PCOType=@pcotype and PCO=@co and PCOItem=@coitem 
	Group By Seq, MaterialGroup, MaterialCode, PhaseGroup, Phase, CostType, MaterialOption, Units, UM,
			UnitCost, ECM, Amount, ReqDate, MtlDescription, VendorGroup, PCOType, PCO, PCOItem, ACO, ACOItem
	END
if @rectype = 'A'
	BEGIN
	-- create a cursor to process approved Change Order materials from PMMF
	declare bcPMMF_RQ cursor LOCAL FAST_FORWARD for
	select Seq, MaterialGroup, MaterialCode, PhaseGroup, Phase, CostType, MaterialOption, 
			Units, UM, UnitCost, ECM, Amount, ReqDate, MtlDescription, VendorGroup,
			PCOType, PCO, PCOItem, ACO, ACOItem
	from bPMMF
	where PMCo = @pmco and Project = @project and MaterialOption='R' and isnull(RequisitionNum,'') = ''
	and SendFlag='Y' ----and ACO=@co and ACOItem=@coitem 
	Group By Seq, MaterialGroup, MaterialCode, PhaseGroup, Phase, CostType, MaterialOption, Units, UM,
			UnitCost, ECM, Amount, ReqDate, MtlDescription, VendorGroup, PCOType, PCO, PCOItem, ACO, ACOItem
	END

-- open cursor
open bcPMMF_RQ
select @openrqcursor = 1

-- loop through all materials in bcPMMF_RQ cursor
rq_cursor_loop:
fetch next from bcPMMF_RQ into @seq, @matlgroup, @material, @phasegroup, @phase, @costtype, @materialoption, 
		@units, @um, @unitprice, @ecm, @amount, @reqdate, @mtldescription, @vendorgroup,
		@pcotype, @pco, @pcoitem, @aco, @acoitem

if @@fetch_status <> 0 goto RQ_end

---- check if valid
if @materialoption <> 'R' goto rq_cursor_loop

---- if initalizing selected sequences check sequence list to the sequence, if not in list goto next
if isnull(@pmmfseqlist,'') <> ''
	begin
	if charindex(';' + convert(varchar(8),@seq) + ';', @pmmfseqlist) = 0 goto rq_cursor_loop
	end
	
---- if @rectype = 'P' pending change order PMMF data must match CO data if we are
---- restricting to a selected PCO and PCO Item
if @rectype = 'P'
	begin
	---- pending values must exist
	if isnull(@pcotype,'') = '' goto rq_cursor_loop
	if isnull(@pco,'') = '' goto rq_cursor_loop
	if isnull(@pcoitem,'') = '' goto rq_cursor_loop
	---- ACO and ACO item must be empty
	if isnull(@aco,'') <> '' goto rq_cursor_loop
	if isnull(@acoitem,'') <> '' goto rq_cursor_loop
	---- pending values must equal restrictions
	if isnull(@cotype,'') <> ''
		begin
		if isnull(@pcotype,'') <> isnull(@cotype,'') goto rq_cursor_loop
		if isnull(@pco,'') <> isnull(@co,'') goto rq_cursor_loop
		if isnull(@pcoitem,'') <> isnull(@coitem,'') goto rq_cursor_loop
		end
	end

---- if @rectype = 'A' approved change order PMSL data must match CO data if we are
---- restricting to a selected ACO and ACO Item
if @rectype = 'A'
	begin
	------ approved values must exist
	if isnull(@aco,'') = '' goto rq_cursor_loop
	if isnull(@acoitem,'') = '' goto rq_cursor_loop
	------ approved values must equal restrictions
	if isnull(@co,'') <> ''
		begin
		if isnull(@aco,'') <> isnull(@co,'') goto rq_cursor_loop
		if isnull(@acoitem,'') <> isnull(@coitem,'') goto rq_cursor_loop
		end
	end


if @rqinuse = 'N'
	begin
	select @msg = 'Requisitions is flagged as not in use in PM Company!', @rcode = 1
	goto bspexit
	end
  
  -- -- -- when no formattedrq and @autorq = 'Y' use @lastrq initially. 
  -- -- -- If exists, then get maximum numeric RQ from RQRH for PM Company
  if @formattedrq is null
  	begin
  	if @autorq = 'Y'
  		begin
  		exec @rcode = dbo.bspRQNextRQID @apco, @lastrq output, @msg output
  		if @rcode = 0 select @formattedrq = @lastrq
 		select @lastrq, @msg
 		end
 	if @autorq <> 'Y' -- -- -- or @formattedrq is null
 		begin
  		select @formattedrq = max(convert(int,RQID)) + 1
 		from bRQRH with (nolock) where RQCo=@apco and isnumeric(RQID) = 1 and RQID not like '%.%'
  		if @@rowcount = 0 select @formattedrq = null
  		end
  
  	-- -- -- either set to first if no in RQ or increment by 1
  	if @formattedrq is null
  		set @tmp_rq = 1
  	else
  		set @tmp_rq = convert(int,@formattedrq)
  
 
  	set @rq_count = 0
  	-- -- -- check for existence of RQ in RQRH, if found increment by 1 up to 10 times
  	while @rq_count < 11
  		begin
  		-- -- -- format RQ
  		select @tmpseq = convert(varchar(10),@tmp_rq + @rq_count), @formattedrq = null
  		exec bspHQFormatMultiPart @tmpseq, @rq_mask, @formattedrq output
  		if isnull(@formattedrq,'') = ''
  			begin
  			select @msg = 'Unable to format RQID for requisitions!', @rcode = 1
  			goto bspexit
  			end
  
  		if not exists(select * from bRQRH where RQCo=@apco and RQID=@formattedrq)
  			BREAK
  		else
  			begin
  			select @rq_count = @rq_count + 1
  			if @rq_count > 10
  				begin
  				select @msg = 'RQ initialize unable to get next numeric RQ: ' + @formattedrq + ' from RQRH!', @rcode = 1
  				goto bspexit
  				end
  			end
  		end
  	end
  
  Create_RQ:
  -- -- -- have RQID if not exists add to bRQRH
  if not exists(select * from bRQRH where RQCo=@apco and RQID=@formattedrq)
  	begin
  	insert bRQRH (RQCo, RQID, Source, Requestor, RecDate, Description)
  	select @apco, @formattedrq, 'PM', SUSER_SNAME(), dbo.vfDateOnly(), null
  	if @@rowcount = 0
  		begin
  		select @msg = 'RQ initialize error occurred adding RQ to RQRH!', @rcode = 1
  		goto bspexit
  		end
  	end
  
  -- -- -- get max(RQLine) from bRQRL
  select @rqline = isnull(max(RQLine),0) + 1
  from bRQRL where RQCo=@apco and RQID=@formattedrq
  if @@rowcount = 0 set @rqline = 1
  
  -- -- -- insert materials into bRQRL
  insert bRQRL (RQCo, RQID, RQLine, LineType, Route, ReqDate, Status, Description, JCCo, Job, JCCType,
  		PhaseGroup, Phase, MatlGroup, Material, VendorGroup, UM, Units, UnitCost, ECM, TotalCost, 
 		Address, City, State, Zip, Address2, Country, Notes)
  select @apco, @formattedrq, @rqline, 1, 0, @reqdate, 0, @mtldescription, @pmco, @project, @costtype,
  		@phasegroup, @phase, @matlgroup, @material, @vendorgroup, @um, @units, @unitprice, @ecm, @amount,
 		@shipaddress, @shipcity, @shipstate, @shipzip, @shipaddress2, @shipcountry,
  		Notes from bPMMF where PMCo=@pmco and Project=@project and Seq=@seq
  if @@rowcount = 0
  	begin
  	select @msg = 'Error has occurred adding RQ Line to bRQRL!', @rcode = 1
  	goto bspexit
  	end
  
  -- -- -- update bPMMF
  update bPMMF set RequisitionNum=@formattedrq, RQLine=@rqline
  where PMCo=@pmco and Project=@project and Seq=@seq
  
  
goto rq_cursor_loop



RQ_end:
	if @openrqcursor = 1
		begin
		close bcPMMF_RQ
		deallocate bcPMMF_RQ
		select @openrqcursor = 0
		end





bspexit:
	if @openmocursor = 1
		begin
		close bcPMMF_MO
		deallocate bcPMMF_MO
		select @openmocursor = 0
		end
  
  	if @openrqcursor = 1
  		begin
  		close bcPMMF_RQ
  		deallocate bcPMMF_RQ
  		select @openrqcursor = 0
  		end
  
  	if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPMMFInitialize] TO [public]
GO
