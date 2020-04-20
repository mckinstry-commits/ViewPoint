SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRPRDelete    Script Date: 2/4/2003 7:41:16 AM ******/
   /****** Object:  Stored Procedure dbo.bspHRPRDelete  ******/
     CREATE  procedure [dbo].[bspHRPRDelete]
      /*************************************************************************************************
       * CREATED BY: ae 1/20/00
       * MODIFIED By :
       *
       * USAGE:This routine is called from HR Resource Master and PR Employee Master.
       *
       * INPUT PARAMETERS
       *     @co         = PR Company
       *     @employee   = PR Employee #
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
   
      select @rcode = 0
   
      if @source='PR'
         begin
            delete from HRWI where HRCo = @co and HRRef = @employee and DednCode = @DednCode
         end
   
      if @source='HR'
         begin
           delete from PRED where PRCo = @co and Employee = @employee and DLCode = @DednCode
         end
   
      bspexit:
   
      	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRPRDelete] TO [public]
GO
