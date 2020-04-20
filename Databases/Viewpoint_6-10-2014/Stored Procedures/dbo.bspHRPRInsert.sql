SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRPRInsert    Script Date: 2/4/2003 7:43:22 AM ******/
   
   CREATE  procedure [dbo].[bspHRPRInsert]
   /*************************************************************************************************
   * CREATED BY: ae 1/20/00
   * MODIFIED By : mh 9/14/00 - PREmp number does not have to match HRRef.  W4 info not being updated
   *                            to PR correctly when HRRef <> PREmp number.  Corrected.
   *			GG 09/20/02 - #18522 ANSI nulls
   *
   * USAGE:This routine is called from HR Resource Master and PR Employee Master.
   *
   * INPUT PARAMETERS
   *     @co         = Company
   *     @employee   = Employee #
   *     @source     = 'HR or 'PR. If 'HR' then changes are updated to PR. If 'PR then changes
   *                     are updated to HR.
   *     The rest of the fields are the changes that get updated. Note the field is null
   *     if no changes have been made to them.
   *
   * OUTPUT PARAMETERS
   *   @errmsg     if something went wrong
   *
   * RETURN VALUE
   *   0   success
   *   1   fail
   **************************************************************************************************/
   
      	(@co bCompany, @employee bEmployee, @DednCode bEDLCode, @source char(2), @errmsg varchar(60) output)
      as
   
      set nocount on
   
      declare @rcode int
      declare @FileStatus char(1), @hrco bCompany, @hrref bHRRef
      declare @RegExemp tinyint
      declare @AddionalExemp int
      declare @OverrideMiscAmtYN bYN
      declare @MiscAmt1 bDollar
      declare @MiscFactor bRate
      declare @glco bCompany
      declare @hremp bHRRef
   
      select @rcode = 0
   
      if @source='PR'
         begin
           select @FileStatus = FileStatus, @RegExemp = RegExempts, @AddionalExemp = AddExempts,
                  @OverrideMiscAmtYN = OverMiscAmt, @MiscAmt1 = MiscAmt, @MiscFactor = MiscFactor
              from PRED where PRCo = @co and Employee = @employee and DLCode = @DednCode
   
           if @OverrideMiscAmtYN is null	-- #18522
               select @OverrideMiscAmtYN = 'N'
   
           if @MiscAmt1 is null	-- #18522
               select @MiscAmt1 = 0
   
           select @hrco = HRCo, @hrref = HRRef from bHRRM where PRCo = @co and
             PREmp = @employee
   
   		if @hrref is null
   			begin
   				select @errmsg = 'Employee not assigned to an HRRef.  Unable to insert into HR.', @rcode = 1
   				goto bspexit
   			end
   
           if not exists(select * from HRWI where HRCo = @hrco and HRRef = @hrref
             and DednCode = @DednCode)
            	insert into HRWI (HRCo, HRRef, DednCode, FileStatus, RegExemp, AddionalExemp,
              	OverrideMiscAmtYN, MiscAmt1, MiscFactor)
              	values (@hrco, @hrref, @DednCode, @FileStatus, @RegExemp, @AddionalExemp,
               @OverrideMiscAmtYN, @MiscAmt1, @MiscFactor)
   		else
   			update HRWI set FileStatus = @FileStatus, RegExemp = @RegExemp, AddionalExemp = @AddionalExemp,
   			OverrideMiscAmtYN = @OverrideMiscAmtYN, MiscAmt1 = @MiscAmt1, MiscFactor = @MiscFactor
   			where HRCo = @hrco and HRRef = @hrref and DednCode = @DednCode
   
         end
   
      if @source='HR'
         begin
   
           --Need HRRef when searching HRWI.  HRRef does not have to equal PREmp number. mh 9/14
           select @hremp = HRRef from HRRM where HRCo = @co and PREmp = @employee
   
           select @FileStatus = FileStatus, @RegExemp = RegExemp,
                  @AddionalExemp = AddionalExemp, @OverrideMiscAmtYN = OverrideMiscAmtYN,
                  @MiscAmt1 = MiscAmt1, @MiscFactor = MiscFactor
              from HRWI where HRCo = @co and HRRef = @hremp and DednCode = @DednCode
   
           --select * from PRED where PRCo = @co and Employee = @employee and DLCode = @DednCode
           --if @@rowcount = 0
   		if not exists(select * from PRED where PRCo = @co and Employee = @employee and DLCode = @DednCode)
            begin
              select @glco = GLCo from PRCO where PRCo = @co
              insert PRED (PRCo, Employee,DLCode,EmplBased,
                       FileStatus,RegExempts,AddExempts,OverMiscAmt,MiscAmt,MiscFactor,
                       OverLimit,NetPayOpt,AddonType, OverCalcs,GLCo)
                   select @co, @employee, DednCode, 'N',
                       FileStatus, RegExemp,AddionalExemp,OverrideMiscAmtYN,MiscAmt1,MiscFactor,
                       'N','N','N','N', @glco
                       from HRWI where HRCo = @co and HRRef = @hremp and DednCode = @DednCode
   	     end
   
   		--New
   		else
   			begin
   
   				select @glco = GLCo from PRCO where PRCo = @co
   
   				select @DednCode = DednCode, @FileStatus = FileStatus, @RegExemp = RegExemp, 
   					@AddionalExemp = AddionalExemp, @OverrideMiscAmtYN = OverrideMiscAmtYN, 
   					@MiscAmt1 = MiscAmt1, @MiscFactor = MiscFactor
   					from HRWI where HRCo = @co and HRRef = @hremp and DednCode = @DednCode
   	
   				--do an update statement.
   				update PRED set EmplBased = 'N', FileStatus = @FileStatus, RegExempts = @RegExemp,
   				AddExempts = @AddionalExemp, OverMiscAmt = @OverrideMiscAmtYN, MiscAmt = @MiscAmt1,
   				MiscFactor = @MiscFactor, OverLimit = 'N', NetPayOpt = 'N', AddonType = 'N', 
   				OverCalcs = 'N', GLCo = @glco
   				where PRCo = @co and Employee = @employee and DLCode = @DednCode
   			end
   
   
   
       end
   
      bspexit:
   
      	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRPRInsert] TO [public]
GO
