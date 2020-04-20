SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[uspDistGrpVal] /** User Defined Validation Procedure **/
(@Type CHAR(1) = 0, 
	@OrgID VARCHAR(10) = 0
	, @msg VARCHAR(MAX) OUTPUT)
AS


declare @rcode int
select @rcode = 0

IF @Type = 'O'
BEGIN
	/****/
	if exists(select * from [udOperatingUnit] with (nolock) where   @OrgID = [OperatingUnit] )
	begin
	select @msg = isnull([UnitName],@msg) from [udOperatingUnit] with (nolock) where   @OrgID = [OperatingUnit]  
	end
	else
	begin
	select @msg = 'Not a valid Operating Unit', @rcode = 1
	goto spexit
	end
END
ELSE
IF @Type = 'R'
BEGIN
	/****/
	if exists(select * from [udRegion] with (nolock) where  @OrgID = [Region] )
	begin
	select @msg = isnull([Name],@msg) from [udRegion] with (nolock) where  @OrgID = [Region]
	end
	else
	begin
	select @msg = 'Not a valid Region', @rcode = 1
	goto spexit
	end
END
ELSE
IF @Type = 'D'
BEGIN
	if exists(select * from dbo.udGLDept with (nolock) where  @OrgID = GLDept )
	begin
	select @msg = isnull(GLPI.Description,@msg) 
		from dbo.udGLDept with (nolock) 
			INNER JOIN dbo.GLPI ON GLPI.PartNo = 3 AND GLPI.Instance = GLDept AND Co = GLPI.GLCo
		where  @OrgID = GLDept
	end
	else
	begin
	select @msg = 'Not a valid Region', @rcode = 1
	goto spexit
	end
END
ELSE
IF @Type = 'X'
BEGIN
	if exists(select * from dbo.udDeptReg with (nolock) where  @OrgID = Seq And  @Type = [Type] )
	begin
	select @msg = isnull(GLPI.Description + ' / ' + Name,@msg) 
		from dbo.udDeptReg with (nolock) 
			INNER JOIN dbo.GLPI ON GLPI.PartNo = 3 AND GLPI.Instance = Dept AND GLPI.GLCo = dbo.udDeptReg.GLCo
			INNER JOIN dbo.udRegion ON dbo.udRegion.Region = dbo.udDeptReg.Region
		where  @OrgID = Seq And  @Type = udDeptReg.Type 
	end
	else
	begin
	select @msg = 'Not a valid Region', @rcode = 1
	goto spexit
	end
END

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspDistGrpVal] TO [public]
GO
