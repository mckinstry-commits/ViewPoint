SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspHRBCDelVal]
   /************************************************************************
   * CREATED: mh 1/27/04    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *   Upon deletion of a benefit code from HR Benefit Code, check and make sure
   *	code is not currently in use.
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@hrco bCompany, @bencode varchar(10), @errmsg varchar(100) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	if @hrco is null
   	begin
   		Select @errmsg = 'Missing HR Company.', @rcode = 1
   		goto bspexit
   	end
   
   	if @bencode is null
   	begin
   		Select @errmsg = 'Missing Benefit Code.', @rcode = 1
   		goto bspexit
   	end
   
   
   	if exists(select 1 from bHRBI with (nolock) where HRCo = @hrco and BenefitCode = @bencode)
   	begin
   		select @rcode = 1
   		select @errmsg = 'Benefit code ' + @bencode + ' is in use in HRBI.  Unable to delete.'  
   		goto bspexit
   	end
   
   	if exists(select 1 from bHREB with (nolock) where HRCo = @hrco and BenefitCode = @bencode)
   	begin
   		select @rcode = 1
   		select @errmsg = 'Benefit code ' + @bencode + ' is in use in HR Resource Benefits.  Unable to delete.'
   		goto bspexit
   	end
   
   	if exists(select 1 from bHRGI with (nolock) where HRCo = @hrco and BenefitCode = @bencode)
   	begin
   		select @rcode = 1
   		select @errmsg = 'Benefit code ' + @bencode + ' is in use in HR Benefit Group.  Unable to delete.'
   		goto bspexit
   	end
   
   	if exists(select 1 from bHRBB with (nolock) where Co = @hrco and BenefitCode = @bencode)
   	begin	
   		select @rcode = 1
   		select @errmsg = 'Benefit Code ' + @bencode + ' is in use in a HR Update Benefit/Salary to PR batch.  Unable to delete.'
   		goto bspexit
   	end	
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRBCDelVal] TO [public]
GO
