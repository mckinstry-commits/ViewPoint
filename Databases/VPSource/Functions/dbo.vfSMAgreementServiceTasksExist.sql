SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 07/16/12
-- Description:	Returns a flag if service tasks exist
-- =============================================
CREATE FUNCTION [dbo].[vfSMAgreementServiceTasksExist]
(
	@SMCo bCompany,
	@Agreement varchar(15),
	@Revision int,
	@Service int
)
RETURNS bYN
AS
BEGIN
	DECLARE @TasksExist bYN
	
	IF EXISTS(SELECT 1 FROM SMAgreementServiceTask 
		WHERE SMCo = @SMCo
		AND Agreement = @Agreement
		AND Revision = @Revision
		AND Service = @Service)
	BEGIN
		SELECT @TasksExist='Y'
	END
	ELSE
	BEGIN
		SELECT @TasksExist='N'
	END

	RETURN @TasksExist
END
GO
GRANT EXECUTE ON  [dbo].[vfSMAgreementServiceTasksExist] TO [public]
GO
