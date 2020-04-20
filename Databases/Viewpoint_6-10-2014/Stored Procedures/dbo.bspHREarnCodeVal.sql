SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspHREarnCodeVal]
   /************************************************************************
   * CREATED:  mh 6/24/04    
   * MODIFIED:	mh 2/5/08 - Issue 23347 
   *			MV 08/21/2012 - TK-17317 added null output param to bspPREarnDedLiabVal    
   *
   * Purpose of Stored Procedure
   *
   *   Validate Earnings Code entered in HR Resource Benefits against
   *	PR.  Informs user if Earnings code is being used by more then
   *	one benefit code.
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
           
	(@hrco bCompany, @hrref bHRRef, @bencode varchar(10), @prco bCompany, 
	@earncode bEDLCode, @dlinstcnt int output, @benefitoption smallint output, @msg varchar(80) = '' output)

	as
	set nocount on

	declare @rcode int

	select @rcode = 0, @dlinstcnt = 0

	exec @rcode = bspPREarnDedLiabVal @prco, 'E', @earncode,
	null, null, null, null, null, null, null, @msg output
   
	if @rcode = 1 
		goto bspexit

	select @dlinstcnt = count(HRCo) from dbo.HRBE with (nolock)
	where HRCo = @hrco and HRRef = @hrref and BenefitCode <> @bencode and DependentSeq = 0 and
	EarnCode = @earncode	

	--Issue 23347   
	if (select count(1) from dbo.HRBI where HRCo = @hrco and BenefitCode = @bencode and EDLCode = @earncode and
	EDLType = 'E') = 1
	begin
		select @benefitoption = BenefitOption 
		from dbo.HRBI (nolock)
		where HRCo = @hrco and BenefitCode = @bencode and EDLCode = @earncode and
		EDLType = 'E'
	end
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHREarnCodeVal] TO [public]
GO
