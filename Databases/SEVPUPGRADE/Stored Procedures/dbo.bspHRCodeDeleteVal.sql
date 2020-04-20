SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[bspHRCodeDeleteVal]
   /************************************************************************
   * CREATED:  mh 4/18/02    
   * MODIFIED: mh 5/13/02 - added HRES
   *			mh 8/11/04 - 25310 - need to make check against HRCO for history
   *						codes.   
   *			mh 11/08/07 - 125908 - added check for HRSP
   *			mh 12/6/2007 - 30010 - Check HRDT.TestStatus
   *
   * Purpose of Stored Procedure
   *
   *	Check for use of HRCode in other tables prior to deletion from 
   *	HRCM.    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@hrco bCompany, @code varchar(10), @type char(1),  @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	if @hrco is null
   	begin
   		select @rcode = 1, @msg = 'Missing HR Company.'
   		goto bspexit
   	end
   
   	if @code is null
   	begin
   		select @rcode = 1, @msg = 'Missing HR Code.'
   		goto bspexit
   	end
   
   	if @type is null
   	begin
   		select @rcode = 1, @msg = 'Missing HR Code Type.'
   		goto bspexit
   	end
   
   	/* check HREH */
   	if exists(select 1 from dbo.bHREH h with (nolock) where h.HRCo = @hrco and h.Code = @code and @type = 'H')
   		begin
   		select @rcode = 1, @msg = 'Assigned as a code in HREmployment History.'
   		goto bspexit
   		end
   
   	/* check HRRI */
   	if exists(select 1 from dbo.bHRRI h with (nolock) where h.HRCo = @hrco and h.Code = @code and @type = 'R')
   	begin
   		select @rcode = 1, @msg = 'Assigned as a code in HRRating Group.'
   		goto bspexit
   	end
   
   	/* check HRED */
   	if exists(select 1 from dbo.bHRED h with (nolock) where h.HRCo = @hrco and h.Code = @code and @type  = 'N')
   	begin
   		select @rcode = 1, @msg = 'Assigned as a code in HRResource Discipline.'
   		goto bspexit
   	end
   
   	/* check HRRP */
   	if exists(select 1 from dbo.bHRRP h with (nolock) where h.HRCo = @hrco and h.Code = @code and @type  = 'R')
   	begin
   		select @rcode = 1, @msg = 'Assigned as a code in HRResource Review.'
   		goto bspexit
   	end
   
   	/* check HRRD */
   	if exists(select 1 from dbo.bHRRD h with (nolock) where h.HRCo = @hrco and h.Code = @code and @type = 'W')
   	begin
   		select @rcode = 1, @msg = 'Assigned as a code in HRResource Rewards.'
   		goto bspexit
   	end
   
   	/* check HRRS */
   	if exists(select 1 from dbo.bHRRS h with (nolock) where h.HRCo = @hrco and h.Code = @code and @type = 'S')
   	begin
   		select @rcode = 1, @msg = 'Assigned as a code in HRResource Skills.'
   		goto bspexit
   	end
   
   	/* check HRET */
   	if exists(select 1 from dbo.bHRET h with (nolock) where h.HRCo = @hrco and h.TrainCode = @code and @type = 'T')
       begin
           select @rcode = 1, @msg = 'Assigned as code in HR Resource Training.'
           goto bspexit
       end
   
   	/* check HRTC */
   	if exists(select 1 from dbo.bHRTC h with (nolock) where h.HRCo = @hrco and h.TrainCode = @code and @type = 'T')
       begin
           select @rcode = 1, @msg = 'Assigned as code in HR Training Class Setup.'
           goto bspexit
       end
   
   	/* check HRDT */
   	if exists(select 1 from dbo.bHRDT h with (nolock) where h.HRCo = @hrco and h.TestType = @code and @type = 'D')
       begin
           select @rcode = 1, @msg = 'Assigned as a code in HR Drug Testing.'
           goto bspexit
       end

	--Issue 30010
	if exists(select 1 from dbo.bHRDT h with (nolock) where h.HRCo = @hrco and h.TestStatus = @code and @type = 'U')
		begin
			select @rcode = 1, @msg = 'Assigned as a Test Status code in HR Drug Testing'
			goto bspexit
		end
   
   	/* check HRAD */
   	if exists(select 1 from dbo.bHRAD h with (nolock) where h.HRCo = @hrco and h.BodyPart = @code and @type = 'B')
       begin
           select @rcode = 1, @msg = 'Assigned as a code in HR Accident Detail.'
           goto bspexit
       end	
   
   	/* check HRAI */
   	if exists(select 1 from dbo.bHRAI h with (nolock) where h.HRCo = @hrco and h.AccidentCode = @code and @type = 'A')
       begin
           select @rcode = 1, @msg = 'Assigned as a code in HR Accident Detail.'
           goto bspexit
       end	
   
   	/* check HRES */
   	if exists(select 1 from dbo.bHRES h with (nolock) where h.HRCo = @hrco and h.ScheduleCode = @code and @type = 'C')
   	begin
   		select @rcode = 1, @msg = 'Assigned as a code in HR Resource Schedule'
   		goto bspexit
   	end
   
   	/* check HRCO */
   	if exists(select 1 from dbo.bHRCO h with (nolock) where h.HRCo = @hrco and h.DependHistCode = @code and @type = 'H')
   	begin
   		select @rcode = 1, @msg = 'Assigned as a code in HR Company Parameters'
   		goto bspexit
   	end
   
   	if exists(select 1 from dbo.bHRCO h with (nolock) where h.HRCo = @hrco and h.BenefitHistCode = @code and @type = 'H')
   	begin
   		select @rcode = 1, @msg = 'Assigned as a code in HR Company Parameters'
   		goto bspexit
   	end
   
   	if exists(select 1 from dbo.bHRCO h with (nolock) where h.HRCo = @hrco and h.SalaryHistCode = @code and @type = 'H')
   	begin
   		select @rcode = 1, @msg = 'Assigned as a code in HR Company Parameters'
   		goto bspexit
   	end
   
   	if exists(select 1 from dbo.bHRCO h with (nolock) where h.HRCo = @hrco and h.ReviewHistCode = @code and @type = 'H')
   	begin
   		select @rcode = 1, @msg = 'Assigned as a code in HR Company Parameters'
   		goto bspexit
   	end
   
   	if exists(select 1 from dbo.bHRCO h with (nolock) where h.HRCo = @hrco and h.TrainHistCode = @code and @type = 'H')
   	begin
   		select @rcode = 1, @msg = 'Assigned as a code in HR Company Parameters'
   		goto bspexit
   	end
   
   	if exists(select 1 from dbo.bHRCO h with (nolock) where h.HRCo = @hrco and h.SkillsHistCode = @code and @type = 'H')
   	begin
   		select @rcode = 1, @msg = 'Assigned as a code in HR Company Parameters'
   		goto bspexit
   	end
   
   	if exists(select 1 from dbo.bHRCO h with (nolock) where h.HRCo = @hrco and h.RewardHistCode = @code and @type = 'H')
   	begin
   		select @rcode = 1, @msg = 'Assigned as a code in HR Company Parameters'
   		goto bspexit
   	end
   
   	if exists(select 1 from dbo.bHRCO h with (nolock) where h.HRCo = @hrco and h.DisciplineHistCode = @code and @type = 'H')
   	begin
   		select @rcode = 1, @msg = 'Assigned as a code in HR Company Parameters'
   		goto bspexit
   	end
   
   	if exists(select 1 from dbo.bHRCO h with (nolock) where h.HRCo = @hrco and h.GrievanceHistCode = @code and @type = 'H')
   	begin
   		select @rcode = 1, @msg = 'Assigned as a code in HR Company Parameters'
   		goto bspexit
   	end
   
   	if exists(select 1 from dbo.bHRCO h with (nolock) where h.HRCo = @hrco and h.AccidentHistCode = @code and @type = 'H')
   	begin
   		select @rcode = 1, @msg = 'Assigned as a code in HR Company Parameters'
   		goto bspexit
   	end
   
   	if exists(select 1 from dbo.bHRCO h with (nolock) where h.HRCo = @hrco and h.DrugHistCode = @code and @type = 'H')
   	begin
   		select @rcode = 1, @msg = 'Assigned as a code in HR Company Parameters'
   		goto bspexit
   	end
    
	if exists(select 1 from dbo.bHRSP h with (nolock) where h.HRCo = @hrco and h.ReasonCode = @code and @type = 'N')
	begin
		select @rcode = 1, @msg = 'Assigned as a code in HR Salary History - Salary Reasons'
		goto bspexit
	end

   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRCodeDeleteVal] TO [public]
GO
