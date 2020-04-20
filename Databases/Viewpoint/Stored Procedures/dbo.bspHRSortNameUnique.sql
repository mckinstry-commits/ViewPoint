SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRSortNameUnique    Script Date: 2/4/2003 7:52:56 AM ******/
   /****** Object:  Stored Procedure dbo.bspHRSortNameUnique    Script Date: 8/28/99 9:35:40 AM ******/
   CREATE  proc [dbo].[bspHRSortNameUnique]
   /***********************************************************
    * CREATED BY	: ae 10/6/99
    * MODIFIED BY	:
    *
    * USAGE:
    * validates HR SortName to see if it is unique. Is called
    * from HR Employee Master.  Checks HRRM
    *
    * INPUT PARAMETERS
    *   @hrco      HR Co to validate against
    *   @hrref      Employee
    *   @sortname  SortName to Validate
    *
    * OUTPUT PARAMETERS
    *   @msg      message if Reference is not unique otherwise nothing
   
   
    *
   
    * RETURN VALUE
    *   0         success
    *   1         Failure  'if sortname has already been used
    *******************************************************************/
   
       (@hrco bCompany = Null,@hrref bHRRef, @sortname bSortName, @msg varchar(80) output )
   as
   
   set nocount on
   
   declare @rcode int
   select @rcode = 0, @msg = 'HR Unique'
   
   select @rcode=1, @msg='Sortname ' + @sortname + ' already used by employee# ' + convert(varchar(10), HRRef)
     from HRRM where HRCo=@hrco and SortName=@sortname and HRRef<>@hrref
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRSortNameUnique] TO [public]
GO
