SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRAccDetailDelete    Script Date: 3/25/2003 12:22:05 PM ******/
   
   CREATE  procedure [dbo].[bspHRAccDetailDelete]
   /************************************************************************
   * CREATED: mh 10/21/02    
   * MODIFIED: mh 3/24/03 - Allow delete of detail for seq or all detail for acc   
   *
   * Purpose of Stored Procedure
   *
   *    Delete the detail associated with an HRAccident.
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@hrco bCompany, @accident varchar(10), @seq int = null, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int, @err tinyint
   
       select @rcode = 0, @err = 0
   
   	begin transaction
   
   		if @seq is not null
   		begin
   			delete HRAI where HRCo = @hrco and Accident = @accident and Seq = @seq	
   
   			if @@error <> 0 
   			begin
   				select @err = 1
   				goto bspexit
   			end
   
   			delete HRAC where HRCo = @hrco and Accident = @accident and Seq = @seq
   
   			if @@error <> 0 
   			begin
   				select @err = 1
   				goto bspexit
   			end
   
   			delete HRAD where HRCo = @hrco and Accident = @accident and Seq = @seq
   
   			if @@error <> 0 
   			begin
   				select @err = 1
   				goto bspexit
   			end
   
   			delete HRAL where HRCo = @hrco and Accident = @accident and Seq = @seq
   
   			if @@error <> 0 
   			begin
   				select @err = 1
   				goto bspexit
   			end
   
   			delete HRCL where HRCo = @hrco and Accident = @accident and Seq = @seq
   
   			if @@error <> 0 
   			begin
   				select @err = 1
   				goto bspexit
   			end
   		end
   		else
   		begin
   			delete HRAI where HRCo = @hrco and Accident = @accident 	
   
   			if @@error <> 0 
   			begin
   				select @err = 1
   				goto bspexit
   			end
   
   			delete HRAC where HRCo = @hrco and Accident = @accident
   
   			if @@error <> 0 
   			begin
   				select @err = 1
   				goto bspexit
   			end
   
   			delete HRAD where HRCo = @hrco and Accident = @accident
   
   			if @@error <> 0 
   			begin
   				select @err = 1
   				goto bspexit
   			end
   
   			delete HRAL where HRCo = @hrco and Accident = @accident
   
   			if @@error <> 0 
   			begin
   				select @err = 1
   				goto bspexit
   			end
   
   			delete HRCL where HRCo = @hrco and Accident = @accident
   
   			if @@error <> 0 
   			begin
   				select @err = 1
   				goto bspexit
   			end
   		end
   
   bspexit:
   
   	if @err = 0
   	begin
   		commit transaction
   		select @rcode = 0
   	end
   	else
   	begin
   		rollback transaction
   		select @rcode = 1
   		select @msg = 'Unable to delete detail for this accident'
   	end
   
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRAccDetailDelete] TO [public]
GO
