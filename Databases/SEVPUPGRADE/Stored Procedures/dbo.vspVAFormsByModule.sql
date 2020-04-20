SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[vspVAFormsByModule]
-- =============================================
-- Created: Aaron Lang 5/14/07
-- Modified: GG 08/23/07 - corrected to retrieve forms based on module assignments, include custom forms,
--							and check license level.
-- Modified: AL 12/10/07 - corrected to include user created forms.
--											AL 11/20/08 - Now using DDFHSecurable rather than DDFHc #131085
--											AL 11/25/08 - Removed check "AND f.SecurityForm = f.[Form]" from where clause. #130969
--			CC	07/14/09 - #129922 - Added link for form header to culture text
--			MCP 12/16/09 - #136936 - Added check to exclude all forms that only inherit add/update/delete permissions from parent form
-- Usage:
--	Called by VA Form Security to return form titles resticted by module assignment
--
-- Inputs:
--	@ModuleList			comma separated string of Modules ('AP,AR,GL,JC,' etc.)
--
-- Output:
--	Resultset of form titles
--
-- =============================================

	@ModuleList varchar(500) = NULL,
	@culture	INT			 = NULL

as
set nocount on

select distinct ISNULL(CultureText.CultureText, f.Title) AS Title
--from dbo.vDDMF mf (nolock)	-- use forms assigned to modules
From dbo.vDDFHSecurable f (nolock)	-- use DDFHShared to include custom UD forms 
LEFT OUTER JOIN DDCTShared AS CultureText ON CultureText.CultureID = @culture AND CultureText.TextID = f.TitleID
join dbo.vDDMO m (nolock) on f.Mod = m.Mod
where (f.AlwayInheritAddUpdateDelete<>'Y' or f.AlwayInheritAddUpdateDelete is null) and charindex(f.Mod,@ModuleList)>0 and f.LicLevel <= m.LicLevel	--AND f.SecurityForm = f.[Form]-- module and license level restrictions
order by ISNULL(CultureText.CultureText, f.Title) 


GO
GRANT EXECUTE ON  [dbo].[vspVAFormsByModule] TO [public]
GO
