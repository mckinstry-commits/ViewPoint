SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMGetNextSL  ******/
CREATE proc [dbo].[vspPMGetNextSL]
/*************************************
 * Created By:	10/02/2006 6.x only
 * Modified By:	GF 06/30/2010 - issue #135813 expanded subcontract to 30 characters.
 *
 *
 *
 * Used to get the next Subcontract number formatted to the PM Company
 * parameter specifications. Currently will only try to get next when
 * using project/sequence (P) option.
 *
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * SLCo			SL Company
 *
 * Success returns:
 *	0 on Success, 1 on ERROR
 * @sl			next subcontract
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@pmco bCompany=null, @project bJob=null, @slco bCompany=null,
 @sl VARCHAR(30) = null output)
as
set nocount on
 
declare @rcode int, @retcode int, @slno varchar(1), @sigpartjob bYN, @validpartjob varchar(30),
		@slcharsproject tinyint, @slcharsvendor tinyint, @projectpart bProject,
		@formattedsl VARCHAR(30), @tmpsl VARCHAR(30), @slseqlen int, @mseq int,
		@paddedstring varchar(60), @tmpseq varchar(30), @sigchars smallint,
		@tmpproject varchar(30), @actchars smallint, @sllength varchar(10), @slmask varchar(30),
		@dummy_sl varchar(30), @tmpsl1 VARCHAR(30), @i int, @value varchar(1), @tmpseq1 VARCHAR(30),
		@slstartseq smallint, @counter int

select @rcode = 0, @sl = '', @counter = 0

if @pmco is null or @project is null or @slco is null
	begin
	select @rcode = 1
	goto bspexit
	end

------ get input mask for SL
select @slmask=InputMask, @sllength = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = 'bSL'
if isnull(@slmask,'') = '' select @slmask = 'L'
if isnull(@sllength,'') = '' select @sllength = '10'
if @slmask in ('R','L')
   	begin
   	select @slmask = @sllength + @slmask + 'N'
   	end

------ get HQ company info
select @slno=SLNo, @sigpartjob=SigPartJob, @sigchars=SigCharsSL, @slseqlen=SLSeqLen,
		@slcharsproject=SLCharsProject, @slcharsvendor=SLCharsVendor, @slstartseq=SLStartSeq
from PMCO with (nolock) where PMCo=@pmco
if @@rowcount = 0
	begin
	select @rcode = 1
	goto bspexit
	end

---- if format option is not project/sequence then exit
if @slno <> 'P' goto bspexit

------ check significant characters of job, if null or zero then not valid.
if @sigchars is null or @sigchars = 0 select @sigpartjob = 'N'

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

select @tmpproject = rtrim(ltrim(@validpartjob)), @actchars = len(@tmpproject)
------ get rid of leading spaces
select @projectpart = substring(ltrim(@project),1,@slcharsproject)
select @mseq = 1

------ need to reset @slcharsproject to project part without any leading spaces
select @slcharsproject = datalength(ltrim(@projectpart))



select @tmpsl = null, @tmpsl1 = null
------ when building the subcontract by sequence, we need to retreive the last sequence
------ used to build the last subcontract number, then add one to it
if exists(select 1 from bPMSL WITH (NOLOCK) where SLCo=@slco and PMCo=@pmco
				and substring(Project,1,@sigchars)=@validpartjob and SL is not null) 
	or
		exists(select 1 from bSLHD with (nolock) where SLCo=@slco and JCCo=@pmco
				and substring(Job,1,@sigchars)=@validpartjob)
	begin
	------ max from PMSL
	select @tmpsl = max(SL) from bPMSL WITH (NOLOCK)
	where SLCo=@slco and PMCo=@pmco and substring(Project,1,@sigchars)=@validpartjob
	and SL is not null and substring(SL,1,len(@projectpart)) = @projectpart
	and datalength(rtrim(SL)) = len(@projectpart) + @slseqlen
	------ max from SLHD
	select @tmpsl1 = max(SL) from bSLHD WITH (NOLOCK)
	where SLCo=@slco and JCCo=@pmco and substring(Job,1,@sigchars)=@validpartjob
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
			begin
			select @i = len(@tmpseq)
			end
		else
			begin
			select @tmpseq1 = @tmpseq1 + @value
			end	
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


---- build SL
build_sl:
---- need to pad the seq with leading zeros to the amount specified in company file @slseqlen
select @paddedstring = reverse(substring(reverse('0000000000000000000' + ltrim(str(@mseq))),1,@slseqlen))
------ format subcontract using appropiate value
select @dummy_sl = null, @formattedsl = null
select @dummy_sl = ltrim(rtrim(@projectpart)) + @paddedstring
exec @retcode = dbo.bspHQFormatMultiPart @dummy_sl, @slmask, @formattedsl output

------ check if subcontract already exists
if exists(select * from SLHD with (nolock) where SLCo=@slco and SL=@formattedsl)
	begin
	if @counter < 10
		begin
		select @mseq = @mseq + 1, @counter = @counter + 1
		goto build_sl
		end
	else
		begin
		select @sl = ''
		goto bspexit
		end
	end


select @sl=@formattedsl		


bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMGetNextSL] TO [public]
GO
