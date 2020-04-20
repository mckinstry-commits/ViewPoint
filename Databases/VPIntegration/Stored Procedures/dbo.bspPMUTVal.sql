SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMUTVal    Script Date: 8/28/99 9:33:07 AM ******/
CREATE PROC [dbo].[bspPMUTVal]
/*************************************
 *	Modified By:	GP 02/03/2009 - Issue 126939, added @FileType output parameter.
 *					AMR 01/24/11 - #142350, making case insensitive by changing OUTPUT @ImportRoutine var
 *
 * validates PM Import Template
 *
 * Pass:
 *	PM Import Template
 *
 * Success returns:
 *	0 and Description from bPMUT
 *
 * Error returns:
 *	1 and error message
 **************************************/
(
  @template varchar(10) = NULL,
  @importroutine varchar(20) = NULL OUTPUT,
  @FileType char(1) = NULL OUTPUT,
  @ImportRoutineOUT varchar(20) = NULL OUTPUT,
  @msg varchar(255) OUTPUT
)
AS 
SET NOCOUNT ON

declare @rcode int

select @rcode = 0


if @template is null
	begin
	select @msg = 'Missing Import Template', @rcode = 1
	goto bspexit
	end

------ validate template and get import routine
select @msg=Description, @importroutine=ImportRoutine
from bPMUT with (nolock) where Template = @template
if @@rowcount = 0
	begin
	select @msg = 'Not a valid Import Template', @rcode = 1
	end

------ get file type for selected template
select @FileType=FileType, @ImportRoutineOUT=ImportRoutine from bPMUT with (nolock) where Template=@template


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMUTVal] TO [public]
GO
