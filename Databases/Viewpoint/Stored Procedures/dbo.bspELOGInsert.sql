SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspELOGInsert]
   /*************************************************************
   *	Adds entries to Error Log table
   *
   *   CREATED:  Jeff Muller 5/96
   *   MODIFIED: RBT 8/15/03 - Issue #18372, Added @username parameter to use instead of SUSER_SNAME().
   *
   *	Pass in ErrorNumber, Description, Source, SQLRetCode, 
   *	and ErrorText
   *
   *	Inserts bELOG entry
   *
   * 	returns 0 if successful, 1 and error msg if not
   **************************************************************/
   
   	(@errno int, @desc varchar(255), @source varchar(255), @sqlretcode varchar(5),
   	 @username varchar(128), @errmsg varchar(60) output)
   as
   	set nocount on
   	declare @rcode int
   	select @rcode=0
   	
   
   /* add Error Log entry */
   insert bELOG (DateTime, UserName, ErrorNumber, Description, Source, SQLRetCode)
   values (getdate(), @username, @errno, @desc, @source, @sqlretcode)
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Unable to add Error Log entry for Error Number ' + convert(varchar(5),@errno) + '!', @rcode = 1
   	end
   	
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspELOGInsert] TO [public]
GO
