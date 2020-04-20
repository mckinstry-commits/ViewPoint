SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mike Brewer
-- Create date: 4/27/09
-- Description:	PCQualificationReport, States subreport
--Null values are used if enduser chooses Blank Form
-- =============================================
CREATE PROCEDURE [dbo].[brptPCQualStatesSubReport]
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
		Country as 'Country',
		[State] as 'State',
		License as 'License',
		Expiration as 'Expiration',
		SalesTaxNo as 'SalesTaxNo',
		UINo as 'UINo'
		from PCStates
		where Vendor = @Vendor
		and VendorGroup = @VendorGroup

		Union all

		Select	'B' as 'CRType',
		'1' as 'Line', NULL as 'GLCo', NULL as 'VendorGroup',	NULL as 'Vendor',NULL as 'Country',
		NULL as 'State', NULL as 'License', NULL as 'Expiration', NULL as 'SalesTaxNo', NULL as 'UINo'

		Union all

		Select	'B' as 'CRType',
		'2' as 'Line', NULL as 'GLCo', NULL as 'VendorGroup',	NULL as 'Vendor',NULL as 'Country',
		NULL as 'State', NULL as 'License', NULL as 'Expiration', NULL as 'SalesTaxNo', NULL as 'UINo'

		Union all

		Select	'B' as 'CRType',
		'3' as 'Line', NULL as 'GLCo', NULL as 'VendorGroup',	NULL as 'Vendor',NULL as 'Country',
		NULL as 'State', NULL as 'License', NULL as 'Expiration', NULL as 'SalesTaxNo', NULL as 'UINo'

		Union all

		Select	'B' as 'CRType',
		'4' as 'Line', NULL as 'GLCo', NULL as 'VendorGroup',	NULL as 'Vendor',NULL as 'Country',
		NULL as 'State', NULL as 'License', NULL as 'Expiration', NULL as 'SalesTaxNo', NULL as 'UINo'

		Union all

		Select	'B' as 'CRType',
		'5' as 'Line', NULL as 'GLCo', NULL as 'VendorGroup',	NULL as 'Vendor',NULL as 'Country',
		NULL as 'State', NULL as 'License', NULL as 'Expiration', NULL as 'SalesTaxNo', NULL as 'UINo'

END

GO
GRANT EXECUTE ON  [dbo].[brptPCQualStatesSubReport] TO [public]
GO
