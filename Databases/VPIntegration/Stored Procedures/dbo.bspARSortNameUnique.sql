SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARSortNameUnique    Script Date: 8/28/99 9:34:14 AM ******/
   CREATE proc [dbo].[bspARSortNameUnique]
   /***********************************************************
   * CREATED BY	: kb 11/24/97
   * MODIFIED BY	: kb 11/24/97
   *
   * USAGE:
   *   Validates AR SortName to see if it is unique. Is called
   *   from AR Customer Master.  Checks ARCM
   *
   * INPUT PARAMETERS
   *   @custgroup Customer Grp to validate against
   *   @cust      Customer
   *   @sortname  SortName to Validate
   *
   * OUTPUT PARAMETERS
   *   @msg      message if Reference is not unique otherwise nothing
   *
   * RETURN VALUE
   *   0         success
   *   1         Failure  'if sortname has already been used
   *******************************************************************/
   (@custgroup bGroup = 0,@cust bCustomer, @sortname bSortName, @msg varchar(80) output)
   
   as
   set nocount on
   declare @rcode int
   
   select @rcode = 0, @msg = 'AR Unique'
   
   select @rcode = 1, 
   	@msg = 'Sortname ' + @sortname + ' already used by customer# ' + convert(varchar(10),Customer)
   from bARCM with (nolock)
   where CustGroup = @custgroup and SortName = @sortname and Customer <> @cust
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARSortNameUnique] TO [public]
GO
