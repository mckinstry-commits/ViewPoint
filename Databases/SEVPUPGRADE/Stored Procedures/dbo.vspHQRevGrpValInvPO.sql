SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[vspHQRevGrpValInvPO]
   /***************************************************
   * CREATED BY    : MV 12/04/07
   *
   * Usage:
   *   Validates Reviewer Group based on Type: Invoice, PO 
   *   Used by JC Job Master
   * Input:
   *	@reviewergroup
   *	@type	'I','P'        
   * Output:
   *   @msg          description
   *
   * Returns:
   *   0             success
   *   1             error
   *************************************************/
   	(@reviewergroup varchar(10) = null, @type varchar(1) = 'B', @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
	if @reviewergroup is null
   	begin
		select @msg = 'Missing Reviewer Group',@rcode=1
   		goto vspexit
   	end

	if not exists (select 1 from HQRG r with (nolock) where r.ReviewerGroup=@reviewergroup)
		begin
		select @msg = 'Invalid Reviewer Group.',@rcode=1
		goto vspexit 
		end 

	if @type = 'I' --Invoice
	begin
	if not exists (select 1 from HQRG r with (nolock) where r.ReviewerGroup=@reviewergroup and
		r.ReviewerGroupType in (1,3))
		begin
		select @msg = 'Invalid Reviewer Group for Invoice.',@rcode=1
		goto vspexit 
		end 
	end
	
	if @type = 'P' --Purchase Order
	begin
	if not exists (select 1 from HQRG r with (nolock) where r.ReviewerGroup=@reviewergroup and
		r.ReviewerGroupType in (2,3))
		begin
		select @msg = 'Invalid Reviewer Group for Purchase Order.',@rcode=1
		goto vspexit 
		end 
	end

	select @msg=Description from HQRG with (nolock) where HQRG.ReviewerGroup=@reviewergroup  
   
   
   vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQRevGrpValInvPO] TO [public]
GO
