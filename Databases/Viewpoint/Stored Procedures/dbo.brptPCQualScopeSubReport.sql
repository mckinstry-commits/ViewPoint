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
CREATE PROCEDURE [dbo].[brptPCQualScopeSubReport]
--	@Type  varchar(12) --Report or Blank Form
 @Vendor bVendor, @VendorGroup bGroup
AS
BEGIN

select 
		'R' as 'CRType',
		NULL as 'Line',
		NULL as 'GLCo',
		P.VendorGroup as 'VendorGroup',
		P.Vendor as 'Vendor',
		P.PhaseCode as 'PhaseCode',
		(select [Description] from JCPM where Phase = P.PhaseCode and PhaseGroup = P.PhaseGroup) as 'PhaseCodeDesc',
		P.PhaseGroup as 'PhaseGroup',
		P.ScopeCode as 'ScopeCode',
		(select [Description]from PCScopeCodes where VendorGroup = P.VendorGroup and ScopeCode = P.ScopeCode ) as 'ScopeCodeDesc',
		case P.SelfPerformed  when 'Y' then 'X' else '' end as 'SelfPerformed',
		CONVERT(varchar(12), CONVERT (decimal(6,2), P.WorkPrevious * 100 )) as 'WorkPrevious',
		Convert(varchar(12), Convert (decimal(6,2), P.WorkNext * 100     )) as 'WorkNext',
		case P.NoPriorWork  when 'Y' then 'X' else '' end as 'NoPriorWork'
		from PCScopes P
		where Vendor = @Vendor
		and VendorGroup = @VendorGroup

		Union all

		select 'B' as 'CRType', '1' as 'Line', NULL as 'GLCo', NULL as 'VendorGroup', NULL as 'Vendor',
		NULL as 'PhaseCode', NULL as 'PhaseCodeDesc', NULL as 'PhaseGroup', NULL as 'ScopeCode',
		NULL as 'ScopeCodeDesc', NULL 'SelfPerformed', NULL as 'WorkPrevious', NULL as 'WorkNext', NULL as 'NoPriorWork'

		Union all

		select 'B' as 'CRType', '2' as 'Line', NULL as 'GLCo', NULL as 'VendorGroup', NULL as 'Vendor',
		NULL as 'PhaseCode', NULL as 'PhaseCodeDesc', NULL as 'PhaseGroup', NULL as 'ScopeCode',
		NULL as 'ScopeCodeDesc', NULL 'SelfPerformed', NULL as 'WorkPrevious', NULL as 'WorkNext', NULL as 'NoPriorWork'

		Union all

		select 'B' as 'CRType', '3' as 'Line', NULL as 'GLCo', NULL as 'VendorGroup', NULL as 'Vendor',
		NULL as 'PhaseCode', NULL as 'PhaseCodeDesc', NULL as 'PhaseGroup', NULL as 'ScopeCode',
		NULL as 'ScopeCodeDesc', NULL 'SelfPerformed', NULL as 'WorkPrevious', NULL as 'WorkNext', NULL as 'NoPriorWork'

		Union all

		select 'B' as 'CRType', '4' as 'Line', NULL as 'GLCo', NULL as 'VendorGroup', NULL as 'Vendor',
		NULL as 'PhaseCode', NULL as 'PhaseCodeDesc', NULL as 'PhaseGroup', NULL as 'ScopeCode',
		NULL as 'ScopeCodeDesc', NULL 'SelfPerformed', NULL as 'WorkPrevious', NULL as 'WorkNext', NULL as 'NoPriorWork'

		Union all

		select 'B' as 'CRType', '5' as 'Line', NULL as 'GLCo', NULL as 'VendorGroup', NULL as 'Vendor',
		NULL as 'PhaseCode', NULL as 'PhaseCodeDesc', NULL as 'PhaseGroup', NULL as 'ScopeCode',
		NULL as 'ScopeCodeDesc', NULL 'SelfPerformed', NULL as 'WorkPrevious', NULL as 'WorkNext', NULL as 'NoPriorWork'

END

GO
GRANT EXECUTE ON  [dbo].[brptPCQualScopeSubReport] TO [public]
GO
