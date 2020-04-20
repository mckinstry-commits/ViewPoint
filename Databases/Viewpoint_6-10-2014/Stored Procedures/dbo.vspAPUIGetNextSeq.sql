SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspAPUIGetNextSeq]
   /***************************************************************
   *    Created MV 05/09/07
   *
   *    Purpose :	Called by AP Unapproved Invoice Entry when the
   *	user starts a new header seq.  It checks for the next available
   *	seq based on Co and Mth.  Standards cannot handle it because
   *	AP Unapproved needs to check bAPUR history as well as bAPUI
   *    
   *    Inputs
   *            @apco
   *            @uimth
   *
   *
   ***************************************************************/
   (@apco bCompany, @uimth bMonth, @uiseq int output, @msg varchar(200) output)
   
   as
   
    declare @rcode int, @urseq int
   
   select @rcode = 0, @uiseq = 0, @urseq=0
   if @apco is null
		begin
		select @msg = 'APCo is missing',@rcode=1
		goto vspexit
		end
	if @uimth is null
		begin
		select @msg = 'UI Mth is missing',@rcode=1
		goto vspexit
		end
   
	select @uiseq = max(UISeq) from APUI with (nolock) where APCo=@apco and UIMth=@uimth
	select @urseq = max(UISeq) from APUR with (nolock) where APCo=@apco and UIMth=@uimth
	if isnull(@uiseq,0) >= isnull(@urseq,0)
		begin
		select @uiseq = isnull(@uiseq,0) + 1
		goto vspexit
		end
	else		
		begin
		select @uiseq = isnull(@urseq,0) + 1
		end
   
   vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPUIGetNextSeq] TO [public]
GO
