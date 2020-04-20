SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE         proc [dbo].[vspJCCTForLinkCT]
/***********************************************************
* CREATED BY:		CHS 01/28/08
* MODIFIED By :		GF 06/30/2009 - issue #134631 added validation for linking cost type to itself.
*
*
* USAGE:
* validates JC Cost Type
* an error is returned if any of the following occurs
* not Cost Type passed, no Cost Type found.
*
* INPUT PARAMETERS
*   PhaseGroup
*   CostType
*
* OUTPUT PARAMETERS
*   @desc     Description for grid
*   @msg      error message if error occurs otherwise Description returned
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(	@phasegroup tinyint = null, 
	@linkcosttype varchar(10) = null, 
	@linkcosttypeout bJCCType = null output,
	@costtype varchar(10) = null, 
	@desc varchar(60) output, 
	@msg varchar(60) output
)

as
set nocount on

declare @rcode int, @rcount int

select @rcode = 0
select @msg = ''

if @phasegroup is null
	begin
	select @msg = 'Missing Phase Group!', @rcode = 1
	goto bspexit
	end

if @linkcosttype is null
	begin
	select @msg = 'Missing Cost Type!', @rcode = 1
	goto bspexit
	end
   
---- If @linkcosttype is numeric then try to find
if dbo.bfIsInteger(@linkcosttype) = 1 and len(@linkcosttype) < 4
       begin
		if convert(numeric(3,0),@linkcosttype) <0 or convert(numeric(3,0),@linkcosttype)>255
			begin
			select @msg = 'CostType must be between 0 and 255.', @rcode = 1
			goto bspexit
			end

		select @linkcosttypeout = CostType, @desc = Abbreviation, @msg = Description
		from JCCT
		where PhaseGroup = @phasegroup and CostType = convert(int,convert(float, @linkcosttype))

       end
   
-- if not numeric or not found try to find as Sort Name 
   if isnull(@linkcosttypeout,'') = ''
   	begin
       	select @linkcosttypeout = CostType, @desc = Abbreviation, @msg = Description
   		from JCCT
   		where PhaseGroup = @phasegroup and CostType=(select min(j.CostType)
                 from bJCCT j where j.PhaseGroup=@phasegroup
                                and j.Abbreviation like @linkcosttype + '%')
   		if @@rowcount = 0
   			begin
   			select @msg = 'JC Cost Type not on file!', @rcode = 1
			if isnumeric(@linkcosttype)=1 select @linkcosttypeout=@linkcosttype
   			goto bspexit
   			end
	end

---- do not allow linking to itself #134631
if @costtype = @linkcosttype
	begin
	select @msg = 'JC Cost Type cannot be linked to itself!', @rcode = 1
	goto bspexit
	end

---- do not allow linking to CostType that is already linked 
if exists (select top 1 1 from JCCT c with (nolock) where @phasegroup = c.PhaseGroup 
					and @linkcosttype = c.CostType and c.LinkProgress is not null)
	begin
	select @msg = 'JC Cost Type is already linked!', @rcode = 1
	goto bspexit
	end
	
----
if exists (select top 1 1 from JCCT c with (nolock) where c.PhaseGroup = @phasegroup and c.LinkProgress = @costtype)
	begin
	select @msg = 'This JC Cost Type has already been linked to!', @rcode = 1
	goto bspexit
	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCCTForLinkCT] TO [public]
GO
