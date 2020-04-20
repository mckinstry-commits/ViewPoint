SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[bspHRETClassSeqVal]
   /************************************************************************
   * CREATED:	MH 2/4/04    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *	Validate Class Seq entered in HR Resource Training exists in 
   *	bHRTC - HR Training Class setup table.    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@hrco bCompany, @traincode varchar(10), @classseq smallint, 
   @classdesc_out bDesc output, @inst_out varchar(30) output, @classdesc2_out bDesc output,
   @date_out bDate output, @status_out char(1) output, @ceucredits_out numeric output, @hours_out bHrs output,
   @cost_out bDollar output, @reimb_out bYN output, @inst1099_out bYN output, 
   @vendor_out bVendor output, @vendgrp_out bGroup output, 
   @oshayn_out bYN output, @mshayn_out bYN output, @firstaidyn_out bYN output, @cpryn_out bYN output, 
   @workrelatedyn_out bYN output,
   @degreeyn_out bYN output, @msg varchar(80) = '' output)
   
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
   
   	if @classseq is null
   	begin
   		select @msg = 'Missing Class Sequence.', @rcode = 1
   		goto bspexit
   	end
   
   	if not exists (select ClassSeq from bHRTC where HRCo = @hrco and TrainCode = @traincode and ClassSeq = @classseq)
   	begin
   		select @msg = 'Class Sequence does not exist in HR Training Class setup for Training Code ' + @traincode, @rcode = 1
   		goto bspexit
   	end
   
   	--return the following to hidden fields
   
   		select 
   			@classdesc_out = ClassDesc, 
   			@inst_out = Institution,
   			@classdesc2_out = ClassDesc, 
   			@date_out = StartDate, 
   			@status_out = Status, 
   			@ceucredits_out = CEUCredits, 
   			@hours_out = Hours, 
   			@cost_out = Cost, 
   			@reimb_out = ReimbursedYN, 
   			@inst1099_out = Instructor1099YN, 
   			@vendgrp_out = VendorGroup,
   			@vendor_out = Vendor, 
   			@oshayn_out = OSHAYN, 
   			@mshayn_out = MSHAYN, 
   			@firstaidyn_out = FirstAidYN, 
   			@cpryn_out = CPRYN,
   			@workrelatedyn_out = WorkRelatedYN,
   			@degreeyn_out = 'N'
   		from bHRTC with (nolock) 
   		where HRCo = @hrco and TrainCode = @traincode and ClassSeq = @classseq
/*  
   		select 
   			@classdesc_out = ClassDesc, 
   			@inst_out = Institution,
   			@classdesc2_out = ClassDesc, 
   			@date_out = StartDate, 
   			@status_out = Status, 
   			@ceucredits_out = CEUCredits, 
   			@hours_out = Hours, 
   			@cost_out = Cost, 
   			@reimb_out = isnull(ReimbursedYN, 'N'), 
   			@inst1099_out = isnull(Instructor1099YN, 'N'), 
   			@vendgrp_out = VendorGroup,
   			@vendor_out = Vendor, 
   			@oshayn_out = isnull(OSHAYN, 'N'), 
   			@mshayn_out = isnull(MSHAYN, 'N'), 
   			@firstaidyn_out = isnull(FirstAidYN,'N'), 
   			@cpryn_out = isnull(CPRYN,'N'),
   			@workrelatedyn_out = isnull(WorkRelatedYN,'N'),
   			@degreeyn_out = 'N'
   		from bHRTC with (nolock) 
   		where HRCo = @hrco and TrainCode = @traincode and ClassSeq = @classseq
*/ 
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRETClassSeqVal] TO [public]
GO
