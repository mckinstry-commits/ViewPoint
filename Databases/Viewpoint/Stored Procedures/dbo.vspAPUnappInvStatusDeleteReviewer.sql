SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   Procedure [dbo].[vspAPUnappInvStatusDeleteReviewer]
  /***********************************************************
   * CREATED BY: MV 02/07/08
   * MODIFIED By : 
   *              
   *
   * USAGE:
   * called from APUnappInvStatus, deletes a reviewer from APUR
   * 
   * INPUT PARAMETERS
   *   APCo, UIMth, UISeq, Line, Reviewer 

   * OUTPUT PARAMETERS
   *    @msg If Error

   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/ 
  	(@apco bCompany , @uimth bMonth, @uiseq int, @line int, @reviewer varchar(3),
	@msg varchar(200)output)
  as
 set nocount on
  
  
  declare @rcode int
  select @rcode = 0

 if @apco is null
  	begin
  	select @msg = 'Missing AP Company - cannot delete reviewer.', @rcode = 1
  	goto vspexit
  	end
if @uimth is null
  	begin
  	select @msg = 'Missing UI Month - cannot delete reviewer.', @rcode = 1
  	goto vspexit
  	end
if @uiseq is null
  	begin
  	select @msg = 'Missing UI Seq - cannot delete reviewero.', @rcode = 1
  	goto vspexit
  	end
if @line is null
  	begin
  	select @msg = 'Missing Line number - cannot delete reviewer.', @rcode = 1
  	goto vspexit
  	end
if @reviewer is null
  	begin
  	select @msg = 'Missing reviewer - cannot delete reviewer.', @rcode = 1
  	goto vspexit
  	end
  
	delete APUR where APCo = @apco and UIMth = @uimth and UISeq = @uiseq
      and Reviewer=@reviewer and Line=@line 
  	if @@rowcount = 0
  		begin
  		select @msg = 'Reviewer was not deleted.', @rcode = 1
  		end

  vspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPUnappInvStatusDeleteReviewer] TO [public]
GO
