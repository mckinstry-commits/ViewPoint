SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMImportCTGet    Script Date: 8/28/99 9:35:12 AM ******/
    CREATE   proc [dbo].[bspPMImportCTGet]
    /****************************************************************************
    * CREATED BY: 	GF  05/29/99
    * MODIFIED BY:
    *
    * USAGE:
    * 	Gets valid CostType for import cost type.     
    *
    * INPUT PARAMETERS:
    *	Template, PhaseGroup, ImportCostType, PMCo, Override, StdTemplate
    *
    * OUTPUT PARAMETERS:
    *	CostType, CostOnly
    *       
    * RETURN VALUE:
    * 	0 	    Success
    *	1 & message Failure
    *
    *****************************************************************************/
    (@template varchar(10), @phasegroup bGroup, @importcosttype varchar(30),
     @pmco bCompany, @override bYN = 'N', @stdtemplate varchar(10) = '',
     @costtype bJCCType output, @costonly bYN = 'N' output)
as
set nocount on

declare @rcode int, @xreftype tinyint, @icosttype bJCCType

select @rcode = 0, @xreftype = 1

if isnull(@importcosttype,'') <> ''
	begin
	if RIGHT(@importcosttype,1) = '.'
		begin
		select @importcosttype = substring(@importcosttype,1,datalength(@importcosttype)-1)
		end
	end
     
if IsNumeric(@importcosttype) = 1
	begin
	select @icosttype = convert(tinyint,@importcosttype)
	end
else
	begin
	select @icosttype = 0
	end

if @importcosttype is not null
	begin   
	select @costtype = isnull(CostType,0), @costonly = isnull(CostOnly,'N')
	from bPMUX with (nolock) where Template=@template and XrefType=@xreftype and XrefCode=@importcosttype and PhaseGroup=@phasegroup
	if @@rowcount = 0
		begin
		select @costtype = isnull(CostType,0), @costonly = isnull(CostOnly,'N')
		from bPMUX with (nolock) where Template=@template and XrefType=@xreftype and XrefCode=@importcosttype -- -- -- and PhaseGroup=@phasegroup
		if @@rowcount = 0 and @override = 'Y'
			begin
			select @costtype = isnull(CostType,0), @costonly = isnull(CostOnly,'N')
			from bPMUX with (nolock) where Template=@stdtemplate and XrefType=@xreftype and XrefCode=@importcosttype and PhaseGroup=@phasegroup
			if @@rowcount = 0 
				begin
                select @costtype = isnull(CostType,0), @costonly = isnull(CostOnly,'N')
                from bPMUX with (nolock) where Template=@stdtemplate and XrefType=@xreftype and XrefCode=@importcosttype -- -- -- and PhaseGroup=@phasegroup
                end
			end
		end
	end


if @costtype is null or @costtype=0
	begin
	select @costtype = isnull(CostType,0), @costonly = 'N'
	from bJCCT with (nolock) where PhaseGroup=@phasegroup and CostType=@icosttype
	if @costtype=0 select @costtype=@icosttype, @costonly='N'
	end


if @costtype=0
	begin
	select @costtype=null, @costonly='N'
	end  


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMImportCTGet] TO [public]
GO
