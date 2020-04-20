
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Stored Procedure dbo.bspPMSLInitialize    Script Date: 8/28/99 9:35:18 AM ******/
CREATE proc [dbo].[bspPMSLInitialize]
/*************************************
* CREATED BY:	LM 04/01/1999
* LAST MODIFIED:GF 04/14/2000 - changed how the SLItem description is defaulted.
*				GF 05/02/2000 - fixed the SubCO get next.
*               GF 06/06/2000 - fixed the project/seq not numeric issue.
*               GF 11/30/2000 - consider status when creating SL by project/seq
*               GF 04/03/2001 - change status check to consider pending or open - issue #12828
*               GF 05/11/2001 - change to get max SL to consider length of SL - issue #13405
*				GF 11/15/2001 - problem with @rectype, should be 'O','A','P'
*				GF 10/17/2002 - issue #18996 do not set SubCO for pending change orders
*				GF 05/14/2003 - issue #21267 need to handle multi-part format SL's
*				GF 02/26/2004 - issue #23764 - no longer create PMSL.SLItemDescription if not empty
*				GF 01/11/2005 - issue #26675 - problem with getting max(SL) when creating project/seq and
*								trim trailing spaces for PMSL.SL is 'N'.
*				GF 03/25/2005 - issue #27482 - if using significant part project and have leading spaces
*								in project, need to not count spaces in SL characters of project.
*				GF 09/15/2005 - issue #29785 trim project part of SL when building SL formatted string.
*				GF 10/31/2005 - issue #30146 completely re-wrote getting max(SL) when using project/seq.
*				GF 08/01/2006 - issue #27853 6.x minor changes, return message. check for inactive phases
*				GF 10/19/2006 - issue #120899 use PMCO.SLStartSeq when no SL's exist for project.
*				GF 01/11/2008 - issue #126706 was not checking ACO and PCO correctly, so did not initialize.
*					GF 04/26/2008 - issue #127908 SubCo numbering by ACO
*					GF 08/19/2008 - issue #129451 sequence needs to start with zero, so that increment value for new project will be 1 not 2
*					GF 06/28/2010 - issue #135813 SL expanded to 30 characters
*				GP 12/16/2010 - added insert to vSLInExclusions if related PC Bid Package In/Exclusions exist (reviewed by DanSo)
*				GF 08/01/2011 TK-07189 allow for rec type = 'X' PCO approval
*				GP 08/30/2011 TK-07993 removed code to get and update @subco
*				GF 10/03/2011 TK-08876 PUT BACK TK-07993 CODE
*				DAN SO 03/13/2013 - TK-13139 - Added @CreateSingleChangeOrder and check for adding to same CO
*											 - @CreateSingleChangeOrder takes precedence over @UseApprSubCo
*				GF 03/30/2012 TK-13768 use the @CreateChangeorders flag
*				AW 03/15/2013 TFS-Make generating the next SL Number its own process (commented out code)
*
*
* Pass this a Project and some issue info and it will initialize SLs
*
* Pass:
*   PMCO
*   Project
*   RecType
*   PCOType
*   CO
*   COItem
*
* Success returns:
*	0 on Success, 1 on ERROR
*
* Error returns:
*	1 and error message
**************************************/
(@pmco bCompany=null, @project bJob=null, @rectype char(1)=null, @cotype bDocType=null,
 @co bACO=null, @coitem bACOItem=null, @pmslseqlist varchar(2000) = '',
 -- TK-13139 -- 
 @CreateSingleChangeOrder bYN = NULL,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @retcode int, @validcnt int, @apco bCompany,
		--@slno varchar(1), @sigpartjob bYN, @validpartjob varchar(30), @slcharsproject tinyint,  
		--@slmask varchar(30), @sllength varchar(30), @slstartseq SMALLINT,
		--@sigchars smallint, @slcharsvendor tinyint, @slseqlen int, @projectpart bProject, @mseq int,
		--@tmpsl varchar(30), @tmpsl1 VARCHAR(30), @tmpseq varchar(30), @i int, @value varchar(1), @tmpseq1 varchar(30),
		--@vendorPart varchar(30), @paddedstring varchar(60), @dummy_sl varchar(30),
		--
		@vendor bVendor, @seq int,
		@SL VARCHAR(30), @slitem bItem,
		@formattedsl varchar(30),  @phase bPhase, @itemtype int,
		@phasegroup bGroup, 
		@slitemfrompm bItem,  @addon tinyint, @addonpct bPct,
		@addonamt bDollar, @sladdonamt bDollar, @pmaddonamt bDollar, @addonseq int,
		@slrcode int, @slmsg varchar(60), @defpcotype bDocType, @defpco bPCO,
		@defpcoitem bPCOItem,@defaco bACO, @defacoitem bACOItem, 
		@partseq int, @tmpproject varchar(30), @actchars smallint,
		@defrecordtype char(1),  
		@slitemdescription bItemDesc, @lastslseq int,  --bSL,  DC #135813
		
		@active bYN, @phasemsg varchar(100), @opencursor int, @recordtype varchar(1),
		@pcotype bDocType, @pco bACO, @pcoitem bACOItem, @aco bACO, @acoitem bACOItem,
		@lastvendor bVendor, 
		@SLExists CHAR(1),
		---- TK-08876
		@subco INT, @UseApprSubCo CHAR(1)

select @rcode = 0, @opencursor = 0, @slrcode = 0, @lastslseq = 0, @lastvendor = null,
		@phasemsg = '', @msg = ''

if @pmco is null or @project is null
	begin
	select @msg = 'Missing information!', @rcode = 1
	goto bspexit
	end

----if @rectype = 'C' and isnull(@cotype,'') = ''  select @rectype='A'
----if @rectype = 'C' and isnull(@cotype,'') <> '' select @rectype = 'P'
----TK-07189
if @rectype <> 'O' and @rectype <> 'P' and @rectype <> 'A' AND @rectype <> 'X'
       begin
       select @msg = 'Missing Record Type!', @rcode = 1
       goto bspexit
       end

------ get input mask for bSL
--select @slmask=InputMask, @sllength = convert(varchar(30), InputLength)  --DC #135813
--from DDDTShared with (nolock) where Datatype = 'bSL'
--if isnull(@slmask,'') = '' select @slmask = 'L'
--if isnull(@sllength,'') = '' select @sllength = '10'
--if @slmask in ('R','L')
--   	begin
--   	select @slmask = @sllength + @slmask + 'N'
--   	end

------ get HQ company info
select @apco=p.APCo, 
          ----TK-08876
          @UseApprSubCo = p.UseApprSubCo
from dbo.bHQCO h with (nolock) join dbo.bPMCO p with (nolock) on h.HQCo=p.APCo where p.PMCo=@pmco
------ check significant characters of job, if null or zero then not valid.
--if @sigchars is null or @sigchars = 0 select @sigpartjob = 'N'

----TK-13768
if @CreateSingleChangeOrder is null set @CreateSingleChangeOrder = @UseApprSubCo

------ set valid part job
--if @sigpartjob = 'Y'
--       begin
--       if @sigchars > len(@project) select @sigchars = len(@project)
--       select @validpartjob = substring(@project,1,@sigchars)
--       end
--else
--       begin
--       select @validpartjob = @project, @sigchars = len(@project)
--       end

--select @tmpproject = rtrim(ltrim(@validpartjob)), @actchars = len(@tmpproject)
------ get rid of leading spaces
--select @projectpart = substring(ltrim(@project),1,@slcharsproject)
select @itemtype = 0
select @slitemfrompm = 0
select @slitem = 1
--select @mseq = 0

------ need to reset @slcharsproject to project part without any leading spaces
--select @slcharsproject = datalength(ltrim(@projectpart))

------ declare cursor on PMSL with no SL's
declare bcPMSL cursor LOCAL FAST_FORWARD
	for select Seq, RecordType, PCOType, PCO, PCOItem, ACO, ACOItem, Vendor 
from PMSL where PMCo=@pmco and Project=@project and isnull(SL,'') = '' and Vendor is not null
Order By Vendor, SLItemType, Seq

------ open cursor
open bcPMSL
select @opencursor = 1

PMSL_loop:
fetch next from bcPMSL into @seq, @recordtype, @pcotype, @pco, @pcoitem, @aco, @acoitem, @vendor
if @@fetch_status <> 0 goto PMSL_end

---- first check record type 'O' - original or 'C' - change order ('A','P')
----TK-07189
IF @rectype <> 'X'
	BEGIN
	if @recordtype <> 'O' and @rectype = 'O' goto PMSL_loop -- originals only
	if @recordtype = 'O' and @rectype <> 'O' goto PMSL_loop -- change orders only
	END
	
---- if initalizing selected sequences check sequence list to the sequence, if not in list goto next
if isnull(@pmslseqlist,'') <> ''
	begin
	if charindex(';' + convert(varchar(6),@seq) + ';', @pmslseqlist) = 0 goto PMSL_loop
	end

---- if @rectype = 'P' pending change order PMSL data must match CO data if we are
---- restricting to a selected PCO and PCO Item
if @rectype = 'P'
	begin
	---- pending values must exist
	if isnull(@pcotype,'') = '' goto PMSL_loop
	if isnull(@pco,'') = '' goto PMSL_loop
	if isnull(@pcoitem,'') = '' goto PMSL_loop
	---- ACO and ACO item must be empty
	if isnull(@aco,'') <> '' goto PMSL_loop
	if isnull(@acoitem,'') <> '' goto PMSL_loop
	---- pending values must equal restrictions
	if isnull(@cotype,'') <> ''
		begin
		if isnull(@pcotype,'') <> isnull(@cotype,'') goto PMSL_loop
		if isnull(@pco,'') <> isnull(@co,'') goto PMSL_loop
		if isnull(@pcoitem,'') <> isnull(@coitem,'') goto PMSL_loop
		end
	end

---- if @rectype = 'A' approved change order PMSL data must match CO data if we are
---- restricting to a selected ACO and ACO Item
----TK-07189
if @rectype IN ('A','X')
	begin
	------ approved values must exist
	if isnull(@aco,'') = '' goto PMSL_loop
	if isnull(@acoitem,'') = '' goto PMSL_loop
	------ approved values must equal restrictions
	if isnull(@co,'') <> ''
		begin
		if isnull(@aco,'') <> isnull(@co,'') goto PMSL_loop
		if isnull(@acoitem,'') <> isnull(@coitem,'') goto PMSL_loop
		end
	end

------ reset values when vendor changes
if isnull(@lastvendor,'') <> @vendor
	begin
	select @slitemfrompm = 0
	--select @mseq = @mseq + 1
	select @slitem = 1
	end


--select 'Sequence: ' + convert(varchar(6),@seq)
--goto PMSL_loop

select @lastvendor = @vendor
------ read PMSL data
select @phasegroup=PhaseGroup, @phase=Phase, @addon=SLAddon, @addonpct=SLAddonPct,
		@itemtype=SLItemType, @defpcotype=PCOType, @defpco=PCO, @defpcoitem=PCOItem,
		@defaco=ACO, @defacoitem=ACOItem, @defrecordtype=RecordType, @slitemdescription=SLItemDescription
from PMSL with (nolock) where PMCo=@pmco and Project=@project and Vendor=@vendor and Seq=@seq
------ if phase is inactive do not initialize - btPMSLu trigger will error out.
select @active=ActiveYN from bJCJP with (nolock)
where JCCo = @pmco and Job = @project and Phase = @phase
if @@rowcount = 1 and @active = 'N'
	begin
	select @phasemsg = 'One or more subcontract phases are inactive, will not be initialized, ' + isnull(@phase,'') + '.', @rcode = 1
	goto PMSL_loop
	end

------ get SLItem description
if isnull(@slitemdescription,'') = ''
	begin
   	exec @slrcode = dbo.bspPMSLItemDescDefault @pmco, @project, @phasegroup, @phase, @defpcotype,
   					@defpco, @defpcoitem, @defaco, @defacoitem, @seq, @slmsg output
   	if @slrcode <> 0
   	    begin
   	    select @slitemdescription='Description not found'
   	    end
   	else
   	    begin
   	    select @slitemdescription=@slmsg
   	    end
   	end

------ if we are building the subcontract by seq, then we need to retreive the last seq
------ used to build the last subcontract number, then add one to it
--select @tmpsl = null, @tmpsl1 = null
--if @slno='P'
--	begin
--	if exists(select 1 from bPMSL WITH (NOLOCK) where SLCo=@apco and PMCo=@pmco
--				and substring(Project,1,@sigchars)=@validpartjob and SL is not null) 
--			or
--		exists(select 1 from bSLHD with (nolock) where SLCo=@apco and JCCo=@pmco
--				and substring(Job,1,@sigchars)=@validpartjob)
--		begin
--		------ max from PMSL
--		select @tmpsl = max(SL) from bPMSL WITH (NOLOCK)
--		where SLCo=@apco and PMCo=@pmco and substring(Project,1,@sigchars)=@validpartjob
--		and SL is not null and substring(SL,1,len(@projectpart)) = @projectpart
--		and datalength(rtrim(SL)) = len(@projectpart) + @slseqlen
--		------ max from SLHD
--		select @tmpsl1 = max(SL) from bSLHD WITH (NOLOCK)
--		where SLCo=@apco and JCCo=@pmco and substring(Job,1,@sigchars)=@validpartjob
--		and substring(SL,1,len(@projectpart)) = @projectpart
--		and datalength(rtrim(SL)) = len(@projectpart) + @slseqlen
--		------ now use highest to get next sequence
--		if isnull(@tmpsl,'') <> '' and isnull(@tmpsl1,'') = '' select @tmpsl1 = @tmpsl
--		if isnull(@tmpsl1,'') <> '' and isnull(@tmpsl,'') = '' select @tmpsl = @tmpsl1
--		if @tmpsl1 > @tmpsl select @tmpsl = @tmpsl1
--		------ now parse out the seq part by using company definitions
--		select @tmpseq = substring(reverse(rtrim(@tmpsl)),1, @slseqlen), @i = 1, @tmpseq1 = ''
--		while @i <= len(@tmpseq)
--			begin
--			select @value = substring(@tmpseq,@i,1)
--			if @value not in ('0','1','2','3','4','5','6','7','8','9')
--				select @i = len(@tmpseq)
--			else
--				select @tmpseq1 = @tmpseq1 + @value
					
--			select @i = @i + 1
--			end
--		------ check if numeric
--		if isnumeric(@tmpseq1) = 1 select @mseq = convert(int,reverse(@tmpseq1)+1)
--		end
--	else
--		begin
--		---- no subcontracts exist for project so use the @slstartseq if there is one
--		if @slstartseq is not null select @mseq = @slstartseq
--		end
--	end

-------- convert Vendor based on Co parameters
--select @vendorPart = reverse(substring(reverse('0000000000000000000' + ltrim(str(@vendor))),1,@slcharsvendor))
-------- need to pad the seq with leading zeros to the amount specified in company file @slseqlen
--select @paddedstring = reverse(substring(reverse('0000000000000000000' + ltrim(str(@mseq))),1,@slseqlen))
--select @formattedsl = null
  
--if @slno = 'P' select @lastslseq = @mseq
------ Need to see if there are any subcontracts set up already for this vendor.
------ This must be done in two parts depending on how the subcontract is being created.
------ If creating using project/seq (P), then consider subcontract status.
------ Remember that the subcontract is added to SL in the PMSL triggers.
------ If a valid subcontract is found then use.
--if @slno = 'P'
--	begin
--	select @formattedsl = max(SL) from SLHD with (nolock) 
--	where SLCo=@apco and JCCo=@pmco and Vendor=@vendor and substring(Job,1,@sigchars)=@validpartjob and Status in (0,3)
--	if @@rowcount = 0 select @formattedsl = null
--	end

--if @slno = 'V'
--	begin
--	select @formattedsl = max(SL) from SLHD with (nolock) 
--	where SLCo=@apco and JCCo=@pmco and Vendor=@vendor and substring(Job,1,@sigchars)=@validpartjob
--	if @@rowcount = 0 select @formattedsl = null
--	end

------ if no valid subcontract found then build using appropiate value
--if @formattedsl is null
--	begin
--   	if @slno = 'V'
--   		begin
--   		set @dummy_sl = ltrim(rtrim(@projectpart)) + @vendorPart
--   		exec @retcode = dbo.bspHQFormatMultiPart @dummy_sl, @slmask, @formattedsl output
--   		end
--   	else
--   		begin
--   		set @dummy_sl = ltrim(rtrim(@projectpart)) + @paddedstring
--   		exec @retcode = dbo.bspHQFormatMultiPart @dummy_sl, @slmask, @formattedsl output
--   		end
--	end

------ check if subcontract already set up under a different job
--if exists(select 1 from SLHD with (nolock) where SLCo=@apco and JCCo=@pmco and SL=@formattedsl
--           and substring(Job,1,@sigchars)<>@validpartjob)
--	begin
--	select @msg = 'One or more subcontracts are already set up under a different project.', @rcode = 1
--	goto PMSL_loop
--	end

------ check if subcontract already setup under a different vendor
--if exists(select 1 from SLHD with (nolock) where SLCo=@apco and JCCo=@pmco and SL=@formattedsl and Vendor<>@vendor)
--	begin
--	select @msg = 'One or more subcontracts are already set up under a different vendor.' + isnull(@formattedsl,''), @rcode = 1
--	goto PMSL_loop
--	end

-- use sl from vspPMSLGetNextSLSeq
exec @retcode = dbo.vspPMSLGetNextSLSeq @pmco,@project,@vendor,'Y',@formattedsl output,@msg output
if @retcode = 1 
	begin
	select @msg = 'Unable to determine SL. ' + isnull(@msg,''),@rcode=1  
	goto bspexit
	end


------ Now check for lines in SLIT and PMSL take the max
------ if the sl already exists then we need to start the seqs there
if exists(select 1 from SLIT with (nolock) where SLCo=@apco and JCCo=@pmco and SL=@formattedsl)
	begin
	select @slitem = isnull(max(SLItem),0)+1
	from SLIT with (nolock) where SLCo=@apco and SL=@formattedsl
	end

------ get the next sl item from PMSL
if exists(select 1 from PMSL with (nolock) where PMCo=@pmco and SLCo=@apco and SL=@formattedsl)
	begin
	select @slitemfrompm = isnull(max(SLItem),0)+1
	from PMSL with (nolock) where PMCo=@pmco and SLCo=@apco and SL=@formattedsl
	end

------ take the max of the two
if @slitemfrompm > @slitem select @slitem = @slitemfrompm

------ Check to see if it is an Approved change order, if so then fill in SUBCo if necessary
---- TK-08876 check rec type and do not get subco if from the PCO approval process (X)
SET @subco = NULL
---- if initialize from subcontract detail call procedure to get next @rectype <. 'X'
if @defrecordtype = 'C' and isnull(@defaco,'') <> '' AND @rectype <> 'X'
	BEGIN
	if @itemtype in (1,2,4)
   		BEGIN
   		exec @slrcode = dbo.bspPMSLSubCoGet @pmco, @project, @apco, @formattedsl, @slitem,
   						@itemtype, @seq, @subco output, @defaco, @defacoitem, @vendor,
   						@UseApprSubCo, @slmsg output
   		if @slrcode <> 0 or @subco = 0 SET @subco = null
   		END
	END

---- if initialize from PCO approve call procedure to get next @rectype = 'X'
if @defrecordtype = 'C' and isnull(@defaco,'') <> '' AND @rectype = 'X'
	BEGIN
	-- TK-13139 --
	if @itemtype in (1,2,4) AND @CreateSingleChangeOrder = 'Y' --@UseApprSubCo = 'Y'
   		BEGIN
   		exec @slrcode = dbo.bspPMSLSubCoGet @pmco, @project, @apco, @formattedsl, @slitem,
   						@itemtype, @seq, @subco output, @defaco, @defacoitem, @vendor,
   						@CreateSingleChangeOrder, @slmsg output
   		if @slrcode <> 0 or @subco = 0 SET @subco = null
   		END
	END
	
--IF @UseApprSubCo= 'Y'
--	BEGIN
--	if @defrecordtype = 'C' and isnull(@defaco,'') <> ''
--		BEGIN
--   		if @itemtype in (1,2,4)
--       		BEGIN
--       		exec @slrcode = dbo.bspPMSLSubCoGet @pmco, @project, @apco, @formattedsl, @slitem,
--       						@itemtype, @seq, @subco output, @defaco, @defacoitem, @vendor,
--       						@slmsg output
--       		if @slrcode <> 0 or @subco = 0 SET @subco = null
--       		END
--		END
--	END
	
------ update PMSL with formatted SL and item
begin transaction
update PMSL set SL=@formattedsl, SLItem=@slitem, SLItemDescription=@slitemdescription,
			----TK-08876
			SubCO = @subco
where PMCo=@pmco and Project=@project and Seq=@seq
if @@rowcount = 0
	begin
	select @msg = 'Error updating PMSL', @rcode=1
	rollback transaction
	goto bspexit
	end

commit transaction

------ Need to re-calculate addon amount for the sl just intialized for addon
------ item types with a percent type addon. Applies to original record types only
if @rectype = 'O'
begin
	-- Insert PM Subcontract Header - Inclusions/Exclusions records.
	-- Try to exclude records already added.
	if not exists (select top 1 1 from dbo.vSLInExclusions where Co = @pmco and SL = @formattedsl)
	begin
		insert vSLInExclusions (Co, SL, Seq, [Type], PhaseGroup, Phase, Detail, DateEntered, EnteredBy, Notes)
		select @pmco, @formattedsl, row_number() over(order by n.JCCo, n.PotentialProject), 
			n.[Type], n.PhaseGroup, n.Phase, n.Detail, dbo.vfDateOnly(), n.EnteredBy, n.Notes
		from dbo.vPCBidPackageScopeNotes n
		join dbo.vPCPotentialWork p on p.JCCo = n.JCCo and p.PotentialProject = n.PotentialProject
		join dbo.bJCJM m on m.PotentialProjectID = p.KeyID
		join dbo.bPMSL l on l.PMCo = n.JCCo and l.Project = m.Job and l.Phase = n.Phase
		where m.JCCo = @pmco and m.Job = @project 
			and not exists (select top 1 1 from dbo.vSLInExclusions s where s.Co = n.JCCo and s.SL = @formattedsl 
			and s.PhaseGroup = @phasegroup and s.Phase = n.Phase and s.[Type] = n.[Type] 
			and isnull(s.Detail,'') = isnull(n.Detail,'') and isnull(s.Notes,'') = isnull(n.Notes,''))
	end
	else
	begin
		insert vSLInExclusions (Co, SL, Seq, [Type], PhaseGroup, Phase, Detail, DateEntered, EnteredBy, Notes)
		select @pmco, @formattedsl, isnull(max(i.Seq),0) + row_number() over(order by n.JCCo, n.PotentialProject), 
			n.[Type], n.PhaseGroup, n.Phase, n.Detail, dbo.vfDateOnly(), n.EnteredBy, n.Notes
		from dbo.vPCBidPackageScopeNotes n
		join dbo.vPCPotentialWork p on p.JCCo = n.JCCo and p.PotentialProject = n.PotentialProject
		join dbo.bJCJM m on m.PotentialProjectID = p.KeyID
		join dbo.bPMSL l on l.PMCo = n.JCCo and l.Project = m.Job and l.Phase = n.Phase
		join dbo.vSLInExclusions i on i.Co = n.JCCo and i.SL = @formattedsl
		where m.JCCo = @pmco and m.Job = @project 
			and not exists (select top 1 1 from dbo.vSLInExclusions s where s.Co = n.JCCo and s.SL = @formattedsl 
			and s.PhaseGroup = @phasegroup and s.Phase = n.Phase and s.[Type] = n.[Type] 
			and isnull(s.Detail,'') = isnull(n.Detail,'') and isnull(s.Notes,'') = isnull(n.Notes,''))
		group by n.JCCo, n.PotentialProject, n.[Type], n.PhaseGroup, n.Phase, n.Detail, n.EnteredBy, n.Notes		
	end	

	select @addonseq=min(Seq) from PMSL with (nolock) where PMCo=@pmco and Project=@project
	and SL=@formattedsl and SLItemType=4
	while @addonseq is not null
	begin

		select @addonpct=SLAddonPct from PMSL with (nolock) 
		where PMCo=@pmco and Project=@project and SL=@formattedsl and SLItemType=4 and Seq=@addonseq
		If isnull(@addonpct,0) <> 0
			begin
			select @sladdonamt=(sum(isnull(OrigCost,0)) * @addonpct) from SLIT with (nolock) 
			where JCCo=@pmco and Job=@project and SLCo=@apco and SL=@formattedsl and ItemType in (1,2)
   
			select @pmaddonamt=(sum(isnull(Amount,0)) * @addonpct) from PMSL with (nolock) 
			where PMCo=@pmco and Project=@project and SLCo=@apco and SL=@formattedsl
			and InterfaceDate is null and SLItemType in (1,2)
   
			select @addonamt = isnull(@sladdonamt,0) + isnull(@pmaddonamt,0)
	   
			update PMSL set Amount=isnull(@addonamt,0)
			where PMCo=@pmco and Project=@project and Seq=@addonseq
			end

	select @addonseq=min(Seq) from bPMSL with (nolock) 
	where PMCo=@pmco and Project=@project and SL=@formattedsl and SLItemType=4 and Seq>@addonseq
	if @@rowcount = 0 select @addonseq = null
	end
end


goto PMSL_loop

PMSL_end:
	if @opencursor = 1
		begin
		close bcPMSL
		deallocate bcPMSL
		select @opencursor = 0
		end






bspexit:
	if @opencursor = 1
		begin
		close bcPMSL
		deallocate bcPMSL
		select @opencursor = 0
		end

	if @rcode <> 0
		begin
		if isnull(@phasemsg,'') <> '' select @msg = isnull(@msg,'') + char(13) + char(10) + @phasemsg
		select @msg = isnull(@msg,'')
		end

   	return @rcode




GO

GRANT EXECUTE ON  [dbo].[bspPMSLInitialize] TO [public]
GO
