SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      procedure [dbo].[bspHRTrainUpdate]
   /************************************************************************
   * CREATED:  MH 1/29/04    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *	Update HR Resource Training and create/update 
   *	HR Resource Skills entries    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@hrco bCompany, @traincode varchar(10), @classseq int, @status char(1), 
   	@completedate bDate, @tester varchar(100), @allowrollback char(1) = 'N', @msg varchar(250) = '' output)
   
   
   as
   set nocount on
   
       declare @rcode int, @open_hret_curs tinyint, @hrref bHRRef, @open_hrts_curs tinyint,
   	@skill varchar(10), @certperiod smallint, @expiredate bDate --, @certdate bDate
   
       select @rcode = 0, @open_hret_curs = 0, @open_hrts_curs = 0
   
   	if @allowrollback = 'N'
   	begin
   		if @status <> 'C'
   		begin
   			if (select Status from dbo.HRTC with (nolock) 
   			where HRCo = @hrco and TrainCode = @traincode and ClassSeq = @classseq) = 'C'
   			begin
   				select @msg = 'Attempting to change the status of a Training Class previously set to "Completed."' + char(13) +
   							  'Skill codes previously inserted or updated in HR Resource Skills will not be affected.' + char(13) + char(10) + 'Continue?'
   				Select @rcode = 1
   				goto bspexit
   			end
   		end
   	end
   
   --Update bHRET entries
   
   	if @status = 'X'
   		Update dbo.HRET set Status = @status, CompleteDate = @completedate
   		where HRCo = @hrco and Type = 'T' and TrainCode = @traincode and
   		ClassSeq = @classseq
   	else
   		Update dbo.HRET set Status = @status, CompleteDate = @completedate
   		where HRCo = @hrco and Type = 'T' and TrainCode = @traincode and
   		ClassSeq = @classseq and Status in ('U','S','I','C')
   
   --Update bHRTC entries
   
   	Update dbo.HRTC set Status = @status
   	where HRCo = @hrco and Type = 'T' and TrainCode = @traincode and
   	ClassSeq = @classseq
   
   --Update HR Skills Entries.
   	if @status = 'C'
   	begin
   
   	declare hrts_curs cursor local fast_forward for
   	select SkillCode from dbo.HRTS with (nolock) where HRCo = @hrco and TrainCode = @traincode and 
   	ClassSeq = @classseq
   
   	open hrts_curs
   	select @open_hrts_curs = 1
   
   	fetch next from hrts_curs into @skill
   
   	--Loop through the skills listed in HRTS for the TrainingClass
   	while @@fetch_status = 0
   	begin
   
   		--Get the certification period for this skill
   		select @certperiod = (Select CertPeriod from dbo.HRCM with (nolock) 
   		where HRCo = @hrco and Type = 'S' and Code = @skill)
   
   		--Calculate the new certification expiration date
   		select @expiredate = dateadd(mm, @certperiod, @completedate)
   
   		declare hret_curs cursor local fast_forward for
   		select HRRef from dbo.HRET with (nolock)
   		where HRCo = @hrco and Type = 'T' and TrainCode = @traincode and 
   		ClassSeq = @classseq and Status = @status
   
   		open hret_curs
   		select @open_hret_curs = 1
   
   		fetch next from hret_curs into @hrref
   
   		while @@fetch_status = 0 
   		begin
   
   			--check if HRRef is in HRRS.
   			if exists (select 1 from dbo.HRRS with (nolock) where HRCo = @hrco and @hrref = HRRef and Code = @skill)
   				--do update
   				Update dbo.HRRS set CertDate = @completedate, ExpireDate = @expiredate, SkillTester = @tester
   				where HRCo = @hrco and HRRef = @hrref and Code = @skill
   			else
   				--do insert
   				Insert dbo.HRRS (HRCo, HRRef, Code, CertDate, ExpireDate, SkillTester) 
   				values (@hrco, @hrref, @skill, @completedate, @expiredate, @tester)
   
   
   			fetch next from hret_curs into @hrref	
   		end
   
   		if @open_hret_curs = 1
   		begin
   			close hret_curs
   			deallocate hret_curs
   			select @open_hret_curs = 0
   		end
   
   		fetch next from hrts_curs into @skill
   
   	end
   
   	end
   bspexit:
   
   	if @open_hrts_curs = 1
   	begin
   		close hrts_curs
   		deallocate hrts_curs
   	end
   
   	if @open_hret_curs = 1
   	begin
   		close hret_curs
   		deallocate hret_curs
   	end
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRTrainUpdate] TO [public]
GO
