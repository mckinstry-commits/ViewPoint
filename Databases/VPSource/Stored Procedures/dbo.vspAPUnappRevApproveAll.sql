SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   Procedure [dbo].[vspAPUnappRevApproveAll]
  /***********************************************************
   * CREATED BY: MV 09/13/06
   * MODIFIED By : 
   *              
   *
   * USAGE:
   * called from APUnappInv, updates all reviewer lines as approved for a UISeq 
   * 
   * INPUT PARAMETERS
   *   APCo, UIMth, UISeq, LoginName  

   * OUTPUT PARAMETERS
   *    @msg If Error

   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/ 
  	(@apco bCompany , @uimth bMonth, @uiseq int, @userid bVPUserName,@msg varchar(200)output)
  as
set nocount on
  
  
  declare @rcode int
  select @rcode = 0
  	
 if @apco is null
  	begin
  	select @msg = 'Missing AP Company', @rcode = 1
  	goto bspexit
  	end
if @uimth is null
  	begin
  	select @msg = 'Missing UI Month', @rcode = 1
  	goto bspexit
  	end
if @uiseq is null
  	begin
  	select @msg = 'Missing UI Seq', @rcode = 1
  	goto bspexit
  	end
if @userid is null
  	begin
  	select @msg = 'Missing User Login name', @rcode = 1
  	goto bspexit
  	end
  
  if exists(select 1 from APUR where APCo=@apco and UIMth=@uimth and
	UISeq=@uiseq and APTrans is null and ExpMonth is null)
  	begin
  	Update APUR set ApprvdYN = 'Y', Rejected = 'N', RejReason = '', LoginName = @userid
	where APCo = @apco and UIMth = @uimth and UISeq = @uiseq
      and APTrans IS NULL AND ExpMonth IS NULL
	if @@rowcount = 0
  		begin
  		select @msg = 'Reviewer lines were not approved.', @rcode = 1
  		end
	end

  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPUnappRevApproveAll] TO [public]
GO
