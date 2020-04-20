SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE        Procedure [dbo].[bspGetRowCount](@sqlstatement varchar(8000))
   
          as
   
   			declare @returncount int
   	       
   			exec(@sqlstatement)
   			select @returncount=@@rowcount
   
   
   
      bfexit:			
      	return(@returncount)

GO
GRANT EXECUTE ON  [dbo].[bspGetRowCount] TO [public]
GO
