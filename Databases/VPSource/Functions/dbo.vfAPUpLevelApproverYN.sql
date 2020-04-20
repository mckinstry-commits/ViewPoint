SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    function [dbo].[vfAPUpLevelApproverYN]
  (@apco bCompany, @uimth bMonth, @uiseq int, @rev varchar(3))
      returns bYN
   /***********************************************************
    * CREATED BY	: MV 02/14/2008
    * MODIFIED BY	: 
    *
    * USAGE:
    * checks if the Reviewer is an up level reviewer for APUnappInvRev
	* returns a flag of Y
    *
    * INPUT PARAMETERS
    * 	@apco
    * 	@udmth
    * 	@uiseq
    *
    * OUTPUT PARAMETERS
    *  @uplevelyn      
    *
    *****************************************************/
      as
      begin
          
        declare @uplevelyn bYN
		 
		--initialize missing flag
		select @uplevelyn = 'N'

		--check for missing info in common for all linetypes
	if exists(select * from APUR r join APUL l on r.APCo=l.APCo and r.UIMth=l.UIMth and r.UISeq=l.UISeq and r.Line=l.Line
	join HQRG g on g.ReviewerGroup=l.ReviewerGroup
	join HQRD h on h.ReviewerGroup=l.ReviewerGroup and h.Reviewer=@rev
	where r.APCo= @apco and r.UIMth=@uimth and r.UISeq=@uiseq and g.AllowUpLevelApproval = 2 and r.Reviewer <> @rev and
		r.ApprovalSeq < h.ApprovalSeq and r.ApprvdYN='N')
			begin
				select @uplevelyn='Y'
				goto exitfunction
			end
		
 
  	exitfunction:
  			
  	return @uplevelyn
      
    end

GO
GRANT EXECUTE ON  [dbo].[vfAPUpLevelApproverYN] TO [public]
GO
