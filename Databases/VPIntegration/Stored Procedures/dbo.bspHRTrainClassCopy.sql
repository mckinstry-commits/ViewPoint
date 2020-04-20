SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspHRTrainClassCopy]
   /************************************************************************
   * CREATED:	MH 2/12/04    
   * MODIFIED:  MH ?? - 125027 - Default "U-Unscheduled" for Status.  
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
   
       (@hrco bCompany, @traincode varchar(10), @oldseq int, @newseq int output, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	if @hrco is null
   	begin
   		select @msg = 'Missing HR Company.', @rcode = 1
   		goto bspexit
   	end
   
   	if @traincode is null
   	begin
   		select @msg = 'Missing Training Code.', @rcode = 1
   		goto bspexit
   	end
   
   	if @oldseq is null
   	begin
   		select @msg = 'Missing Class Sequence.', @rcode = 1
   		goto bspexit
   	end
   
   	--develop the new class seq
   /*
   	select @newseq = ClassSeq + 1 from dbo.HRTC with (nolock) where HRCo = @hrco and 
   	TrainCode = @traincode and ClassSeq = @oldseq
   */
   
   	select @newseq = isnull(max(ClassSeq), 0) + 1 from dbo.HRTC with (nolock) where HRCo = @hrco and
   	TrainCode = @traincode
   
   	
   	--copy the training code
   	insert into dbo.HRTC (HRCo, TrainCode, Type, ClassSeq, ClassDesc, Instructor, Institution,
   	Address, City, State, Zip, Contact, Phone, EMail, Room, Hours, Status, CEUCredits,
   	Cost, VendorGroup, Vendor, StartDate, ClassTime, EndDate, TimeDesc, MaxAttend, 
   	Instructor1099YN, OSHAYN, MSHAYN, FirstAidYN, CPRYN, ReimbursedYN, WorkRelatedYN, Notes,
   	UniqueAttchID)
   	select HRCo, TrainCode, Type, @newseq, ClassDesc, Instructor, Institution,
   	Address, City, State, Zip, Contact, Phone, EMail, Room, Hours, /*Status,*/ 'U', CEUCredits,
   	Cost, VendorGroup, Vendor, StartDate, ClassTime, EndDate, TimeDesc, MaxAttend, 
   	Instructor1099YN, OSHAYN, MSHAYN, FirstAidYN, CPRYN, ReimbursedYN, WorkRelatedYN, Notes,
   	UniqueAttchID from dbo.HRTC with (nolock)
   	where HRCo = @hrco and TrainCode = @traincode and Type = 'T' and ClassSeq = @oldseq
   
   	--copy the skills
   	insert into dbo.HRTS (HRCo, TrainCode, Type, ClassSeq, SkillCode)
   	select HRCo, TrainCode, Type, @newseq, SkillCode 
   	from dbo.HRTS with (nolock)
   	where HRCo = @hrco and TrainCode = @traincode and Type = 'S' and ClassSeq = @oldseq
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRTrainClassCopy] TO [public]
GO
