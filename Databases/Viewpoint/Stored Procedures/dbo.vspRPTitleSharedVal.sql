SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspRPTitleSharedVal]   
  /*Created - Terrylis 01/3/2007, */
  (@title varchar(60) , @msg varchar(255) output)
  AS
  /* Validates All Reports in RPRTShared used on RP Report Copy and RPRT
  *
  *  
  *
  *
  * pass ReportID
  * 
  * returns error message if error */
  set nocount on
  declare @rcode int
  select @rcode=0
  
 if @title =null
begin
  	select @msg='Title cannot be null.',@rcode=1
  	goto vspexit
end

begin
  	select @msg=Title From dbo.RPRTShared where Title=@title
	If @@rowcount >=1 
	Begin
	select @msg='Title: '+ @title + ' already exists. ',@rcode=1 
	end
	goto vspexit
end

vspexit:
return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspRPTitleSharedVal] TO [public]
GO
