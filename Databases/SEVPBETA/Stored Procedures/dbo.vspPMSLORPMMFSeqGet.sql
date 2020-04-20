SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMSLORPMMFSeqGet ******/
CREATE   procedure [dbo].[vspPMSLORPMMFSeqGet]
/*******************************************************************************
* Created By:	GF 04/03/2006 - Gets next PMSL or PMMF sequence number for project 6.x
* Modified By:
*
*
*
* Pass In
* PMCo				PM Company
* Project			PM Project
* PMView			PM View to get sequence for
*
* RETURN PARAMS
* Sequence			Next PMSL or PMMF Sequence
* msg           	Error Message, or Success message
*
* Returns
*      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
*
********************************************************************************/
(@pmco bCompany, @project bJob, @pmview varchar(30),
 @next_seq integer = 0 output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode=0

-- -- -- check key fields
if @pmco is null or @project is null
	begin
	select @msg = 'Invalid PM Company or project!', @rcode = 1
	goto bspexit
	end

-- -- -- check PM view
if @pmview <> 'PMSL' and @pmview <> 'PMMF'
	begin
	select @msg = 'Invalid PM Table, unable to generate next sequential number!', @rcode = 1
	goto bspexit
	end

-- -- -- get next seqeunce number
if @pmview = 'PMSL'
	begin
	select @next_seq = isnull(max(Seq),0) + 1
	from PMSL with (nolock) where PMCo=@pmco and Project=@project
	if @@rowcount = 0 select @next_seq = 1
	goto bspexit
	end

-- -- -- get next seqeunce number
if @pmview = 'PMMF'
	begin
	select @next_seq = isnull(max(Seq),0) + 1
	from PMMF with (nolock) where PMCo=@pmco and Project=@project
	if @@rowcount = 0 select @next_seq = 1
	goto bspexit
	end



bspexit:
  	if @rcode <> 0 select @msg = isnull(@msg,'') 
    return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMSLORPMMFSeqGet] TO [public]
GO
