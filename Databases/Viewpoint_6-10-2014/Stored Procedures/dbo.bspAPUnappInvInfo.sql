SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspAPUnappInvInfo]
    /***********************************************************
     * CREATED BY: kb 6/14/1
     * MODIFIED By : kb 10/29/2 - issue #18878 - fix double quotes
     *
     * USAGE:
     *
     * INPUT PARAMETERS
     *
     * OUTPUT PARAMETERS
     *   @msg      error message if error occurs otherwise Description of Contract
     * RETURN VALUE
     *   0         success
     *   1         Failure
     *****************************************************/
   
     @co bCompany, @uimth bMonth, @uiseq int, @description bDesc output,
     @invdate bDate output, @discdate bDate output, @duedate bDate output,
     @holdcode bHoldCode output, @paycontrol varchar(10) output,
     @msg varchar(255) output
   
    as
    set nocount on
   
    	declare @rcode int
    	select @rcode = 0
   
    if @co is null
    	begin
    	select @msg = 'Missing Company!', @rcode = 1
    	goto bspexit
    	end
   
    if @uimth is null
       begin
       select @msg = 'Missing Month!', @rcode = 1
       goto bspexit
       end
   
    if @uiseq is null
       begin
       select @msg = 'Missing Seq!', @rcode = 1
       goto bspexit
       end
   
     select @description = Description, @invdate = InvDate, @duedate = DueDate,
       @discdate = DiscDate, @holdcode = HoldCode, @paycontrol = PayControl
    from APUI
    where APCo = @co and UIMth = @uimth and UISeq = @uiseq
    if @@rowcount = 0
    	begin
    	select @msg = 'Month and Seq do not exist in APUI', @rcode = 1
    	goto bspexit
    	end
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPUnappInvInfo] TO [public]
GO
