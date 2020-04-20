SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspPMSLGetNextSLSeq]
/*************************************
* CREATED BY:	AW 03/13/2013 Make generating the next SL Number its own process pulled from bspPMSLInitialize
*			SL's are generated based on PMCO either (P)Project/Seq or (V)Project/Vendor based on PMSL values
*
* LAST MODIFIED:
*
* Pass: @pmco,
*	@project,
*	@vendor,
*	@allowExistingSLsYN  -- Y allows SLs to already exist, N can't exist in SLHD
*
* Output: @formattedsl - Next available SL
*		@msg - error msg if any
*
* returns:
*	0 on Success, 1 on ERROR
*
**************************************/
(@pmco bCompany=null, @project bJob=null, @vendor bVendor=null, @allowExistingSLsYN bYN='N',@formattedsl varchar(30) output,@msg varchar(255) output)
as
set nocount on

declare @rcode int,@slno varchar(1),@sigpartjob bYN, @validpartjob varchar(30),@slcharsproject tinyint,
	@apco bCompany, @slmask varchar(30),@sllength varchar(30),@slstartseq SMALLINT,
	@sigchars smallint,@slcharsvendor tinyint,@slseqlen int,@projectpart bProject, @mseq int,
	@tmpsl varchar(30),@tmpsl1 VARCHAR(30),@tmpseq varchar(30),@i int, @value varchar(1),@tmpseq1 varchar(30),
	@vendorPart varchar(30),@paddedstring varchar(60),@dummy_sl varchar(30),@retcode int

set @rcode = 0
set @msg = ''

if @pmco is null 
	begin
	select @msg = 'Missing PMCo!', @rcode = 1
	goto bspexit
	end

if @project is null 
	begin
	select @msg = 'Missing Project!', @rcode = 1
	goto bspexit
	end

if @vendor is null
	begin
	select @msg = 'Missing Vendor required!', @rcode = 1
	goto bspexit
	end

------ get HQ/PM company info
select @apco=p.APCo, @slno=p.SLNo, @sigpartjob=p.SigPartJob, @sigchars= p.SigCharsSL,
          @slcharsproject=p.SLCharsProject, @slcharsvendor=p.SLCharsVendor, @slseqlen=p.SLSeqLen,
          @slstartseq=p.SLStartSeq
from dbo.bHQCO h with (nolock) join dbo.bPMCO p with (nolock) on h.HQCo=p.APCo where p.PMCo=@pmco
------ check significant characters of job, if null or zero then not valid.
if @sigchars is null or @sigchars = 0 select @sigpartjob = 'N'

------ get input mask for bSL
select @slmask=InputMask, @sllength = convert(varchar(30), InputLength) 
from DDDTShared with (nolock) where Datatype = 'bSL'
if isnull(@slmask,'') = '' select @slmask = 'L'
if isnull(@sllength,'') = '' select @sllength = '10'
if @slmask in ('R','L')
   	begin
   	select @slmask = @sllength + @slmask + 'N'
   	end

------ set valid part job
if @sigpartjob = 'Y'
       begin
       if @sigchars > len(@project) select @sigchars = len(@project)
       select @validpartjob = substring(@project,1,@sigchars)
       end
else
       begin
       select @validpartjob = @project, @sigchars = len(@project)
       end

------ get rid of leading spaces
select @projectpart = substring(ltrim(@project),1,@slcharsproject)
select @mseq = 0

------ need to reset @slcharsproject to project part without any leading spaces
select @slcharsproject = datalength(ltrim(@projectpart))

