SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************************/
   CREATE   procedure [dbo].[bspPMSubmittalCopy]
   /************************************************************************
   * Created By:	GF 01/07/2005
   * Modified By:
   *
   * Purpose of Stored Procedure
   * Copy a submittal from a source project to a destination project.
   *
   *
   *
   * Notes about Stored Procedure
   *
   *
   * returns 0 if successfull
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   (@pmco bCompany, @src_project bProject, @dest_project bProject, @resp_person bEmployee, 
    @date_due bDate = null, @submittype bDocType, @submittal bDocument, @copy_items bYN = 'Y', 
    @copy_revs bYN = 'N', @generate_next_submittal bYN, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @opencursor tinyint, @errmsg varchar(255),
   		@pmsmud_flag bYN, @pmsiud_flag bYN, @archengfirm bVendor,
   		@ourfirm bVendor, @contactcode bEmployee, @joins varchar(2000), @where varchar(2000),
   		@subno int, @inputmask varchar(30), @itemlength varchar(10), @temp_submittal varchar(20),
   		@next_submittal bDocument, @beg_status bStatus, @subm_phase bPhase, @phasegroup bGroup,
   		@vendorgroup bGroup, @pmsl_vendor bVendor, @pmmf_vendor bVendor, @subfirm bVendor,
   		@subcontact bEmployee, @firmtype bFirmType, @revision tinyint
   
   select @rcode = 0, @pmsmud_flag = 'N', @pmsiud_flag = 'N', @firmtype=null, @opencursor = 0
   
   if @pmco is null
   	begin
   	select @msg = 'Missing PM Company', @rcode = 1
   	goto bspexit
   	end
   
   if @src_project is null
   	begin
   	select @msg = 'Missing source project', @rcode = 1
   	goto bspexit
   	end
   
   if @dest_project is null
   	begin
   	select @msg = 'Missing destination project', @rcode = 1
   	goto bspexit
   	end
   
   if @resp_person is null
   	begin
   	select @msg = 'Missing responsible person', @rcode = 1
   	goto bspexit
   	end
   
   if @submittype is null
   	begin
   	select @msg = 'Missing submittal type', @rcode = 1
   	goto bspexit
   	end
   
   if @submittal is null
   	begin
   	select @msg = 'Missing submittal', @rcode = 1
   	goto bspexit
   	end
   
   -- -- -- check for submittal user memos
   if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bPMSM'))
   	select @pmsmud_flag = 'Y'
   
   if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bPMSI'))
   	select @pmsiud_flag = 'Y'
   
   
   -- get the mask for bDocument
   select @inputmask=InputMask, @itemlength = convert(varchar(10), InputLength)
   from DDDTShared with (nolock) where Datatype = 'bDocument'
   if isnull(@inputmask,'') = '' select @inputmask = 'R'
   if isnull(@itemlength,'') = '' select @itemlength = '10'
   if @inputmask in ('R','L')
   	begin
    	select @inputmask = @itemlength + @inputmask + 'N'
    	end
   
   
   -- -- -- get phase group and phase from source submittal.
   select @subm_phase=Phase, @phasegroup=PhaseGroup, @vendorgroup=VendorGroup
   from bPMSM with (nolock) where PMCo=@pmco and Project=@src_project 
   and SubmittalType=@submittype and Submittal=@submittal and Rev=0
   if @@rowcount = 0
   	begin
   	select @msg = 'Unable to get submittal from source project.', @rcode = 1
   	goto bspexit
   	end
   
   -- -- -- get destination project info
   select @archengfirm=ArchEngFirm, @contactcode=ContactCode, @ourfirm=OurFirm
   from bJCJM where JCCo=@pmco and Job=@dest_project
   if @@rowcount = 0
   	begin
   	select @msg = 'Error occurred retrieving destination project info.', @rcode = 1
   	goto bspexit
   	end
   
   -- -- -- if no @ourfirm using PMCO.Ourfirm
   if @ourfirm is null
   	begin
   	select @ourfirm=OurFirm from bPMCO where PMCo=@pmco
   	end
   
   -- -- -- Default status to first Beginning type status code
   -- -- -- use Default Begin status from PMCO if there is one else use from PMSC
   select @beg_status = BeginStatus from bPMCO with (nolock) where PMCo=@pmco and BeginStatus is not null
   if @@rowcount = 0 select @beg_status = min(Status) from bPMSC with (nolock) where CodeType = 'B'
   
   
   -- -- -- if generating next submittal number then get next subno.
   if @generate_next_submittal = 'Y'
   	begin
   	-- -- -- first if revision <> 0 check destination for original and use that submittal number
   	exec @rcode = dbo.bspPMGetNextSubmittal @pmco, @dest_project, @submittype, @subno output, @errmsg output
   	if @rcode <> 0 
   		begin
   		select @msg = isnull(@errmsg,''), @rcode = 1
   		goto bspexit
   		end
   
   	-- -- -- format submittal number
   	set @temp_submittal = convert(varchar(20), @subno)
   	set @next_submittal = null
   	exec @rcode = dbo.bspHQFormatMultiPart @temp_submittal, @inputmask, @next_submittal output
   	if @rcode <> 0
   		begin
   		select @msg = 'Error formatting next submittal number.', @rcode = 1
   		goto bspexit
   		end
   
   	-- -- -- verify next submittal is not in destination project for original revision
   	if exists(select * from bPMSM where PMCo=@pmco and Project=@dest_project and Submittal=@next_submittal
   					and SubmittalType=@submittype and Rev=0)
   		begin
   		select @msg = 'Unable to generate next submittal: ' + isnull(@next_submittal,'') + ', already exists in destination project.', @rcode = 1
   		goto bspexit
   		end
   	end
   else
   	begin
   	set @next_submittal = @submittal
   	end
   
   
   -- declare cursor on bPMSM Submittal header for source project and submittal to copy. All revisions
   declare bcPMSM cursor LOCAL FAST_FORWARD for select Rev
   from bPMSM
   where PMCo=@pmco and Project=@src_project and Submittal=@submittal and SubmittalType=@submittype
   
   -- open cursor
   open bcPMSM
   set @opencursor = 1
   
   PMSM_loop:
   fetch next from bcPMSM into @revision
   
   if @@fetch_status <> 0 goto PMSM_end
   
   -- -- -- if @revision <> 0 than not original, check @copy_revs flag
   if @copy_revs = 'N' and @revision <> 0 goto PMSM_loop
   
   -- -- -- get phase group and phase from source submittal.
   select @subm_phase=Phase, @phasegroup=PhaseGroup, @vendorgroup=VendorGroup
   from bPMSM with (nolock) where PMCo=@pmco and Project=@src_project 
   and SubmittalType=@submittype and Submittal=@submittal and Rev=@revision
   
   select @subfirm = null, @subcontact = null
   -- -- -- now look for applicable vendors from PMSL or PMMF for the submittal phase in destination project
   if @subm_phase is not null
   	begin
   	-- -- -- get first vendor from bPMSL
   	select TOP 1 @pmsl_vendor=Vendor
   	from bPMSL with (nolock) where PMCo=@pmco and Project=@dest_project and PhaseGroup=@phasegroup
   	and Phase=@subm_phase and VendorGroup=@vendorgroup and Vendor is not null
   	group by PMCo, Project, Phase, VendorGroup, Vendor
   	-- -- -- get first vendor from bPMMF 
   	select TOP 1 @pmmf_vendor=Vendor
   	from bPMMF with (nolock) where PMCo=@pmco and Project=@dest_project and PhaseGroup=@phasegroup
   	and Phase=@subm_phase and VendorGroup=@vendorgroup and Vendor is not null
   	group by PMCo, Project, Phase, VendorGroup, Vendor
   
   	-- -- -- set subfirm
   	select @subfirm = isnull(@pmsl_vendor, @pmmf_vendor)
   
   	-- -- -- initialize vendor into bPMFM if needed
   	if @subfirm is not null
   		begin
   		exec dbo.bspPMFirmInitialize @vendorgroup, @subfirm, @subfirm, @firmtype, @errmsg
   		end
   
   	-- -- -- Default contact from bPMPF where vendor is setup and only one contact
   	select TOP 1 @subcontact = ContactCode
   	from bPMPF with (nolock) where PMCo=@pmco and Project=@dest_project and VendorGroup=@vendorgroup and FirmNumber=@subfirm
   	group by PMCo, Project, VendorGroup, FirmNumber, ContactCode
   	end
   
   
   -- -- -- copy Submittal document into bPMSM if missing in destination project
   insert into bPMSM (PMCo, Project, Submittal, SubmittalType, Rev, Description, PhaseGroup, Phase, Issue,
   		Status, VendorGroup, ResponsibleFirm, ResponsiblePerson, SubFirm, SubContact, ArchEngFirm,
   		ArchEngContact, DateReqd, DateRecd, ToArchEng, DueBackArch, RecdBackArch, DateRetd, ActivityDate,
   		CopiesRecd, CopiesSent, CopiesReqd, CopiesRecdArch, CopiesSentArch, Notes, SpecNumber)
   
   select @pmco, @dest_project, @next_submittal, @submittype, @revision, s.Description, @phasegroup, s.Phase, null,
   		@beg_status, @vendorgroup, @ourfirm, @resp_person, @subfirm, @subcontact,
   		@archengfirm, @contactcode, @date_due, null, null, null, null, null, null,
   		null, null, null, null, null,
   		s.Notes, s.SpecNumber
   from bPMSM s with (nolock) where s.PMCo=@pmco and s.Project=@src_project
   and Submittal=@submittal and SubmittalType=@submittype and Rev=@revision
   and not exists(select top 1 1 from bPMSM a with (nolock) where a.PMCo=@pmco and a.Project=@dest_project
                       and a.Submittal=@next_submittal and a.SubmittalType=@submittype and a.Rev=@revision)
   if @@rowcount = 0
   	begin
   	select @msg = '', @rcode = 2
   	goto bspexit
   	end
   else
   	begin
   	-- -- -- copy user memos if any
   	if @pmsmud_flag = 'Y'
   		begin
   		-- build joins and where clause
   		select @joins = ' from PMSM join PMSM z on z.PMCo = ' + convert(varchar(3),@pmco) +
   						' and z.Project = ' + CHAR(39) + @src_project + CHAR(39) +
   						' and z.Submittal = ' + CHAR(39) + @submittal + CHAR(39) +
   						' and z.SubmittalType = ' + CHAR(39) + @submittype + CHAR(39) + 
   						' and z.Rev = ' + convert(varchar(3), @revision)
   		select @where = ' where PMSM.PMCo = ' + convert(varchar(3),@pmco) + +
   						' and PMSM.Project = ' + CHAR(39) + @dest_project + CHAR(39) +
   						' and PMSM.Submittal = ' + CHAR(39) + @next_submittal + CHAR(39) +
   						' and PMSM.SubmittalType = ' + CHAR(39) + @submittype + CHAR(39) + 
   						' and PMSM.Rev = ' + convert(varchar(3), @revision)
   		-- execute user memo update
   		exec @rcode = dbo.bspPMProjectCopyUserMemos 'PMSM', @joins, @where, @msg output
   		end
   
   	-- -- -- copy items if flagged
   	if @copy_items = 'Y'
   		begin
   		-- -- -- insert submittal items in destination project
   		-- -- -- bulk copy submittal items
   		insert into bPMSI (PMCo, Project, Submittal, SubmittalType, Rev, Item, Description, Status, Send,
   					DateReqd, DateRecd, ToArchEng, DueBackArch, RecdBackArch, DateRetd, ActivityDate,
   					CopiesRecd, CopiesSent, CopiesReqd, CopiesRecdArch, CopiesSentArch, Notes)
   		select @pmco, @dest_project, @next_submittal, @submittype, @revision, i.Item, Description, @beg_status, i.Send,
   					@date_due, null, null, null, null, null, null, 
   					null, null, null, null, null, i.Notes
   		from bPMSI i with (nolock) where i.PMCo=@pmco and i.Project=@src_project and Submittal=@submittal
   		and SubmittalType=@submittype and Rev=@revision
   		and not exists(select top 1 1 from bPMSI a with (nolock) where a.PMCo=@pmco and a.Project=@dest_project
   				and a.Submittal=@next_submittal and a.SubmittalType=@submittype and a.Rev=@revision and a.Item=i.Item)
   		end
   	end
   
   
   
   goto PMSM_loop
   
   
   
   PMSM_end:
        if @opencursor <> 0
            begin
            close bcPMSM
            deallocate bcPMSM
            select @opencursor = 0
            end
   
   
   
   bspexit:
   	if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMSubmittalCopy] TO [public]
GO
