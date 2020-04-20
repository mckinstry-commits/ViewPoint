SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
CREATE proc [dbo].[bspPMPDGetNextLine]
/***********************************************************
 * Created By:	GF 04/12/2007 6.x
 * Modified By:
 *
 * USAGE:
 * Called from the PM Punch List to get next punch list item line for
 * auto sequencing.
 *
 *
 * INPUT PARAMETERS
 * PMCO			- JC Company
 * PROJECT		- Project
 * PunchList	- Punch List
 * Item			- Punch List Item
 *
 * OUTPUT PARAMETERS
 * @msg - error message if error occurs or next numeric item line for PMPD
 *
 * RETURN VALUE
 *   0 - Success
 *   1 - Failure
 *****************************************************/
(@pmco bCompany = 0, @project bJob = null, @punchlist bDocument = null,
 @item int = null, @msg varchar(255) output)  
as
set nocount on

declare @rcode int, @next_line tinyint

select @rcode = 0, @next_line = 0, @msg = ''

---- get next line from PMPD
if not exists(select PMCo from PMPD with (nolock) where PMCo=@pmco and Project=@project
			and PunchList=@punchlist and Item=@item)
	begin
	select @next_line = 1
	end
else
	begin
	select @next_line = isnull(max(ItemLine),0) + 1 from PMPD
	where PMCo=@pmco and Project=@project and PunchList=@punchlist and Item=@item
	if @next_line is null select @next_line = 1
	end

---- since line is a integer, just convert to varchar no formatting needed
select @msg = convert(varchar(3), isnull(@next_line,1))




bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPDGetNextLine] TO [public]
GO
