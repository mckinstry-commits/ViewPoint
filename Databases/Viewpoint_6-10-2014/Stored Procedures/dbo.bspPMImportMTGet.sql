SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMImportMTGet    Script Date: 8/28/99 9:35:13 AM ******/
CREATE  proc [dbo].[bspPMImportMTGet]
/****************************************************************************
   * CREATED BY: 	GF  06/02/99
   * MODIFIED BY:	GF 05/15/2006 - issue #       - 6.x changes
   *
   * USAGE:
   * 	Gets valid material for import material.     
   *
   * INPUT PARAMETERS:
   *	Template, MatlGroup, ImportMaterial, PMCo, Override, StdTemplate
   *
   * OUTPUT PARAMETERS:
   *	Material
   *       
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
 *****************************************************************************/
(@template varchar(10), @matlgroup bGroup, @importmaterial varchar(30),
 @pmco bCompany, @override bYN = 'N', @stdtemplate varchar(10) = '',
 @material bMatl output, @mdescription bDesc output, @found bYN output)
as
set nocount on


declare @rcode int, @xreftype tinyint, @imaterial bMatl

select @rcode = 0, @mdescription = '', @xreftype = 3, @found = 'N'

select @imaterial = substring(@importmaterial,1,20)

if @importmaterial is not null
	begin   
	select @material = isnull(Material,'')
	from bPMUX with (nolock)
	where Template=@template and XrefType=@xreftype and XrefCode=@importmaterial
	if @@rowcount = 0
		begin
		if @override = 'Y'
			begin
			select @material = isnull(Material,'')
			from bPMUX with (nolock)
			where Template=@stdtemplate and XrefType=@xreftype and XrefCode=@importmaterial
			if @@rowcount <> 0 select @found = 'Y'
			end
		end
	else
		select @found = 'Y'
	end

------ xref not found, look in HQMT for import material code
if isnull(@material,'') = ''
	begin
	select @material = Material, @mdescription=Description
	from bHQMT where MatlGroup=@matlgroup and Material=@imaterial
	if @@rowcount <> 0 select @found = 'Y'
	end
else
	------ get HQMT description
	begin
	select @mdescription=Description
	from bHQMT where MatlGroup=@matlgroup and Material=@material
	if @@rowcount <> 0 select @found = 'Y'
	end

------ if still no material set to import material
if isnull(@material,'') = ''
	begin
	select @material=@imaterial, @mdescription=null
	end
     
------ if no material found and import material is empty, set all output parameters to null
if @material = ''
	begin
	select @material=Null, @mdescription=Null
	end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMImportMTGet] TO [public]
GO
