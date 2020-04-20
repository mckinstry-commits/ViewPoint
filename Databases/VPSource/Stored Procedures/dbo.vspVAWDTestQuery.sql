SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[vspVAWDTestQuery] 

   /*********************************************************
   *    Created: TV 10/29/02
   *    			TV - 23061 added isnulls
   *			 DANF - Added Try Catch
   *    Purpose: To test user queries
   *
   *    Inputs: @select
   *            @fromwhere
   *
   *    outputs: @errmsg
   *
   **********************************************************/
   (@select varchar(MAX), @fromwhere varchar(MAX), @errmsg varchar(255)output) with execute as 'viewpointcs'
   
   as 
   
   Set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if isnull(@select,'') = ''
       begin
       select @errmsg = 'No Select Statement passed in.', @rcode = 1
       goto bspexit
       end
   
   if lower(left(ltrim(@select),6)) <> 'select'
       begin
       select @errmsg = 'Queries must be a Select type statment.', @rcode = 1
       goto bspexit
       end
   
   if isnull(@fromwhere,'') = ''
       begin
       select @errmsg = 'No From/Where Stament passed in.', @rcode = 1
       goto bspexit
       end
   if (select charindex('@', lower(@fromwhere) , 1)) > 0
       begin
       --remove where clause in case there are variables
       if (select charindex('group by', lower(@fromwhere) , 1)) > 0
           begin
           select @fromwhere = substring(@fromwhere, 1, charindex('where', lower(@fromwhere) , 1)-1) + 
                               substring(@fromwhere, charindex('group by', lower(@fromwhere) , 1),
                               len(@fromwhere))
           end
       else
           begin
           select @fromwhere = substring(@fromwhere, 1, charindex('where', lower(@fromwhere) , 1)-1)
           end
       end
   begin try

   exec(@select + ' Into #temptest ' + @fromwhere) AS USER = 'viewpointcs';

   end try

   begin catch
       select @errmsg = ERROR_MESSAGE() + ' - Error number - ' + convert(varchar(10),ERROR_NUMBER()), @rcode = 1
       goto bspexit
   end catch

  
   
   bspexit:
   
   if (select @rcode) = 0     
       begin
       select @errmsg = 'Query compiled successfully.'
       end 
   
   return

GO
GRANT EXECUTE ON  [dbo].[vspVAWDTestQuery] TO [public]
GO
