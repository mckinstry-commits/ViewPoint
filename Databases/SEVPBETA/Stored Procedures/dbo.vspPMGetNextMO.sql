SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMGetNextMO  ******/
CREATE proc [dbo].[vspPMGetNextMO]
/*************************************
 * Created By:	10/02/2006 6.x only
 * Modified By:
 *
 *
 * Used to get the next material order number formatted to the PM Company
 * parameter specifications. Currently will only try to get next when
 * using project/sequence (P) option.
 *
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * INCo			in Company
 *
 * Success returns:
 * 0 on Success, 1 on ERROR
 * @mo			next material order
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@pmco bCompany=null, @project bJob=null, @inco bCompany=null,
 @mo bMO = null output)
as
set nocount on
 
declare @rcode int, @retcode int, @mono varchar(1), @mosigpartjob bYN, @validpartjob varchar(30),
		@mocharsproject tinyint, @projectpart bProject, @formattedmo varchar(10),
		@tmpmo varchar(30), @moseqlen int, @mseq int, @paddedstring varchar(60),
		@tmpseq varchar(30), @sigcharsmo smallint, @tmpproject varchar(30), @actchars smallint,
		@molength varchar(10), @momask varchar(30), @dummy_mo varchar(30), @tmpmo1 bMO, @i int,
		@value varchar(1), @tmpseq1 varchar(10), @mostartseq smallint, @counter int

select @rcode = 0, @mo = '', @counter = 0

if @pmco is null or @project is null or @inco is null
	begin
	select @rcode = 1
	goto bspexit
	end

------ get input mask for bPO
select @momask=InputMask, @molength = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = 'bMO'
if isnull(@momask,'') = '' select @momask = 'L'
if isnull(@molength,'') = '' select @molength = '10'
if @momask in ('R','L')
   	begin
   	select @momask = @molength + @momask + 'N'
   	end

---- Initial local variable assignments
select @mono=MONo, @sigcharsmo=SigCharsMO, @mocharsproject=MOCharsProject,
		@moseqlen=MOSeqLen, @mostartseq=MOStartSeq
from bPMCO with (nolock) where PMCo=@pmco
if @@rowcount = 0
	begin
	select @rcode = 1
	goto bspexit
	end

---- if format option is not project/sequence then exit
if @mono <> 'P' goto bspexit

-- -- -- no significant part job for MO's currently
select @validpartjob = @project, @sigcharsmo = len(@project)
select @tmpproject = rtrim(ltrim(@validpartjob)), @actchars = len(@tmpproject)

-- -- -- get rid of leading spaces
select @projectpart = substring(ltrim(@project),1,@mocharsproject)

select @tmpmo = null, @tmpmo1 = null, @mseq = 1
------ when building the MO by sequence, we need to retreive the last sequence
------ used to build the last MO number, then add one to it
if exists(select 1 from bPMMF WITH (NOLOCK) where INCo=@inco and PMCo=@pmco
				and substring(Project,1,@sigcharsmo)=@validpartjob and MO is not null) 
	or
		exists(select 1 from bINMO with (nolock) where INCo=@inco and JCCo=@pmco and substring(Job,1,@sigcharsmo)=@validpartjob)
	begin
	------ max from PMMF
	select @tmpmo = max(PO) from bPMMF WITH (NOLOCK)
	where INCo=@inco and PMCo=@pmco and substring(Project,1,@sigcharsmo)=@validpartjob
	and MO is not null and substring(MO,1,len(@projectpart)) = @projectpart
	and datalength(rtrim(MO)) = len(@projectpart) + @moseqlen
	------ max from INMO
	select @tmpmo1 = max(MO) from bINMO WITH (NOLOCK)
	where INCo=@inco and JCCo=@pmco and substring(Job,1,@sigcharsmo)=@validpartjob
	and substring(MO,1,len(@projectpart)) = @projectpart
	and datalength(rtrim(MO)) = len(@projectpart) + @moseqlen
	------ now use highest to get next sequence
	if isnull(@tmpmo,'') <> '' and isnull(@tmpmo1,'') = '' select @tmpmo1 = @tmpmo
	if isnull(@tmpmo1,'') <> '' and isnull(@tmpmo,'') = '' select @tmpmo = @tmpmo1
	if @tmpmo1 > @tmpmo select @tmpmo = @tmpmo1
	------ now parse out the seq part by using company definitions
	select @tmpseq = substring(reverse(rtrim(@tmpmo)),1, @moseqlen), @i = 1, @tmpseq1 = ''
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
	---- no material order exist so use the @mostartseq if there is one
	if @mostartseq is not null select @mseq = @mostartseq
	end


---- build MO
build_mo:
------ need to pad the seq with leading zeros to the number specified in company parameters
select @paddedstring = reverse(substring(reverse('0000000000000000000' + ltrim(str(@mseq))),1,@moseqlen))
------ format mo using appropiate value
select @dummy_mo = null, @formattedmo = null
set @dummy_mo = ltrim(rtrim(@projectpart)) + @paddedstring
exec @retcode = dbo.bspHQFormatMultiPart @dummy_mo, @momask, @formattedmo output

------ check if material order already exists
if exists(select * from INMO with (nolock) where INCo=@inco and MO=@formattedmo)
	begin
	if @counter < 10
		begin
		select @mseq = @mseq + 1, @counter = @counter + 1
		goto build_mo
		end
	else
		begin
		select @mo = ''
		goto bspexit
		end
	end


select @mo = @formattedmo




bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMGetNextMO] TO [public]
GO