------ if we are building the subcontract by seq, then we need to retreive the last seq
------ used to build the last subcontract number, then add one to it
select @tmpsl = null, @tmpsl1 = null
if @slno='P'
	begin
	if exists(select 1 from bPMSL WITH (NOLOCK) where SLCo=@apco and PMCo=@pmco
				and substring(Project,1,@sigchars)=@validpartjob and SL is not null) 
			or
		exists(select 1 from bSLHD with (nolock) where SLCo=@apco and JCCo=@pmco
				and substring(Job,1,@sigchars)=@validpartjob)
		begin
		------ max from PMSL
		select @tmpsl = max(SL) from bPMSL WITH (NOLOCK)
		where SLCo=@apco and PMCo=@pmco and substring(Project,1,@sigchars)=@validpartjob
		and SL is not null and substring(SL,1,len(@projectpart)) = @projectpart
		and datalength(rtrim(SL)) = len(@projectpart) + @slseqlen
		------ max from SLHD
		select @tmpsl1 = max(SL) from bSLHD WITH (NOLOCK)
		where SLCo=@apco and JCCo=@pmco and substring(Job,1,@sigchars)=@validpartjob
		and substring(SL,1,len(@projectpart)) = @projectpart
		and datalength(rtrim(SL)) = len(@projectpart) + @slseqlen
		------ now use highest to get next sequence
		if isnull(@tmpsl,'') <> '' and isnull(@tmpsl1,'') = '' select @tmpsl1 = @tmpsl
		if isnull(@tmpsl1,'') <> '' and isnull(@tmpsl,'') = '' select @tmpsl = @tmpsl1
		if @tmpsl1 > @tmpsl select @tmpsl = @tmpsl1
		------ now parse out the seq part by using company definitions
		select @tmpseq = substring(reverse(rtrim(@tmpsl)),1, @slseqlen), @i = 1, @tmpseq1 = ''
		while @i <= len(@tmpseq)
			begin
			select @value = substring(@tmpseq,@i,1)
			if @value not in ('0','1','2','3','4','5','6','7','8','9')
				select @i = len(@tmpseq)
			else
				select @tmpseq1 = @tmpseq1 + @value
					
			select @i = @i + 1
			end
		------ check if numeric
		if isnumeric(@tmpseq1) = 1 select @mseq = convert(int,reverse(@tmpseq1)+1)
		end
	else
		begin
		---- no subcontracts exist for project so use the @slstartseq if there is one
		if @slstartseq is not null select @mseq = @slstartseq
		end
	end

------ convert Vendor based on Co parameters
select @vendorPart = reverse(substring(reverse('0000000000000000000' + ltrim(str(@vendor))),1,@slcharsvendor))
------ need to pad the seq with leading zeros to the amount specified in company file @slseqlen
select @paddedstring = reverse(substring(reverse('0000000000000000000' + ltrim(str(@mseq))),1,@slseqlen))
select @formattedsl = null

if @allowExistingSLsYN = 'Y'
	begin
	if @slno = 'P'
		begin
		select @formattedsl = max(SL) from SLHD with (nolock) 
		where SLCo=@apco and JCCo=@pmco and Vendor=@vendor and substring(Job,1,@sigchars)=@validpartjob and Status in (0,3)
		if @@rowcount = 0 select @formattedsl = null
		end

	if @slno = 'V'
		begin
		select @formattedsl = max(SL) from SLHD with (nolock) 
		where SLCo=@apco and JCCo=@pmco and Vendor=@vendor and substring(Job,1,@sigchars)=@validpartjob
		if @@rowcount = 0 select @formattedsl = null
		end
	end
if @formattedsl is null
	begin
	if @slno = 'V'
   		begin
   		set @dummy_sl = ltrim(rtrim(@projectpart)) + @vendorPart
   		exec @retcode = dbo.bspHQFormatMultiPart @dummy_sl, @slmask, @formattedsl output
   		end
	else
   		begin
   		set @dummy_sl = ltrim(rtrim(@projectpart)) + @paddedstring
   		exec @retcode = dbo.bspHQFormatMultiPart @dummy_sl, @slmask, @formattedsl output
   		end
	end

if @allowExistingSLsYN = 'N' and exists(select 1 from SLHD where SLCo=@apco and JCCo=@pmco and SL=@formattedsl)
	begin
	select @msg = 'Default SL ' + rtrim(dbo.vfToString(@formattedsl)) + ' already exists.', @formattedsl = '', @rcode = 1
	goto bspexit
	end
------ check if subcontract already set up under a different job
if exists(select 1 from SLHD with (nolock) where SLCo=@apco and JCCo=@pmco and SL=@formattedsl
           and substring(Job,1,@sigchars)<>@validpartjob)
	begin
	select @msg = 'One or more subcontracts are already set up under a different project.', @formattedsl = '', @rcode = 1
	goto bspexit
	end

------ check if subcontract already setup under a different vendor
if exists(select 1 from SLHD with (nolock) where SLCo=@apco and JCCo=@pmco and SL=@formattedsl and Vendor<>@vendor)
	begin
	select @msg = 'One or more subcontracts are already set up under a different vendor.', @formattedsl = '', @rcode = 1
	goto bspexit
	end

-- exit
bspexit:

	if @rcode <> 0
		begin
		select @msg = isnull(@msg,'')
		end

   	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMSLGetNextSLSeq] TO [public]
GO
