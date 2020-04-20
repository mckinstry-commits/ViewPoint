SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		CC
-- Create date: 08/14/09
-- Description:	Gets all attachment types
-- =============================================
CREATE PROCEDURE [dbo].[vspDMGetAttachmentTypes]
AS
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT AttachmentTypeID, dbo.DMAttachmentTypesShared.[Name]
		FROM DMAttachmentTypesShared;
GO
GRANT EXECUTE ON  [dbo].[vspDMGetAttachmentTypes] TO [public]
GO
