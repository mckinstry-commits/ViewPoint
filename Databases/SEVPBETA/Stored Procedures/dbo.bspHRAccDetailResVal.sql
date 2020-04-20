SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspHRAccDetailResVal]
   /************************************************************************
   * CREATED: MH 4/25/01    
   * MODIFIED:    allenn 3/06/2002 - issue 16164
   *			mh 24736 
   *
   * Purpose of Stored Procedure
   *
   *	Enhance bspHRResourceVal for use in HRAccident.  If bspHRResourceVal cannot
   *	find the resource number we want to return an error instead of letting the 
   *	the number fall through as a new resource.
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   	(@HRCo bCompany = null, @HRRef varchar(15), @RefOut int output, @position varchar(10) output, @msg varchar(75) output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	exec @rcode = bspHRResourceVal @HRCo, @HRRef, @RefOut output, @position output, @msg output
   
   	if @rcode = 0
   	begin
   		if @RefOut is not null and @msg = ''
   		select @msg = 'HR Resource not set up in HR Resource Master.', @rcode = 1
   	end
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRAccDetailResVal] TO [public]
GO
