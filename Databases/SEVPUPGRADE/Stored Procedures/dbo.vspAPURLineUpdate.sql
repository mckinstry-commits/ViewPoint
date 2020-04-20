SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspAPURLineUpdate]
   /***************************************************************
   *    Created 09/07/06 by MAV
   *
   *    This SP is called from APUnappInv StdFieldAfterValidate to update
   *	the Reject field in APUR for any APUR lines associated with the
   *	APUR header (-1)
   *    
   *    Inputs
   *            @apco
   *            @uimth
   *            @uiseq
   *            @reviewer
   *			@rejectyn
   *
   ***************************************************************/
   (@apco bCompany, @uimth bMonth, @uiseq int, @reviewer varchar(3), @rejectyn bYN)
   
   as
   
  Update APUR Set Rejected = @rejectyn where APCo = @apco and Reviewer = @reviewer and 
	UIMth = @uimth and UISeq =  @uiseq and Line <> -1

GO
GRANT EXECUTE ON  [dbo].[vspAPURLineUpdate] TO [public]
GO
