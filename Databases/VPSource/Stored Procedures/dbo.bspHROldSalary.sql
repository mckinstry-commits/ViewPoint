SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHROldSalary    Script Date: 2/4/2003 7:40:42 AM ******/
   /****** Object:  Stored Procedure dbo.bspHROldSalary    Script Date: 8/28/99 9:32:52 AM ******/
   CREATE     proc [dbo].[bspHROldSalary]
   /***********************************************************
    * CREATED BY: ae 10/28/98 
    * MODIFIED By : ae 6/7/99
    *               mh 10/18/00 - Need to return pay type (salary or hourly wage).
    *               allenn - 2/28/2002 issue 13002
	*				mh 12/10/07 - Issue 28461 - Check if there is a later salary history record
    * USAGE:
    * 
    * This procedure (bspHROldSalary) returns the latest salary for the resource based on EffectiveDate
    *
    * INPUT PARAMETERS
    *   @HRCo - HR Company	
    *   @HRRef - HR Reference
    *  
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of EarnCode
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   	(@HRCo bCompany = null, @HRRef varchar(15), @EffectiveDate bDate, @OldSalary bUnitCost output, 
           @Type varchar(1) output, @oldrecordyn bYN = 'N' output, @msg varchar(60) output )
   as
   
   
   set nocount on
   
   declare @rcode int, @EDate bDate --, @OldSalary bUnitCost,
   
   select @rcode = 0
   
   if @HRCo is null
   	begin
   	select @msg = 'Missing HR Company', @rcode = 1
   	goto bspexit
   	end
   
   if @HRRef is null
   	begin
   	select @msg = 'Missing HR Reference Number', @rcode = 1
   	goto bspexit
   	end
   
   if @EffectiveDate is null
   	begin
   	select @msg = 'Missing Effective Date', @rcode = 1 
   	goto bspexit
   	end
   
   
   select @EDate = Max(EffectiveDate) 
   from dbo.HRSH with (nolock) 
   where HRCo = @HRCo and HRRef = convert(int,@HRRef) and EffectiveDate < @EffectiveDate
   
   --Begin 10/18/00 mh
   /*
   select @OldSalary = NewSalary from HRSH where HRCo = @HRCo and HRRef = @HRRef and EffectiveDate = @EDate
   if @@rowcount = 0 select @OldSalary = 0
   
   select @msg = convert(varchar(60), @OldSalary)
   */
   
   select @EDate = isnull(@EDate, @EffectiveDate)
   
   select @OldSalary = NewSalary, @Type = Type from dbo.HRSH with (nolock) where HRCo = @HRCo and HRRef = convert(int,@HRRef) and EffectiveDate = @EDate
   if @@rowcount = 0 select @OldSalary = 0
   --End 10/18/00 mh
   
   
   --debug
   --select 'Date=' + CONVERT(varchar(12), @Date)
   --select 'Seq=' + CONVERT(varchar(12),@Seq)
   --select 'OldSalary=' + CONVERT(varchar(12),@OldSalary)

	--Issue 28461 - Check if there is a later salary history record and return 'Y' if so.
	select @oldrecordyn = 'N'

	if exists(select EffectiveDate from HRSH where HRCo = @HRCo and HRRef = @HRRef and
	EffectiveDate > @EffectiveDate)
	begin
		select @oldrecordyn = 'Y'
	end

--	if exists(select EffectiveDate 
--	from HRSH where HRCo = @HRCo and HRRef = @HRRef and 
--	EffectiveDate < (select max(EffectiveDate) from HRSH where HRCo = @HRCo and HRRef = @HRRef))
--	begin
--		select @oldrecordyn = 'Y'
--	end
  		   				
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHROldSalary] TO [public]
GO
