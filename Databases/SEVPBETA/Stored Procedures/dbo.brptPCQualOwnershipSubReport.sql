SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mike Brewer
-- Create date: 4/27/09
-- Description:	PCQualificationReport, Ownership subreport
--Null values are used if enduser chooses Blank Form
-- =============================================
CREATE PROCEDURE [dbo].[brptPCQualOwnershipSubReport]
--	@Type  varchar(12) --Report or Blank Form
 @Vendor bVendor, @VendorGroup bGroup
AS
BEGIN
		Select
		'R' as 'CRType',
		NULL as 'Line',
		NULL as 'GLCo',
		VendorGroup as 'VendorGroup',
		Vendor as 'Vendor',
		[Name] as 'Name',
		[Role] as 'Role',
		BirthYear as 'BirthYear',
		CONVERT(varchar(10), CONVERT (decimal(6,2),(Ownership * 100))) as 'Ownership'
		from PCOwners
		where Vendor = @Vendor
		and VendorGroup = @VendorGroup

		Union all

		Select	'B' as 'CRType',
		'1' as 'Line', NULL as 'GLCo', Null as 'VendorGroup', NULL as 'Vendor',
		NULL as 'Name', NULL as 'Role', NULL as 'BirthYear', NULL as 'Ownership'

		Union all

		Select	'B' as 'CRType',
		'2' as 'Line', NULL as 'GLCo', Null as 'VendorGroup', NULL as 'Vendor',
		NULL as 'Name', NULL as 'Role', NULL as 'BirthYear', NULL as 'Ownership'

		Union all

		Select	'B' as 'CRType',
		'3' as 'Line', NULL as 'GLCo', Null as 'VendorGroup', NULL as 'Vendor',
		NULL as 'Name', NULL as 'Role', NULL as 'BirthYear', NULL as 'Ownership'

		Union all

		Select	'B' as 'CRType',
		'4' as 'Line', NULL as 'GLCo', Null as 'VendorGroup', NULL as 'Vendor',
		NULL as 'Name', NULL as 'Role', NULL as 'BirthYear', NULL as 'Ownership'

		Union all

		Select	'B' as 'CRType',
		'5' as 'Line', NULL as 'GLCo', Null as 'VendorGroup', NULL as 'Vendor',
		NULL as 'Name', NULL as 'Role', NULL as 'BirthYear', NULL as 'Ownership'
		
END

GO
GRANT EXECUTE ON  [dbo].[brptPCQualOwnershipSubReport] TO [public]
GO
