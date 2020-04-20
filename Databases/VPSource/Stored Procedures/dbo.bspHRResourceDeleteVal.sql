SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspHRResourceDeleteVal]
   /************************************************************************
   * CREATED:	MH 1/27/03    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *	Prevent deletion of a HRResource if dependent records exist.  
   *	Similar to a delete trigger.    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@hrco bCompany, @hrref bHRRef, @msg varchar(100) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	if exists(select HRRef from HRWI where HRCo = @hrco and HRRef = @hrref)
   	begin
   		select @msg = 'Related W4 information exists.  Please remove using HR Resource Master.', @rcode = 1
   		goto bspexit
   	end
   
   	if exists(select HRRef from HREH where HRCo = @hrco and HRRef = @hrref) 
   	begin
   		select @msg = 'Related Employment History exists.  Please remove using HR Employment History.', @rcode = 1
   		goto bspexit
   	end
   
   	if exists(select HRRef from HRDP where HRCo = @hrco and HRRef = @hrref)
   	begin
   		select @msg = 'Related Dependent entries exist.  Please remove using HR Resource Dependents.', @rcode = 1
   		goto bspexit
   	end
   
   	if exists(select HRRef from HREC where HRCo = @hrco and HRRef = @hrref)
   	begin
   		select @msg = 'Related Contact entries exist.  Please remove using HR Resource Contacts.', @rcode = 1
   		goto bspexit
   	end
   
   	if exists(select HRRef from HREB where HRCo = @hrco and HRRef = @hrref)
   	begin
   		select @msg = 'Related Benefit entries exist.  Please remove using HR Resource Benefits.', @rcode = 1
   		goto bspexit
   	end		
   
   	if exists(select HRRef from HRSP where HRCo = @hrco and HRRef = @hrref)
   	begin
   		select @msg = 'Related Salary entries exist.  Please remove using HR Resource Salary.', @rcode = 1
   		goto bspexit
   	end		
   
   	if exists(Select HRRef from HRSH where HRCo = @hrco and HRRef = @hrref)
   	begin
   		select @msg = 'Related Salary History entries exist. Please remove using HR Resource Salary.', @rcode = 1
   		goto bspexit
   	end		
   
   	if exists(Select HRRef from HRER where HRCo = @hrco and HRRef = @hrref)
   	begin
   		select @msg = 'Related Review entries exist.  Please remove using HR Resource Review.', @rcode = 1
   		goto bspexit
   	end
   		
   	if exists(Select HRRef from HRES where HRCo = @hrco and HRRef = @hrref)
   	begin
   		select @msg = 'Related Schedule entries exist. Please remove using HR Resource Schedule.', @rcode = 1
   		goto bspexit
   	end
   		
   	if exists(Select HRRef from HRET where HRCo = @hrco and HRRef = @hrref)
   	begin
   		select @msg = 'Related Training entries exist.  Please remove using HR Resource Training.', @rcode = 1
   		goto bspexit
   	end	
   
   	if exists(Select HRRef from HRRS where HRCo = @hrco and HRRef = @hrref)
   	begin
   		select @msg = 'Related Skills entries exist.  Please remove using HR Resource Skills.', @rcode = 1
   		goto bspexit
   	end
   	
   	if exists(Select HRRef from HRRD where HRCo = @hrco and HRRef = @hrref)
   	begin
   		select @msg = 'Related Rewards entries exist.  Please remove using HR Resource Rewards.', @rcode = 1
   		goto bspexit
   	end		
   
   	if exists(Select HRRef from HRED where HRCo = @hrco and HRRef = @hrref)
   	begin
   		select @msg = 'Related Discipline entries exist.  Please remove using HR Resource Discipline.', @rcode = 1
   		goto bspexit
   	end	
   
   	if exists(Select HRRef from HREG where HRCo = @hrco and HRRef = @hrref)
   	begin
   		select @msg = 'Related Grievance entries exist.  Please remove using HR Resource Grievances.', @rcode = 1
   		goto bspexit
   	end	
   
   	if exists(Select HRRef from HRBE where HRCo = @hrco and HRRef = @hrref)
   	begin
   		select @msg = 'Related Benefit entries exist.  Please remove using HR Resource Benefits.', @rcode = 1
   		goto bspexit
   	end	
   
   	if exists(Select HRRef from HRRC where HRCo = @hrco and HRRef = @hrref)
   	begin
   		select @msg = 'Related COBRA entries exist.  Please remove using HR Resource COBRA.', @rcode = 1
   		goto bspexit
   	end	
   
   	if exists(Select HRRef from HRBL where HRCo = @hrco and HRRef = @hrref)
   	begin
   		select @msg = 'Related Benefit entries exist.  Please remove using HR Resource Benefits.', @rcode = 1
   		goto bspexit
   	end	
   
   	if exists(Select HRRef from HRRP where HRCo = @hrco and HRRef = @hrref)
   	begin
   		select @msg = 'Related Review entries exist.  Please remove using HR Resource Review.', @rcode = 1
   		goto bspexit
   	end	
   
   	if exists(Select HRRef from HRAR where HRCo = @hrco and HRRef = @hrref)
   	begin
   		select @msg = 'Related Application Reference entries exist.  Please remove using HR Application References.', @rcode = 1
   		goto bspexit
   	end	
   
   	if exists(Select HRRef from HRAP where HRCo = @hrco and HRRef = @hrref)
   	begin
   		select @msg = 'Related Application Position entries exist.  Please remove using HR Application Positions.', @rcode = 1
   		goto bspexit
   	end	
   
   	if exists(Select HRRef from HREI where HRCo = @hrco and HRRef = @hrref)
   	begin
   		select @msg = 'Related Interview entries exist.  Please remove using HR Resource Interview.', @rcode = 1
   		goto bspexit
   	end	
   
   	if exists(Select HRRef from HRDT where HRCo = @hrco and HRRef = @hrref)
   	begin
   		select @msg = 'Related Drug Testing entries exist.  Please remove using HR Drug Testing.', @rcode = 1
   		goto bspexit
   	end	
   
   	if exists(Select HRRef from HRAI where HRCo = @hrco and HRRef = @hrref)
   	begin
   		select @msg = 'Resource Involved in an accident and cannot be removed.  Entries exist in HR Accident', @rcode = 1
   		goto bspexit
   	end	
   
   	if exists(Select HRRef from HRBL where HRCo = @hrco and HRRef = @hrref)
   	begin
   		select @msg = 'Related Benefit entries exist.  Please remove using HR Resource Benefits.', @rcode = 1
   		goto bspexit
   	end	
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRResourceDeleteVal] TO [public]
GO
