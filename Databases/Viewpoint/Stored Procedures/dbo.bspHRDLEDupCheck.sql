SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspHRDLEDupCheck]
   /************************************************************************
   * CREATED:	mh 10/28/03    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@hrco bCompany, @hrref bHRRef, @msg varchar(5000) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	-- Issue 22329...  check the D/L codes. If they are used by more then one 
   	-- Benefit Code send a warning back to the user.
   	declare @bencode varchar(10), @bencodelist varchar(500)
   	
   	if (select count(h.HRCo) from HRBL h with (nolock) where h.HRCo = @hrco and h.HRRef = @hrref and DLCode in 
   	(select DLCode from HRBL with (nolock) where HRCo = @hrco and HRRef = @hrref and BenefitCode <> h.BenefitCode)) > 0
   	begin
   		declare dl_curs cursor fast_forward for
   		select distinct(h.BenefitCode) from HRBL h with (nolock) where h.HRCo = @hrco and h.HRRef = @hrref 
   		and DLCode in (select DLCode from HRBL with (nolock) where HRCo = @hrco and HRRef = @hrref and 
   		BenefitCode <> h.BenefitCode)
   	
   		open dl_curs
   		fetch next from dl_curs into @bencode
   	
   		while @@fetch_status = 0
   		begin
   	
   			if @bencodelist is null
   				select @bencodelist = @bencode
   			else
   				select @bencodelist = @bencodelist + ', ' + @bencode
   	
   			fetch next from dl_curs into @bencode
   	
   		end
   	
   		close dl_curs
   		deallocate dl_curs
   	
   		if @bencodelist is not null
   		begin
   			if @msg is not null
   				select @msg = @msg + 'Warning:  The following Benefit Codes contain Deduction/Liability' + char(13) + char(10) + 'Codes used more than once for this Resource.'
   			else
   				select @msg = 'Warning:  The following Benefit Codes contain Deduction/Liability' + char(13) + char(10) + 'Codes used more than once for this Resource.'
   	
   			select @msg = @msg + char(13) + char(10) + char(13) + char(10) + @bencodelist
   	
   			select @rcode = 2
   	
   		end
   	end
   	
   	
   	declare @earncode varchar(10), @earncodelist varchar(500)
   	
   	if (select count(h.HRCo) from HRBE h with (nolock) where h.HRCo = @hrco and h.HRRef = @hrref and EarnCode in 
   	(select EarnCode from HRBE with (nolock) where HRCo = @hrco and HRRef = @hrref and BenefitCode <> h.BenefitCode)) > 0
   	begin
   		declare earn_curs cursor fast_forward for
   		select distinct(h.BenefitCode) from HRBE h with (nolock) where h.HRCo = @hrco and h.HRRef = @hrref 
   		and EarnCode in (select EarnCode from HRBE with (nolock)  where HRCo = @hrco and HRRef = @hrref and
   		BenefitCode <> h.BenefitCode)
   	
   		open earn_curs
   		fetch next from earn_curs into @earncode
   	
   		while @@fetch_status = 0
   		begin
   			if @earncodelist is null
   				select @earncodelist = @earncode
   			else
   				select @earncodelist = @earncodelist + ', ' + @earncode
   	
   			fetch next from earn_curs into @earncode
   		end
   	
   		close earn_curs
   		deallocate earn_curs
   	
   		if @earncodelist is not null
   		begin
   			if @msg is not null
   				select @msg = @msg + char(13) + char(10) + 'Warning:  The following Benefit Codes contain Earnings Codes used more then once for this Resource.'
   			else
   				select @msg = 'Warning:  The following Benefit Codes contain Earnings Codes used more then once for this Resource.'
   	
   			select @msg = @msg + char(13) + char(13) + char(10) + @earncodelist
   	
   			select @rcode = 2
   	
   		end
   	end
   
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRDLEDupCheck] TO [public]
GO
