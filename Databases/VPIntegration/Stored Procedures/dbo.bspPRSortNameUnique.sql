SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRSortNameUnique    Script Date: 8/28/99 9:35:40 AM ******/
   CREATE  proc [dbo].[bspPRSortNameUnique]
   /***********************************************************
    * CREATED BY	: kb 11/24/97
    * MODIFIED BY	: kb 11/24/97
    *				EN 10/9/02 - issue 18877 change double quotes to single
    *
    * USAGE:
    * validates PR SortName to see if it is unique. Is called
    * from PR Employee Master.  Checks PREH 
    *
    * INPUT PARAMETERS
    *   @prco      PR Co to validate against 
    *   @empl      Employee
    *   @sortname  SortName to Validate
    * 
    * OUTPUT PARAMETERS
    *   @msg      message if Reference is not unique otherwise nothing
   
   
    *  * RETURN VALUE
    *   0         success
    *   1         Failure  'if sortname has already been used
    *******************************************************************/ 
   
       (@prco bCompany = 0,@empl bEmployee, @sortname bSortName, @msg varchar(80) output )
   as
   
   set nocount on
   
   declare @rcode int
   select @rcode = 0, @msg = 'PR Unique'
    
   select @rcode=1, @msg='Sortname ' + @sortname + ' already used by employee# ' + convert(varchar(10), Employee) 
     from bPREH where PRCo=@prco and SortName=@sortname and Employee<>@empl
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRSortNameUnique] TO [public]
GO
