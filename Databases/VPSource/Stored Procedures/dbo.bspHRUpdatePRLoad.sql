SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspHRUpdatePRLoad]
   /************************************************************************
   * CREATED:  mh 2/14/2005    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *	Get initial data to load HRUpdatePR    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@hrco bCompany, @glco bCompany output, @updatesalaryyn bYN output, @updatebenefitsyn bYN output, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int, @prco bCompany
   
       select @rcode = 0
   
	if @hrco is null
	begin
		select @msg = 'Missing HR Company', @rcode = 1
		goto bspexit
	end

	if not exists(select 1 from HRCO where HRCo = @hrco) 
	begin
		select @msg = 'Company# ' + convert(varchar(4), @hrco) + ' not setup in HR', @rcode = 1
		goto bspexit
	end
   
   	select @prco = PRCo, @updatesalaryyn = UpdateSalaryYN, @updatebenefitsyn = UpdateBenefitsYN
   	from dbo.HRCO with (nolock) where HRCo = @hrco
   
   	--validate PRCo
   
   	if (select count(1) from PRCO where PRCo = @prco) < 1 
   	begin
   		select @msg = 'Payroll Company in HRCO is not valid.', @rcode = 1
   		goto bspexit
   	end
   
   	select @glco = GLCo from dbo.PRCO with (nolock) where PRCo = @prco
   
   	if (select count(1) from GLCO where GLCo = @glco) < 1
   	begin
   		select @msg = 'GL Company in GLCO is not valid.', @rcode = 1
   		goto bspexit
   	end
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRUpdatePRLoad] TO [public]
GO
