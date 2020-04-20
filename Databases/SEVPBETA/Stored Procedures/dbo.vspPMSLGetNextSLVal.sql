SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspPMSLGetNextSLVal]
/*************************************
* CREATED BY:	AW 03/13/2013 returns the next available SL number to the form when user requests a new one
*
* LAST MODIFIED:
*
* Pass: @pmco,
*	@project,
*	@vendor,
*   @createSLYN,  - form field for wheather we creating a new SL or not
*	@selectedsl - form field value for the sl
*
* Output: @formattedsl - Next available SL
*		@msg - error msg if any
*
* returns:
*	0 on Success, 1 on ERROR
*
**************************************/
(@pmco bCompany=null, @project bJob=null, @vendor bVendor=null, @createSLYN bYN='N',@selectedsl varchar(30)=null, @formattedsl varchar(30) output,@msg varchar(255) output)
as
set nocount on

declare @rcode int



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

-- verify if user entered a new sl if required
if @createSLYN = 'Y' and isnull(@selectedsl,'') <> '' 
 and not exists(select top 1 1 from PMSL l 
	join PMCO p on l.PMCo=p.PMCo where l.PMCo=@pmco and l.Project=@project and l.SLCo=p.APCo and SL=@selectedsl)
	begin
	select @formattedsl = @selectedsl,@rcode = 0
	goto bspexit
	end

-- attempt to calculate a new sl 
if @createSLYN = 'Y'
	begin 
	exec @rcode = dbo.vspPMSLGetNextSLSeq @pmco,@project,@vendor,'N',@formattedsl output,@msg output
	if @rcode = 1 
		begin
		select @formattedsl = '',@msg = @msg +' Please enter new SL.'
		goto bspexit
		end
	end

-- exit
bspexit:

	if @rcode <> 0
		begin
		select @msg = isnull(@msg,'')
		end

   	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMSLGetNextSLVal] TO [public]
GO
