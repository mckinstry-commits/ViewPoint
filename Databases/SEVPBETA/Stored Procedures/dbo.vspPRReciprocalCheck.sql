SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPRReciprocalCheck    Script Date: 8/28/99 9:34:50 AM ******/
  CREATE       proc [dbo].[vspPRReciprocalCheck]
/*************************************
* CREATED BY	: EN 2/27/06
* MODIFIED BY	: EN 3/7/08 - #127081  in declare statements change State declarations to varchar(4)
*
* Checks for a reciprocal agreement between a job state and a resident state in HQRS.
*
* Pass:
*	@jobstate	Job State
*	@resstate	Resident State
*
* Returns:
*	@recipYN	"Y" if reciprocal agreement exists; else "N"
*	@msg		error message if any
*
* Error returns:
*	1 and error message
**************************************/
(@jobstate varchar(4), @resstate varchar(4), @recipYN bYN output, @msg varchar(60) output)

as 
 	set nocount on
  	declare @rcode int
  	select @rcode = 0
  	
if @jobstate is null
  	begin
  	select @msg = 'Missing job state', @rcode = 1
  	goto bspexit
  	end
if @resstate is null
  	begin
  	select @msg = 'Missing resident state', @rcode = 1
  	goto bspexit
  	end

select @recipYN='N'
if exists (select * from dbo.HQRS where JobState = @jobstate and ResidentState = @resstate) select @recipYN='Y'


bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRReciprocalCheck] TO [public]
GO
