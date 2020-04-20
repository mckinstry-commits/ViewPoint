SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[bspHRTrainCreateHRET]
 /************************************************************************
 * CREATED: mh 2/9/04    
 * MODIFIED:  mh 05/31/07 - Issue 30413.  If there is an HRET record for this training
 *							code with an unscheduled status, assume it was manually added
 *							or came from Initialize Training based on the Position Code.
							In that case, back fill the record with HRTC data.
 *
 * Purpose of Stored Procedure
 *
 *	Create HRET training entries based on user selection 
 *	in HR Training Class Resource Selection
 *           
 * Notes about Stored Procedure
 * 
 *
 * returns 0 if successfull 
 * returns 1 and error msg if failed
 *
 *************************************************************************/
 
     (@hrco bCompany, @traincode varchar(10), @classseq int, 
 	@classlist varchar(8000), @errmsg varchar(8000) output, @msg varchar(80) = '' output)
 
 as
 set nocount on
 
     declare @rcode int, @x int, @hrref bHRRef, @nexthretseq int
 

declare @rowcount int

     select @rcode = 0
 
 	if @hrco is null
 	begin
 		select @msg = 'Missing required HR Company.', @rcode = 1
 		goto bspexit
 	end
 
 	if @traincode is null
 	begin
 		select @msg = 'Missing required Training Class.', @rcode = 1
 		goto bspexit
 	end
 
 	if @classseq is null
 	begin
 		select @msg = 'Missing required Class Sequence.', @rcode = 1
 		goto bspexit
 	end
 
 	if @classlist is null
 	begin
 		select @msg = 'Missing Class list.', @rcode = 1
 		goto bspexit
 	end
 
 	select @x = 0
 
 	--Update HRTC class status
 	Update dbo.HRTC set Status = 'S' 
 	where HRCo = @hrco and TrainCode = @traincode and ClassSeq = @classseq
 
 	while len(@classlist) <> 0
 	begin
 	
 		select @x = charindex(',', @classlist)
 	
 		--HRRef to insert
 		select @hrref = convert(int,substring(@classlist, 1, @x - 1))
 
 		--code to create the new HRET record
 
 		--Check of resource is already registered.  Count will be non-zero
  	    if (Select count(HRCo) from dbo.HRET 
  		where HRCo = @hrco and HRRef = @hrref and Type = 'T' and TrainCode = @traincode and ClassSeq = @classseq) > 0
  			goto NextResource
 

		--See if there is an entry brought in from Initialize.  If so, update that record to what is
		--coming in from HRET.

		if exists (Select 1 from HRET where HRCo = @hrco and TrainCode = @traincode and ClassSeq is null and Status = 'U' and HRRef = @hrref)
		begin

			begin transaction

			declare @testseq int
			select @testseq = min(Seq) from HRET where HRCo = @hrco and TrainCode = @traincode and ClassSeq is null and Status = 'U' and HRRef = @hrref

			Update HRET
			set ClassSeq = @classseq, Institution = c.Institution, Class = c.ClassDesc,
			Date = c.StartDate, Status = c.Status, CEUCredits = c.CEUCredits, Hours = c.Hours, Cost = c.Cost, 
			ReimbursedYN = c.ReimbursedYN, Instructor1099YN = c.Instructor1099YN, VendorGroup = c.VendorGroup,
			Vendor = c.Vendor, OSHAYN = c.OSHAYN, MSHAYN = c.MSHAYN, FirstAidYN = c.FirstAidYN, WorkRelatedYN = c.WorkRelatedYN,
			CPRYN = c.CPRYN
			from HRTC c Join HRET t on c.HRCo = t.HRCo and c.TrainCode = t.TrainCode
			where t.HRCo = @hrco and t.HRRef = @hrref and t.TrainCode = @traincode and c.ClassSeq = @classseq

		end
		else
		begin	
 		--Resource has not been previously registered.  Get next HRET.Seq number.  This is not
 		--the same as the ClassSeq.  ClassSeq is for the Training Class in HRTC.
 		
 			select @nexthretseq = isnull(max(Seq) + 1, 1) 
 			from dbo.HRET where HRCo = @hrco and HRRef = @hrref

 			begin transaction
 			insert dbo.HRET (HRCo, HRRef, Seq, Type, TrainCode, ClassSeq, Institution,
 			Class, Date, Status, CEUCredits, Hours, Cost, ReimbursedYN, Instructor1099YN, VendorGroup,
 			Vendor, OSHAYN, MSHAYN, FirstAidYN, WorkRelatedYN, DegreeYN, CPRYN)
 			select HRCo, @hrref, @nexthretseq, 'T', TrainCode, ClassSeq, Institution,
 			ClassDesc, StartDate, Status, CEUCredits, Hours, Cost, ReimbursedYN, Instructor1099YN, 
 			VendorGroup, Vendor, OSHAYN, MSHAYN, FirstAidYN, WorkRelatedYN, 'N', CPRYN from HRTC where
 			HRCo = @hrco and TrainCode = @traincode and ClassSeq = @classseq
 			
		end 


select @rowcount = @@rowcount

 		If @rowcount = 1
 			commit transaction
 		else
 		begin
 
 			select @rcode = 2
 			if @errmsg = ''
 				select @errmsg = convert(varchar(10), isnull(@hrref, 'somehrref'))
 			else
 				select @errmsg = @errmsg + char(13) + convert(varchar(10), isnull(@hrref, 'somehrref'))
 
 			rollback transaction
 		end
 		
 		
 NextResource:
 		select @classlist = substring(@classlist, @x + 1, (len(@classlist) - @x))
 
 	end
 
 
 bspexit:
 
      return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspHRTrainCreateHRET] TO [public]
GO
