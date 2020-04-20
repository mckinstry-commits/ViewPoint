SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMProjFirmVal    Script Date: 8/28/99 9:33:06 AM ******/
   CREATE proc [dbo].[bspPMProjFirmVal]
   /*************************************
   * CREATED BY    : LM  9/3/98
   * LAST MODIFIED :
   * validates PM Firm by Project
   *
   * Pass:
   *   PM Company
   *   PM Project
   *	PM VendorGroup
   *	PM FirmSort    Firm or sortname of firm, will validate either
   * Returns:
   *	FirmNumber
   *       Firm Contact
   * Success returns:
   *      FirmNumber and Firm Name
   *
   * Error returns:
   *	1 and error message
   *******
   *******************************/
   	(@pmco bCompany, @project bJob, @vendorgroup bGroup, @firmsort varchar(15),
   	 @firmout bFirm = null output, @msg varchar(60) output)
   
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @firmsort is null
   	begin
   	select @msg = 'Missing Firm!', @rcode = 1
   	goto bspexit
   	end
   
   -- If @firm is numeric then try to find firm number
   if isnumeric(@firmsort) = 1
   	select @firmout = m.FirmNumber, @msg=m.FirmName
   	from PMFM m with (nolock) 
   	JOIN PMPF f with (nolock) ON m.VendorGroup=f.VendorGroup and m.FirmNumber=f.FirmNumber
   	 and f.PMCo=@pmco and f.Project = @project
   	where m.VendorGroup = @vendorgroup
   	and m.FirmNumber = convert(int,convert(float, @firmsort))
   
   -- if not numeric or not found try to find as Sort Name
   if @@rowcount = 0
   	begin
   	select @firmout = m.FirmNumber, @msg = m.FirmName
   	from PMFM m with (nolock) 
   	JOIN PMPF f with (nolock) ON m.VendorGroup=f.VendorGroup and m.FirmNumber=f.FirmNumber
   	and f.PMCo=@pmco and f.Project = @project
   	where m.VendorGroup = @vendorgroup and m.SortName = @firmsort
   	if @@rowcount = 0
   		begin
   		select @msg = 'PM Firm ' + convert(varchar(6),isnull(@firmsort,'')) + ' not set up for Project ' + @project + '!', @rcode = 1
   		goto bspexit
   		end
   	end
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMProjFirmVal] TO [public]
GO
