SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspHRDLTypeDescVal]
   /************************************************************************
   * CREATED:  mh 10/16/03    
   * MODIFIED: mh 10/23/03 issue 22737 added @rateamt1 output param   
   *
   * Purpose of Stored Procedure
   *
   *	Validate D/L code against PRDL    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   	(@hrco bCompany, @hrref bHRRef, @bencode varchar(10), @prco bCompany = null, 
   	@dlcode bEDLCode, @dltype char(1) output, @description bDesc output, 
   	@dlinstcnt int output, @rateamt1 bUnitCost output, @msg varchar(60) output)
   
   as
   set nocount on
   
       declare @rcode int
       select @rcode = 0, @dlinstcnt = 0
   
   	if @hrco is null
   	begin
   		select @msg = 'Missing HR Company', @rcode = 1
   		goto bspexit
   	end
   
   	if @prco is null
   	begin
   		select @msg = 'Missing PR Company', @rcode = 1
   		goto bspexit
   	end
   
   	if @dlcode is null
   	begin
   		select @msg = 'Missing Code', @rcode = 1
   		goto bspexit
   	end
   
   	exec @rcode = bspPRDLTypeDescVal @prco, @dlcode, @dltype output, @description output, @rateamt1 output, @msg output
   
   	if @rcode <> 0 goto bspexit
   
   	--Looking for how many times this DLCode is being used on another Benefit Code.
   /*
   	select @dlinstcnt = count(a.HRCo) 
   	from HRBL a with (nolock)
   	join HRBL b with (nolock) on 
   	a.HRCo = b.HRCo and a.HRRef = b.HRRef and
   	a.DLCode = b.DLCode and a.DLType = b.DLType and a.BenefitCode <> b.BenefitCode
   	where a.HRCo = @hrco and a.HRRef = @hrref and a.DLCode = @dlcode and a.DLType = @dltype	
   */
   
   	select @dlinstcnt = count(HRCo) from HRBL with (nolock)
   	where HRCo = @hrco and HRRef = @hrref and BenefitCode <> @bencode and DependentSeq = 0 and
   	DLCode = @dlcode and DLType = @dltype
   
   
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRDLTypeDescVal] TO [public]
GO
