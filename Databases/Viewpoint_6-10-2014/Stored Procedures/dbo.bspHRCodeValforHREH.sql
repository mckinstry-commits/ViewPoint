SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRCodeValforHREH    Script Date: 3/19/2003 8:28:56 AM ******/
   
   /****** Object:  Stored Procedure dbo.bspHRCodeValforHREH    Script Date: 1/23/2003 12:46:51 PM ******/
   
   /****** Object:  Stored Procedure dbo.bspHRCodeValforHREH    Script Date: 1/22/2003 3:53:00 PM ******/
   
   CREATE    procedure [dbo].[bspHRCodeValforHREH]
   /************************************************************************
   * CREATED:  MH 1/8/03    
   * MODIFIED:    
   *
   *
   * Purpose of Stored Procedure
   *
   *    An extension of bspHRCodeVal.  Used by HR Employement History
   *	If we are validating a code that was the result of a position change
   *	it needs to validate against HRPC as opposed to HRCM.
   *   
   * 	Type = H or N - Validate against HRCM
   *	Type = P - Validate against HRPC
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@HRCo bCompany = null, @Code varchar(10), @Type char(1), 
   	@msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	if @Type = 'H' or @Type = 'N'
   	begin
   		exec @rcode = bspHRCodeVal @HRCo, @Code, @Type, @msg output
   	end
   	
   	if @Type = 'P' 
   	begin
   		if (select count(JobTitle) from HRPC where HRCo = @HRCo and PositionCode = @Code) > 0
   		begin
   			Select @msg = JobTitle 
   			from HRPC 
   			where HRCo = @HRCo and PositionCode = @Code
   		end
   		else
   			select @msg = 'Not a valid Position code', @rcode = 1
   	end
   	
   
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRCodeValforHREH] TO [public]
GO
