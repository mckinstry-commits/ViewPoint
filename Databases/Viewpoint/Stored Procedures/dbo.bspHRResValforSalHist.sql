SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspHRResValforSalHist]
   /************************************************************************
   * CREATED:	mh 2/9/2005    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *   Validate a Resource for HR Resource Salary and return Position Code and
   *	Last EffectiveDate.
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@HRCo bCompany = null, @HRRef varchar(15), @RefOut int output, @position varchar(10) output, @lasteffdate bDate output, @msg varchar(75) output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	exec @rcode = bspHRResVal @HRCo, @HRRef, @RefOut output, @position output, @msg output
   
   	if @rcode = 0 
   	begin
   		select @lasteffdate = Max(EffectiveDate) 
   		from dbo.HRSH with (nolock) 
   		where HRCo = @HRCo and HRRef = @RefOut
   	end
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRResValforSalHist] TO [public]
GO
