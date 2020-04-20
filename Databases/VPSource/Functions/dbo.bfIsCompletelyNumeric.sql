SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  User Defined Function dbo.bfIsCompletelyNumeric    Script Date: 3/11/2002 11:10:59 AM ******/
  
  
  
  
  -- ALTER   IsCompletelyNumeric
  CREATE  function [dbo].[bfIsCompletelyNumeric](@expression varchar(30))
      returns tinyint --1 = success, 0 = failure
      as
      begin
  		declare @comparestring varchar(150),@counter int,@rcode int
  		select @counter = 1,@rcode = 0
  				
  
  
  		while @counter <= len(@expression)
  		begin
  			select @comparestring = isnull(@comparestring,'') + '[0-9]'
  			select @counter = @counter + 1
  		end
  		
  
  
  
  		if @expression like @comparestring
  			select @rcode = 1
  		
  
  	--return(@comparestring)
  	return(@rcode)
      end

GO
GRANT EXECUTE ON  [dbo].[bfIsCompletelyNumeric] TO [public]
GO
