SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRDependentVal    Script Date: 2/4/2003 6:53:50 AM ******/
   /****** Object:  Stored Procedure dbo.bspHRDependentVal    Script Date: 8/28/99 9:32:50 AM ******/
   CREATE  procedure [dbo].[bspHRDependentVal]
   /*************************************
   *  Created by:??
   *  Date created: ??
   *  Modified:  MarkH 4/27/07 - Issue 124168
   *  validates HR Resources
   *
   * Pass:
   *   HRCo - Human Resources Company
   *   HRRef - Resource ID to be Validated
   *   Seq   - Dependent Seqence Number
   *
   *
   * Success returns:
   *   Concatinated:  LastName, FirstName, MiddleName
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@HRCo bCompany = null, @HRRef varchar(15), @Seq varchar(15), @RefOut int output, @msg varchar(75) output)
   as
   	set nocount on
   	declare @rcode int
      	select @rcode = 0
   
   if @HRCo is null
   	begin
   	select @msg = 'Missing HR Company', @rcode = 1
   	goto bspexit
   	end
   
   if @HRRef is null
   	begin
   	select @msg = 'Missing HR Resource Number', @rcode = 1
   	goto bspexit
   	end
   
   if @Seq is null
   	begin
   	select @msg = 'Missing HR Depedent Sequence Number', @rcode = 1
   	goto bspexit
   	end
   
   
   if convert(int,@Seq) = 0
   	begin
   	select @msg = 'Same as Resource Number'
   	select @RefOut = convert(int,@Seq)
   	goto bspexit
   
   	end
   
   if @Seq = '0'
   	begin
   	select @msg = 'Same as Resource Number'
   	select @RefOut = convert(int,@Seq)
   	goto bspexit
   	end
   
   select @msg = Name, @RefOut = Seq
   from HRDP
   where HRCo = @HRCo and HRRef = convert(int,@HRRef) and Seq = convert(int,@Seq)
   
	--Issue 124168 - Set return code = 1 if dependent seq is invalid/not set up.
   if @RefOut is null
   	begin
   	select @msg = 'Dependent not set up.', @rcode = 1
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRDependentVal] TO [public]
GO
