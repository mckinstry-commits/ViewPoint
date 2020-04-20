SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*********************************************/
CREATE proc [dbo].[vspPMCTVal]
/***********************************************************
* CREATED By:	GF 05/21/2009 - issue #24641
* MODIFIED By:	GF 08/10/2010 - issue #140980
*						TL 02/05/2012 - Task 29751, User Story 13599 Remove MTG from generating validation error
*				GP 04/11/2013 - TFS 13594 Removed check against DAILYLOG
*				GP 04/11/2013 - TFS 13585 Removed check against ACO
*				TL  04/22/2013 - TFS13609 Remvoved check ugainst PUNCH
*
* USAGE:
* validates the PM Document Category from Document Categories (PMCT)
*
*
*
*
* INPUT PARAMETERS
* DocCat	PM Document Category to validate
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs otherwise Description
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@doccat varchar(10) = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @doccat is null
	begin
	select @msg = 'Missing Document Category', @rcode = 1
	goto bspexit
	end

---- validate document category, some do not have document feature so not
---- allowed to have overrides. #140980
if @doccat in ('PROJNOTES')
	begin
	select @msg = 'Invalid Document Category', @rcode = 1
	goto bspexit
	end
	
---- first validate whole phase to JC Job Phase
select @msg = Description
from PMCT with (nolock) where DocCat=@doccat
if @@rowcount = 0
	begin
	select @msg = 'Invalid Document Category.', @rcode = 1
	goto bspexit
	end





bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMCTVal] TO [public]
GO