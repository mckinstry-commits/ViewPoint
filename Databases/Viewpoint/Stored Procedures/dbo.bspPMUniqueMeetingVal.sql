SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMUniqueMeetingVal    Script Date: 8/28/99 9:33:08 AM ******/
   CREATE  proc [dbo].[bspPMUniqueMeetingVal]
   /*************************************
   * CREATED BY    :kb 11/20/98
   * LAST MODIFIED :
   *
   * Pass:
   *
   * Returns:
   *
   
   * Success returns:
   *	0
   *
   * Error returns:
   
   *	1 and error message
   *******
   *******************************/
   	(@pmco bCompany, @project bProject, @meetingtype varchar(10), @meeting int,
   	@minutestype tinyint, @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @pmco is null
   	begin
   	select @msg = 'PM Company is missing!', @rcode = 1
   	goto bspexit
   	end
   
   if @project is null
   	begin
   	select @msg = 'Project is missing!', @rcode = 1
   	goto bspexit
   	end
   
   if @meetingtype is null
   	begin
   	select @msg = 'Meeting type is missing!', @rcode = 1
   	goto bspexit
   	end
   
   if @meeting is null
   	begin
   	select @msg = 'Meeting is missing!', @rcode = 1
   	goto bspexit
   	end
   
   if @minutestype is null
   	begin
   	select @msg = 'Minutes type is missing!', @rcode =1
   	goto bspexit
   	end
   
   if exists (select * from PMMM where PMCo = @pmco and Project = @project
   	and MeetingType = @meetingtype and Meeting = @meeting and MinutesType = @minutestype)
   	begin
   	select @msg = 'This Meeting/Minutes Type already exists', @rcode = 1
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMUniqueMeetingVal] TO [public]
GO
