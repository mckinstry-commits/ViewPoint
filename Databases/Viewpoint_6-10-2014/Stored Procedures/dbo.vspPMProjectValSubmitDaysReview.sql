SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/****** Object:  Stored Procedure dbo.vspPMProjectVal    Script Date: 04/27/2005 ******/
CREATE proc [dbo].[vspPMProjectValSubmitDaysReview]
/***********************************************************
* Created By:	NH	08/30/2012
* Modified By:	ScottP	01/22/2013  Return DefaultStdDaysDue field value
*
*
* USAGE: Used to validate project and return Submittal Days For Review
*
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@pmco bCompany = 0, @project bJob = null, @statusstring varchar(20) = null,
 @ourfirm bFirm = null output, @submitRevDaysRespFirm int = null output,
 @submitRevDaysAppFirm int = null output,@submitRevDaysReqFirm int = null output,
 @submitRevDaysAutoCalc bYN = null output
 ,@approvingfirm bFirm = null output
 ,@approvingfirmcontact bEmployee = null output
 ,@defaultStdDaysDue int = null output
 ,@msg varchar(255) output)
as
set nocount on

declare @rcode int, @jcode int

select @rcode = 0

exec @rcode = vspPMProjectVal @pmco,@project,@statusstring,null,null,null,
null,null,null,null,null,@ourfirm output,null,null,null,
null,null,null,null,null,null,null,null,@msg output

if @rcode = 0
begin
	select 
	@submitRevDaysRespFirm=SubmittalReviewDaysResponsibleFirm,
	@submitRevDaysAppFirm=SubmittalReviewDaysApprovingFirm,
	@submitRevDaysReqFirm=SubmittalReviewDaysRequestingFirm,
	@submitRevDaysAutoCalc=SubmittalReviewDaysAutoCalcYN,
	@defaultStdDaysDue=DefaultStdDaysDue,
	@approvingfirmcontact=SubmittalApprovingFirmContact,
	@approvingfirm=SubmittalApprovingFirm
	from JCJMPM where PMCo=@pmco and Project=@project
end

bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspPMProjectValSubmitDaysReview] TO [public]
GO
