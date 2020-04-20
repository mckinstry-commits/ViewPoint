SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspPMGetNextPO  ******/
CREATE proc [dbo].[vspPMGetNextPO]
/*************************************
 * Created By:	10/02/2006 6.x only
 * Modified By:	GP 7/28/2011 - TK-07143 changed bPO to varchar(30)
 *				GP 4/4/2012 - TK-13774 added check against POUnique view
 *
 *
 * Used to get the next purchase order number formatted to the PM Company
 * parameter specifications. Currently will only try to get next when
 * using project/sequence (P) option.
 *
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * POCo			PO Company
 *
 * Success returns:
 * 0 on Success, 1 on ERROR
 * @po			next purchase order
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@pmco bCompany=null, @project bJob=null, @poco bCompany=null,
 @po varchar(30) = null output)
as
set nocount on
 
declare @rcode int, @retcode int, @pono varchar(1), @posigpartjob bYN, @validpartjob varchar(30),
		@pocharsproject tinyint, @pocharsvendor tinyint, @projectpart bProject,
		@formattedpo varchar(30), @tmppo varchar(30), @poseqlen int, @mseq int,
		@paddedstring varchar(60), @tmpseq varchar(30), @sigcharspo smallint,
		@tmpproject varchar(30), @actchars smallint, @polength varchar(10), @pomask varchar(30),
		@dummy_po varchar(30), @tmppo1 varchar(30), @i int, @value varchar(1), @tmpseq1 varchar(10),
		@postartseq smallint, @counter int

select @rcode = 0, @po = '', @counter = 0

if @pmco is null or @project is null or @poco is null
begin
	select @rcode = 1
	goto bspexit
end

------ get input mask for bPO
select @pomask=InputMask, @polength = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = 'bPO'
if isnull(@pomask,'') = '' select @pomask = 'L'
if isnull(@polength,'') = '' select @polength = '10'
if @pomask in ('R','L')
begin
   	select @pomask = @polength + @pomask + 'N'
end

------ get PM company info
select @pono=PONo, @posigpartjob=POSigPartJob, @sigcharspo=SigCharsPO, @poseqlen=POSeqLen,
		@pocharsproject=POCharsProject, @pocharsvendor=POCharsVendor, @postartseq=POStartSeq
from PMCO with (nolock) where PMCo=@pmco
if @@rowcount = 0
begin
	select @rcode = 1
	goto bspexit
end

---- if format option is not project/sequence then exit
if @pono <> 'P' goto bspexit

------ check significant characters of job, if null or zero then not valid.
if @sigcharspo is null or @sigcharspo = 0 select @posigpartjob = 'N'

------ set valid part job
if @posigpartjob = 'Y'
begin
	if @sigcharspo > len(@project) select @sigcharspo = len(@project)
	select @validpartjob = substring(@project,1,@sigcharspo)
end
else
begin
	select @validpartjob = @project, @sigcharspo = len(@project)
end

select @tmpproject = rtrim(ltrim(@validpartjob)), @actchars = len(@tmpproject)
------ get rid of leading spaces
select @projectpart = substring(ltrim(@project),1,@pocharsproject)

------ need to reset @pocharsproject to project part without any leading spaces
select @pocharsproject = datalength(ltrim(@projectpart))


select @tmppo = null, @tmppo1 = null, @mseq = 1
------ when building the po by sequence, we need to retreive the last sequence
------ used to build the last po number, then add one to it
if exists(select 1 from bPMMF WITH (NOLOCK) where POCo=@poco and PMCo=@pmco
				and substring(Project,1,@sigcharspo)=@validpartjob and PO is not null) 
	or
		exists(select 1 from dbo.POUnique with (nolock) where POCo=@poco and JCCo=@pmco and substring(Job,1,@sigcharspo)=@validpartjob)
begin	
	------ max from PMMF
	select @tmppo = max(PO) from bPMMF WITH (NOLOCK)
	where POCo=@poco and PMCo=@pmco and substring(Project,1,@sigcharspo)=@validpartjob
	and PO is not null and substring(PO,1,len(@projectpart)) = @projectpart
	and datalength(rtrim(PO)) = len(@projectpart) + @poseqlen
		
	------ max from POHD, POHB, POPendingPurchaseOrder
	select @tmppo1 = max(PO) 
	from dbo.POUnique
	where POCo = @poco and JCCo = @pmco and substring(Job, 1, @sigcharspo) = @validpartjob
		and PO is not null and substring(PO, 1, len(@projectpart)) = @projectpart
		and datalength(rtrim(PO)) = len(@projectpart) + @poseqlen
			
	-------- now use highest to get next sequence	
	if isnull(@tmppo,'') <> '' and isnull(@tmppo1,'') = '' select @tmppo1 = @tmppo
	if isnull(@tmppo1,'') <> '' and isnull(@tmppo,'') = '' select @tmppo = @tmppo1
	
	if @tmppo1 > @tmppo select @tmppo = @tmppo1
	
	------ now parse out the seq part by using company definitions
	select @tmpseq = substring(reverse(rtrim(@tmppo)),1, @poseqlen), @i = 1, @tmpseq1 = ''
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
	---- no purchase order exist for project so use the @postartseq if there is one
	if @postartseq is not null select @mseq = @postartseq
end


---- build PO
build_po:
------ need to pad the seq with leading zeros to the number specified in company parameters
select @paddedstring = reverse(substring(reverse('0000000000000000000' + ltrim(str(@mseq))),1,@poseqlen))
------ format po using appropiate value
select @dummy_po = null, @formattedpo = null
set @dummy_po = ltrim(rtrim(@projectpart)) + @paddedstring
exec @retcode = dbo.bspHQFormatMultiPart @dummy_po, @pomask, @formattedpo output

------ check if purchase order already exists
if exists(select * from POHD with (nolock) where POCo=@poco and PO=@formattedpo)
begin
	if @counter < 10
	begin
		select @mseq = @mseq + 1, @counter = @counter + 1
		goto build_po
	end
	else
	begin
		select @po = ''
		goto bspexit
	end
end


select @po = @formattedpo




bspexit:
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMGetNextPO] TO [public]
GO
