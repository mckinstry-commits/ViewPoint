SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspInsertPortidocParticipantPR]
@co bCompany, 
@prgroup bGroup, 
@prenddate bDate, 
@payseq int, 
@empl bEmployee, 
@UserName bVPUserName

AS
BEGIN
	SET NOCOUNT ON;
	SELECT	NEWID() as ParticipantId,
				e1.FirstName as FirstName,
				e1.LastName as LastName,
				e1.Email as Email,
				ISNULL(e1.FirstName,'') + ISNULL(' ' + e1.LastName, '') as DisplayName,
				'' as Title,
				'' as CompanyName,
				@co as CompanyNumber,				
				'Associated' as Status,				
				'A0172E82-854D-6C2B-417A-8081D063A835' as DocumentRoleTypeId,
				@UserName as CreatedByUser,
				GETUTCDATE() as DBCreatedDate,
				1 as [Version]
	FROM dbo.PRSQ (nolock) p1 
	INNER JOIN dbo.PREH (nolock) e1 on p1.PRCo = e1.PRCo and p1.PRGroup = e1.PRGroup and p1.Employee = e1.Employee
			AND e1.PayMethodDelivery <> 'N'
				WHERE p1.PRCo = @co 
					and p1.PREndDate = @prenddate
					and p1.PRGroup = @prgroup 
					and p1.PaySeq = @payseq 
					and p1.Employee = @empl
					and p1.CMRef is not null;
END
GO
GRANT EXECUTE ON  [dbo].[vspInsertPortidocParticipantPR] TO [public]
GO
