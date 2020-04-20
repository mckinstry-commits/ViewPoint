SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   Procedure [dbo].[vspAPUnappInvRevMemoUpdate]
  /***********************************************************
   * CREATED BY: MV 12/31/07
   * MODIFIED By : 
   *              
   *
   * USAGE:
   * called from APUnappInvStatus, updates bAPUR.Memo
   * 
   * INPUT PARAMETERS
   *   APCo, UIMth, UISeq, Line, Reviwer, Reviewer Group, memo 

   * OUTPUT PARAMETERS
   *    @msg If Error

   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/ 
  	(@apco bCompany , @uimth bMonth, @uiseq int, @line int, @reviewer varchar(3),
	 @memo varchar(max), @msg varchar(200)output)
  as
 set nocount on
  
  
  declare @rcode int
  select @rcode = 0
  	
 if @apco is null
  	begin
  	select @msg = 'Missing AP Company - cannot update Memo.', @rcode = 1
  	goto vspexit
  	end
if @uimth is null
  	begin
  	select @msg = 'Missing UI Month - cannot update Memo.', @rcode = 1
  	goto vspexit
  	end
if @uiseq is null
  	begin
  	select @msg = 'Missing UI Seq - cannot update Memo.', @rcode = 1
  	goto vspexit
  	end
if @line is null
  	begin
  	select @msg = 'Missing Line number - cannot update Memo.', @rcode = 1
  	goto vspexit
  	end
if @reviewer is null
  	begin
  	select @msg = 'Missing reviewer - cannot update Memo.', @rcode = 1
  	goto vspexit
  	end
  
  	Update APUR set Memo=@memo 
	where APCo = @apco and UIMth = @uimth and UISeq = @uiseq
      and Reviewer=@reviewer and Line=@line 
	if @@rowcount = 0
  		begin
  		select @msg = 'Memo was not updated.', @rcode = 1
  		end

  vspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPUnappInvRevMemoUpdate] TO [public]
GO
