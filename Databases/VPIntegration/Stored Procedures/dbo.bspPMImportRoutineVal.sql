SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMImportRoutineVal    Script Date: 8/28/99 9:33:04 AM ******/
CREATE proc [dbo].[bspPMImportRoutineVal]
/******************************************
 * Created By:
 * Modified By:	GF 05/09/2006 - 6.x
 *
 *
 * validates PM Import Routine
 *
 * pass in Import Routine
 *
 * returns Import Routine description or error msg if doesn't exist
 ******************************************/
(@importroutine varchar(20) = null, @filetype varchar(1) = null output, @delimiter varchar(1) = null output,
 @otherdelim varchar(2) = null output, @textqualifier varchar(2) output, @scheduleofvalues bYN = 'N' output,
 @standarditemcode bYN = 'N' output, @recordtypecol int = null output, @begrectypepos int = null output,
 @endrectypepos int = null output, @xmlrowtag varchar(30) = null output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int

set @rcode = 0

if @importroutine is null
   	begin
   	select @msg = 'Missing Import Routine!', @rcode = 1
   	goto bspexit
   	end

-- -- -- get import routine data from PMUI
select @msg=Description, @filetype=FileType, @delimiter=Delimiter, @otherdelim=OtherDelim,
	   @textqualifier=TextQualifier, @scheduleofvalues=ScheduleOfValues,
	   @standarditemcode=StandardItemCode, @recordtypecol=RecordTypeCol,
	   @begrectypepos=BegRecTypePos, @endrectypepos=EndRecTypePos, @xmlrowtag=XMLRowTag
from PMUI with (nolock) where ImportRoutine = @importroutine
if @@rowcount = 0
	begin
   	select @msg = 'Not a valid Import Routine!', @rcode = 1
   	end





bspexit:
	if @rcode<>0 select @msg=@msg 
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMImportRoutineVal] TO [public]
GO
