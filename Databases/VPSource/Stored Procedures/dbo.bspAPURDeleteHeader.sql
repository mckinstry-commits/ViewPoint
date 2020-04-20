SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspAPURDeleteHeader]
   /**************************************
   *    Created by TV 11/05/02
   *	Modified by:	MV 07/28/08 - #129135 don't delete if reviewer is in line RG
   *
   *    Why? To delete qualifying lines when Header is deleted
   *
   *    Inputs: APCo
   *            UIMth
   *            UISeq
   *            Reviewer
   *            APTrans
   *            EXPMnth
   *
   *
   ***************************************/
   (@APCo bCompany, @UIMth bMonth, @UISeq int, @Reviewer varchar(3), @APTrans bTrans, @ExpMonth bMonth)
   
   As
   Set nocount on
   
   
   delete bAPUR
   where APCo= @APCo and UIMth= @UIMth and UISeq= @UISeq and Reviewer = @Reviewer  and 
   isnull(APTrans,0) = isnull(@APTrans,0) and isnull(ExpMonth,0) = isnull(@ExpMonth,0)
	and not exists (select * from bAPUL l join vHQRD d on l.ReviewerGroup=d.ReviewerGroup
	where l.APCo= @APCo and l.UIMth= @UIMth and l.UISeq= @UISeq and 
	l.ReviewerGroup=d.ReviewerGroup and d.Reviewer=@Reviewer)
   
   return

GO
GRANT EXECUTE ON  [dbo].[bspAPURDeleteHeader] TO [public]
GO
