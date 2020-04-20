SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[bspHRMinename]
   /*************************************
   *  Created:	 5/8/03  DC Issue 20935 -  returns the Mine Name
   *	Modified:  9/12/06 - Issue 122030 - Changed table to HRMN
   *					
   * 
   *
   * Pass:
   *	MSHAID - MSHA ID #
   *
   * Returns:
   *	@msg
   *	@rcode  = 0 success / 1 = error
   * 
   **************************************/
   
   	(@mshaid varchar(10), @msg varchar(80) = null output)
   
	as

   	declare @rcode int
   	set nocount on
   
	select @rcode = 0
   
	if exists(select MSHAID from HRMN where MSHAID = @mshaid)
   	begin
   		select @msg = MineName
   		from HRMN 
   		where MSHAID = @mshaid 
   	end
	else
   	begin
   		Select @msg = 'Invalid mine name.', @rcode = 1
   	end
   
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRMinename] TO [public]
GO
