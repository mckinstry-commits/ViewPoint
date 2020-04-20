SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************************/
   CREATE procedure [dbo].[bspPMMeetingsGet]
   /************************************************************************
   * Created By:	GF 01/18/2005
   * Modified By:	
   *
   * Purpose of Stored Procedure to get meetings for copying.
   * Called from PMMeetingCopy form.
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   (@pmco bCompany, @project bProject, @copydetail bYN = 'Y', @copyattendees bYN = 'Y')
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   -- get submittal information
   select @copydetail, @copyattendees, MeetingType, Meeting, MinutesType, MeetingDate, Subject
   from PMMM where PMCo=@pmco and Project = @project
   order by MeetingType, Meeting, MinutesType, MeetingDate, Subject
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMMeetingsGet] TO [public]
GO
