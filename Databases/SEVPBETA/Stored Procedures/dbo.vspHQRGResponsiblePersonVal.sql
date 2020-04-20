SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[vspHQRGResponsiblePersonVal]
   /***************************************************
   * CREATED BY    : MV 1/7/08
   *
   * Usage:
   *   Validates Reviewer is a Responsible Person in vHQRG 
   *
   * Input:
   *	@reviewergroup         
   * Output:
   *   @msg          description
   *
   * Returns:
   *   0             success
   *   1             error
   *************************************************/
   	(@responsiblePerson varchar(3) = null, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
	if @responsiblePerson is null
   	begin
		select @msg = 'Missing Responsible Person',@rcode=1
   		goto vspexit
   	end
	
	
	if not exists (select 1 from HQRV v with (nolock) left join HQRG r with (nolock) on v.Reviewer=r.ResponsiblePerson
		where v.Reviewer=@responsiblePerson)
	begin
		select @msg = 'This reviewer is not a Responsible Person in a Reviewer Group.',@rcode=1
		goto vspexit 
	end 

	select @msg=Name from HQRV with (nolock) where HQRV.Reviewer=@responsiblePerson  
   
   
   vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQRGResponsiblePersonVal] TO [public]
GO
