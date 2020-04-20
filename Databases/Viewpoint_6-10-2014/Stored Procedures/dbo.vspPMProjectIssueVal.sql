SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMProjectIssueVal    Script Date: 08/08/2005 ******/
CREATE  proc [dbo].[vspPMProjectIssueVal]
/*************************************
 * Created By:	CJW  12/3/97
 * Modified By:	SAE  12/12/97   'Issue now accepts Chars
 *				GF 08/08/2005 - updated for 6.x 'New' allowed
 *
 *
 * validates PM Project Issues. Called from multiple PM forms
 *
 * Pass:
 * PM Company
 * PM Project
 * PM Issue
 *
 * Returns:
 * @status		PM Project Issue Status
 *
 *
 * Success returns:
 *	0 and Description from Issue
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@pmco bCompany, @project bJob = null, @sissue varchar(10) = null,
 @status int output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @issue bIssue

select @rcode = 0, @issue = 0

if @pmco is null
	begin
  	select @msg = 'Missing PM Company!', @rcode = 1
  	goto bspexit
  	end

if @project is null
	begin
  	select @msg = 'Missing Project!', @rcode = 1
  	goto bspexit
  	end

if @sissue is null
	begin
	select @msg = 'Missing Issue!', @rcode = 1
	goto bspexit
	end

if substring(@sissue,1,1) in ('N','n','+')
	begin
	select @msg='(New Issue)', @rcode = 0
	goto bspexit
	end

if substring(@sissue,1,2) in ('-1')
	begin
	select @msg='(New Issue)', @rcode = 0
	goto bspexit
	end

-- -- -- if issue is numeric then validation to PMIM
if dbo.bfIsInteger(@sissue) = 1
	begin
  	if len(@sissue) < 9
  		begin
		select @status=Status, @msg=Description 
		from PMIM with (nolock) where PMCo=@pmco and Project=@project and Issue=convert(int,convert(float, @sissue))
		if @@rowcount = 0
			begin
			select @msg = 'PM Issue not on file!', @rcode = 1
			goto bspexit
			end
		else
			goto bspexit
  		end
	end

---- not a 'New' issue or a numeric value. Error
set @msg = 'Issue must be numeric!'
set @rcode=1







bspexit:
  	if @rcode <> 0 select @msg = isnull(@msg,'') 
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMProjectIssueVal] TO [public]
GO
